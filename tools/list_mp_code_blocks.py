#!/usr/bin/env python3
"""List the Praat code blocks in the Master Prompt core and RULES files — see MAINTENANCE.md §2."""
import re, glob, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY = re.compile(r'^\s*(Draw|Text|Marks|One mark|Select|Axes|Colour|Font size|'
                 r'Line width|Save as|@eml|Erase|Paint)', re.M)
for mp in (glob.glob(os.path.join(ROOT, 'MASTER_PROMPT_CORE_*.md')) +
           sorted(glob.glob(os.path.join(ROOT, 'pkb', 'RULES_*.md')))):
    lines = open(mp, encoding='utf-8').read().split('\n')
    cur, start = [], 0
    print(f'== {os.path.basename(mp)} ==')
    for i, l in enumerate(lines):
        if l.startswith('    ') and l.strip() and not l.strip().startswith('|'):
            if not cur: start = i + 1
            cur.append(l)
        else:
            if len(cur) >= 3 and KEY.search('\n'.join(cur)):
                print(f'  line {start:<6} {len(cur):>2} lines   {cur[0].strip()[:50]}')
            cur = []
