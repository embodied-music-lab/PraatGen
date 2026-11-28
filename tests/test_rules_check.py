#!/usr/bin/env python3
"""Offline test of the PraatGen 0.6.0 hook on synthetic transcripts shaped
like this machine's Claude Code transcripts (a skill call, its "Launching
skill" result and the skill's "Base directory for this skill:" entry; Read
results in line-number form). Nothing in them comes from a real transcript.

From 0.6.0 the hook only logs usage: it never blocks, never adds context and
never prints. It ships only in the maintainer's test build
(praatgen-plugin-usagelog/, from build_plugin.py --with-usage-log), which is
where --plugin points by default. This test covers where it looks, which events it runs on, which
sessions it takes for PraatGen sessions that are on (and so logs), and that
nothing it does reaches the session. test_usage_log.py covers the log lines.

The hook runs from a copy of the plugin in a temporary folder, found through
CLAUDE_PLUGIN_ROOT, with a small rules file in its skill folder and the log
redirected.

    python3 test_rules_check.py [--plugin DIR]
"""
import argparse, contextlib, importlib.util, io, json, os, shutil, sys, tempfile, threading, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True                  # nothing written into build/ or the plugin
ap = argparse.ArgumentParser()
ap.add_argument('--plugin', default=os.path.join(HERE, os.pardir, 'plugin-usagelog'))
ARGS = ap.parse_args()
TMP = tempfile.mkdtemp(prefix='rules_check_060_')

# ---- a plugin copy whose skill folder holds a small rules file ----
ROOT = os.path.join(TMP, 'plugin')
shutil.copytree(os.path.join(ARGS.plugin, 'hooks'), os.path.join(ROOT, 'hooks'),
                ignore=shutil.ignore_patterns('__pycache__'))
SKILL_DIR = os.path.join(ROOT, 'skills', 'praatgen')
os.makedirs(SKILL_DIR)
RULES_LINES = ['# PRAATGEN RULES, FULL TEXT (read every turn)', 'intro',
               '=== SECTION: CORE.md', 'core text', '=== SECTION: RULES_CODE.md',
               'code text', 'End of PRAATGEN_RULES_FULL.md.', 'Marker: test-0001']
RULES = os.path.join(SKILL_DIR, 'PRAATGEN_RULES_FULL.md')
open(RULES, 'w').write('\n'.join(RULES_LINES) + '\n')
LOG = os.path.join(TMP, 'usage.log')
sys.path.insert(0, os.path.join(HERE, os.pardir, 'build'))
from phrases import OFF_COMMAND as OFF  # noqa: E402  the off command as the user is told to type it


def load_hook(path, name, env_root=ROOT):
    saved = os.environ.pop('CLAUDE_PLUGIN_ROOT', None)
    if env_root:
        os.environ['CLAUDE_PLUGIN_ROOT'] = env_root
    try:
        spec = importlib.util.spec_from_file_location(name, path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    finally:
        os.environ.pop('CLAUDE_PLUGIN_ROOT', None)
        if saved is not None:
            os.environ['CLAUDE_PLUGIN_ROOT'] = saved
    return mod


H = load_hook(os.path.join(ROOT, 'hooks', 'rules_check.py'), 'hook_060')
DEFAULT_LOGS = H.LOGS
H.LOGS, H.TRANSCRIPT_WAIT = (LOG,), 0.02
RESULTS = []


def check(name, cond, detail=''):
    RESULTS.append((name, bool(cond)))
    print(f'{"PASS" if cond else "FAIL"}  {name}' + ('' if cond else f'\n      {detail}'))


# ---- transcript entries ----
def prompt(text):
    return {'type': 'user', 'message': {'role': 'user', 'content': text}}


def meta(text):
    return {**prompt(text), 'isMeta': True}


def tool(name, tid='t', **args):
    return {'type': 'tool_use', 'id': tid, 'name': name, 'input': args}


def reply(text='', *uses, mid=None):
    m = {'role': 'assistant', 'content': [{'type': 'text', 'text': text}, *uses]}
    if mid:
        m.update(id=mid, model='claude-opus-5-5', usage={'input_tokens': 1, 'cache_creation_input_tokens': 2,
                                                         'cache_read_input_tokens': 3, 'output_tokens': 4})
    return {'type': 'assistant', 'message': m}


def result(text='ok', tid='t'):
    return {'type': 'user', 'message': {'role': 'user', 'content': [
        {'type': 'tool_result', 'tool_use_id': tid, 'content': text}]}}


def numbered(lines, start=1):
    """Text as the Read tool returns it: each line after its number and a tab."""
    return '\n'.join(f'{n}\t{l}' for n, l in enumerate(lines, start))


def invoke(name='praatgen', base=SKILL_DIR):
    return [reply('', tool('Skill', 'sk', skill=name)), result(f'Launching skill: {name}', 'sk'),
            meta(f'Base directory for this skill: {base}\n\nEML PraatGen, Master Prompt 17.1.9.\n\n'
                 'At the start of every turn ... Open the reply with "Rules read this turn: " ...')]


def command(name, args=''):
    """A / menu command as the client writes it: the marker message, then the command's text."""
    return [prompt(f'<command-message>praatgen:{name} is running…</command-message>\n'
                   f'<command-name>/praatgen:{name}</command-name>\n<command-args>{args}</command-args>'),
            meta(open(os.path.join(ARGS.plugin, 'skills', name, 'SKILL.md'), encoding='utf-8').read())]


READ = [reply('', tool('Read', 'rd', file_path=RULES)), result(numbered(RULES_LINES), 'rd')]
TASK = prompt('Write me a Praat script that measures local jitter and shimmer for every WAV in a folder.')
OK_REPLY = reply('Rules read this turn: test-0001\nHere is the PRE-FLIGHT.')
FIRST = [TASK, *invoke(), *READ, OK_REPLY]
TURN_OFF = [prompt(OFF), reply('PraatGen is off.')]


# ---- running the hook ----
def run(mode, entries, path=None, **extra):
    """(what the hook printed, the usage log's lines)."""
    if path is None:
        path = os.path.join(TMP, 'transcript.jsonl')
        with open(path, 'w') as f:
            f.writelines(json.dumps(e) + '\n' for e in entries)
    with contextlib.suppress(FileNotFoundError):
        os.remove(LOG)
    data = {'session_id': 'testsess-1234', 'transcript_path': path, **extra}
    out = io.StringIO()
    argv, stdin = sys.argv, sys.stdin
    sys.argv, sys.stdin = ['rules_check.py', mode], io.StringIO(json.dumps(data))
    try:
        with contextlib.redirect_stdout(out):
            H.main()
    finally:
        sys.argv, sys.stdin = argv, stdin
    rows = [json.loads(l.split(' ', 1)[1]) for l in open(LOG).read().splitlines()] if os.path.exists(LOG) else []
    PRINTED.append(out.getvalue())
    return out.getvalue(), rows


PRINTED = []


def state(entries, pending=None):
    return H.classify(entries, pending)


# ==== 1. Where the hook looks, and when it runs ====
check('rules file found through CLAUDE_PLUGIN_ROOT, in the skill folder',
      H.RULES == os.path.join(ROOT, 'skills', 'praatgen', 'PRAATGEN_RULES_FULL.md'), H.RULES)
FALLBACK = load_hook(os.path.join(ROOT, 'hooks', 'rules_check.py'), 'hook_noenv', env_root=None)
check('without CLAUDE_PLUGIN_ROOT, the plugin folder is the hook folder\'s parent',
      os.path.realpath(FALLBACK.RULES) == os.path.realpath(RULES), FALLBACK.RULES)
check('the usage log goes to the outputs folder\'s praatgen/ folder, then /tmp',
      DEFAULT_LOGS == ('/mnt/user-data/outputs/praatgen/usage.log', '/tmp/praatgen-usage.log'), DEFAULT_LOGS)
hooks = json.load(open(os.path.join(ARGS.plugin, 'hooks', 'hooks.json')))['hooks']
check('hooks.json runs the hook only at typed messages and turn ends, nothing on tools or session start',
      hooks == {event: [{'hooks': [{'type': 'command', 'command':
                f'python3 "${{CLAUDE_PLUGIN_ROOT}}/hooks/rules_check.py" {mode}'}]}]
                for event, mode in (('UserPromptSubmit', 'prompt'), ('Stop', 'stop'))}
      and set(H.MODES) == {'prompt', 'stop'}, hooks)
for mode in ('session', 'skill', ''):
    out, rows = run(mode, [*FIRST, prompt('ok'), reply('x', mid='m1')], tool_name='Skill', tool_input={'skill': 'praatgen'})
    check(f'the retired mode {mode!r} does nothing: no output, no log line', out == '' and rows == [], f'{out} {rows}')

# ==== 2. Which sessions are PraatGen sessions ====
RECOGNIZED = {
    'the skill invoked by its bare name': [TASK, *invoke()],
    'the skill invoked by its plugin-qualified name': [TASK, *invoke('praatgen:praatgen')],
    'only the skill\'s instructions entry (a / menu pick)': [prompt('/praatgen'), invoke()[2]],
    'the model loads the skill on a request by name, with no / pick': [prompt('Use PraatGen for this.'), *invoke()],
    'the model loads the skill after the user says yes to the suggestion':
        [TASK, reply('PraatGen can help with this.'), prompt('yes'), *invoke()],
    'a mode command run, then the skill loaded': [*command('sandbox', 'AUTO measure jitter'), *invoke()],
}
for why, entries in RECOGNIZED.items():
    check(f'on: {why}', state([*entries, reply('Hello.')]) == 'praatgen', state(entries))
NOT_RECOGNIZED = {
    'only a Read of the rules file (a maintainer session)': [TASK, *READ],
    'only a reply that opens with the rules line': [TASK, OK_REPLY],
    'the user typed the rules line and the skill name': [prompt('Rules read this turn: marsh-7316. Use praatgen.')],
    'another skill invoked': [TASK, *invoke('anthropic-skills:pdf', '/x/skills/pdf')],
    'a skill whose name only starts with praatgen': [TASK, *invoke('praatgen-dev', '/x/skills/praatgen-dev')],
    'the rules file read through a shell command': [TASK, reply('', tool('Bash', 'b', command=f'cat {RULES}'))],
    'the skill\'s base-directory line inside a tool result':
        [TASK, reply('', tool('Bash', 'b', command='ls')), result(f'Base directory for this skill: {SKILL_DIR}', 'b')],
    "another skill's instructions entry": [TASK, meta('Base directory for this skill: /x/skills/pdf\n\n# PDF')],
    'a mode command whose text has not loaded the skill yet': command('sandbox'),
}
for why, entries in NOT_RECOGNIZED.items():
    check(f'not on: {why}', state([*entries, reply('Done.')]) == 'other', state(entries))

# ==== 3. Off and on ====
check('PRAATGEN OFF turns a PraatGen session off', state([*FIRST, *TURN_OFF]) == 'off')
check('PRAATGEN OFF given to the typed-message hook before the transcript holds it', state(FIRST, OFF) == 'off')
check('a typed message that is not the off command leaves it on', state(FIRST, 'go on') == 'praatgen')
check('the off command from the / menu turns PraatGen off', state([*FIRST, *command('off')]) == 'off')
for name in ('sandbox', 'nointro', 'verify', 'scaffold'):
    check(f'the {name} command does not turn PraatGen off', state([*FIRST, *command(name)]) == 'praatgen')
check('a block-form typed message', state([*FIRST, {'type': 'user', 'message': {'role': 'user', 'content': [
    {'type': 'text', 'text': OFF}, {'type': 'text', 'text': 'more'}]}}]) == 'off')
OFF_FORMS = {'lowercase': OFF.lower(), 'mixed case': OFF.title(), 'no space': 'PRAATGENOFF',
             'extra words before it': 'Turn PRAATGENOFF', 'extra words after it': f'{OFF} please',
             'not on the first line': f'Hello\n{OFF}', 'inside a sentence': 'Please turn praatgen off for now.',
             'a doubled letter': 'PRaaaTGEnOFF', 'punctuation between': 'PraatGen: off',
             'surrounding whitespace': f'  {OFF}  \nPlease continue.'}
for why, msg in OFF_FORMS.items():
    check(f'off: {why}', state([*FIRST, prompt(msg), reply('PraatGen is off.')]) == 'off')
NEAR_MISSES = {'a system-inserted entry': meta(OFF), 'a tool result': result(OFF), 'assistant text': reply(OFF),
               'text an assistant passes to a tool': reply('', tool('SendUserMessage', 'sm', message=OFF)),
               'PraatGen named without off': prompt('PraatGen is on. To start, tell me the task.'),
               'off as part of another word': prompt('praatgen offers this'),
               'praatgen and off far apart': prompt('Use praatgen for this, and switch the lights off.'),
               '"of" with one f': prompt('PraatGen of course'),
               '"of" with one f, lowercase, mid-sentence': prompt('Is praatgen of any use for vibrato?')}
for why, entry in NEAR_MISSES.items():
    check(f'not off: {why}', state([*FIRST, prompt('Next question.'), entry, reply('Hello.')]) == 'praatgen')
check('a / pick whose text mentions praatgen off is on',
      state([*FIRST, *TURN_OFF, prompt('/praatgen how do I type praatgen off later?'), invoke()[2]]) == 'praatgen')
check('a / pick typed with capitals is on', state([*FIRST, *TURN_OFF, prompt('/PraatGen'), invoke()[2]]) == 'praatgen')
check('off lasts for later turns until PraatGen starts again',
      state([*FIRST, *TURN_OFF, prompt('Write me a Praat script.'), reply('Here it is.')]) == 'off')
check('on again after off, by a request by name', state([*FIRST, *TURN_OFF, prompt('start praatgen'), *invoke()]) == 'praatgen')
check('off after a second on turns it off again',
      state([*FIRST, *TURN_OFF, prompt('go'), *invoke(), reply('Hello.'), prompt(OFF), reply('Off.')]) == 'off')
check('off with no prior on is off; then on', state(TURN_OFF) == 'off'
      and state([*TURN_OFF, prompt('go'), *invoke()]) == 'praatgen')

# ==== 4. The hook logs only sessions that are on, and nothing reaches the session ====
SESSIONS = {
    'on, no read': ([TASK, *invoke(), reply('Hello', mid='a1')], True),
    'on, full read': ([TASK, *invoke(), *READ, reply('Rules read this turn: test-0001', mid='a1')], True),
    'off': ([*FIRST, prompt(OFF), reply('PraatGen is off.', mid='a1')], False),
    'another session': ([TASK, reply('Here is a summary of your email.', mid='a1')], False),
    'a maintainer session that reads the rules file': ([TASK, *READ, reply('Done.', mid='a1')], False),
}
for why, (entries, logged) in SESSIONS.items():
    for mode in H.MODES:
        out, rows = run(mode, entries, prompt='next')
        check(f'{why}, {mode}: prints nothing; ' + ('logs its calls' if logged else 'writes no log line'),
              out == '' and (bool(rows) and rows[-1]['kind'] == 'turn' if logged else rows == []), f'{out!r} {rows}')
folder = os.path.join(TMP, 'not-made')
H.LOGS = (os.path.join(folder, 'usage.log'),)
try:
    run('stop', SESSIONS['another session'][0])
finally:
    H.LOGS = (LOG,)
check('a session that is not logged gets no log folder', not os.path.exists(folder))

# ==== 5. Transcript access ====
missing = os.path.join(TMP, 'nowhere', 'x.jsonl')
open(os.path.join(TMP, 'empty.jsonl'), 'w').close()
for why, path in {'missing': missing, 'an empty path': '', 'unreadable (a folder)': TMP,
                  'empty': os.path.join(TMP, 'empty.jsonl')}.items():
    for mode in H.MODES:
        out, rows = run(mode, FIRST, path=path, prompt='ok')
        check(f'transcript {why}, {mode}: no output, no line (the session can\'t be recognized)',
              out == '' and rows == [], f'{out!r} {rows}')
began = time.time()
run('stop', FIRST, path=missing)
check('transcript missing: tried again, briefly', time.time() - began >= (H.TRANSCRIPT_TRIES - 1) * H.TRANSCRIPT_WAIT)
late = os.path.join(TMP, 'late.jsonl')
LATE = [TASK, *invoke(), reply('Hello', mid='late1')]


def write_late():
    with open(late, 'w') as f:
        f.write('\n'.join(json.dumps(e) for e in LATE) + '\n')


tries, H.TRANSCRIPT_TRIES = H.TRANSCRIPT_TRIES, 50
timer = threading.Timer(H.TRANSCRIPT_WAIT * 3, write_late)
timer.start()
out, rows = run('stop', [], path=late)
timer.join()
H.TRANSCRIPT_TRIES = tries
check('transcript written while the hook waits: read and logged',
      out == '' and [r.get('message') for r in rows if r['kind'] == 'call'] == ['late1'], f'{out!r} {rows}')

# ==== 6. Failures leave a line and never reach the session ====
odd = os.path.join(TMP, 'odd.jsonl')
with open(odd, 'w') as f:
    f.write('[1, 2]\n"a string"\nnot json\n' + json.dumps({'type': 'user', 'message': 'a string'}) + '\n'
            + '\n'.join(json.dumps(e) for e in [TASK, *invoke(), reply('Hello', mid='odd1')]) + '\n')
out, rows = run('stop', [], path=odd)
check('odd lines in the transcript: no crash, still logged', out == '' and any(r['kind'] == 'call' for r in rows), rows)
real = H.classify
H.classify = lambda *a: 1 / 0
try:
    out, rows = run('stop', [TASK, *invoke(), reply('Hello', mid='e1')])
finally:
    H.classify = real
check('an error inside the hook is logged as one error line with its type, and nothing is printed',
      out == '' and len(rows) == 1 and rows[0]['kind'] == 'error' and 'ZeroDivisionError' in rows[0]['error'], rows)
os.rename(RULES, RULES + '.away')
try:
    out, rows = run('stop', [TASK, *invoke(), reply('Hello', mid='n1')])
finally:
    os.rename(RULES + '.away', RULES)
check('without the rules file the hook does nothing', out == '' and rows == [], f'{out!r} {rows}')


class Unreadable(io.StringIO):
    def __init__(self, err):
        super().__init__()
        self.err = err

    def read(self, *a):
        raise self.err


for why, err in {'an OSError': OSError('stdin closed'), 'bad UTF-8': UnicodeDecodeError('utf-8', b'\xff', 0, 1, 'bad'),
                 'a RuntimeError': RuntimeError('odd')}.items():
    argv, stdin, out = sys.argv, sys.stdin, io.StringIO()
    sys.argv, sys.stdin = ['rules_check.py', 'stop'], Unreadable(err)
    with contextlib.suppress(FileNotFoundError):
        os.remove(LOG)
    try:
        with contextlib.redirect_stdout(out):
            H.main()
        exited = 'returned'
    except BaseException as e:                  # noqa: BLE001  what escaped main()
        exited = f'{e.__class__.__name__}: {e}'
    finally:
        sys.argv, sys.stdin = argv, stdin
    PRINTED.append(out.getvalue())
    check(f'reading the input fails with {why}: main returns (exit 0), prints nothing, writes no line',
          exited == 'returned' and out.getvalue() == '' and not os.path.exists(LOG), exited)

# ==== 7. Nothing the hook does reaches the session ====
check(f'the hook printed nothing in any of the {len(PRINTED)} runs', not any(PRINTED), [p for p in PRINTED if p][:3])
source = open(os.path.join(ARGS.plugin, 'hooks', 'rules_check.py'), encoding='utf-8').read()
check('the hook has no block, deny or added-context output left in it',
      not any(w in source for w in ('print(', "'decision'", 'permissionDecision', 'additionalContext')))

failed = [n for n, ok in RESULTS if not ok]
print(f'\n{len(RESULTS) - len(failed)} of {len(RESULTS)} checks passed; temporary folder {TMP}')
shutil.rmtree(TMP, ignore_errors=True)
sys.exit(1 if failed else 0)
