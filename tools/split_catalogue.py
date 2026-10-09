#!/usr/bin/env python3
"""Split the Praat capability catalogue into two PKB parts, or join them back.

The Claude app returns at most 256 KiB of a text project file, and the whole
catalogue is larger, so the PKB carries it in two parts. Each part opens with
a part note: which part holds which object type, plus, in part 2, a copy of
the catalogue header and the §2 header. The part note ends at END_MARK. Every
line after END_MARK is the catalogue itself, unchanged, so joining the parts
gives back the whole file byte for byte.

Run from the repo root:
    python3 tools/split_catalogue.py split FULL.txt   # write the two parts
    python3 tools/split_catalogue.py join OUT.txt     # rebuild the whole file
    python3 tools/split_catalogue.py --check          # parts join cleanly, fit
"""
import re
import sys

PARTS = ('pkb/PRAAT_DEFINITIVE_CATALOGUE_PART1.txt',
         'pkb/PRAAT_DEFINITIVE_CATALOGUE_PART2.txt')
END_MARK = '#### END OF PART NOTE: the catalogue text follows, unchanged ####\n'
LIMIT = 256 * 1024          # the app's cap on one text read
SPLIT_BEFORE = 'Spectrogram'  # first object type in part 2
BLOCK = re.compile(r'^={20,}\n  (\S.*?)\s+\(\d+ commands?\)\n={20,}\n', re.M)


def blocks(text):
    """(offset, title) of every §2 block."""
    return [(m.start(), m.group(1)) for m in BLOCK.finditer(text)]


def note(part, p1_types, p2_types, header):
    lines = [
        f'# PRAAT_DEFINITIVE_CATALOGUE_PART{part}.txt: part {part} of 2 of the',
        '# Praat capability catalogue. It is in two parts so that each part reads',
        '# in full; the app returns at most 256 KiB of one text file. Together the',
        '# two parts are the whole catalogue, unchanged. Provenance lines elsewhere',
        '# that cite PRAAT_DEFINITIVE_CATALOGUE.txt mean this catalogue.',
        '#',
        '# PART 1: the header and accuracy banner, §1 class hierarchy, and the',
        '#   single-type command blocks for these object types:',
    ]
    lines += wrap(p1_types)
    lines += [
        '# PART 2: a copy of the header and accuracy banner, then the single-type',
        '#   command blocks for these object types:',
    ]
    lines += wrap(p2_types)
    lines += [
        '#   then every multi-type block (two or more object types selected',
        '#   together, such as "Sound & Pitch" or "Pitch & TextGrid"), the Objects',
        '#   and Picture menu commands, and §3 Formula engine functions.',
        '# A command for one object type is in that type\'s block. A command that',
        '# needs two or more selected types, a menu command or a formula function',
        '# is in part 2. Search both parts before concluding a command is absent.',
        '#',
    ]
    text = '\n'.join(lines) + '\n'
    if header:
        text += ('# ---- Copy of the catalogue header and §2 header, from part 1 ----\n'
                 + header)
    return text + END_MARK


def wrap(names):
    out, line = [], '#     '
    for i, n in enumerate(names):
        item = n + (', ' if i < len(names) - 1 else '.')
        if len(line) + len(item) > 78:
            out.append(line.rstrip())
            line = '#     '
        line += item
    out.append(line.rstrip())
    return out


def split(full):
    bl = blocks(full)
    cut = next(o for o, t in bl if t == SPLIT_BEFORE)
    single = [t for o, t in bl if '&' not in t and t not in ('Objects', 'Picture')]
    p1 = [t for o, t in bl if o < cut and t in single]
    p2 = [t for o, t in bl if o >= cut and t in single]
    # Part 2 carries the header (to the end of §1's banner) and the §2 header
    # (its banner, warning and totals), so its readers see the accuracy notes.
    s1 = full.index('# §1 CLASS HIERARCHY')
    s1 = full.rindex('#' * 80, 0, s1)
    s2 = full.index('# §2 ALL COMMANDS WITH PARAMETERS AND DEFAULTS')
    s2 = full.rindex('#' * 80, 0, s2)
    header = full[:s1] + full[s2:bl[0][0]]
    return (note(1, p1, p2, '') + full[:cut],
            note(2, p1, p2, header) + full[cut:])


def join(parts):
    return ''.join(p.split(END_MARK, 1)[1] for p in parts)


def read(path):
    with open(path, encoding='utf-8', newline='') as f:
        return f.read()


def write(path, text):
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(text)


if __name__ == '__main__':
    args = sys.argv[1:]
    if args[:1] == ['split'] and len(args) == 2:
        full = read(args[1])
        parts = split(full)
        assert join(parts) == full
        for path, text in zip(PARTS, parts):
            write(path, text)
            print(f'wrote {path} ({len(text.encode())} bytes)')
    elif args[:1] == ['join'] and len(args) == 2:
        write(args[1], join([read(p) for p in PARTS]))
        print(f'wrote {args[1]}')
    elif args == ['--check']:
        parts = [read(p) for p in PARTS]
        ok = all(p.count(END_MARK) == 1 for p in parts)
        ok = ok and split(join(parts)) == tuple(parts)
        ok = ok and all(len(p.encode()) <= LIMIT for p in parts)
        print('catalogue parts are current' if ok else 'catalogue parts are STALE: re-split')
        sys.exit(0 if ok else 1)
    else:
        print(__doc__)
        sys.exit(2)
