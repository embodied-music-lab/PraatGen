#!/usr/bin/env python3
"""PraatGen usage log, for the maintainer only. It isn't in the released
plugin: build/build_plugin.py --with-usage-log adds it to a separately named
test package. PraatGen works from its skill instructions and rules file alone.
This hook never blocks a turn, never adds context and never changes what a
session does. Cowork runs plugin hooks only in a task, so chat threads aren't
logged.

The rules file is the skill's PRAATGEN_RULES_FULL.md, found through
CLAUDE_PLUGIN_ROOT (RULES). The hook acts only when that file is there.

Whether PraatGen is on. A session's state is the latest of two kinds of event
in its transcript.
  ON   The skill invoked (a tool call whose "skill" names this skill) or the
       skill's own instructions loaded (the "Base directory for this skill:"
       entry), which includes the user picking praatgen from the / menu.
  OFF  A message the user typed that contains the off command anywhere
       (OFF_FORM): "praatgen off" in any capitalization, with or without the
       space or punctuation between the words, and with a doubled letter
       allowed; "off" needs both f's, so "PraatGen of course" is not it.
       The off command from the / menu is one. A message that is itself a /
       pick of praatgen is not OFF. A tool result, a system-inserted entry
       and assistant text do nothing.
Only a session whose latest event is ON is logged (USAGE_SESSIONS). A session
that never had an ON event, or whose latest event is OFF, gets no line and no
log folder. A new ON event turns logging back on, and the log skips the calls
made while PraatGen was off. Nothing else is an ON event: a session that only
reads the rules file, such as a maintainer session, isn't logged.

  prompt   At each typed message.
  stop     At each turn end.

At each, a session that is on and whose transcript holds entries gets one line
for every model call not yet logged, then one summary line for each turn
those calls belong to. A call is an assistant message id; a streamed message
repeats its id, and its last entry's usage counts. Calls a missed turn end
left out are caught at the next typed message. A summary covers its whole
turn as it stands, so a turn that ends more than once has one summary per
end, and the last one counts. A session whose replies carry no usage gets one
line saying usage can't be measured, and why. A transcript that is not yet
written is read again briefly. An error inside the hook is logged as an error
line. Each line is the time and one JSON object; USAGE_LINES lists each kind's
fields and USAGE_FIELD says what each field means.
"""
import collections, contextlib, json, os, re, sys, time

# ---- Settings and constants: every fixed path, phrase and limit the hook uses ----
HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN_ROOT = os.environ.get('CLAUDE_PLUGIN_ROOT') or os.path.join(HERE, os.pardir)
SKILL = 'praatgen'                          # the skill's name and its folder under skills/
RULES = os.path.join(PLUGIN_ROOT, 'skills', SKILL, 'PRAATGEN_RULES_FULL.md')
MODES = ('prompt', 'stop')                  # the hooks.json events this file serves
# The session's outputs folder, which a Cowork session can send files from;
# /tmp when that folder can't be written.
LOG_DIR = '/mnt/user-data/outputs/praatgen'
LOGS = (os.path.join(LOG_DIR, 'usage.log'), '/tmp/praatgen-usage.log')

SKILL_LOADED = 'Base directory for this skill:'   # how a loaded skill's instructions begin
OFF_EVENT = 'off command'                   # the label of an OFF event
# What counts as the off command in a typed message, anywhere in it, any case.
OFF_FORM = re.compile(r'\bp+r+a+t+\W*g+e+n+[\W_]*o+ff+\b', re.I)
# The forms a / pick of the skill takes in a typed message, defined once:
# the message begins with the command (the plugin name may come first), or it carries
# the client's slash-command marker (<command-name>/praatgen</command-name>).
SLASH = rf'/(?:{SKILL}:)?{SKILL}'
PICK_FORMS = (re.compile(rf'\A\s*{SLASH}(?![\w:-])', re.I),
              re.compile(rf'<command-name>\s*{SLASH}\s*</command-name>', re.I))

TRANSCRIPT_TRIES = 5                        # reads of the transcript before giving up
TRANSCRIPT_WAIT = 0.2                       # seconds between them
LOG_ERROR_CHARS = 300

SHELL_TOOL = re.compile(r'bash|shell|terminal|exec', re.I)
PATH_KEY = re.compile(r'path|file|dest|target', re.I)

USAGE_SESSIONS = ('praatgen',)              # kinds of session (see classify) that are logged
USAGE = ('input_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens', 'output_tokens')
USAGE_TARGET_CHARS = 60                     # characters of a command kept as its target
COMPACT_BOUNDARY = 'compact_boundary'       # a system entry's subtype at a compaction
NO_USAGE = 'replies hold no message id with usage'
RULES_GROUP, COMMANDS_GROUP = 'rules file', 'commands'
USAGE_FIELD = {
    'kind': 'call, turn, unmeasured or error',
    'session': 'the session id',
    'event': 'the hook that wrote the line: stop (turn end) or prompt (typed message)',
    'time': "the call's transcript timestamp",
    'turn': 'the turn number: typed messages up to and including this turn (0 before the first)',
    'call': 'the call number within its turn, from 1',
    'message': 'the assistant message id',
    'model': 'the model the call used',
    'input_tokens': 'usage input_tokens; on a turn line, summed over its calls',
    'cache_creation_input_tokens': 'usage cache_creation_input_tokens; summed on a turn line',
    'cache_read_input_tokens': 'usage cache_read_input_tokens; summed on a turn line',
    'output_tokens': 'usage output_tokens; summed on a turn line',
    'tool_results': ('the tool results this call received since the previous call: '
                     '[tool, target, characters], the target being a file path or a '
                     "command's first USAGE_TARGET_CHARS characters"),
    'calls': 'the number of calls in the turn',
    'compaction': 'none, before (before its first call), during (between its calls) or both',
    'full_reads': 'full reads of the rules file in the turn',
    'since_compaction': ('characters of tool results since the last compaction, up to the '
                         "turn's last call, by group: rules file, each other file by path, "
                         'commands, and any other tool as "tool <name>"'),
    'reason': "why usage can't be measured",
    'error': 'an error inside the hook',
}
USAGE_LINES = {
    'call': ('kind', 'session', 'event', 'time', 'turn', 'call', 'message', 'model',
             *USAGE, 'tool_results'),
    'turn': ('kind', 'session', 'event', 'turn', 'calls', *USAGE, 'compaction',
             'full_reads', 'since_compaction'),
    'unmeasured': ('kind', 'session', 'event', 'reason'),
    'error': ('kind', 'session', 'event', 'error'),
}


def log(line):
    """Appends a line to the first log place that can be written."""
    stamp = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    for path in LOGS:
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, 'a', encoding='utf-8') as f:
                f.write(f'{stamp} {line}\n')
            return
        except OSError:
            continue


def signature():
    """First line, section headers and last line of the rules file."""
    with open(RULES, encoding='utf-8') as f:
        lines = [l.rstrip('\n') for l in f]
    nonblank = [l for l in lines if l.strip()]
    sections = [l for l in lines if l.startswith('=== SECTION: ')]
    return [nonblank[0], *sections, nonblank[-1]]


# ---- Reading entries ----

def content_of(e):
    """An entry's message content, or None when it has no message object."""
    m = e.get('message')
    return m.get('content') if isinstance(m, dict) else None


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        out = []
        for x in content:
            if isinstance(x, dict):
                if x.get('type') == 'text' and isinstance(x.get('text'), str):
                    out.append(x['text'])
                elif x.get('type') == 'tool_result':
                    out.append(text_of(x.get('content')))
        return '\n'.join(out)
    return ''


def is_prompt(e):
    # A compaction summary and other system-inserted user entries are not
    # typed messages, so they don't start a new turn.
    if e.get('type') != 'user' or e.get('isCompactSummary') or e.get('isMeta'):
        return False
    c = content_of(e)
    if isinstance(c, str):
        return True
    return isinstance(c, list) and not any(
        isinstance(x, dict) and x.get('type') == 'tool_result' for x in c)


def tool_uses(e):
    c = content_of(e)
    if e.get('type') != 'assistant' or not isinstance(c, list):
        return []
    return [x for x in c if isinstance(x, dict) and x.get('type') == 'tool_use']


# ---- The transcript ----

def load(path):
    """(entries, problem): problem is None, or why the transcript can't be used."""
    if not path:
        return [], 'no path given'
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            raw = f.read()
    except FileNotFoundError:
        return [], 'missing'
    except OSError as err:
        return [], f'unreadable: {err.__class__.__name__}'
    entries = []
    for line in raw.splitlines():
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if isinstance(e, dict):                 # a transcript line is an object; skip anything else
            entries.append(e)
    return entries, (None if entries else 'empty')


def unflushed(entries):
    """At a turn's end, a reply must follow the last typed message."""
    last = max((i for i, e in enumerate(entries) if is_prompt(e)), default=-1)
    return not any(e.get('type') == 'assistant' for e in entries[last + 1:])


def read_transcript(path, mode):
    """(entries, problem): the transcript, read again while it can't be used yet."""
    for attempt in range(TRANSCRIPT_TRIES):
        entries, problem = load(path)
        if problem is None and mode == 'stop' and unflushed(entries):
            problem = 'not flushed: no reply after the last typed message'
        if problem is None or not path:
            break
        if attempt + 1 < TRANSCRIPT_TRIES:
            time.sleep(TRANSCRIPT_WAIT)
    return entries, problem


# ---- Which session this is ----

def names_skill(value):
    """A skill name is this skill's: "praatgen", or "<plugin>:praatgen"."""
    return isinstance(value, str) and value.strip().split(':')[-1] == SKILL


def skill_loaded(e):
    """A system-inserted entry that is this skill's instructions."""
    if e.get('type') != 'user' or not e.get('isMeta'):
        return False
    m = re.match(rf'\s*{re.escape(SKILL_LOADED)}\s*(\S+)', text_of(content_of(e)))
    return bool(m) and os.path.basename(m.group(1).rstrip('/')) == SKILL


ON, OFF = 'on', 'off'


def off_command(e):
    """A message the user typed that contains the off command (OFF_FORM) and
    isn't itself a / pick of praatgen."""
    if not is_prompt(e):
        return False
    text = text_of(content_of(e))
    return bool(OFF_FORM.search(text)) and not any(f.search(text) for f in PICK_FORMS)


def events(entries, pending=None):
    """(index, ON or OFF, label) for each event that changes the state, in
    order. pending is a typed message the transcript may not hold yet."""
    out = []
    for i, e in enumerate(entries):
        if skill_loaded(e):
            out.append((i, ON, 'skill loaded'))
        if off_command(e):
            out.append((i, OFF, OFF_EVENT))
        for u in tool_uses(e):
            args = u.get('input') if isinstance(u.get('input'), dict) else {}
            if names_skill(args.get('skill')):
                out.append((i, ON, f'skill invoked ({u.get("name")})'))
    if isinstance(pending, str) and off_command(prompt_entry(pending)):
        out.append((len(entries), OFF, OFF_EVENT))
    return out


def prompt_entry(text):
    return {'type': 'user', 'message': {'content': text}}


def off_spans(evs, end):
    """[start, stop) entry ranges in which PraatGen is off."""
    spans, start = [], None
    for i, kind, _ in evs:
        if kind == OFF and start is None:
            start = i
        elif kind == ON and start is not None:
            spans.append((start, i))
            start = None
    return spans + ([(start, end)] if start is not None else [])


def classify(entries, pending=None):
    """'praatgen' when the latest event is ON, 'off' when it is OFF, 'other'
    when there is none."""
    evs = events(entries, pending)
    return 'other' if not evs else 'praatgen' if evs[-1][1] == ON else 'off'


# ---- The usage log ----

def usage_line(kind, **values):
    """One usage log line: exactly the fields USAGE_LINES gives its kind."""
    row = {'kind': kind, **values}
    if set(row) != set(USAGE_LINES[kind]):
        raise ValueError(f'{kind} line has fields {sorted(row)}')
    return json.dumps({f: row[f] for f in USAGE_LINES[kind]})


def logged_calls():
    """Message ids of the calls the usage logs already hold."""
    ids = set()
    for path in LOGS:
        try:
            with open(path, encoding='utf-8', errors='replace') as f:
                lines = f.read().splitlines()
        except OSError:
            continue
        for line in lines:
            try:
                row = json.loads(line.split(' ', 1)[1])
            except (IndexError, ValueError):
                continue
            if isinstance(row, dict) and row.get('kind') == 'call':
                ids.add(row.get('message'))
    return ids


def is_compaction(e):
    return bool(e.get('isCompactSummary')) or (
        e.get('type') == 'system' and e.get('subtype') == COMPACT_BOUNDARY)


def chars_of(content):
    """Characters of text in a tool result's content."""
    if isinstance(content, str):
        return len(content)
    return sum(len(text_of([x])) for x in content) if isinstance(content, list) else 0


def tool_result(block, uses, index):
    """A tool result: its tool, target, size and group."""
    use = uses.get(block.get('tool_use_id'), {})
    name, args = str(use.get('name', '?')), use.get('input')
    args = args if isinstance(args, dict) else {}
    shell = bool(SHELL_TOOL.search(name)) and isinstance(args.get('command'), str)
    target = (args['command'][:USAGE_TARGET_CHARS] if shell else
              next((v for k, v in args.items() if isinstance(v, str) and PATH_KEY.search(k)), ''))
    named = args['command'] if shell else target      # the whole command, not its shortened target
    group = (RULES_GROUP if os.path.basename(RULES) in named else
             COMMANDS_GROUP if shell else target or f'tool {name}')
    return {'tool': name, 'target': target, 'chars': chars_of(block.get('content')),
            'group': group, 'index': index}


def model_calls(entries):
    """(calls, tool results, turn number of each entry). A call is an
    assistant message id, numbered within its turn; it holds its last
    entry's usage and the tool results received since the previous call (a
    compaction clears them)."""
    uses, calls, by_id, results, pending = {}, [], {}, [], []
    turn, turn_of, per_turn = 0, [], collections.Counter()
    for i, e in enumerate(entries):
        turn += is_prompt(e)
        turn_of.append(turn)
        if is_compaction(e):
            pending = []
        for u in tool_uses(e):
            uses[u.get('id')] = u
        m = e.get('message')
        if e.get('type') == 'assistant' and isinstance(m, dict) and m.get('id') \
                and isinstance(m.get('usage'), dict):
            if m['id'] not in by_id:
                per_turn[turn] += 1
                by_id[m['id']] = {'message': m['id'], 'turn': turn, 'call': per_turn[turn],
                                  'time': e.get('timestamp'), 'index': i, 'received': pending}
                calls.append(by_id[m['id']])
                pending = []
            by_id[m['id']].update(model=m.get('model'), usage=m['usage'])
        elif e.get('type') == 'user' and not is_prompt(e) and isinstance(content_of(e), list):
            for b in content_of(e):
                if isinstance(b, dict) and b.get('type') == 'tool_result':
                    results.append(tool_result(b, uses, i))
                    pending.append(results[-1])
    return calls, results, turn_of


def tokens(calls):
    return {k: sum(int(c['usage'].get(k) or 0) for c in calls) for k in USAGE}


def full_reads(entries, turn_of, n, sig):
    """Full reads of the rules file in turn n (a paged read counts once)."""
    count, seen = 0, set()
    for e, t in zip(entries, turn_of):
        if t != n or e.get('type') != 'user' or is_prompt(e) or e.get('isCompactSummary'):
            continue
        out = text_of(content_of(e))
        seen.update(s for s in sig if s in out)
        if len(seen) == len(sig):
            count, seen = count + 1, set()
    return count


def turn_summary(n, calls, results, entries, turn_of, sig, base):
    mine = [c for c in calls if c['turn'] == n]
    first, last = mine[0]['index'], mine[-1]['index']
    before = max((c['index'] for c in calls if c['index'] < first), default=-1)
    marks = [i for i, e in enumerate(entries) if is_compaction(e)]
    when = [w for w, lo, hi in (('before', before, first), ('during', first, last))
            if any(lo < i < hi for i in marks)]
    since = max((i for i in marks if i < last), default=-1)
    groups = collections.Counter()
    for r in results:
        if since < r['index'] < last:
            groups[r['group']] += r['chars']
    return usage_line('turn', **base, turn=n, calls=len(mine), **tokens(mine),
                      compaction='both' if len(when) == 2 else (when or ['none'])[0],
                      full_reads=full_reads(entries, turn_of, n, sig),
                      since_compaction=dict(groups.most_common()))


def usage_lines(entries, base):
    """A line for each call not yet logged, then a summary of each turn they're in."""
    calls, results, turn_of = model_calls(entries)
    if not calls and any(e.get('type') == 'assistant' for e in entries):
        return [usage_line('unmeasured', **base, reason=NO_USAGE)]
    spans = off_spans(events(entries), len(entries))
    done = logged_calls()
    calls = [c for c in calls if not any(lo <= c['index'] < hi for lo, hi in spans)]
    new = [c for c in calls if c['message'] not in done]
    sig = signature()
    out = []
    for n in dict.fromkeys(c['turn'] for c in new):
        out += [usage_line('call', **base, time=c['time'], turn=n, call=c['call'],
                           message=c['message'], model=c['model'], **tokens([c]),
                           tool_results=[[r['tool'], r['target'], r['chars']] for r in c['received']])
                for c in new if c['turn'] == n]
        out.append(turn_summary(n, calls, results, entries, turn_of, sig, base))
    return out


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    try:
        data = json.load(sys.stdin)
    except Exception:                           # any failure to read the input: exit 0, silently
        return
    if not isinstance(data, dict):
        data = {}
    if mode not in MODES or not os.path.isfile(RULES):
        return
    base = {'session': str(data.get('session_id', '')), 'event': mode}
    try:
        entries, problem = read_transcript(data.get('transcript_path', ''), mode)
        if classify(entries, data.get('prompt') if mode == 'prompt' else None) not in USAGE_SESSIONS:
            return
        for line in (usage_lines(entries, base) if entries else
                     [usage_line('unmeasured', **base, reason=problem or 'no entries')]):
            log(line)
    except Exception as err:                    # logged; never blocks and never prints
        with contextlib.suppress(Exception):
            log(usage_line('error', **base, error=f'{err.__class__.__name__}: {err}'[:LOG_ERROR_CHARS]))


if __name__ == '__main__':
    main()
