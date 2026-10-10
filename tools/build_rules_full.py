"""Build pkb/PRAATGEN_RULES_FULL.md from the core and the six RULES files in src/.

The Claude app doesn't re-send project instructions on every turn. PraatGen's
project instructions therefore hold one rule: read PRAATGEN_RULES_FULL.md in
full at the start of every turn. This script writes that file: a short header,
the core and the six RULES files word for word, and a footer whose last line
is the marker each reply opens with.

    python3 tools/build_rules_full.py           # write the file
    python3 tools/build_rules_full.py --check   # exit 1 if it is out of date

The app returns at most 262,144 bytes of a text project file, so the build
fails if the file reaches that size.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'pkb', 'PRAATGEN_RULES_FULL.md')
RULES_ORDER = ['RETRIEVAL', 'PLANNING', 'AUDIT', 'CODE', 'MODES', 'SANDBOX']
MARKER = 'marsh-7316'
APP_READ_LIMIT = 262144
RULE = '=' * 64


def sources():
    cores = glob.glob(os.path.join(ROOT, 'src', 'MASTER_PROMPT_CORE_v*.md'))
    if len(cores) != 1:
        sys.exit(f'expected one core in src/, found {len(cores)}')
    return cores + [os.path.join(ROOT, 'src', f'RULES_{n}.md') for n in RULES_ORDER]


def build():
    paths = sources()
    with open(paths[0], encoding='utf-8') as f:
        m = re.search(r'^\*\*Version:\*\* (\S+)', f.read(), re.M)
    version = m.group(1) if m else 'unknown'
    parts = [
        '# PRAATGEN RULES, FULL TEXT (read every turn)\n\n'
        f'This file is the whole PraatGen prompt: the Master Prompt core ({version}) '
        'followed by the six RULES files. At the start of every turn, before any '
        'other tool call or any text, read this entire file with project_read. '
        'Then open your reply with the line "Rules read this turn: " followed by '
        "the marker on this file's last line.\n\n"
        'Wherever the text below says to read a RULES_*.md file (RULES_RETRIEVAL.md, '
        'RULES_PLANNING.md, RULES_AUDIT.md, RULES_CODE.md, RULES_MODES.md, '
        'RULES_SANDBOX.md), that file is the section of the same name below, which '
        "you read in full this turn. Don't look for it as a separate file. Its read "
        'token is at the end of its section.\n']
    for p in paths:
        with open(p, encoding='utf-8') as f:
            body = f.read()
        parts.append(f'\n\n{RULE}\n=== SECTION: {os.path.basename(p)}\n{RULE}\n\n{body}')
    parts.append(f'\n\n{RULE}\nEnd of PRAATGEN_RULES_FULL.md. Read this whole file '
                 f'again at the start of the next turn.\nMarker: {MARKER}\n')
    text = ''.join(parts)
    size = len(text.encode('utf-8'))
    if size >= APP_READ_LIMIT:
        sys.exit(f'PRAATGEN_RULES_FULL.md would be {size} bytes, over the '
                 f'{APP_READ_LIMIT}-byte app read limit')
    return text, size


def main():
    text, size = build()
    if '--check' in sys.argv[1:]:
        try:
            with open(OUT, encoding='utf-8') as f:
                current = f.read()
        except FileNotFoundError:
            current = None
        if current != text:
            print('pkb/PRAATGEN_RULES_FULL.md is out of date: run tools/build_rules_full.py')
            sys.exit(1)
        print(f'pkb/PRAATGEN_RULES_FULL.md is current ({size} bytes)')
        return
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f'wrote pkb/PRAATGEN_RULES_FULL.md ({size} bytes, '
          f'{APP_READ_LIMIT - size} under the app read limit)')


if __name__ == '__main__':
    main()
