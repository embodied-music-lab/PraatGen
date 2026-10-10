#!/usr/bin/env python3
"""
Self-contradiction sweep — see MAINTENANCE.md §1.

Finds places where a file uses a construct the PKB prohibits, outside any block
labelled WRONG / anti-pattern / never. Deliberately noisy: triage every hit.

Exit 0 = clean, 1 = hits found.
"""
import re
import sys
import glob
import os

# regex -> the rule it violates. Add an entry for every hard prohibition.
BANNED = {
    # not anchored: `demo Marks left:` and other prefixed forms must match too
    r'(^|\s)Marks (left|bottom|right|top):\s*\d':
        'bare Marks for tick placement (BEST_PRACTICES_DRAWING.txt)',
    r'^\s*#?\s*Font size:\s*\d+\s*$':
        'literal Font size (font-state invariant, Rule 28L)',
}

# a hit within this many lines of one of these labels is a counter-example
LABELS = re.compile(r'WRONG|never bare|anti-pattern|Anti-pattern|NEVER use|'
                    r'DO NOT EMIT|do not use|does not respect')
WINDOW = 12

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Triaged-correct occurrences, keyed on file + exact line text so they survive
# line-number drift. Kept here rather than as markers in the PKB, which a
# generating model reads and should not be cluttered with maintainer notes.
# eml-* hits are deliberately NOT allowlisted — they are a live upstream report.
def _load_allow():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        'sweep_allow.txt')
    out = set()
    if os.path.exists(path):
        for raw in open(path, encoding='utf-8'):
            raw = raw.split('#', 1)[0].strip() if raw.startswith('#') else raw.rstrip('\n')
            if not raw.strip() or raw.lstrip().startswith('#'):
                continue
            fname, _, text = raw.partition('\t')
            if text:
                out.add((fname.strip(), text.strip()))
    return out

ALLOW = _load_allow()


def sweep(paths):
    hits = []
    for path in sorted(paths):
        try:
            lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
        except OSError:
            continue
        excused = set()
        for i, line in enumerate(lines):
            if LABELS.search(line):
                # a note may sit before OR after the lines it governs
                excused.update(range(max(0, i - WINDOW),
                                     min(i + WINDOW, len(lines))))
        for i, line in enumerate(lines):
            if i in excused:
                continue
            if (os.path.basename(path), line.strip()) in ALLOW:
                continue
            for pattern, rule in BANNED.items():
                if re.search(pattern, line):
                    hits.append((os.path.relpath(path, ROOT), i + 1,
                                 line.strip()[:56], rule))
    return hits


def main():
    # pkb/PRAATGEN_RULES_FULL.md is built from src/, so src/ is swept instead.
    targets = ([p for p in glob.glob(os.path.join(ROOT, 'pkb', '*'))
                if os.path.basename(p) != 'PRAATGEN_RULES_FULL.md'] +
               glob.glob(os.path.join(ROOT, 'src', '*.md')))
    hits = sweep(targets)
    if not hits:
        print('clean — no prohibited construct outside a labelled block')
        return 0
    print(f'{len(hits)} hit(s) to triage:\n')
    for path, line, text, rule in hits:
        lib = '  [plugin source — fix only a verified defect; mark it PraatGen-only and log it in UPSTREAM_CORRECTIONS.md]' \
              if os.path.basename(path).startswith('eml-') else ''
        print(f'{path}:{line}\n    {text}\n    violates: {rule}{lib}\n')
    return 1


if __name__ == '__main__':
    sys.exit(main())
