#!/usr/bin/env python3
"""Tests for the linter's CSV text fields check (Rule 27).

    python3 tools/test_lint_csv_text.py

Each case is a short Praat script. A case lists the script lines the check
must block, or none. Exit 0 when every case passes.
"""
import glob
import importlib.util
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('lint', os.path.join(HERE, 'praatgen_lint.py'))
lint = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lint)

CASES = [
    # --- blocked: a traced text field joined bare to a comma separator
    ('file list name as a write argument', [5], '''
files = Create Strings as file list: "files", "snd/*.wav"
for i to 2
    selectObject: files
    name$ = Get string: i
    appendFileLine: out$, name$, ",", 1
endfor
'''),
    ('object name inline', [2], '''
selectObject: sound
appendFileLine: out$, selected$ ("Sound"), ",", fixed$ (d, 3)
'''),
    ('TextGrid label in a + chain', [2], '''
label$ = Get label of interval: 1, i
appendFileLine: out$, "x," + label$ + "," + string$ (i)
'''),
    ('name carried through string subtraction', [3], '''
file$ = Get string: i
base$ = file$ - ".wav"
appendFileLine: out$, base$, ",", 3
'''),
    ('row variable built first, written later', [3], '''
name$ = Get string: i
d$ = fixed$ (dur, 3)
row$ = name$ + "," + d$
appendFileLine: out$, row$
'''),
    ('row extended across lines', [3], '''
name$ = Get string: i
row$ = fixed$ (dur, 3)
row$ = row$ + "," + name$
writeFileLine: out$, row$
'''),
    ('separator held in a variable', [3], '''
sep$ = ","
name$ = selected$ ("Sound")
appendFileLine: out$, name$ + sep$ + "1"
'''),
    ('form sentence field', [4], '''
form: "Test"
    sentence: "Speaker name", "Jo"
endform
appendFileLine: out$, speaker_name$, ",", 1
'''),
    ('beginPause word field', [4], '''
beginPause: "Test"
    word: "Group", "a"
endPause: "Quit", "OK", 2, 0
appendFileLine: out$, group$, ",", 1
'''),
    ('continuation line reports its own line', [4], '''
name$ = Get string: i
appendFileLine: out$,
... fixed$ (dur, 3), ",",
... name$
'''),
    # --- not blocked
    ('Rule 27 pattern', [], '''
name$ = Get string: i
field$ = """" + replace$ (name$, """", """""", 0) + """"
appendFileLine: out$, field$, ",", fixed$ (0.1, 3)
'''),
    ('quote held in a variable', [], '''
q$ = """"
name$ = Get string: i
field$ = q$ + replace$ (name$, q$, q$ + q$, 0) + q$
appendFileLine: out$, field$, ",", 1
'''),
    ('variable quoted in place', [], '''
name$ = Get string: i
name$ = """" + replace$ (name$, """", """""", 0) + """"
appendFileLine: out$, name$, ",", 1
'''),
    ('numeric strings are not traced', [], '''
d$ = fixed$ (dur, 3)
n$ = string$ (count)
appendFileLine: out$, d$, ",", n$
'''),
    ('header literal', [], '''
writeFileLine: out$, "file,duration"
'''),
    ('Info window output', [], '''
name$ = Get string: i
appendInfoLine: name$, ",", 1
row$ = name$ + "," + "1"
appendInfoLine: row$
'''),
    ('tab-separated file', [], '''
name$ = Get string: i
appendFileLine: out$, name$, tab$, 1
'''),
    ('prose in a log file', [], '''
name$ = Get string: i
appendFileLine: log$, "Skipped ", name$, ", no TextGrid"
'''),
    ('name alone on a line', [], '''
name$ = Get string: i
appendFileLine: list$, name$
'''),
    ('variable reassigned to a number string', [], '''
name$ = Get string: i
name$ = fixed$ (dur, 3)
appendFileLine: out$, name$, ",", 1
'''),
    ('name used as an argument, not joined', [], '''
name$ = Get string: i
appendFileLine: out$, "n,", length (name$)
'''),
]


def run(source):
    with tempfile.NamedTemporaryFile('w', suffix='.praat', delete=False,
                                     encoding='utf-8') as f:
        f.write(source.lstrip('\n'))
        path = f.name
    try:
        return lint.check_csv_text(lint.read_lines(path))
    finally:
        os.unlink(path)


def main():
    failed = 0
    for title, want, source in CASES:
        findings = run(source)
        got = sorted(n for _level, n, _msg in findings)
        levels = {level for level, _n, _msg in findings}
        ok = got == sorted(want) and levels <= {'BLOCKING'}
        failed += not ok
        print(f'{"ok  " if ok else "FAIL"} {title}: blocked lines {got}'
              + ('' if ok else f', want {sorted(want)}'))
    # The EML library copies follow the rule, so none of them is blocked.
    library = sorted(glob.glob(os.path.join(HERE, os.pardir, 'pkb', 'eml-*.txt')))
    lib_hits = [(os.path.basename(p), n) for p in library
                for _level, n, _msg in lint.check_csv_text(lint.read_lines(p))]
    ok = bool(library) and not lib_hits
    failed += not ok
    print(f'{"ok  " if ok else "FAIL"} {len(library)} EML library files: blocked {lib_hits}')
    total = len(CASES) + 1
    print(f'{total - failed} of {total} pass')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
