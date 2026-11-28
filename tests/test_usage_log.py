#!/usr/bin/env python3
"""Offline test of the usage log (praatgen/usage.log), ported from plugin 0.3.3's
test to the Cowork plugin (0.6.0, where the usage log is all the hook does, and
the hook ships only in the maintainer's test build, praatgen-plugin-usagelog/,
where --plugin points by default).

Runs the hook from a copy of the plugin in a temporary folder, found through
CLAUDE_PLUGIN_ROOT, with a small rules file in its skill folder and the logs
redirected, on small synthetic transcripts shaped like Claude Code
transcripts: one content block per assistant entry, a streamed message
repeating its id, tool results as user entries with tool_use_id, string or
block content (text and image), and the entry types a session holds
(queue-operation, attachment, meta entries, compaction boundaries and
summaries). Nothing in them comes from a real transcript. The last checks
compare every usage line with plugin 0.3.3's, without its variant field.

    python3 test_usage_log.py [--plugin DIR] [--old DIR]
"""
import argparse, contextlib, importlib.util, io, json, os, shutil, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True                  # nothing written into build/ or the plugin
ap = argparse.ArgumentParser()
ap.add_argument('--plugin', default=os.path.join(HERE, os.pardir, 'plugin-usagelog'))
ap.add_argument('--old', default='/mnt/user-data/outputs/study3/plugin_033/plugin',
                help='plugin 0.3.3, for the comparison')
ARGS = ap.parse_args()
TMP = tempfile.mkdtemp(prefix='usage_log_050_')
ROOT = os.path.join(TMP, 'plugin')
shutil.copytree(os.path.join(ARGS.plugin, 'hooks'), os.path.join(ROOT, 'hooks'),
                ignore=shutil.ignore_patterns('__pycache__'))
shutil.copytree(os.path.join(ARGS.plugin, '.claude-plugin'), os.path.join(ROOT, '.claude-plugin'))

RULES_LINES = ['# PRAATGEN RULES, FULL TEXT (read every turn)', 'intro',
               '=== SECTION: CORE.md', 'core text', '=== SECTION: RULES_CODE.md',
               'code text', 'End of PRAATGEN_RULES_FULL.md.', 'Marker: test-0001']
RULES_TEXT = '\n'.join(RULES_LINES) + '\n'
SKILL_DIR = os.path.join(ROOT, 'skills', 'praatgen')
os.makedirs(SKILL_DIR)
RULES = os.path.join(SKILL_DIR, 'PRAATGEN_RULES_FULL.md')
open(RULES, 'w').write(RULES_TEXT)
STUDY = os.path.join(TMP, 'no-study.json')
LOG = os.path.join(TMP, 'rules-check.log')      # plugin 0.3.3's check log; its usage log sits beside it
sys.path.insert(0, os.path.join(HERE, os.pardir, 'build'))
from phrases import OFF_COMMAND  # noqa: E402
USAGE_LOG = os.path.join(TMP, 'usage.log')



def load_hook(path, name, root):
    os.environ['CLAUDE_PLUGIN_ROOT'] = root
    try:
        spec = importlib.util.spec_from_file_location(name, path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    finally:
        del os.environ['CLAUDE_PLUGIN_ROOT']
    return mod


H = load_hook(os.path.join(ROOT, 'hooks', 'rules_check.py'), 'hook_050', ROOT)
DEFAULT_LOGS = H.LOGS
H.LOGS, H.TRANSCRIPT_WAIT = (USAGE_LOG,), 0.01
OLD = load_hook(os.path.join(ARGS.old, 'hooks', 'rules_check.py'), 'hook_033', ROOT)
OLD.RULES, OLD.STUDY, OLD.LOGS, OLD.TRANSCRIPT_WAIT = RULES, STUDY, (LOG,), 0.01


# ---- synthetic entries, shaped like a Claude Code transcript ----
def typed(text):
    return {'type': 'user', 'timestamp': '2026-11-27T20:00:00.000Z', 'message': {'role': 'user', 'content': text}}


def meta(text):
    return {**typed(text), 'isMeta': True}


LOADED = meta(f'Base directory for this skill: {SKILL_DIR}\n\nEML PraatGen')   # the skill's instructions load


def use(tid, name, **args):
    return {'type': 'tool_use', 'id': tid, 'name': name, 'input': args}


def call(mid, *blocks, usage=(3, 200, 5000, 40), final_output=None, model='claude-opus-5-5',
         ts='2026-11-27T20:01:00.000Z'):
    """One model call: one assistant entry per content block, all with the
    same message id. final_output gives the last entry a larger output count,
    as a streamed message's last entry can have."""
    blocks = blocks or ({'type': 'text', 'text': 'ok'},)
    out = []
    for k, b in enumerate(blocks):
        u = dict(zip(H.USAGE, usage), cache_creation={'ephemeral_5m_input_tokens': 0},
                 service_tier='standard')
        if final_output is not None and k == len(blocks) - 1:
            u['output_tokens'] = final_output
        out.append({'type': 'assistant', 'timestamp': ts, 'requestId': f'req_{mid}',
                    'message': {'id': mid, 'model': model, 'role': 'assistant',
                                'content': [b], 'usage': u}})
    return out


def result(tid, content):
    return {'type': 'user', 'timestamp': '2026-11-27T20:01:30.000Z', 'toolUseResult': {'x': 'not counted'},
            'message': {'role': 'user', 'content': [{'type': 'tool_result', 'tool_use_id': tid, 'content': content}]}}


def text(t):
    return {'type': 'text', 'text': t}


NOISE = [{'type': 'queue-operation', 'operation': 'enqueue', 'content': 'x'}, {'type': 'mode', 'mode': 'normal'},
         {'type': 'attachment', 'attachment': {'type': 'skill_listing', 'content': 'praatgen: EML PraatGen'}}]
WAKE = typed('Write me a Praat script that measures jitter in every WAV in a folder.')
BOUNDARY = {'type': 'system', 'subtype': 'compact_boundary', 'compactMetadata': {'preTokens': 9, 'postTokens': 1}}
SUMMARY = {'type': 'user', 'isCompactSummary': True, 'message': {'role': 'user', 'content': 'Summary so far.'}}
OPEN = text('Rules read this turn: test-0001\nPRE-FLIGHT.')
def read_rules(mid='m_read'):
    return [*call(mid, use(f't_{mid}', 'Read', file_path=RULES)), result(f't_{mid}', RULES_TEXT)]


def first_turn(prefix='a'):
    """A PraatGen session's first turn: the skill's instructions load, then read the rules file, run a command, answer."""
    return [*NOISE, WAKE, LOADED, *read_rules(),
            *call(f'{prefix}2', text('Checking.'), use(f'{prefix}t2', 'Bash', command='ls /mnt/user-data/outputs/PraatGen_output'),
                  final_output=77),
            result(f'{prefix}t2', 'a.wav\nb.wav'),
            *call(f'{prefix}3', OPEN)]


# ---- running the hook ----
def run(mode, entries, fresh=True, path=None, hook=None, **extra):
    hook = hook or H
    if fresh:
        for p in (LOG, USAGE_LOG):
            with contextlib.suppress(FileNotFoundError):
                os.remove(p)
    if path is None:
        path = os.path.join(TMP, 'transcript.jsonl')
        with open(path, 'w') as f:
            f.writelines(json.dumps(e) + '\n' for e in entries)
    data = {'session_id': 'thread-0001-aaaa', 'transcript_path': path, **extra}
    out = io.StringIO()
    argv, stdin = sys.argv, sys.stdin
    sys.argv, sys.stdin = ['rules_check.py', mode], io.StringIO(json.dumps(data))
    try:
        with contextlib.redirect_stdout(out):
            hook.main()
    finally:
        sys.argv, sys.stdin = argv, stdin
    rows = []
    if os.path.exists(USAGE_LOG):
        rows = [json.loads(l.split(' ', 1)[1]) for l in open(USAGE_LOG).read().splitlines()]
    logs = open(LOG).read().splitlines() if os.path.exists(LOG) else []
    return out.getvalue(), logs, rows


RESULTS = []


def check(name, cond, detail=''):
    RESULTS.append((name, bool(cond)))
    print(f'{"PASS" if cond else "FAIL"}  {name}' + ('' if cond else f'\n      {detail}'))


def kinds(rows, kind):
    return [r for r in rows if r['kind'] == kind]


# ---- the log's name and fields ----
check('usage log names: praatgen/usage.log in the outputs folder, then /tmp/praatgen-usage.log',
      DEFAULT_LOGS == ('/mnt/user-data/outputs/praatgen/usage.log', '/tmp/praatgen-usage.log'), DEFAULT_LOGS)
check('every field a line kind lists has a stated meaning, and every meaning is used',
      set(f for fs in H.USAGE_LINES.values() for f in fs) == set(H.USAGE_FIELD))

# ---- one turn, logged at its end ----
out, logs, rows = run('stop', first_turn())
calls, turns = kinds(rows, 'call'), kinds(rows, 'turn')
check('turn end: one line per call, then one turn line', [r['kind'] for r in rows] == ['call'] * 3 + ['turn'], rows)
check('every line has exactly its kind\'s fields, in order',
      all(list(r) == list(H.USAGE_LINES[r['kind']]) for r in rows), rows)
check('call lines carry session, event, time, turn, call number, message id and model',
      [(r['session'], r['event'], r['turn'], r['call'], r['message'], r['model'], r['time'])
       for r in calls] == [('thread-0001-aaaa', 'stop', 1, k, m, 'claude-opus-5-5', '2026-11-27T20:01:00.000Z')
                           for k, m in ((1, 'm_read'), (2, 'a2'), (3, 'a3'))], calls)
check('a streamed message repeating its id is one call, with its last entry\'s usage',
      [r['message'] for r in calls].count('a2') == 1 and calls[1]['output_tokens'] == 77, calls)
check('usage fields come from message.usage',
      (calls[0]['input_tokens'], calls[0]['cache_creation_input_tokens'], calls[0]['cache_read_input_tokens'],
       calls[0]['output_tokens']) == (3, 200, 5000, 40), calls[0])
check('each call lists the tool results it received since the previous call',
      calls[0]['tool_results'] == [] and calls[1]['tool_results'] == [['Read', RULES, len(RULES_TEXT)]]
      and calls[2]['tool_results'] == [['Bash', 'ls /mnt/user-data/outputs/PraatGen_output', len('a.wav\nb.wav')]], calls)
t = turns[0]
check('turn line sums the four usage fields over its calls',
      all(t[k] == sum(c[k] for c in calls) for k in H.USAGE) and t['calls'] == 3
      and t['output_tokens'] == 40 + 77 + 40, t)
check('turn line: no compaction, one full read, tool results grouped',
      t['compaction'] == 'none' and t['full_reads'] == 1
      and t['since_compaction'] == {'rules file': len(RULES_TEXT), 'commands': len('a.wav\nb.wav')}, t)
check('the hook prints nothing and writes no other log', out == '' and logs == [], f'{out!r} {logs}')

# ---- dedupe across hook calls ----
_, _, again = run('stop', first_turn(), fresh=False)
check('a second turn end with no new calls adds no lines', again == rows, again[len(rows):])
_, _, later = run('prompt', [*first_turn(), typed('Pitch range 75 to 500 Hz.')], fresh=False,
                  prompt='Pitch range 75 to 500 Hz.')
check('the next typed message adds nothing when the turn end logged every call', later == rows, later[len(rows):])

# ---- a turn end that was blocked, then ended again ----
part = [*NOISE, WAKE, LOADED, *call('b1', text('Rules read this turn: test-0001\nHello.'))]   # no read yet
_, _, rows1 = run('stop', part)
whole = [*part, *read_rules(), *call('b3', OPEN)]
_, _, rows2 = run('stop', whole, fresh=False, stop_hook_active=True)
new = rows2[len(rows1):]
check('a turn that ends twice: the second end logs only the new calls, and a summary of the whole turn',
      [r['kind'] for r in rows1] == ['call', 'turn'] and [r['message'] for r in kinds(new, 'call')] == ['m_read', 'b3']
      and [c['call'] for c in kinds(new, 'call')] == [2, 3]
      and kinds(new, 'turn')[0]['calls'] == 3 and kinds(new, 'turn')[0]['full_reads'] == 1, new)

# ---- a missed turn end, caught at the next typed message ----
turn2 = [typed('Use 75 Hz.'), *call('c1', text('Rules read this turn: test-0001'), ts='2026-11-27T20:05:00.000Z')]
entries = [*first_turn(), *turn2]
run('stop', first_turn())                        # turn 1 is logged; turn 2's end is missed
_, _, rows = run('prompt', [*entries, typed('EXECUTE')], fresh=False, prompt='EXECUTE')
caught = [r for r in rows if r.get('turn') == 2]
check('a missed turn end: the next typed message logs its calls and its summary',
      [r['kind'] for r in caught] == ['call', 'turn'] and caught[0]['message'] == 'c1'
      and all(r['event'] == 'prompt' for r in caught) and caught[1]['calls'] == 1
      and caught[1]['full_reads'] == 0, caught)
check('turn 1 is not logged twice', [r['message'] for r in kinds(rows, 'call')].count('m_read') == 1, rows)
_, _, rows = run('prompt', [*entries, typed('EXECUTE')], prompt='EXECUTE')
check('two missed turn ends: both turns caught, each with its own summary',
      [(r['kind'], r['turn']) for r in rows] == [('call', 1)] * 3 + [('turn', 1), ('call', 2), ('turn', 2)], rows)

# ---- compaction and grouping ----
OTHER = '/mnt/user-data/outputs/PraatGen_output/jit.praat'
pre = [*first_turn(), typed('Write it.'),
       *call('d1', use('dt1', 'Read', file_path=OTHER)), result('dt1', 'form x\nendform\n'),
       *call('d2', use('dt2', 'Bash', command='cat ' + RULES)), result('dt2', RULES_TEXT),
       *call('d3', text('Done.'))]
post = [BOUNDARY, SUMMARY, typed('Where were we?'),
        *call('e1', use('et1', 'Read', file_path=OTHER, offset=1, limit=10)),
        result('et1', [text('form x'), {'type': 'image', 'source': {'data': 'AAAA'}}]),
        *call('e2', use('et2', 'Bash', command='praat --run ' + 'x' * 80)), result('et2', 'ok'),
        *call('e3', use('et3', 'SendUserMessage', message='hi')), result('et3', 'sent'),
        *call('e4', OPEN)]
_, _, rows = run('stop', [*pre, *post])
t2, t3 = [r for r in kinds(rows, 'turn') if r['turn'] in (2, 3)]
check('turn line: a command that names the rules file counts in the rules file group, other files by path',
      t2['since_compaction'] == {'rules file': 2 * len(RULES_TEXT), 'commands': len('a.wav\nb.wav'),
                                 OTHER: len('form x\nendform\n')} and t2['full_reads'] == 1, t2)
check('turn after a compaction: "before", and only tool results since the compaction count',
      t3['compaction'] == 'before'
      and t3['since_compaction'] == {OTHER: len('form x'), 'tool SendUserMessage': 4,
                                     'commands': 2}, t3)
e = {r['message']: r for r in kinds(rows, 'call')}
check('a command target is its first 60 characters; image blocks add no characters',
      e['e3']['tool_results'] == [['Bash', ('praat --run ' + 'x' * 80)[:60], 2]]
      and e['e2']['tool_results'] == [['Read', OTHER, len('form x')]], e)
_, _, rows = run('stop', [*first_turn(), typed('GO'), *call('k1', use('kt1', 'Read', file_path=OTHER)),
                          result('kt1', 'abc'), BOUNDARY, SUMMARY, *call('k2', OPEN)])
k = {r['message']: r for r in kinds(rows, 'call')}
check('the first call after a compaction received no tool results from before it',
      k['k2']['tool_results'] == [] and k['k1']['tool_results'] == [], k)
mid = [*first_turn(), typed('GO'), *call('f1', use('ft1', 'Read', file_path=OTHER)), result('ft1', 'abc'),
       *call('f2', text('Working.')), BOUNDARY, SUMMARY, *read_rules('f3'), *call('f4', OPEN)]
_, _, rows = run('stop', mid)
tm = [r for r in kinds(rows, 'turn') if r['turn'] == 2][0]
check('compaction between a turn\'s calls: "during", and grouping restarts after it',
      tm['compaction'] == 'during' and tm['since_compaction'] == {'rules file': len(RULES_TEXT)}
      and tm['full_reads'] == 1, tm)
both = [*first_turn(), BOUNDARY, typed('GO'), *call('g1', text('x')), SUMMARY, *call('g2', text('y'))]
_, _, rows = run('stop', both)
check('compaction before and during a turn: "both"',
      [r for r in kinds(rows, 'turn') if r['turn'] == 2][0]['compaction'] == 'both', rows)

# ---- full reads ----
HALF = len(RULES_LINES) // 2
paged = [*NOISE, WAKE, LOADED,
         *call('h1', use('ht1', 'Read', file_path=RULES, limit=HALF)), result('ht1', '\n'.join(RULES_LINES[:HALF])),
         *call('h2', use('ht2', 'Read', file_path=RULES, offset=HALF)), result('ht2', '\n'.join(RULES_LINES[HALF:])),
         *call('h3', use('ht3', 'Read', file_path=RULES)), result('ht3', [text(RULES_TEXT)]),
         *call('h4', use('ht4', 'Read', file_path=RULES, limit=2)), result('ht4', RULES_LINES[0]),
         *call('h5', OPEN)]
_, _, rows = run('stop', paged)
check('full reads: a paged read counts once, a whole read once, a partial read not at all',
      kinds(rows, 'turn')[0]['full_reads'] == 2, kinds(rows, 'turn'))

# ---- turn numbers ----
_, _, rows = run('stop', [*call('z0', text('before any message')), *first_turn(),
                          meta('system-inserted'), WAKE, *call('z2', OPEN)])
check('turn numbers count typed messages (wake notices too); meta entries and calls before the first are turn 0',
      [(r['message'], r['turn']) for r in kinds(rows, 'call')]
      == [('z0', 0), ('m_read', 1), ('a2', 1), ('a3', 1), ('z2', 2)], kinds(rows, 'call'))

# ---- sessions that aren't measured ----
for why, (path, reason) in {'missing': (os.path.join(TMP, 'nowhere.jsonl'), 'missing'),
                            'given no path': ('', 'no path given'),
                            'unreadable (a folder)': (TMP, 'unreadable: IsADirectoryError'),
                            'empty': (os.path.join(TMP, 'empty.jsonl'), 'empty')}.items():
    open(os.path.join(TMP, 'empty.jsonl'), 'w').close()
    for mode in ('prompt', 'stop'):
        saved = H.USAGE_SESSIONS
        H.USAGE_SESSIONS = ('praatgen', 'other')    # an unreadable transcript can't show the skill
        out_u, logs_u, rows = run(mode, [], path=path, prompt='x')
        H.USAGE_SESSIONS = saved
        check(f'transcript {why}, {mode}, with other sessions measured: one line saying usage can\'t be measured',
              rows == [{'kind': 'unmeasured', 'session': 'thread-0001-aaaa',
                        'event': mode, 'reason': reason}], rows)
        out_u, logs_u, rows = run(mode, [], path=path, prompt='x')
        check(f'transcript {why}, {mode}, by default: no usage line, since the session can\'t be recognized',
              rows == [], rows)
_, _, rows = run('stop', [*NOISE, WAKE, LOADED, {'type': 'assistant', 'message': {'content': [OPEN]}}])
check('a PraatGen session whose replies carry no message id with usage: one line saying so, no more',
      rows == [{'kind': 'unmeasured', 'session': 'thread-0001-aaaa', 'event': 'stop',
                'reason': H.NO_USAGE}], rows)
_, _, rows = run('prompt', [*NOISE, WAKE], prompt='x')
check('a session with no reply yet writes nothing', rows == [], rows)
_, _, rows = run('session', [], source='startup')
check('session start writes no usage line', rows == [], rows)
chat = [typed('Summarize my inbox.'), *call('p1', use('pt1', 'Skill', skill='anthropic-skills:morning')),
        result('pt1', 'Launching skill: anthropic-skills:morning'), *call('p2', text('Here is your brief.'))]
_, logs, rows = run('stop', chat)
check('a readable session that isn\'t PraatGen\'s gets no usage lines and no other log line',
      rows == [] and logs == [], f'{rows} {logs}')
saved = H.USAGE_SESSIONS
H.USAGE_SESSIONS = ('praatgen', 'other')
_, _, rows = run('stop', chat)
H.USAGE_SESSIONS = saved
check('the setting USAGE_SESSIONS can add other sessions',
      [r['kind'] for r in rows] == ['call', 'call', 'turn'], rows)
skill_turn = [*NOISE, WAKE, *call('s1', use('st1', 'Skill', skill='praatgen:praatgen')),
              result('st1', 'Launching skill: praatgen:praatgen'),
              meta(f'Base directory for this skill: {SKILL_DIR}\n\nEML PraatGen'), *read_rules('s2'), *call('s3', OPEN)]
_, _, rows = run('stop', skill_turn)
check('a session recognized by its skill call is measured, and the skill entry starts no turn',
      [(r['kind'], r['turn']) for r in rows] == [('call', 1)] * 3 + [('turn', 1)]
      and kinds(rows, 'turn')[0]['full_reads'] == 1, rows)
check('no line has a variant field', all('variant' not in r for r in rows))

# ---- PraatGen off and on ----
OFFCMD = OFF_COMMAND
before = first_turn()
off_turn = [typed(OFFCMD), *call('o1', text('PraatGen is off.'))]
on_turn = [typed('/praatgen'), LOADED, *read_rules('n1'), *call('n2', OPEN)]
_, _, rows = run('stop', [*before, *off_turn])
check('PRAATGEN OFF: the off turn writes no usage line (the earlier turn is not logged by it either)',
      rows == [], rows)
_, _, rows = run('prompt', before, prompt=OFFCMD)
check('PRAATGEN OFF at the typed-message hook: no usage line', rows == [], rows)
run('stop', before)
_, _, rows = run('stop', [*before, *off_turn], fresh=False)
check('after the off command, an earlier turn already logged stays logged and the off turn adds nothing',
      [r['kind'] for r in rows] == ['call'] * 3 + ['turn'] and all(r['turn'] == 1 for r in rows), rows)
_, _, rows = run('stop', [*before, *off_turn, *on_turn], fresh=False)
check('ON again: only the calls after the new ON are logged; the off turn\'s call is skipped',
      sorted(r['message'] for r in kinds(rows, 'call')) == ['a2', 'a3', 'm_read', 'n1', 'n2']
      and 'o1' not in [r.get('message') for r in rows], rows)
_, _, rows = run('stop', [*before, *off_turn, *on_turn], fresh=True)
check('ON again, with nothing logged before: turn 1 and the new turn are measured, the off turn is not',
      sorted(set(r['turn'] for r in rows)) == [1, 3], [(r['kind'], r['turn']) for r in rows])
for why, entry in {'lowercase': typed(OFFCMD.lower()), 'extra words': typed(f'{OFFCMD} please'),
                   'not the first line': typed(f'Hi\n{OFFCMD}')}.items():
    _, _, rows = run('stop', [*before, typed('Next.'), entry, *call('z1', OPEN)])
    check(f'off ({why}): the turn is not measured', not any(r['message'] == 'z1' for r in kinds(rows, 'call')), rows)
for why, entry in {'a tool result': result('xx', OFFCMD)}.items():
    _, _, rows = run('stop', [*before, typed('Next.'), entry, *call('z1', OPEN)])
    check(f'not off ({why}): the next turn is still measured', any(r['message'] == 'z1' for r in kinds(rows, 'call')), rows)
_, _, rows = run('stop', [typed(OFFCMD), *call('v1', text('Off.'))])
check('OFF with no prior ON writes nothing', rows == [], rows)
_, _, rows = run('stop', [*NOISE, WAKE, meta(f'Base directory for this skill: {SKILL_DIR}\n\nEML PraatGen'), *call('w1', OPEN)])
check('a / menu load alone (instructions entry, no tool call) is ON and measured', len(kinds(rows, 'call')) == 1, rows)

# ---- errors never reach the session ----
real = H.model_calls
H.model_calls = lambda entries: 1 / 0
try:
    err_out, err_logs, rows = run('stop', [*NOISE, WAKE, LOADED, *call('q1', text('Rules read this turn: test-0001'))])
finally:
    H.model_calls = real
check('an error in the usage code: one error line in usage.log, nothing printed, no other log',
      err_out == '' and err_logs == []
      and len(rows) == 1 and rows[0]['kind'] == 'error' and 'ZeroDivisionError' in rows[0]['error'], f'{err_logs} {rows}')
blocker = os.path.join(TMP, 'blocked')
os.makedirs(os.path.join(blocker, 'usage.log'))      # a folder where the usage log should be
saved = H.LOGS
H.LOGS = (os.path.join(blocker, 'usage.log'),)
try:
    out_b, _, _ = run('stop', first_turn())
finally:
    H.LOGS = saved
check('a usage log that can\'t be written doesn\'t break the hook', out_b == '', out_b)

# ---- the same lines as plugin 0.3.3, without its variant field ----
# 'compaction and grouping' is left out: its shell read of the rules file is grouped differently (next check).
SAME = {'first turn': ('stop', first_turn()), 'compaction': ('stop', [*first_turn(), *post]),
        'compaction during a turn': ('stop', mid), 'compaction before and during': ('stop', both),
        'full reads': ('stop', paged), 'turn numbers': ('stop', [*call('z0', text('x')), *first_turn(),
                                                                  meta('m'), WAKE, *call('z2', OPEN)]),
        'a missed turn end': ('prompt', [*entries, typed('EXECUTE')])}
for case, (mode, ents) in SAME.items():
    _, _, new_rows = run(mode, ents, prompt='EXECUTE')
    _, _, old_rows = run(mode, ents, hook=OLD, prompt='EXECUTE')
    old_rows = [{k: v for k, v in r.items() if k != 'variant'} for r in old_rows]
    check(f'same usage lines as 0.3.3 apart from the variant field: {case}',
          new_rows == old_rows and new_rows, f'new={new_rows}\n      old={old_rows}')
LONG = [*first_turn(), typed('Check it.'), *call('l1', use('lt1', 'Bash', command='cat ' + RULES)),
        result('lt1', RULES_TEXT), *call('l2', OPEN)]
_, _, new_rows = run('stop', LONG)
_, _, old_rows = run('stop', LONG, hook=OLD)
group = lambda rows: [r for r in kinds(rows, 'turn') if r['turn'] == 2][0]['since_compaction']
check(f'a shell read of the rules file at a path longer than {H.USAGE_TARGET_CHARS} characters counts in '
      'the rules file group (0.3.3 counted it as a command)',
      len('cat ' + RULES) > H.USAGE_TARGET_CHARS and group(new_rows).get('rules file') == 2 * len(RULES_TEXT)
      and 'commands' in group(old_rows), f'{group(new_rows)} {group(old_rows)}')

# ---- speed ----
import time
big = [*NOISE, WAKE]
for k in range(400):
    big += [*call(f'big{k}', use(f'bt{k}', 'Read', file_path=RULES)), result(f'bt{k}', RULES_TEXT * 100)]
big += [*call('bigend', OPEN)]
began = time.time()
run('stop', big)
took = time.time() - began
size = os.path.getsize(os.path.join(TMP, 'transcript.jsonl'))
check(f'a {size // 1_000_000} MB transcript with 401 calls is measured in under 2 seconds ({took:.2f} s)',
      took < 2, took)

failed = [n for n, ok in RESULTS if not ok]
print(f'\n{len(RESULTS) - len(failed)} of {len(RESULTS)} checks passed; temporary folder {TMP}')
shutil.rmtree(TMP, ignore_errors=True)
sys.exit(1 if failed else 0)
