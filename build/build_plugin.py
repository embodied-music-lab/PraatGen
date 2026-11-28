#!/usr/bin/env python3
"""Assemble the PraatGen Cowork plugin from an edited export of main, and
package it.

    python3 build_plugin.py                     # the release: plugin/, its package and the marketplace file
    python3 build_plugin.py --with-usage-log    # the maintainer's test build, with the usage log
    python3 build_plugin.py --check [--with-usage-log]   # exit 1 if that build is stale

Run it after tools/build_rules_full.py and tools/build_lint.py. It writes the skill folder
(SKILL.md, the rules file, the linter as a Python file, and pkb/), the mode
skills in skills/<mode>/SKILL.md, README.md and .claude-plugin/plugin.json. The release
has no hooks. The test build adds every file in usage_log/ (the usage-log hook)
at the same path, in its own folder and package.
"""
import io
import json
import os
import re
import shutil
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import phrases as P  # noqa: E402

COWORK = os.path.dirname(HERE)                   # the repository root
# The PraatGen sources (src/, pkb/, tools/): the root itself in the repository, work/ in a maintainer tree.
WORK = os.path.join(COWORK, 'work') if os.path.isdir(os.path.join(COWORK, 'work')) else COWORK
USAGE_LOG = os.path.join(COWORK, 'usage_log')    # maintainer-only: the usage-log hook, for the test build
USAGE_LOG_FLAG = '--with-usage-log'
USAGE_LOG_SUFFIX = 'usagelog'                    # names the test build's folder and package

NAME = 'praatgen'
PLUGIN_FOLDER = 'plugin'                        # the built plugin, the folder the marketplace points at
VERSION = '3.0.0'
MODES_DIR = 'skills'                             # one skill folder per mode command, beside the praatgen skill
LEGACY_COMMANDS_DIR = 'commands'                 # the older format, removed if an earlier build left it
# Only the user runs a mode command; Claude never loads one on its own.
MODE_FRONTMATTER = 'disable-model-invocation: true'
HOOKS_DIR = 'hooks'                              # in the test build only
GENERATED_DIRS = ('skills', LEGACY_COMMANDS_DIR, HOOKS_DIR)   # emptied before each build


def build(with_log):
    """(plugin folder, package path) of the release, or of the test build with the usage log."""
    suffix = f'-{USAGE_LOG_SUFFIX}' if with_log else ''
    return (os.path.join(COWORK, f'{PLUGIN_FOLDER}{suffix}'),
            # Named for the plugin, as Anthropic's packaging guidance does; the version lives in
            # plugin.json and the release tag, and a fixed name keeps the latest-release link stable.
            os.path.join(COWORK, f'{NAME}{suffix}.plugin'))


PLUGIN, PACKAGE = build(False)
PLUGIN_LOG, PACKAGE_LOG = build(True)
SKILL_DIR = os.path.join(PLUGIN, 'skills', NAME)
RULES = 'PRAATGEN_RULES_FULL.md'                 # at the top of the skill folder
LINT_ZIP, LINT_IN_ZIP = 'TOOL_PRAATGEN_LINT.zip', 'TOOL_PRAATGEN_LINT.txt'
LINT = 'TOOL_PRAATGEN_LINT.py'                   # at the top of the skill folder
ZIP_TIME = (2026, 1, 1, 0, 0, 0)                 # fixed, so the same files give the same bytes

DESCRIPTION = P.TAGLINE
# How Claude names PraatGen to the user; in when_to_use, the only text Claude has before PraatGen starts,
# and in SKILL.md. It governs text written to the user, not the Skill tool's argument.
NAMING = ("Text you write to the user names PraatGen and its / menu entry PraatGen or praatgen, never with the "
          "plugin's name and a colon in front; the Skill tool's argument isn't text to the user.")
WHEN_TO_USE = (
    'Start it when the user picks praatgen from the / menu, asks for PraatGen by name in any wording or '
    'capitalization, or says yes to the suggestion below. '
    "When PraatGen isn't running and the user asks a substantive question or for work in its areas "
    '(Praat measures, commands, settings or results; designing a voice study; choosing measurements and their '
    'settings; reading signals or the measurements taken from them; figures and statistics; writing, fixing, '
    'reviewing or running a Praat script or plugin), reply with one plain line and wait: '
    f'{P.SUGGESTION} Do no other work in that reply: no searching, no reading files, no answer. '
    'A reply that could mean yes, such as "yes, go ahead", is a yes. "Go ahead without it", or the '
    'like, declines: help as usual and don\'t suggest it again in that session. A passing mention of Praat or '
    'PraatGen gets no suggestion. '
    f'{NAMING}')
PLUGIN_JSON = {
    'name': NAME,
    'displayName': 'PraatGen',
    'version': VERSION,
    'description': P.PLUGIN_DESCRIPTION,
    'author': {'name': 'Ian Howell, Embodied Music Lab'},
    'license': 'GPL-3.0-or-later',
}

# The repository is a plugin marketplace: the Claude app reads this file and installs ./plugin.
MARKETPLACE = os.path.join(COWORK, '.claude-plugin', 'marketplace.json')
MARKETPLACE_JSON = {
    'name': 'embodied-music-lab',
    'description': P.TAGLINE,
    'owner': PLUGIN_JSON['author'],
    'plugins': [{'name': NAME, 'source': f'./{PLUGIN_FOLDER}', 'description': P.TAGLINE}],
}


def marketplace():
    return (json.dumps(MARKETPLACE_JSON, indent=2) + '\n').encode('utf-8')


def found(pattern, text):
    """The first group of pattern in the rules text; stops the build when it's missing."""
    m = re.search(pattern, text, re.M)
    if not m:
        sys.exit(f'{RULES}: no match for {pattern!r}')
    return m.group(1)


MODES_TABLE = '| Keyword | What it does |'      # the header of the introduction's Modes table


def row(key):
    """A keyword's row of the introduction's Modes table, as its / menu text."""
    return lambda rules: found(rf'^\| {re.escape(key)} \| (.+) \|$', rules[rules.index(MODES_TABLE):])


def shared_and_own(key, keyword):
    """A shared Modes table row's first sentence, then its sentence that starts with the keyword, as that
    keyword's / menu text."""
    def text(rules):
        r = row(key)(rules)
        return f"{found(r'^([^.]*\.)', r)} {found(rf'\b({re.escape(keyword)} [^.]*\.)', r)}"
    return text


def reworded(key, old, new, draft):
    """A draft / menu text that is a keyword's Modes table row with old changed to new; stops the build
    when the row and the draft no longer match."""
    def text(rules):
        if row(key)(rules).replace(old, new) != draft:
            sys.exit(f'{key}: its Modes table row with {old!r} changed to {new!r} is no longer {draft!r}')
        return draft
    return text


def phrase(text):
    return lambda rules: text


# The mode commands: file name -> (the keyword it applies, its / menu text from the rules text).
COMMANDS = {
    'scaffold': ('SCAFFOLD', row('SCAFFOLD')),
    'sandbox': ('SANDBOX', row('SANDBOX')),
    'auto': ('AUTO', row('AUTO')),
    'debugging': ('DEBUGGING', row('DEBUGGING')),
    'noreview': ('NOREVIEW', row('NOREVIEW')),
    'verbose': ('VERBOSE', shared_and_own('VERBOSE / SPARSE', 'VERBOSE')),
    'sparse': ('SPARSE', shared_and_own('VERBOSE / SPARSE', 'SPARSE')),
    'nointro': ('NOINTRO', reworded('NOINTRO', 'this introduction', 'the introduction', P.NOINTRO_MENU)),
    'off': (P.OFF_COMMAND, phrase(P.OFF_EFFECT)),
    'verify': ('VERIFY YOUR STATE', lambda rules: found(r'On that command (I .+)$', rules)),
}
OFF_NAME = 'off'                                 # the command that turns PraatGen off
ARGUMENTS = '$ARGUMENTS'                         # where a command's text goes

# The other start that is a yes, besides a yes to the suggestion; defined here only. The rules' opening
# (STEP 1) points to it as "started from a yes (skill instructions)".
BY_NAME_YES = ('Asking for PraatGen by name, without the / menu or a command, in a message that also '
               'states a task, such as "Use PraatGen to measure jitter in these recordings", counts as a yes.')
START_PARAGRAPH = (
    'PraatGen starts when the user picks praatgen from the / menu, runs one of its commands, asks for '
    'PraatGen by name in any wording or capitalization, or says yes to the suggestion to use it. '
    f'{BY_NAME_YES} When it starts from a yes, the request that came with the yes or before it is their '
    "first message: carry on with it, and don't ask them to repeat it. If that request is a question, "
    "don't answer it: reply as the rules' STEP 1 sets out for a first message that is a question. "
    f'{NAMING}')


def keyword_list():
    words = [k for k, _ in COMMANDS.values()]
    return ', '.join(words[:-1]) + f' and {words[-1]}'


def commands_paragraph():
    return (f'Each of these keywords also has a command in the / menu: {keyword_list()}. A command '
            'applies its keyword exactly as the rules define that keyword, and, except for '
            f"{OFF_NAME}, starts PraatGen first if it isn't running. Keywords combine however they arrive: typed after the praatgen pick, typed "
            'after a command, or several in one message, with or without a command (for example, pick '
            'praatgen, then type SANDBOX AUTO NOINTRO followed by the task). Apply them together, as if '
            'typed together at the start of the message, within the combinations the rules allow. The '
            "text after them is the user's message.")


def off_paragraph():
    """The off rule, defined here only."""
    return (f'When a message from the user asks to turn PraatGen off ({P.OFF_COMMAND} in any capitalization, '
            f'anywhere in the message, with or without the space, or the {OFF_NAME} command), PraatGen is off '
            f"from that message on. Don't read {RULES}, don't open replies with the rules line, and don't "
            f'apply PraatGen\'s rules. Reply "{P.OFF_REPLY}", then answer the rest of the message as usual. '
            'When PraatGen starts again later in the conversation (the / menu pick, any command, or a request '
            f"by name), read {RULES} in full, then return to the conversation's current work with any mode the "
            "user asked for on. Don't give the introduction again.")


def command_body(name, keyword):
    """What a command tells Claude. It points to the keyword's rule and never restates it."""
    if name == OFF_NAME:
        return (f"This message is PraatGen's {OFF_NAME} command, {keyword}: apply the off rule in PraatGen's "
                "skill instructions. If PraatGen isn't running in this conversation, don't start it, and "
                f'answer the message as usual. The rest of the message: {ARGUMENTS}')
    return (f'Apply the PraatGen keyword {keyword} exactly as PraatGen\'s rules define it. If PraatGen '
            "isn't running in this conversation, start it first: load the praatgen skill with the Skill "
            'tool and follow its instructions, including the full read of its rules. Treat what follows '
            f'as the user\'s message, typed after {keyword}: {ARGUMENTS}')


def command_files(rules):
    """{path under PLUGIN: text} for each mode command, as a skill the user runs from the / menu."""
    return {os.path.join(MODES_DIR, name, 'SKILL.md'):
            f'---\nname: {name}\ndescription: {json.dumps(text(rules))}\n{MODE_FRONTMATTER}\n---\n\n'
            f'{command_body(name, keyword)}\n'
            for name, (keyword, text) in COMMANDS.items()}


def skill_md():
    with open(os.path.join(WORK, 'PROJECT_INSTRUCTIONS.txt'), encoding='utf-8') as f:
        body = f.read()
    return (f'---\nname: {NAME}\ndescription: {json.dumps(DESCRIPTION)}\n'
            f'when_to_use: {json.dumps(WHEN_TO_USE)}\n---\n\n'
            f'{body.rstrip()}\n\n{START_PARAGRAPH}\n\n{commands_paragraph()}\n\n{off_paragraph()}\n')


def readme():
    return f'# {PLUGIN_JSON["displayName"]}\n\n{P.TAGLINE}\n\n{P.OFF_LINE}\n'


def linter():
    with zipfile.ZipFile(os.path.join(WORK, 'pkb', LINT_ZIP)) as z:
        return z.read(LINT_IN_ZIP)


def tree(root):
    """Every file under root: {path under root: bytes}, caches left out."""
    out = {}
    for d, dirs, names in os.walk(root):
        dirs[:] = sorted(x for x in dirs if x != '__pycache__')
        for fn in sorted(names):
            path = os.path.join(d, fn)
            with open(path, 'rb') as f:
                out[os.path.relpath(path, root)] = f.read()
    return out


def wanted(with_log=False):
    """Every file of the build: {path under its plugin folder: bytes}."""
    out = {os.path.join('.claude-plugin', 'plugin.json'):
           (json.dumps(PLUGIN_JSON, indent=2) + '\n').encode('utf-8'),
           'README.md': readme().encode('utf-8'),
           os.path.join('skills', NAME, 'SKILL.md'): skill_md().encode('utf-8'),
           os.path.join('skills', NAME, LINT): linter()}
    pkb = os.path.join(WORK, 'pkb')
    for fn in sorted(os.listdir(pkb)):
        with open(os.path.join(pkb, fn), 'rb') as f:
            data = f.read()
        if fn == RULES:
            out[os.path.join('skills', NAME, RULES)] = data
        elif fn != LINT_ZIP:
            out[os.path.join('skills', NAME, 'pkb', fn)] = data
    rules = out[os.path.join('skills', NAME, RULES)].decode('utf-8')
    out.update({rel: text.encode('utf-8') for rel, text in command_files(rules).items()})
    if with_log:
        out.update(tree(USAGE_LOG))
    return out


def package(files):
    """The plugin folder as a zip, sorted, with fixed times and modes."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as z:
        for rel in sorted(files):
            info = zipfile.ZipInfo(rel.replace(os.sep, '/'), ZIP_TIME)
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, files[rel])
    return buf.getvalue()


def main():
    args = sys.argv[1:]
    with_log = USAGE_LOG_FLAG in args
    folder, pkg = build(with_log)
    files = wanted(with_log)
    name = f'{os.path.relpath(folder, COWORK)}/'
    if '--check' in args:
        current = tree(folder) if os.path.isdir(folder) else {}
        stale = [p for p in files if current.get(p) != files[p]]
        extra = [p for p in current if p not in files]
        pkg_ok = os.path.exists(pkg) and open(pkg, 'rb').read() == package(files)
        market_ok = with_log or (os.path.exists(MARKETPLACE) and open(MARKETPLACE, 'rb').read() == marketplace())
        if stale or extra or not pkg_ok or not market_ok:
            print(f'{name} is STALE: {len(stale)} files differ, {len(extra)} extra, '
                  f'package {"current" if pkg_ok else "stale"}, marketplace {"current" if market_ok else "stale"}')
            sys.exit(1)
        print(f'{name} and {os.path.basename(pkg)} are current')
        return
    for generated in GENERATED_DIRS:
        shutil.rmtree(os.path.join(folder, generated), ignore_errors=True)
    for rel, data in files.items():
        path = os.path.join(folder, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'wb') as f:
            f.write(data)
    extra = sorted(set(tree(folder)) - set(files))
    if extra:
        sys.exit(f'{name} holds files the build does not write: {extra}')
    data = package(files)
    with open(pkg, 'wb') as f:
        f.write(data)
    if not with_log:
        os.makedirs(os.path.dirname(MARKETPLACE), exist_ok=True)
        with open(MARKETPLACE, 'wb') as f:
            f.write(marketplace())
    print(f'wrote {name} ({len(files)} files) and {os.path.basename(pkg)} ({len(data)} bytes)')


if __name__ == '__main__':
    main()
