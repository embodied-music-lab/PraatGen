#!/usr/bin/env python3
"""Offline test of the PraatGen 0.6.0 skill text: SKILL.md, the mode commands,
the rules file's opening and connected-folder edits, the doubled skill name,
the copy list in BUILD.md, and the two packages (the release, with no hooks,
and the maintainer's test build with the usage log). Phrases come from
build/phrases.py, so each is stated once.

    python3 test_skill_text.py [--plugin DIR]
"""
import argparse, json, os, re, sys, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True                  # nothing written into build/ or the plugin
COWORK = os.path.join(HERE, os.pardir)
ap = argparse.ArgumentParser()
ap.add_argument('--plugin', default=os.path.join(COWORK, 'plugin'))
ARGS = ap.parse_args()
sys.path.insert(0, os.path.join(COWORK, 'build'))
import phrases as P  # noqa: E402
import build_plugin as B  # noqa: E402

RESULTS = []


def check(name, cond, detail=''):
    RESULTS.append((name, bool(cond)))
    print(f'{"PASS" if cond else "FAIL"}  {name}' + ('' if cond else f'\n      {detail}'))


def read(*parts):
    with open(os.path.join(ARGS.plugin, *parts), encoding='utf-8') as f:
        return f.read()


def front(text):
    """(frontmatter fields, body) of a skill or command file."""
    m = re.match(r'---\n(.*?)\n---\n\n(.*)\Z', text, re.S)
    fields = dict(line.split(': ', 1) for line in m.group(1).splitlines())
    return {k: json.loads(v) for k, v in fields.items() if v.startswith('"')} | \
           {k: v for k, v in fields.items() if not v.startswith('"')}, m.group(2)


SKILL = read('skills', 'praatgen', 'SKILL.md')
FIELDS, BODY = front(SKILL)
RULES = read('skills', 'praatgen', 'PRAATGEN_RULES_FULL.md')
COMMANDS = {d: read('skills', d, 'SKILL.md') for d in sorted(os.listdir(os.path.join(ARGS.plugin, 'skills')))
            if d != 'praatgen'}
HOOK = open(os.path.join(B.USAGE_LOG, 'hooks', 'rules_check.py'), encoding='utf-8').read()   # maintainer-only
README = read('README.md')
OFF_FORM = re.search(r"OFF_FORM = re\.compile\(r'(.+?)', re\.I\)", HOOK).group(1)

# ==== 1. Starting PraatGen ====
WHEN = FIELDS['when_to_use']
check('the / menu text is the tagline', FIELDS['description'] == P.TAGLINE, FIELDS['description'])
check('when_to_use starts PraatGen by name in any wording or capitalization, and on a yes',
      'asks for PraatGen by name in any wording or capitalization' in WHEN and 'says yes' in WHEN, WHEN)
check('when_to_use carries the suggestion line, with "type / and choose praatgen"',
      P.SUGGESTION in WHEN and 'typing / and choosing praatgen' in P.SUGGESTION, WHEN)
check('when_to_use waits after the suggestion', 'reply with one plain line and wait' in WHEN, WHEN)
check('when_to_use: a reply that could mean yes, such as "yes, go ahead", is a yes',
      'A reply that could mean yes, such as "yes, go ahead", is a yes.' in WHEN, WHEN)
check('when_to_use: "go ahead without it" or the like declines, and the suggestion is not repeated',
      '"Go ahead without it", or the like, declines: help as usual and don\'t suggest it again' in WHEN, WHEN)
check('when_to_use is no longer than 0.6.0\'s first build (1,178 characters)', len(WHEN) < 1178, len(WHEN))
check('SKILL.md: after a yes, the request that came with or before it is the first message, not asked for again',
      'When it starts from a yes, the request that came with the yes or before it is their first message' in BODY
      and "don't ask them to repeat it" in BODY, BODY)
check('SKILL.md: asking for PraatGen by name with the task in the same message counts as a yes',
      'Asking for PraatGen by name' in B.BY_NAME_YES and 'states a task' in B.BY_NAME_YES
      and 'Use PraatGen to measure jitter' in B.BY_NAME_YES and B.BY_NAME_YES.endswith('counts as a yes.'),
      B.BY_NAME_YES)
check('SKILL.md: a / pick or a command is not a by-name yes, so the short opening stays for them',
      'without the / menu or a command' in B.BY_NAME_YES, B.BY_NAME_YES)
check('the by-name yes is defined once, in SKILL.md, and nowhere else the plugin ships',
      SKILL.count(B.BY_NAME_YES) == 1 and B.BY_NAME_YES not in RULES
      and not any(B.BY_NAME_YES in t for t in COMMANDS.values()) and B.BY_NAME_YES not in README
      and open(B.__file__, encoding='utf-8').read().count('counts as a yes') == 1)
check('the by-name yes stays in what Claude reads after PraatGen starts, not in when_to_use',
      B.BY_NAME_YES in BODY and B.BY_NAME_YES not in WHEN)
check('SKILL.md: a question carried by a yes gets the rules\' question line, by pointing to STEP 1',
      "If that request is a question, don't answer it: reply as the rules' STEP 1 sets out for a first "
      'message that is a question.' in BODY and P.QUESTION_LINE not in SKILL, BODY)
check('the rules: a start from a yes is handled as NOINTRO, with no second offer, by pointing to SKILL.md',
      'If the first message contains `NOINTRO`, or PraatGen started from a yes\n(skill '
      'instructions), the first exception applies instead.' in RULES)
check('the rules restate neither kind of yes: no suggestion and no by-name request in the opening exceptions',
      not re.search(r'its suggestion|by name[^.]*states a task|counts as a yes',
                    RULES[RULES.index('**First exception'):RULES.index('Respond with:')]))
check('nothing in the skill says a hook refuses a load, or that Claude must never load it',
      not re.search(r'hook|Never load it yourself', SKILL), re.findall(r'.{40}(?:hook|Never load).{40}', SKILL))

# ==== 2. The doubled name never appears in what Claude reads or says ====
DOUBLED = 'praatgen:praatgen'
SHIPPED = {'SKILL.md': SKILL, 'the rules file': RULES, 'plugin.json': read('.claude-plugin', 'plugin.json'),
           'README.md': README,
           **{f'the {n} command': t for n, t in COMMANDS.items()}}
for where, text in SHIPPED.items():
    check(f'no doubled skill name in {where}', DOUBLED not in text.lower())
check('when_to_use and SKILL.md each say once not to write the plugin-qualified name, from one definition',
      WHEN.count(B.NAMING) == 1 and BODY.count(B.NAMING) == 1
      and "never with the plugin's name and a colon in front" in B.NAMING
      and open(B.__file__, encoding='utf-8').read().count('colon in front') == 1)
check('the naming rule governs text written to the user, and says the Skill tool\'s argument is not that text',
      B.NAMING.startswith('Text you write to the user') and "the Skill tool's argument isn't text to the user"
      in B.NAMING, B.NAMING)

# ==== 3. Mode commands ====
check('one command per mode: scaffold, sandbox, auto, debugging, noreview, verbose, sparse, nointro, off, verify',
      sorted(COMMANDS) == sorted(['scaffold', 'sandbox', 'auto', 'debugging', 'noreview', 'verbose', 'sparse',
                                  'nointro', 'off', 'verify']), sorted(COMMANDS))
TEMPLATE = None
for name, text in COMMANDS.items():
    fields, body = front(text)
    keyword = B.COMMANDS[name][0]
    check(f'{name}: a plain-English description and the user\'s text placed after the keyword',
          set(fields) == {'name', 'description', 'disable-model-invocation'} and fields['description'] and body.rstrip().endswith('$ARGUMENTS'), text)
    if name == B.OFF_NAME:
        rule = B.off_paragraph()
        restated = [s for s in re.split(r'(?<=\.) ', rule[rule.index('PraatGen is off'):]) if s in body]
        check('off: points to the off rule in the skill instructions and restates none of it',
              "apply the off rule in PraatGen's skill instructions" in body and not restated, restated)
        check('off: never starts PraatGen', 'Skill tool' not in body and "don't start it" in body, body)
        continue
    general = body.replace(keyword, '<KEYWORD>')
    TEMPLATE = TEMPLATE or general
    check(f'{name}: points to the {keyword} rule, starts PraatGen if needed, and restates no mode rule',
          general == TEMPLATE and f'the PraatGen keyword {keyword} exactly as PraatGen\'s rules define it' in body
          and "If PraatGen isn't running" in body and 'load the praatgen skill with the Skill tool' in body, body)
    check(f'{name}: nothing in it reads as the off command', not re.search(OFF_FORM, text, re.I))
modes = RULES[RULES.index('**Modes.**'):RULES.index('Modes combine,')]          # the introduction's Modes table
table = {m.group(1): m.group(2) for m in re.finditer(r'^\| ([A-Z /]+) \| (.+) \|$', modes, re.M)}
for name, row in {'scaffold': 'SCAFFOLD', 'sandbox': 'SANDBOX', 'auto': 'AUTO', 'debugging': 'DEBUGGING',
                  'noreview': 'NOREVIEW'}.items():
    check(f'{name}: its description is its row of the introduction\'s Modes table, word for word',
          front(COMMANDS[name])[0]['description'] == table[row])
SHARED = 'More or less detailed replies.'
for name, text in {'sparse': 'SPARSE is the default and uses fewer tokens.',
                   'verbose': 'VERBOSE works at any step that waits for your GO.'}.items():
    check(f'{name}: its description is the VERBOSE / SPARSE row\'s shared sentence, then its own',
          front(COMMANDS[name])[0]['description'] == f'{SHARED} {text}'
          and table['VERBOSE / SPARSE'].startswith(SHARED) and text in table['VERBOSE / SPARSE'],
          front(COMMANDS[name])[0]['description'])
check('nointro: its description is the NOINTRO row with "this introduction" made "the introduction", a draft',
      front(COMMANDS['nointro'])[0]['description'] == P.NOINTRO_MENU
      == table['NOINTRO'].replace('this introduction', 'the introduction') and P.NOINTRO_MENU in P.DRAFTS,
      front(COMMANDS['nointro'])[0]['description'])
check('verify: its description is the introduction\'s sentence on what VERIFY YOUR STATE does',
      'On that command ' + front(COMMANDS['verify'])[0]['description'] in RULES)
check('off: its description is the introduction\'s sentence on what turning PraatGen off does',
      front(COMMANDS['off'])[0]['description'] == P.OFF_EFFECT and P.OFF_EFFECT in RULES)
COMPOSE = 'Keywords combine however they arrive'
check('SKILL.md states once how keywords and commands combine, with the SANDBOX AUTO NOINTRO example',
      BODY.count(COMPOSE) == 1 and 'SANDBOX AUTO NOINTRO' in BODY
      and not any(COMPOSE in t for t in COMMANDS.values()), BODY)
check('SKILL.md lists every command keyword', all(k in BODY for k, _ in B.COMMANDS.values()))
check('SKILL.md: every command but off starts PraatGen first',
      'and, except for off, starts PraatGen first if it isn\'t running' in BODY, BODY)
check('SKILL.md holds the one definition of the off rule',
      SKILL.count(B.off_paragraph()) == 1 and not any(B.off_paragraph() in t for t in COMMANDS.values()))
check('SKILL.md names the off command, accepted anywhere in any case',
      f'({P.OFF_COMMAND} in any capitalization, anywhere in the message' in BODY)
check('the off reply is one fixed line, "PraatGen is off." and the introduction\'s back-on sentence',
      P.OFF_REPLY == f'PraatGen is off. {P.BACK_ON}' and P.OFF_LINE.endswith(P.BACK_ON)
      and f'Reply "{P.OFF_REPLY}", then answer the rest of the message as usual.' in BODY, BODY)
check('the off reply is defined once: in phrases.py, and shipped only in the off rule',
      SKILL.count(P.OFF_REPLY) == 1 and P.OFF_REPLY not in RULES and P.OFF_REPLY not in README
      and not any(P.OFF_REPLY in t for t in COMMANDS.values())
      and open(P.__file__, encoding='utf-8').read().count("'PraatGen is off.") == 1)
check('a start after off reads the rules in full and returns to the current work, without the introduction',
      'When PraatGen starts again later in the conversation (the / menu pick, any command, or a request by name), '
      f"read {B.RULES} in full, then return to the conversation's current work with any mode the user asked for "
      "on. Don't give the introduction again." in BODY, BODY)

# ==== 4. The rules file ====
check('the full introduction still opens with the off line and the tagline',
      f'"{P.OFF_LINE}\n\n{P.TAGLINE}\n' in RULES)
check('a first message that states the task gets the short opening: off line, tagline, restatement, offer',
      '**Second exception: a first message that already states the task.**' in RULES
      and "Reply with a short opening: the\nresponse's first two paragraphs (the line on turning PraatGen off, "
          "and the\ntagline)" in RULES
      and 'STEP 2 restatement (`RULES_PLANNING.md`)' in RULES and f'"{P.MISSING}" for each item' in RULES
      and f'"{P.OFFER_LINE}"' in RULES)
check('second exception: a yes goes straight to the PRE-FLIGHT when all four items are present; with items '
      'marked missing it asks for those first, then gives the PRE-FLIGHT',
      'If they say yes and all four items are\npresent, go straight to the PRE-FLIGHT. If any item is marked\n'
      f'"{P.MISSING}", ask only for those items first, then give the PRE-FLIGHT.' in RULES)
check('second exception: a yes to the scaffold offer starts the scaffold discussion',
      'instead, and a yes starts the scaffold discussion:' in RULES)
check('NOINTRO keeps its meaning, as the first of the two exceptions',
      '**First exception: `NOINTRO`.** If the user\'s first message contains `NOINTRO`, skip' in RULES
      and 'One exception' not in RULES)
second = RULES[RULES.index('**Second exception'):RULES.index('Respond with:')]
check('second exception: NOINTRO in the same message wins',
      'If the first message contains `NOINTRO`' in second and 'the first exception applies instead' in second)
check('second exception: other keywords take effect as normal; AUTO has no offer and no wait; '
      'SCAFFOLD offers the scaffold discussion',
      'Other mode keywords in the same message take effect as normal: with `AUTO`,\ngive no offer line and '
      "don't wait; with `SCAFFOLD`, end with this line\ninstead, and a yes starts the scaffold discussion:" in second
      and f'"{P.SCAFFOLD_OFFER_LINE}"' in second, second)
check('second exception: it covers a first message that states a task, and no longer a question',
      "If the\nuser's first message already states a task, don't make them restate it\nafter the full response."
      in second and 'or asks a question' not in second, second)
third = RULES[RULES.index('**Third exception'):RULES.index('Respond with:')]
second = second[:second.index('**Third exception')]
check('third exception: a first message that is a question is not answered and gets no restatement',
      "**Third exception: a first message that is a question.** If the user's\nfirst message asks a question and "
      "states no task, don't answer it, and\ndon't give the STEP 2 restatement." in third, third)
check('third exception: it holds however PraatGen started: / pick, command, by name or a yes',
      'This holds however PraatGen started:\nthe / menu pick, a command, a request by name, or a yes' in third, third)
check('third exception: exactly the approved line, after the off line and tagline, or without them with '
      'NOINTRO or a yes',
      "Reply with exactly this line, after the response's first\ntwo paragraphs, or without them when the message "
      f'contains `NOINTRO` or\nPraatGen started from a yes:\n\n"{P.QUESTION_LINE}"\n\nThen wait.' in third, third)
check('third exception: a yes or a task takes the script path (restatement, then PRE-FLIGHT as NOINTRO sets out)',
      'A yes or a task takes the script path: the STEP 2 restatement\nof what they\'ve given, with '
      f'"{P.MISSING}" for each item they haven\'t, then\nthe PRE-FLIGHT as NOINTRO sets out.' in third, third)
check('third exception: the scaffold command or SCAFFOLD goes to scaffold, and the two paths never mix',
      'The scaffold command or `SCAFFOLD`\nstarts scaffold (STEP 2A, `RULES_MODES.md`). Take one path, never a mix '
      'of\nthe two.' in third, third)
check('third exception: a question with SCAFFOLD already on gets the off line and tagline as for a task, then '
      'the scaffold discussion, without the line',
      "When the first message itself turns `SCAFFOLD` on, give the\nresponse's first two paragraphs as the second "
      'exception does, then go to\nthe scaffold discussion, without this line.' in third, third)
check('after a yes (or a by-name request), the first reply opens with the off line once, defined in one place',
      "**After a yes.** When PraatGen started from a yes (skill instructions),\nits first reply opens with the "
      "response's first paragraph, the line on\nturning PraatGen off, once, then follows the exception that "
      'applies.' in RULES and RULES.count('**After a yes.**') == 1 and RULES.count(P.OFF_LINE) == 1)
check('the question line is defined once: one copy in the rules, none in SKILL.md, the commands or the README',
      RULES.count(P.QUESTION_LINE) == 1 and P.QUESTION_LINE not in SKILL and P.QUESTION_LINE not in README
      and not any(P.QUESTION_LINE in t for t in COMMANDS.values())
      and open(P.__file__, encoding='utf-8').read().count('Would you like to build a script now?') == 1)
gate = RULES[RULES.index('## HARD GATE'):RULES.index('## WEB ACCESS')]
check('HARD GATE: the short opening and the question line are not turn 1, like the introduction',
      "the introduction doesn't\n  count, and neither do the short opening and the question line in STEP 1's\n"
      '  second and third exceptions' in gate, gate)
cf = RULES[RULES.index('## CONNECTED FOLDERS AND RECORDINGS'):RULES.index('**Recordings of people.**')]
check('CONNECTED FOLDERS: a folder is asked for only when the task gains, and then through the folder tool',
      'Ask for one only when the task gains from it.' in cf
      and 'When you ask\nfor one and the session has a tool that asks the user for access' in cf, cf)
check('CONNECTED FOLDERS: without that reach, the local route first; the linking line only when the user '
      'wants the session itself on their files',
      cf.index('offer the local\nroute first') < cf.index(P.LINK_LINE)
      and f'Say once "{P.LINK_LINE}"\nonly when the user wants the session itself to work with files on their\n'
          'computer.' in cf, cf)
check('CONNECTED FOLDERS: other files change when the user asks or the task needs it; new outputs go in the '
      'output folder; Rule 27 governs new output writes',
      'may be changed or reorganized when the user asks\n  or the task needs it.' in cf
      and '- New outputs still go in an output folder inside the connected folder.' in cf
      and '- Every new output goes through the unique-path rule (Rule 27).' in cf
      and 'Every write goes through' not in cf, cf)

rec = RULES[RULES.index('**Recordings of people.**'):RULES.index('## CHECKPOINTS')]
check('recordings of people: a folder connected after the PRE-FLIGHT gets the notice before any recording is read',
      'When such a\nfolder is connected after the PRE-FLIGHT, do it then, before reading any of\nthem:' in rec, rec[:400])

# ==== 5. README ====
check('README.md: the tagline and how to start and stop PraatGen, all reused, with no hooks sentence',
      README == f'# PraatGen\n\n{P.TAGLINE}\n\n{P.OFF_LINE}\n' and 'hook' not in README.lower(), README)
PLUGIN_JSON = json.loads(read('.claude-plugin', 'plugin.json'))
check('plugin.json: the existing description, with no hooks clause, and no hook declaration',
      PLUGIN_JSON['description'] == P.PLUGIN_DESCRIPTION == ('EML PraatGen as a Cowork skill: the PraatGen Master '
      'Prompt, its reference files and its linter.') and 'hooks' not in PLUGIN_JSON, PLUGIN_JSON)

# ==== 6. Copy awaiting Ian (maintainer tree only: BUILD.md isn't in the repository) ====
if os.path.exists(os.path.join(COWORK, 'BUILD.md')):
    build_md = open(os.path.join(COWORK, 'BUILD.md'), encoding='utf-8').read()
    section = build_md[build_md.rfind('Copy awaiting Ian'):]
    for text in P.DRAFTS:
        check(f'BUILD.md lists the draft verbatim: {text[:50]}', text in section)
    items = re.findall(r'^  > (.+)$', section, re.M)
    check('BUILD.md lists only the drafts', sorted(items) == sorted(P.DRAFTS), items)
    for text in (P.OFFER_LINE, P.SCAFFOLD_OFFER_LINE, P.QUESTION_LINE, P.PLUGIN_DESCRIPTION):
        check(f'approved, and so not a draft: {text[:50]}', text not in P.DRAFTS and text not in section)
    approved = build_md[build_md.rfind('### Approved copy'):build_md.rfind('### Copy awaiting Ian')]
    check('BUILD.md notes the two offer lines as approved, moved from the copy list',
          P.OFFER_LINE in approved and P.SCAFFOLD_OFFER_LINE in approved, approved)
    check('the linking line says how to link, and BUILD.md notes where its control names come from',
          'open the + menu in the message box, choose Devices, and pick your computer' in P.LINK_LINE
          and "control names come from Ian's own app, not Anthropic's docs" in section, section)

# ==== 7. The two packages ====
def entries(pkg):
    with zipfile.ZipFile(pkg) as z:
        return {n: z.read(n) for n in z.namelist()}


RELEASE, TEST = entries(B.PACKAGE), entries(B.PACKAGE_LOG)
LOG_FILES = {rel.replace(os.sep, '/'): data for rel, data in B.tree(B.USAGE_LOG).items()}
check('the release package is praatgen.plugin and the test package praatgen-usagelog.plugin; the version is in plugin.json',
      os.path.basename(B.PACKAGE) == 'praatgen.plugin'
      and os.path.basename(B.PACKAGE_LOG) == 'praatgen-usagelog.plugin'
      and B.PLUGIN_JSON['version'] == B.VERSION, (B.PACKAGE, B.PACKAGE_LOG))
check('the release package has no hooks folder and no hooks.json anywhere',
      not any(n.startswith('hooks/') or n.endswith('hooks.json') for n in RELEASE), sorted(RELEASE)[:5])
check('the release plugin folder has no hooks folder', not os.path.exists(os.path.join(B.PLUGIN, 'hooks')))
check('neither package declares hooks in plugin.json',
      all('hooks' not in json.loads(p['.claude-plugin/plugin.json']) for p in (RELEASE, TEST)))
check('the usage log ships as hooks/hooks.json and hooks/rules_check.py',
      sorted(LOG_FILES) == ['hooks/hooks.json', 'hooks/rules_check.py'], sorted(LOG_FILES))
check('the test package is the release plus the usage log, byte for byte',
      TEST == {**RELEASE, **LOG_FILES} and not set(RELEASE) & set(LOG_FILES), sorted(set(TEST) ^ set(RELEASE)))
check('the test package\'s hooks.json runs the usage log at typed messages and turn ends',
      set(json.loads(TEST['hooks/hooks.json'])['hooks']) == {'UserPromptSubmit', 'Stop'})

# ---- 0.6.1: scaffold discusses measures and settings (Ian, 28 Nov 2026) ----
check('scaffold: SKILL.md lets a no-read turn answer a settings question from the covering reference file',
      "read the reference file in the skill's pkb/ folder that covers it" in SKILL and 'never from memory' in SKILL)
check('scaffold: only code waits; the old ban on commands and parameter values is gone',
      "On a turn without the read, don't write code." in SKILL and 'propose parameter values' not in SKILL
      and 'choose specific commands or set parameter values' not in SKILL)
check('scaffold: Step 2A answers specifics under the Reference Retrieval Protocol and holds only code',
      'Code waits until scaffold ends.' in RULES and 'stays conceptual' not in RULES
      and 'stay conceptual' not in RULES)
check('scaffold: the Modes row drops its false clause and adds nothing',
      "While it's on, I don't reread my rules each turn. Tell me" in RULES
      and 'not commands or settings' not in RULES)
check('third exception: scaffold answers the opening question',
      'Scaffold answers the question in its discussion.' in RULES)

# ---- 0.6.2: mode commands are skills (the commands/ format is the older one) ----
check('no commands/ folder: every mode command is a skill folder with name, description and '
      'disable-model-invocation: true',
      not os.path.exists(os.path.join(ARGS.plugin, 'commands'))
      and all(front(t)[0].get('name') == n and front(t)[0].get('disable-model-invocation') == 'true'
              for n, t in COMMANDS.items()))
check('the praatgen skill itself stays model-invocable (start by name or by a yes)',
      'disable-model-invocation' not in SKILL)

check('the marketplace file names the plugin folder and the tagline',
      json.loads(open(B.MARKETPLACE).read()) == B.MARKETPLACE_JSON
      and B.MARKETPLACE_JSON['plugins'][0]['source'] == './plugin')

failed = [n for n, ok in RESULTS if not ok]
print(f'\n{len(RESULTS) - len(failed)} of {len(RESULTS)} checks passed')
sys.exit(1 if failed else 0)
