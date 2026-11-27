#!/usr/bin/env python3
"""PraatGen rules-read check.

Acts only where the project holds the PraatGen rules file. A session counts as
a PraatGen session once one of its replies opens with "Rules read this turn:"
or whose first message carries the PraatGen brief (threads do; the project
chat never does). For those sessions:

  session  At thread start, says the rules file must be read in full first.
  prompt   At each typed message, reminds the session to read the file in
           full, and says so when the previous turn didn't.
  stop     At the end of a turn with no full read (and no scaffold opening
           line), blocks the turn from ending until the file is read.

A read counts as full when this turn's tool output contains the file's first
line, every section header and its last line. Every check is logged to
/mnt/project-files/praatgen/rules-check.log, or /tmp if that can't be written.
"""
import json, os, re, sys, time

RULES = '/mnt/project-files/pkb/PRAATGEN_RULES_FULL.md'
LOGS = ('/mnt/project-files/praatgen/rules-check.log', '/tmp/praatgen-rules-check.log')


def plugin_version():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir,
                        '.claude-plugin', 'plugin.json')
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f).get('version', '?')
    except (OSError, ValueError):
        return '?'


VERSION = plugin_version()
TAG = f'PraatGen check (plugin {VERSION})'
OPENING = 'Rules read this turn:'
SCAFFOLD = 'Rules not read this turn: scaffold mode is on.'
EXCEPTION = ('The one exception is a SCAFFOLD discussion turn as your instructions '
             f'define it: skip the read and open the reply with exactly "{SCAFFOLD}"')


def log(line):
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


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        out = []
        for x in content:
            if isinstance(x, dict):
                if x.get('type') == 'text':
                    out.append(x.get('text', ''))
                elif x.get('type') == 'tool_result':
                    out.append(text_of(x.get('content')))
        return '\n'.join(out)
    return ''


def is_prompt(e):
    # A compaction summary and other system-inserted user entries are not
    # typed messages, so they don't start a new turn.
    if e.get('type') != 'user' or e.get('isCompactSummary') or e.get('isMeta'):
        return False
    c = (e.get('message') or {}).get('content')
    if isinstance(c, str):
        return True
    return isinstance(c, list) and not any(
        isinstance(x, dict) and x.get('type') == 'tool_result' for x in c)


def load(path):
    entries = []
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            for line in f:
                try:
                    entries.append(json.loads(line))
                except ValueError:
                    pass
    except OSError:
        pass
    return entries


def turns(entries):
    """Split the transcript at each typed message: list of entry lists."""
    out, cur = [], []
    for e in entries:
        if is_prompt(e) and cur:
            out.append(cur)
            cur = []
        cur.append(e)
    if cur:
        out.append(cur)
    return out


def assistant_text(turn):
    return '\n'.join(text_of((e.get('message') or {}).get('content'))
                     for e in turn if e.get('type') == 'assistant')


def tool_output(turn):
    return '\n'.join(text_of((e.get('message') or {}).get('content'))
                     for e in turn if e.get('type') == 'user' and not is_prompt(e))


def full_read(turn, sig):
    out = tool_output(turn)
    return all(s in out for s in sig)


BRIEFS = ('PraatGen phase:', 'Run PraatGen on the attached message.')


def praatgen_session(entries):
    """A thread started by the PraatGen brief, or any session that has
    opened a reply with the rules line. The project chat is neither."""
    for e in entries:
        if e.get('type') == 'assistant' and OPENING in assistant_text([e]):
            return True
        if is_prompt(e) and any(b in text_of((e.get('message') or {}).get('content')) for b in BRIEFS):
            return True
    return False


def emit(obj):
    print(json.dumps(obj))


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    if not os.path.isfile(RULES):
        return
    sig = signature()
    sid = str(data.get('session_id', ''))[:8]
    entries = load(data.get('transcript_path', ''))
    ts = turns(entries)

    if mode == 'session':
        log(f'{sid} session start, plugin {VERSION} ({data.get("source", "")})')
        emit({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext':
              f'{TAG}: if this is a PraatGen thread, read '
              f'{RULES} in full, to its last line, before anything else on every turn. '
              f'{EXCEPTION}'}})
        return

    if not praatgen_session(entries):
        return

    if mode == 'prompt':
        prev = ts[-1] if ts else []
        if not any(e.get('type') == 'assistant' for e in prev):
            log(f'{sid} first turn')
            note = ''
        else:
            ok = full_read(prev, sig) or SCAFFOLD in assistant_text(prev)
            log(f'{sid} previous turn: {"full read" if ok else "NO full read"}')
            note = '' if ok else ' Your previous turn did not read it in full.'
        emit({'hookSpecificOutput': {'hookEventName': 'UserPromptSubmit', 'additionalContext':
              f'{TAG}: read {RULES} in full, to its last line, '
              f'before anything else this turn.{note} {EXCEPTION}'}})
        return

    if mode == 'stop':
        cur = ts[-1] if ts else []
        if SCAFFOLD in assistant_text(cur) or full_read(cur, sig):
            log(f'{sid} turn end: full read')
            return
        if data.get('stop_hook_active'):
            log(f'{sid} turn end: still no full read after the check asked once')
            return
        log(f'{sid} turn end: NO full read; asked to read before ending')
        emit({'decision': 'block', 'reason':
              f'{TAG}: this turn did not read {RULES} in full. '
              'Read it now, to its last line. Then check your reply against it and '
              'correct anything it breaks, saying what you changed.'})


if __name__ == '__main__':
    main()
