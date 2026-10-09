#!/usr/bin/env python3
"""Static checks for a Praat script produced by PraatGen.

Usage:  python3 praatgen_lint.py SCRIPT.praat [PLAN.md] [PKB_FOLDER]
        python3 praatgen_lint.py --procedure NAME [NAME ...]

--procedure prints EML library procedures ready to paste at the end of a
script: each named procedure and every library procedure it calls, with its
header comment, renamed to the emlPG prefix and otherwise verbatim. NAME may
carry @, the eml prefix or the emlPG prefix. Exit status 1 names any NAME the
library doesn't have.

With PKB_FOLDER, the command reference files are read from that folder.
Without it, the index embedded at the end of this file is used (the PKB copy,
TOOL_PRAATGEN_LINT.txt, carries one). With neither, the pkb folder beside the
folder that holds this file is used. PLAN.md holds the command plan: a
markdown table whose header row has the columns Command and Source.

Each finding is BLOCKING or NOTE, with its script line. Resolve every
BLOCKING finding before the script ships; a NOTE names what to check. The
first output line is a summary; each check follows, with its findings or
"none"; the last line is a one-line tally per severity.

Checks:
  Command references   Every command call against the COMMANDS_*.txt files
                       and the two catalogue part files (outcomes below).
  Plan coverage        Every command called is a row of the command plan
                       (Rule 17); every row has a Source.
  Task coverage        The plan quotes the task under "Task as given" and has
                       a Requested | Produced by table; every row names what
                       produces it, or "dropped:" with the user's words.
  Form numeric defaults  real/positive/integer/natural (and vector) fields in
                       form ... endform have a quoted default (Rule 18).
  Non-ASCII text       Non-ASCII in a string on a line that writes a file
                       blocks; elsewhere it is a note.
  Plugin includes      include only from a relative folder named *_lib.
  Library prefix       eml library procedures are copied as emlPG<Name>.
  Procedure calls      Every @name call has a procedure definition.
  Library copies       Every emlPG procedure, in the script or an included
                       *_lib file, matches its EML library source line for
                       line, apart from the emlPG prefix on procedure names.
  Reserved names       No assignment, loop variable or procedure parameter
                       named e, pi or undefined.
  Old syntax           No do ( / do$ ( / call / select / plus / minus / echo /
                       printline / fileappend, no "Command... arguments"
                       form, and no 'variable' interpolation.
  Pause dialogs        endPause: ends with 0, the cancel-button index.
  Hardcoded paths      No absolute path, file:// URL or UNC path in a string.
  Hardcoded values     Notes each number written outside the constants block
                       (0, 1, 2, 12, 100, fixed$ digits and indexes are
                       exempt), and each constant whose value appears in the
                       user's words quoted in the plan (Rules 26 and 35).
  Overwrite guard      A script that writes files checks fileReadable or
                       calls a *UniquePath* procedure. A note.
  Nested queries       No query command inside an expression (Rule 5E).
  Functions            Every function call is spelled as
                       APPENDIX_B_FUNCTIONS.txt spells it.
  Read tokens          Each line "RULES_NAME.md: token" in the plan names
                       that file's real read token. RULES_CODE.md must be
                       listed. The linter holds only a one-way hash of each
                       pairing, so it can confirm a token but never reveal it.

Command references. The selection's type is inferred from the commands that
created the selected objects, from a literal file extension in Read from file:,
and from object arguments passed to procedures. Entries in
COMMANDS_Universal.txt, COMMANDS_PictureWindow.txt, COMMANDS_DemoWindow.txt
and COMMANDS_Editor.txt apply whatever the selection is.
  VERIFIED        Name and argument count match a curated COMMANDS_*.txt
                  entry for the selection's type or for any type.
  ARITY MISMATCH  A curated entry documents the name's arguments with a
                  different count. Blocks.
  ARGS UNDOCUMENTED  The curated entries list the name with no argument list
                  and the script passes arguments. A note.
  CATALOGUE ONLY  No curated entry. Only the catalogue (two PART files) lists
                  the name, with the same argument count. The catalogue is the
                  last fallback and its counts run low, so this blocks until
                  the Praat manual, a sandbox probe or Paste Commands confirms
                  the call (Rule 12).
  NO ARGUMENT LIST  Only the catalogue lists the name, with no arguments or a
                  different count. The catalogue drops some fields, so its
                  count can't confirm the call. Blocks.
  TYPE UNKNOWN    The selection's type isn't inferred, or the name has no
                  listing for it, and the listing types disagree on the
                  count. A note when the script's count matches a listing;
                  blocks when it matches none.
  NOT FOUND       No reference file lists the name. Blocks.
A blocked call is cleared by a Praat manual citation or Paste Commands output.
Exit status: 1 when any finding blocks, 0 otherwise, 2 on a usage error.
"""
import bisect
import hashlib
import os
import re
import sys
from collections import defaultdict

QUERY_WORDS = ('Get', 'Count', 'Is', 'List', 'Report')
QUERY = tuple(w + ' ' for w in QUERY_WORDS)
# Assignment target: a name, possibly built with 'interpolation' (.row'.i'$),
# possibly indexed (a# [2]).
ASSIGN = re.compile(r"^[.\w]+(?:'[.\w]+[$#]?'[.\w]*)*[$#]*\s*(?:\[[^\]]*\]\s*)?=\s*(?!=)")
PREFIXES = ('noprogress ', 'nocheck ', 'nowarn ')
NON_ARG_FIELDS = {'COMMENT'}

# Reference files (COMMANDS_<name>.txt) and catalogue sections whose commands
# apply whatever the selection is.
TYPE_FREE = {'Universal', 'PictureWindow', 'DemoWindow', 'Editor',
             'Objects', 'Picture', 'Daata'}
EDITOR = 'Editor'

# Commands whose new object has the same type as the selection.
SAME_TYPE = {'Copy', 'Extract part', 'Extract one channel', 'Resample',
             'Filter (pass Hann band)', 'Filter (stop Hann band)',
             'Convert to mono', 'Convert to stereo', 'Remove noise',
             'Lengthen (overlap-add)'}
# Name prefixes of commands that create an object and select it.
CREATORS = ('To ', 'Extract ', 'Create ', 'Read ', 'Down to ', 'Up to ',
            'Open ', 'Concatenate', 'Merge')
# Commands whose result type the name does not spell out. Derivative is the
# Electroglottogram command, which returns a Sound (COMMANDS_Electroglottogram).
FIXED_RESULT = {'Open long sound file': 'LongSound', 'Derivative': 'Sound'}
# Read from file: result type by literal file extension (lower case). An
# extension that names a type (.Pitch, .Table) gives that type.
READ_EXT = {'textgrid': 'TextGrid', 'csv': 'Table', 'tsv': 'Table',
            'txt': 'Table', 'table': 'Table', 'wav': 'Sound', 'aif': 'Sound',
            'aiff': 'Sound', 'aifc': 'Sound', 'flac': 'Sound', 'mp3': 'Sound',
            'ogg': 'Sound', 'nist': 'Sound'}

# form fields whose default must be a quoted string (Rule 18).
NUMERIC_FIELDS = ('real', 'positive', 'integer', 'natural',
                  'realvector', 'positivevector', 'integervector')
FILE_WRITERS = ('writeFile', 'writeFileLine', 'appendFile', 'appendFileLine')
RESERVED = ('e', 'pi', 'undefined')
OLD_KEYWORDS = ('select', 'plus', 'minus', 'echo', 'printline', 'fileappend')
# An absolute path at the start of a string, after a space or after "=".
ABS_PATH = re.compile(r'(?:^|[\s=])(/Users\b|/home/|/Volumes/|/tmp/|/mnt/|'
                      r'/var/|/opt/|/Applications/|~/|file://|[A-Za-z]:[\\/])')
# Forms recognized only at the start of a string: UNC path, C:folder.
ABS_PATH_START = re.compile(r'^(\\\\|[A-Za-z]:[A-Za-z])')
LIB_PREFIX = 'emlPG'
BODY_WIDTH = 70
LIST_WIDTH = 6


# ---------------------------------------------------------------- parsing

def split_args(text):
    """Split an argument list at top-level commas."""
    if text.strip() == '':
        return []
    args, depth, cur, quote = [], 0, '', False
    i = 0
    while i < len(text):
        c = text[i]
        if quote:
            cur += c
            if c == '"':
                if i + 1 < len(text) and text[i + 1] == '"':
                    cur += '"'
                    i += 1
                else:
                    quote = False
        elif c == '"':
            quote = True
            cur += c
        elif c in '([{':
            depth += 1
            cur += c
        elif c in ')]}':
            depth -= 1
            cur += c
        elif c == ',' and depth == 0:
            args.append(cur.strip())
            cur = ''
        else:
            cur += c
        i += 1
    args.append(cur.strip())
    return args


def scan_strings(text):
    """Return (code, strings): code is text with every string literal's
    contents blanked (quotes kept, offsets unchanged); strings is a list of
    (offset of the opening quote, literal contents with "" undoubled)."""
    code, strings = [], []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c != '"':
            code.append(c)
            i += 1
            continue
        start, buf = i, []
        code.append('"')
        i += 1
        while i < n:
            if text[i] == '"':
                if i + 1 < n and text[i + 1] == '"':
                    buf.append('"')
                    code.append('  ')
                    i += 2
                    continue
                break
            buf.append(text[i])
            code.append(' ')
            i += 1
        if i < n:
            code.append('"')
            i += 1
        strings.append((start, ''.join(buf)))
    return ''.join(code), strings


class Line:
    """One logical line: continuation lines joined, with a map back to the
    physical line of any offset."""

    def __init__(self, n, text, in_form):
        self.n = n
        self.text = text
        self.in_form = in_form
        self.starts = [0]
        self.lines = [n]
        self._scan = None

    def join(self, n, more):
        self.text += ' '
        self.starts.append(len(self.text))
        self.lines.append(n)
        self.text += more

    def line_at(self, offset):
        return self.lines[bisect.bisect_right(self.starts, offset) - 1]

    @property
    def code(self):
        if self._scan is None:
            self._scan = scan_strings(self.text)
        return self._scan[0]

    @property
    def strings(self):
        if self._scan is None:
            self._scan = scan_strings(self.text)
        return self._scan[1]


def read_lines(path):
    """Logical lines of a script, comments removed, form lines marked."""
    with open(path, encoding='utf-8') as f:
        raw = f.read().split('\n')
    out = []
    in_form = False
    for n, line in enumerate(raw, 1):
        s = line.strip()
        if s.startswith('...') and out:
            out[-1].join(n, s[3:].strip())
            continue
        if s == '' or s[0] in '#;!':
            continue
        if not in_form and (s == 'form' or s.startswith('form ')
                            or s.startswith('form:')):
            in_form = True
            out.append(Line(n, s, True))
            continue
        out.append(Line(n, s, in_form))
        if in_form and s == 'endform':
            in_form = False
    return out


def strip_prefixes(body):
    for p in PREFIXES:
        if body.startswith(p):
            body = body[len(p):]
    return body


def statement(text):
    """(assignment target or None, statement body without target/prefixes)."""
    m = ASSIGN.match(text)
    target, body = None, text
    if m:
        target = text[:m.end()].split('=')[0].strip()
        body = text[m.end():]
    return target, strip_prefixes(body)


def is_assignment(text):
    """True for x = ..., x += ... and the like."""
    return bool(ASSIGN.match(text) or re.match(r'^[.\w]+[$#]*\s*[-+*/]=', text))


def short(text):
    return text if len(text) <= BODY_WIDTH else text[:BODY_WIDTH - 3] + '...'


def name_list(names):
    names = sorted(names)
    if len(names) <= LIST_WIDTH:
        return ', '.join(names)
    return ', '.join(names[:LIST_WIDTH]) + f' and {len(names) - LIST_WIDTH} more'


# ------------------------------------------------------ command references

def load_curated(pkb):
    """name -> list of (type, arity, file, line)."""
    ref = defaultdict(list)
    for fn in sorted(os.listdir(pkb)):
        if not (fn.startswith('COMMANDS_') and fn.endswith('.txt')):
            continue
        otype = fn[len('COMMANDS_'):-len('.txt')]
        path = os.path.join(pkb, fn)
        with open(path, encoding='utf-8') as f:
            raw_lines = f.read().split('\n')
        for n, raw in enumerate(raw_lines, 1):
            s = raw.strip()
            if s.startswith('# Verified:'):
                call = s[len('# Verified:'):].strip()
                name, _, args = call.partition(':')
                ref[name.strip()].append(
                    (otype, len(split_args(args)), fn, n))
                continue
            if not raw.startswith('  ') or s.startswith('#') or not s:
                continue
            if not re.match(r'[A-Z]', s):
                continue
            # An argument list continued on the next line with "...".
            k = n
            while k < len(raw_lines) and raw_lines[k].strip().startswith('...'):
                s += ' ' + raw_lines[k].strip()[3:].strip()
                k += 1
            # A trailing verification tag: [V], [V-n], [S].
            s = re.sub(r'\s+\[[A-Z][\w-]*\]$', '', s)
            name, colon, params = s.partition(':')
            name = name.strip().rstrip('?').strip()
            arity = len(split_args(params)) if colon else 0
            ref[name].append((otype, arity, fn, n))
    return ref


TOKEN_LINE = re.compile(r"^\s*[-*|]?\s*`?(RULES_[A-Z]+\.md)`?\s*[:|]\s*`?([a-z]+-\d{3})`?", re.M)


def token_hash(name, token):
    return hashlib.sha256(f'{name}:{token}'.encode('utf-8')).hexdigest()


def load_token_hashes(pkb):
    """RULES file name -> hash of the pairing with the token on its last
    line ("End of RULES_X.md. Read token: word-NNN")."""
    out = {}
    for fn in sorted(os.listdir(pkb)):
        if not (fn.startswith('RULES_') and fn.endswith('.md')):
            continue
        with open(os.path.join(pkb, fn), encoding='utf-8') as f:
            lines = [s.strip() for s in f.read().split('\n') if s.strip()]
        m = re.search(r'Read token:\s*([a-z]+-\d{3})\s*$', lines[-1]) if lines else None
        if m:
            out[fn] = token_hash(fn, m.group(1))
    return out


FUNCTIONS_FILE = 'APPENDIX_B_FUNCTIONS.txt'
FUNCTION_NAME = re.compile(r"(?<![\w.$#@'])([a-z][A-Za-z0-9_]*(?:\$#|\$|##|#)?)\s*\(")


def load_functions(pkb):
    """name -> line in APPENDIX_B_FUNCTIONS.txt where it first appears."""
    out = {}
    path = os.path.join(pkb, FUNCTIONS_FILE)
    if not os.path.isfile(path):
        return out
    with open(path, encoding='utf-8') as f:
        for n, raw in enumerate(f.read().split('\n'), 1):
            for m in FUNCTION_NAME.finditer(raw):
                out.setdefault(m.group(1), n)
    return out


CATALOGUE_PARTS = ('PRAAT_DEFINITIVE_CATALOGUE_PART1.txt',
                   'PRAAT_DEFINITIVE_CATALOGUE_PART2.txt')


def load_catalogue(pkb):
    """name -> list of (type, arity, file, line). Arity excludes COMMENT
    fields. The catalogue is in two parts; each line is counted in its part."""
    cat = defaultdict(list)
    for part in CATALOGUE_PARTS:
        path = os.path.join(pkb, part)
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            lines = f.read().split('\n')
        otype, entry = None, None
        for n, raw in enumerate(lines, 1):
            m = re.match(r'^  (\S.*?)\s+\(\d+ commands?\)\s*$', raw)
            if m and n > 1 and lines[n - 2].startswith('====='):
                otype = m.group(1)
                entry = None
                continue
            if otype is None:
                continue
            if re.match(r'^  [A-Z]', raw) and not raw.startswith('   '):
                name = re.sub(r'\s*\[alias\]\s*$', '', raw.strip())
                entry = [otype, 0, part, n]
                cat[name].append(entry)
                continue
            fm = re.match(r'^    ([A-Z_]+)\s', raw)
            if fm and entry is not None and fm.group(1) not in NON_ARG_FIELDS:
                entry[1] += 1
    return {k: [tuple(e) for e in v] for k, v in cat.items()}


def sole_owners(curated, catalogue):
    """name -> the one object type that lists it, for names that no
    type-free reference lists and exactly one object type lists."""
    owners = defaultdict(set)
    for src in (curated, catalogue):
        for name, entries in src.items():
            owners[name].update(e[0] for e in entries)
    out = {}
    for name, ts in owners.items():
        if ts & TYPE_FREE:
            continue
        ts = {t for t in ts if re.match(r'[A-Z]', t)}
        if len(ts) == 1 and ' & ' not in next(iter(ts)):
            out[name] = next(iter(ts))
    return out


def infer_type(name, argtext, selection_type, types):
    """Type of the object a command creates, or None."""
    if name in SAME_TYPE:
        return selection_type
    if name in FIXED_RESULT:
        return FIXED_RESULT[name]
    if name == 'Read from file':
        args = split_args(argtext)
        m = re.match(r'^"[^"]*\.(\w+)"$', args[0]) if args else None
        if m:
            ext = m.group(1).lower()
            if ext in READ_EXT:
                return READ_EXT[ext]
            return next((t for t in types if t.lower() == ext), None)
        return None
    m = re.match(r'^Read (\w+) from ', name)
    if m:
        return m.group(1) if m.group(1) in types else None
    for verb in ('To ', 'Extract ', 'Create ', 'Down to ', 'Up to '):
        if name.startswith(verb):
            rest = name[len(verb):]
            base = re.sub(r'\s*\(.*\)\s*$', '', rest).strip()
            first = base.split(' ')[0]
            for cand in (base, first):
                if cand in types:
                    return cand
    return None


def selection_changers(lines):
    """procedure name -> whether its body can change the selection."""
    out, cur = {}, None
    for ln in lines:
        m = re.match(r'^procedure\s+([A-Za-z_][\w.]*)', ln.text)
        if m:
            cur = m.group(1)
            out[cur] = False
            continue
        if re.match(r'^endproc\b', ln.text):
            cur = None
            continue
        if cur is None:
            continue
        _t, body = statement(ln.text)
        if (body.startswith('@')
                or re.match(r'^(selectObject|plusObject|minusObject|removeObject)\b', body)
                or (re.match(r'[A-Z]', body) and not body.startswith(QUERY))):
            out[cur] = True
    return out


TEXT = 'text of '  # var_type key prefix for a string variable's literal value


def _walk(lines, types, owners, param_types, changers):
    """One pass of type tracking. Returns (rows, call sites), where a call
    site list holds, per procedure, the types of each call's arguments."""
    var_type = {}
    sel = []
    rows = []
    sites = defaultdict(list)
    chains = []
    outside = None
    in_editor = False
    count = [0]

    def anonymous(t):
        count[0] += 1
        key = f'<object {count[0]}>'
        var_type[key] = t
        return key

    def type_of(v):
        if v in var_type:
            return var_type[v]
        m = re.match(r'^"(\w+) ', v)
        return m.group(1) if m and m.group(1) in types else None

    def restore(vars_, selection):
        var_type.clear()
        var_type.update(vars_)
        sel[:] = selection

    for ln in lines:
        if ln.in_form:
            continue
        s = ln.text
        kw = re.match(r'^(if|elsif|elif|else|endif)\b', s)
        if kw:
            k = kw.group(1)
            if k == 'if':
                chains.append({'vars': dict(var_type), 'sel': list(sel),
                               'ends': [], 'else': False})
            elif chains:
                ch = chains[-1]
                ch['ends'].append((dict(var_type), list(sel)))
                if k == 'endif':
                    chains.pop()
                    if not ch['else']:
                        ch['ends'].append((ch['vars'], ch['sel']))
                    # A variable typed differently by two branches is untyped.
                    merged = {}
                    for key in set().union(*(d for d, _s in ch['ends'])):
                        vals = {d.get(key) for d, _s in ch['ends']}
                        merged[key] = vals.pop() if len(vals) == 1 else None
                    sels = [x for _d, x in ch['ends']]
                    restore(merged, sels[0] if all(x == sels[0] for x in sels) else [])
                else:
                    ch['else'] = ch['else'] or k == 'else'
                    restore(dict(ch['vars']), list(ch['sel']))
            continue
        if re.match(r'^editor\b', s):
            in_editor = True
            continue
        if re.match(r'^endeditor\b', s):
            in_editor = False
            continue
        proc = re.match(r'^procedure\s+([A-Za-z_][\w.]*)\s*(?::\s*(.*))?$', s)
        if proc:
            outside = list(sel)
            sel[:] = []
            params = [a.strip() for a in split_args(proc.group(2) or '')]
            for prm, t in zip(params, param_types.get(proc.group(1), [])):
                var_type[prm] = t
            continue
        if re.match(r'^endproc\b', s):
            if outside is not None:
                sel[:] = outside
                outside = None
            continue
        call = re.match(r'^@([A-Za-z_][\w.]*)\s*(?::\s*(.*))?$', s)
        if call:
            args = [a.strip() for a in split_args(call.group(2) or '')]
            sites[call.group(1)].append([type_of(a) for a in args])
            if changers.get(call.group(1), True):
                sel[:] = []
            continue
        target, body = statement(s)
        m = re.match(r'^(selectObject|plusObject|minusObject|removeObject)\s*:\s*(.*)$', body)
        if m:
            ids = [a.strip() for a in split_args(m.group(2))]
            if m.group(1) == 'selectObject':
                sel[:] = ids
            elif m.group(1) == 'plusObject':
                sel[:] = sel + ids
            else:
                sel[:] = [v for v in sel if v not in ids]
            continue
        if not re.match(r'[A-Z]', body):
            if target:
                # x = y copies y's type; x = selected ("Sound") is a Sound.
                b = body.strip()
                picked = re.match(r'^selected\s*\(\s*(?:"(\w+)")?', b)
                if target.endswith('$'):
                    # Kept so Read from file: path$ can use the extension.
                    lit = re.fullmatch(r'"([^"]*)"', b)
                    var_type[TEXT + target] = lit.group(1) if lit else None
                elif re.fullmatch(r'[.\w]+', b):
                    var_type[target] = type_of(b)
                elif picked and picked.group(1):
                    var_type[target] = picked.group(1) if picked.group(1) in types else None
                elif picked:
                    ts = {type_of(v) for v in sel}
                    var_type[target] = ts.pop() if len(ts) == 1 else None
                else:
                    var_type[target] = None
            continue
        name, colon, argtext = body.partition(':')
        name = name.strip()
        if '...' in name:
            continue  # old "Command... arguments" form; Old syntax reports it
        arity = len(split_args(argtext)) if colon else 0
        if in_editor:
            rows.append((ln.n, name, arity, [EDITOR], body))
            continue
        sel_types = sorted({type_of(v) for v in sel} - {None})
        if not sel_types and name in owners and len(sel) <= 1:
            # A command only one object type has tells the selection's type.
            t = owners[name]
            if sel:
                var_type[sel[0]] = t
            else:
                sel[:] = [anonymous(t)]
            sel_types = [t]
        rows.append((ln.n, name, arity, sel_types, body))
        if name.startswith(QUERY):
            continue
        if name == 'Read from file':
            first = split_args(argtext)[:1]
            if first and var_type.get(TEXT + first[0]) is not None:
                argtext = '"' + var_type[TEXT + first[0]] + '"'
        created = infer_type(name, argtext,
                             sel_types[0] if len(sel_types) == 1 else None, types)
        if target and not target.endswith('$'):
            var_type[target] = created
            sel[:] = [target]
        elif not target and (created or name in SAME_TYPE or name.startswith(CREATORS)):
            sel[:] = [anonymous(created)]
    return rows, sites


def command_rows(lines, types, owners=None):
    """(line, name, arity, selection types, body) for every command call.
    Repeats the pass so procedures defined above their calls get the types
    of the objects passed to them; a parameter passed different types at
    different call sites stays untyped."""
    owners = owners or {}
    changers = selection_changers(lines)
    param_types = {}
    for _pass in range(4):
        rows, sites = _walk(lines, types, owners, param_types, changers)
        found = {}
        for proc, calls_ in sites.items():
            width = max(len(c) for c in calls_)
            merged = []
            for i in range(width):
                vals = {c[i] if i < len(c) else None for c in calls_}
                merged.append(vals.pop() if len(vals) == 1 else None)
            found[proc] = merged
        if found == param_types:
            break
        param_types = found
    return rows


def where(e):
    """file:line of a reference entry, curated or catalogue."""
    return f'{e[2]}:{e[3]}'


def settle(arity, cur, cat, free):
    """Outcome for a call against the listings that apply to it: cur and
    cat for the selection's type, free for the type-free curated files."""
    hit = next((e for e in cur if e[1] == arity), None)
    if hit:
        return 'VERIFIED', where(hit)
    for entries in (cur, None, free):
        if entries is None:
            hit = next((e for e in cat if e[1] == arity), None)
            if hit:
                return 'CATALOGUE ONLY', where(hit)
            continue
        if not entries:
            continue
        if arity and all(e[1] == 0 for e in entries):
            return 'ARGS UNDOCUMENTED', (
                f'argument list not documented in {where(entries[0])}; '
                f'cite the Praat manual or Paste Commands')
        listed = ', '.join(sorted({f'{e[1]} in {where(e)}' for e in entries}))
        return 'ARITY MISMATCH', f'script passes {arity}; listed {listed}'
    if cat:
        listed = ', '.join(sorted({f'{e[1]} ({e[0]}, {e[2]}:{e[3]})' for e in cat}))
        return 'NO ARGUMENT LIST', f'script passes {arity}; catalogue lists {listed}'
    return 'NOT FOUND', ''


OUTCOME_LEVEL = [('BLOCKING', 'NOT FOUND'), ('BLOCKING', 'TYPE UNKNOWN'),
                 ('BLOCKING', 'NO ARGUMENT LIST'), ('BLOCKING', 'ARITY MISMATCH'),
                 ('BLOCKING', 'CATALOGUE ONLY'),
                 ('NOTE', 'TYPE UNKNOWN'), ('NOTE', 'ARGS UNDOCUMENTED')]


def check_commands(rows, curated, catalogue):
    """Findings for the command reference check, in outcome order."""
    groups = defaultdict(list)
    verified = []
    for n, name, arity, sel_types, body in rows:
        cur_all = curated.get(name, [])
        cat_all = catalogue.get(name, [])
        free = [e for e in cur_all if e[0] in TYPE_FREE]
        hit = next((e for e in free if e[1] == arity), None)
        if hit:
            verified.append(f'line {n}: {short(body)} -- {where(hit)} (any type)')
            continue
        want = set(sel_types)
        cur = [e for e in cur_all if e[0] in want and e[0] not in TYPE_FREE]
        cat = [e for e in cat_all if want and (
            e[0] in want or e[0] in TYPE_FREE or set(e[0].split(' & ')) == want)]
        if want and (cur or cat):
            scope = '+'.join(sel_types)
        else:
            scope = '+'.join(sel_types) + ' (no listing)' if want else 'any type'
            cur = [e for e in cur_all if e[0] not in TYPE_FREE]
            cat = cat_all
            arities = {e[1] for e in cur_all + cat_all}
            if len(arities) > 1:
                matches = {e[0] for e in cur_all + cat_all if e[1] == arity}
                lead = (f'no listing for {"+".join(sel_types)}' if want
                        else 'type not inferred')
                cur_matches = {e[0] for e in cur_all if e[1] == arity}
                if cur_matches:
                    groups[('NOTE', 'TYPE UNKNOWN')].append(
                        (n, body, f'{lead}; argument count matches {name_list(matches)}'))
                elif matches:
                    groups[('BLOCKING', 'CATALOGUE ONLY')].append(
                        (n, body, f'{lead}; argument count matches only catalogue '
                         f'entries for {name_list(matches)}'))
                else:
                    owners = {e[0] for e in cur_all + cat_all}
                    groups[('BLOCKING', 'TYPE UNKNOWN')].append(
                        (n, body, f'{lead}; script passes {arity}; listed on '
                         f'{name_list(owners)} with counts '
                         + ', '.join(str(a) for a in sorted(arities))))
                continue
        outcome, detail = settle(arity, cur, cat, free)
        if outcome == 'VERIFIED':
            verified.append(f'line {n}: {short(body)} -- {detail} ({scope})')
            continue
        level = 'NOTE' if outcome == 'ARGS UNDOCUMENTED' else 'BLOCKING'
        groups[(level, outcome)].append(
            (n, body, f'{detail} ({scope})' if detail else scope))
    findings = []
    for key in OUTCOME_LEVEL:
        for n, body, info in groups.get(key, []):
            findings.append((key[0], n, f'{key[1]}: {short(body)} -- {info}'))
    return findings, verified


# --------------------------------------------------------- plan coverage

def table_cells(line):
    s = line.strip()
    if not s.startswith('|'):
        return None
    s = s[1:]
    if s.endswith('|'):
        s = s[:-1]
    return [c.strip() for c in s.split('|')]


def plan_name(cell):
    return cell.strip().strip('`').strip().rstrip(':').strip()


def read_plan(path):
    """List of (plan line, command, source) from every table whose header
    has Command and Source columns."""
    with open(path, encoding='utf-8') as f:
        lines = f.read().split('\n')
    rows = []
    i = 0
    while i < len(lines):
        cells = table_cells(lines[i])
        heads = [c.strip('*').lower() for c in cells] if cells else []
        if 'command' in heads and 'source' in heads:
            ci, si = heads.index('command'), heads.index('source')
            i += 1
            while i < len(lines):
                row = table_cells(lines[i])
                if row is None:
                    break
                if not all(re.fullmatch(r':?-{2,}:?', c) for c in row if c):
                    cmd = plan_name(row[ci]) if ci < len(row) else ''
                    src = row[si].strip() if si < len(row) else ''
                    if cmd:
                        rows.append((i + 1, cmd, src))
                i += 1
            continue
        i += 1
    return rows


def check_checkpoint_files(script_path, plan_path):
    """The plan as sent must exist, predate the script, and still be covered
    by the current plan (CHECKPOINTS steps 1 and 2)."""
    if plan_path is None:
        return []
    if not plan_path.endswith('_plan.md'):
        return [('NOTE', 0, f'plan file is not named <name>_plan.md: {plan_path}')]
    with open(plan_path, encoding='utf-8', errors='replace') as f:
        head = f.read(4000)
    if re.search(r'^\s*Mode:\s*(DEBUGGING|modification)', head, re.M | re.I):
        return []  # DEBUGGING and modification requests have no sent plan
    sent = plan_path[:-len('_plan.md')] + '_plan_sent.md'
    if not os.path.isfile(sent):
        return [('BLOCKING', 0, f'missing {os.path.basename(sent)} (the plan as sent, never edited)')]
    findings = []
    if os.path.getmtime(sent) > os.path.getmtime(script_path):
        findings.append(('BLOCKING', 0, f'{os.path.basename(sent)} is newer than the script: the plan was not sent before the code'))
    sent_rows = {cmd for _l, cmd, _s in read_plan(sent)}
    now_rows = {cmd for _l, cmd, _s in read_plan(plan_path)}
    for cmd in sorted(sent_rows - now_rows):
        findings.append(('BLOCKING', 0, f'{cmd} was in the plan as sent but is missing from {os.path.basename(plan_path)}'))
    return findings


def check_plan(rows, plan_path):
    if plan_path is None:
        return [('BLOCKING', 0, 'plan not supplied')]
    plan = read_plan(plan_path)
    if not plan:
        return [('BLOCKING', 0, f'no table with Command and Source columns in {plan_path}')]
    findings = []
    planned = {cmd for _l, cmd, _s in plan}
    used = {}
    for n, name, *_rest in rows:
        used.setdefault(name, n)
    for name, n in sorted(used.items(), key=lambda kv: kv[1]):
        if name not in planned:
            findings.append(('BLOCKING', n, f'not in the command plan: {name}'))
    for pl, cmd, src in plan:
        if src == '':
            findings.append(('BLOCKING', 0, f'plan line {pl}: no Source for {cmd}'))
        # Rule 17's universal safe commands and dialog keywords are not
        # command calls the linter counts, so their rows are expected.
        if cmd not in used and 'rule 17' not in src.lower() and 'appendix_c' not in src.lower():
            findings.append(('NOTE', 0, f'plan line {pl}: {cmd} is never called'))
    return findings


NUMBER = re.compile(r"(?<![\w.$#'])(-?\d+(?:\.\d+)?)(?![\w.])")
# Numerals that are structure, not values: counts, unit conversions.
STRUCTURAL = {'0', '0.0', '1', '-1', '2', '12', '100'}
DIALOG_FIELDS = ('real', 'positive', 'integer', 'natural', 'word', 'sentence',
                 'text', 'boolean', 'optionmenu', 'choice', 'option', 'comment',
                 'infile', 'outfile', 'folder')
CONSTANT_DEF = re.compile(r'^[A-Za-z_]\w*\$?\s*=\s*(-?\d+(?:\.\d+)?)\s*$')


def blank_precision(code):
    """Blank the digits argument of fixed$ (value, digits): formatting, not a value."""
    out = list(code)
    for m in re.finditer(r'fixed\$\s*\(', code):
        depth, i = 1, m.end()
        comma = None
        while i < len(code) and depth:
            c = code[i]
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
            elif c == ',' and depth == 1:
                comma = i
            i += 1
        if comma is not None:
            for j in range(comma + 1, i - 1):
                out[j] = ' '
    return ''.join(out)


def task_numbers(plan_path):
    """Numbers quoted under "Task as given" in the plan (the user's words)."""
    if plan_path is None:
        return set()
    with open(plan_path, encoding='utf-8') as f:
        lines = f.read().split('\n')
    start = next((i for i, s in enumerate(lines) if TASK_HEADING.match(s.strip())), None)
    if start is None:
        return set()
    nums = set()
    for s in lines[start + 1:]:
        if s.lstrip().startswith('#') or table_cells(s) is not None:
            break
        if s.lstrip().startswith('>'):
            nums |= {n for n in NUMBER.findall(s) if n not in STRUCTURAL}
    return nums


def check_hardcoded(lines, plan_path):
    """Notes: numbers outside the constants block, and constants whose value
    the user supplied (Rules 26 and 35). Copied library procedures and the
    version-check block are exempt."""
    findings = []
    user_nums = task_numbers(plan_path)
    in_lib = False
    for ln in lines:
        text = ln.text.strip()
        if re.match(r'^procedure\s+emlPG', text):
            in_lib = True
        if in_lib:
            if text.startswith('endproc'):
                in_lib = False
            continue
        code = ln.code
        if 'vc_' in code or ln.in_form:
            continue
        head = code.lstrip().split(':', 1)[0].strip()
        if head in DIALOG_FIELDS:
            continue
        m = CONSTANT_DEF.match(code.strip())
        if m:
            if m.group(1) in user_nums:
                findings.append(('NOTE', ln.n, f'{short(text)} -- {m.group(1)} also appears in the '
                                 "user's words; if the user supplied it, it belongs in a dialog field (Rule 26)"))
            continue
        scan = re.sub(r'\[[^\]]*\]', lambda s: ' ' * len(s.group(0)), blank_precision(code))
        for n in NUMBER.findall(scan):
            if n not in STRUCTURAL:
                findings.append(('NOTE', ln.n, f'bare number {n} -- {short(text)}'))
    return findings


TASK_HEADING = re.compile(r'^#{1,6}\s*Task as given\s*$', re.I)


def check_task_coverage(plan_path):
    """The plan quotes the task under "Task as given" and maps each requested
    item in a Requested | Produced by table. Returns (findings, summary)."""
    if plan_path is None:
        return [], ''
    with open(plan_path, encoding='utf-8') as f:
        lines = f.read().split('\n')
    findings = []
    start = next((i for i, s in enumerate(lines) if TASK_HEADING.match(s.strip())), None)
    if start is None:
        findings.append(('BLOCKING', 0, 'the plan has no "Task as given" section quoting the task'))
    else:
        body = []
        for s in lines[start + 1:]:
            if s.lstrip().startswith('#') or table_cells(s) is not None:
                break
            if s.strip():
                body.append(s)
        if not body:
            findings.append(('BLOCKING', 0,
                             f'plan line {start + 1}: "Task as given" quotes nothing'))
    rows, dropped, found = 0, 0, False
    i = 0
    while i < len(lines):
        cells = table_cells(lines[i])
        heads = [c.strip('*').lower() for c in cells] if cells else []
        if 'requested' in heads and 'produced by' in heads:
            found = True
            ri, pi = heads.index('requested'), heads.index('produced by')
            i += 1
            while i < len(lines):
                row = table_cells(lines[i])
                if row is None:
                    break
                if not all(re.fullmatch(r':?-{2,}:?', c) for c in row if c):
                    req = row[ri].strip() if ri < len(row) else ''
                    prod = row[pi].strip() if pi < len(row) else ''
                    if req:
                        rows += 1
                        if not prod:
                            findings.append(('BLOCKING', 0, f'plan line {i + 1}: nothing produces {short(req)}'))
                        elif prod.lower().startswith('dropped'):
                            dropped += 1
                            if len(prod.split(':', 1)[-1].strip()) < 3 or ':' not in prod:
                                findings.append(('BLOCKING', 0, f'plan line {i + 1}: {short(req)} dropped without '
                                                 "the user's words agreeing"))
                i += 1
            continue
        i += 1
    if not found:
        findings.append(('BLOCKING', 0, 'the plan has no table with Requested and Produced by columns'))
    elif rows == 0:
        findings.append(('BLOCKING', 0, 'the Requested | Produced by table has no rows'))
    summary = f'{rows} requested items mapped, {dropped} dropped' if found else ''
    return findings, summary


# ------------------------------------------------------- script checks

def form_variable(label):
    """Praat's variable name for a form field label."""
    label = re.split(r'[(:]', label)[0].strip()
    if not label:
        return None
    return (label[0].lower() + label[1:]).replace(' ', '_')


def check_form_defaults(lines):
    findings = []
    for ln in lines:
        if not ln.in_form:
            continue
        m = re.match(r'^(' + '|'.join(NUMERIC_FIELDS) + r')(:\s*|\s+)(.*)$', ln.text)
        if not m:
            continue
        kind, sep, rest = m.groups()
        if ':' in sep:
            args = split_args(rest)
            if len(args) < 2:
                continue
            default = args[1]
            if not (default.startswith('"') and default.endswith('"')):
                findings.append(('BLOCKING', ln.n,
                                 f'{kind}: default {default} is not quoted -- {short(ln.text)}'))
        else:
            parts = rest.split(None, 1)
            default = parts[1].strip() if len(parts) > 1 else ''
            if default and not default.startswith('"'):
                findings.append(('BLOCKING', ln.n,
                                 f'old {kind} field, default {default} is not quoted -- '
                                 f'{short(ln.text)}'))
    return findings


def writes_file(body):
    if re.match(r'^(' + '|'.join(FILE_WRITERS) + r')\s*:', body):
        return True
    return bool(re.match(r'^(Save as\b|Write to .*\bfile\b)', body))


def check_non_ascii(lines):
    findings = []
    for ln in lines:
        _t, body = statement(ln.text)
        level = 'BLOCKING' if writes_file(body) else 'NOTE'
        for start, lit in ln.strings:
            bad = sorted({c for c in lit if ord(c) > 127})
            if bad:
                off = start + 1 + lit.index(bad[0])
                chars = ' '.join(f'U+{ord(c):04X}' for c in bad)
                where_ = 'in a line that writes a file' if level == 'BLOCKING' \
                    else 'in a string (check it does not reach a file)'
                findings.append((level, ln.line_at(off),
                                 f'{chars} {where_} -- {short(lit)}'))
    return findings


def include_target(ln):
    m = re.match(r'^include\s+(.+)$', ln.text)
    return m.group(1).strip() if m else None


def check_includes(lines):
    findings = []
    for ln in lines:
        path = include_target(ln)
        if path is None:
            continue
        p = path.replace('\\', '/')
        absolute = p.startswith(('/', '~')) or re.match(r'^[A-Za-z]:', p)
        parent = p.rsplit('/', 1)[0] if '/' in p else ''
        if absolute or not parent.split('/')[-1].endswith('_lib'):
            findings.append(('BLOCKING', ln.n,
                             f'include outside a relative *_lib folder: {path}'))
    return findings


def procedures(lines):
    out = {}
    for ln in lines:
        m = re.match(r'^procedure\s+([A-Za-z_][\w.]*)', ln.text)
        if m:
            out.setdefault(m.group(1), ln.n)
    return out


def calls(ln):
    return [(m.group(1), m.start()) for m in
            re.finditer(r'@([A-Za-z_][\w.]*?)(?=[\s:(]|$)', ln.code)]


def check_prefix(lines):
    findings = []
    for ln in lines:
        for name, off in calls(ln):
            if re.match(r'eml[A-Z]', name) and not name.startswith(LIB_PREFIX):
                findings.append(('BLOCKING', ln.line_at(off),
                                 f'@{name} -- library procedures are copied as {LIB_PREFIX}<Name>'))
    for name, n in procedures(lines).items():
        if re.match(r'eml[A-Z]', name) and not name.startswith(LIB_PREFIX):
            findings.append(('BLOCKING', n,
                             f'procedure {name} -- library procedures are copied as {LIB_PREFIX}<Name>'))
    return sorted(findings, key=lambda f: f[1])


LIBRARY_FILE = re.compile(r'^eml-[\w-]+\.txt$')
PROC_DEF = re.compile(r'^procedure\s+([A-Za-z_]\w*)')


def load_procedures(pkb):
    """name -> [file, header comment, body] for every procedure in the PKB
    copies of the EML library (eml-*.txt). The body runs from the procedure
    line to its endproc, trailing spaces removed; the header is the block of
    comment lines directly above the procedure line."""
    out = {}
    for fn in sorted(os.listdir(pkb)):
        if not LIBRARY_FILE.match(fn):
            continue
        with open(os.path.join(pkb, fn), encoding='utf-8') as f:
            raw = [s.rstrip() for s in f.read().split('\n')]
        i = 0
        while i < len(raw):
            m = PROC_DEF.match(raw[i])
            if not m:
                i += 1
                continue
            j = i
            while j < len(raw) and not raw[j].startswith('endproc'):
                j += 1
            k = i
            while k > 0 and raw[k - 1].startswith('#'):
                k -= 1
            out.setdefault(m.group(1), [fn, '\n'.join(raw[k:i]),
                                        '\n'.join(raw[i:j + 1])])
            i = j + 1
    return out


LIB_NAME = re.compile(r'(@|^procedure\s+)(eml\w+)', re.M)
PG_NAME = re.compile(r'(@|^procedure\s+)emlPG(?=\w)', re.M)


def to_pg(text, names):
    """Rename library procedures to the emlPG prefix, at definitions and calls."""
    return LIB_NAME.sub(lambda m: m.group(1) + LIB_PREFIX + m.group(2)[3:]
                        if m.group(2) in names else m.group(0), text)


def from_pg(text):
    """Undo to_pg. The library has no emlPG names, so this is its exact inverse."""
    return PG_NAME.sub(r'\1eml', text)


def with_callees(names, procs):
    """The requested procedures, then every library procedure they call, in turn."""
    order, queue = [], list(names)
    while queue:
        n = queue.pop(0)
        if n in order or n not in procs:
            continue
        order.append(n)
        queue += [c for c in re.findall(r'@(eml\w+)', procs[n][2]) if c != n]
    return order


def extract(names, procs):
    """Praat text for the procedures, renamed to emlPG, with their callees.
    Returns (text, unknown names)."""
    wanted, unknown = [], []
    for n in names:
        n = n.lstrip('@').rstrip(':')
        if n.startswith(LIB_PREFIX):
            n = 'eml' + n[len(LIB_PREFIX):]
        (wanted if n in procs else unknown).append(n)
    order = with_callees(wanted, procs)
    added = [n for n in order if n not in wanted]
    out = [f'# EML library procedures: {", ".join(wanted) or "none"}'
           + (f'; called by them: {", ".join(added)}' if added else '')]
    for n in order:
        fn, header, body = procs[n]
        out.append('')
        out.append(f'# --- {LIB_PREFIX}{n[3:]}, copied verbatim from {fn} ---')
        if header:
            out.append(to_pg(header, procs))
        out.append(to_pg(body, procs))
    return '\n'.join(out) + '\n', unknown


def script_copies(path, seen=None):
    """(file, line number, name, body) for every emlPG procedure in the script
    and in the *_lib files it includes that exist on disk."""
    seen = set() if seen is None else seen
    path = os.path.normpath(path)
    if path in seen or not os.path.isfile(path):
        return []
    seen.add(path)
    with open(path, encoding='utf-8') as f:
        raw = [s.rstrip() for s in f.read().split('\n')]
    out = []
    for i, s in enumerate(raw):
        m = PROC_DEF.match(s.strip())
        if m and m.group(1).startswith(LIB_PREFIX):
            j = i
            while j < len(raw) and not raw[j].strip().startswith('endproc'):
                j += 1
            out.append((path, i + 1, m.group(1), raw[i:j + 1]))
    for ln in read_lines(path):
        target = include_target(ln)
        if target:
            out += script_copies(os.path.join(os.path.dirname(path), target), seen)
    return out


def check_library_copies(script_path, procs):
    """Every emlPG procedure matches its library source, apart from the prefix.
    Returns (findings, verified names)."""
    findings, verified = [], []
    top = os.path.normpath(script_path)
    for path, n, name, body in script_copies(script_path):
        where_ = '' if path == top else f'{os.path.basename(path)} '
        orig = 'eml' + name[len(LIB_PREFIX):]
        if orig not in procs:
            findings.append(('BLOCKING', 0 if where_ else n,
                             f'{where_}{"line " + str(n) + ": " if where_ else ""}'
                             f'procedure {name}: the EML library has no {orig}; '
                             f'the {LIB_PREFIX} prefix is only for library copies'))
            continue
        lib = procs[orig][2].split('\n')
        got = from_pg('\n'.join(body)).split('\n')
        if got == lib:
            verified.append(name)
            continue
        k = next((i for i, (a, b) in enumerate(zip(got, lib)) if a != b),
                 min(len(got), len(lib)))
        expected = lib[k].strip() if k < len(lib) else '(the procedure ends here)'
        findings.append(('BLOCKING', 0 if where_ else n + k,
                         f'{where_}{"line " + str(n + k) + ": " if where_ else ""}'
                         f'{name} differs from {orig} in {procs[orig][0]} '
                         f'at its line {k + 1}; the source has: {short(expected)}'))
    return findings, verified


def lib_procedures(lines, script_dir, seen=None):
    """Procedures defined in included *_lib files that exist on disk."""
    seen = set() if seen is None else seen
    out = {}
    for ln in lines:
        path = include_target(ln)
        if path is None:
            continue
        full = os.path.normpath(os.path.join(script_dir, path))
        if full in seen or not os.path.isfile(full):
            continue
        seen.add(full)
        inc = read_lines(full)
        out.update(procedures(inc))
        out.update(lib_procedures(inc, os.path.dirname(full), seen))
    return out


def check_calls(lines, script_dir):
    defined = set(procedures(lines)) | set(lib_procedures(lines, script_dir))
    findings = []
    for ln in lines:
        for name, off in calls(ln):
            if name not in defined:
                findings.append(('BLOCKING', ln.line_at(off),
                                 f'@{name} has no procedure definition'))
    return findings


def check_reserved(lines):
    findings = []
    names = '|'.join(RESERVED)
    assign = re.compile(r'^(' + names + r')\s*[-+*/]?=(?!=)')
    loop = re.compile(r'^for\s+(' + names + r')\s+(?:from|to)\b')
    proc = re.compile(r'^procedure\s+[\w.]+\s*:\s*(.*)$')
    for ln in lines:
        if ln.in_form:
            continue
        m = assign.match(ln.text)
        if m:
            findings.append(('BLOCKING', ln.n,
                             f'assignment to reserved name {m.group(1)} -- {short(ln.text)}'))
        m = loop.match(ln.text)
        if m:
            findings.append(('BLOCKING', ln.n,
                             f'loop variable named {m.group(1)} -- {short(ln.text)}'))
        m = proc.match(ln.text)
        if m:
            for prm in split_args(m.group(1)):
                if prm.strip() in RESERVED:
                    findings.append(('BLOCKING', ln.n,
                                     f'procedure parameter named {prm.strip()} -- '
                                     f'{short(ln.text)}'))
    return findings


def known_variables(lines):
    names = set()
    for ln in lines:
        if ln.in_form:
            m = re.match(r'^\w+:\s*(.*)$', ln.text)
            if m:
                args = split_args(m.group(1))
                if args and args[0].startswith('"'):
                    v = form_variable(args[0].strip('"'))
                    if v:
                        names.update({v, v + '$'})
            continue
        target, _b = statement(ln.text)
        if target:
            names.add(target)
        m = re.match(r'^for\s+([.\w]+)', ln.text)
        if m:
            names.add(m.group(1))
        m = re.match(r'^procedure\s+[\w.]+:\s*(.*)$', ln.text)
        if m:
            names.update(a.strip() for a in split_args(m.group(1)))
    return names


INTERP = re.compile(r"'([A-Za-z_.][\w.]*[$#]?)(?::\d+)?'")
# Outside strings, interpolation glued to a name builds a variable name
# (.cell'.i'_'.j'); only a free-standing 'var' is the old command syntax.
INTERP_FREE = re.compile(r"(?<![\w.'])" + INTERP.pattern + r"(?![\w.'])")
OLD_KEYWORD = re.compile(r'^(' + '|'.join(OLD_KEYWORDS) + r') ')
# The old command form: To Pitch... 0 75 600
DOT_FORM = re.compile(r'^[A-Z][^:"]*?\.\.\.(?:\s|$)')


def check_old_syntax(lines):
    findings = []
    known = known_variables(lines)
    for ln in lines:
        if ln.in_form:
            continue
        code = ln.code
        for m in re.finditer(r'(?<![\w.$#])do\$?\s*\(', code):
            findings.append(('BLOCKING', ln.line_at(m.start()),
                             f'old do ( ... ) call -- {short(ln.text)}'))
        if re.match(r'^call\s+\S', ln.text):
            findings.append(('BLOCKING', ln.n, f'old call keyword -- {short(ln.text)}'))
        m = OLD_KEYWORD.match(ln.text)
        if m and not is_assignment(ln.text):
            findings.append(('BLOCKING', ln.n,
                             f'old {m.group(1)} keyword -- {short(ln.text)}'))
        _t, body = statement(code)
        if DOT_FORM.match(body):
            findings.append(('BLOCKING', ln.n,
                             f'old "Command... arguments" form -- {short(ln.text)}'))
        hits = [m for m in INTERP_FREE.finditer(code)]
        for start, lit in ln.strings:
            hits += [m for m in INTERP.finditer(lit) if m.group(1) in known]
        if hits:
            findings.append(('BLOCKING', ln.n,
                             f"'{hits[0].group(1)}' interpolation -- {short(ln.text)}"))
    return findings


def check_pause(lines):
    findings = []
    for ln in lines:
        _t, body = statement(ln.text)
        m = re.match(r'^endPause:\s*(.*)$', body)
        if not m:
            continue
        args = split_args(m.group(1))
        # Button labels come first; the numbers after them are the default
        # button and then the cancel button. 0 as the cancel index hides
        # Praat's Stop button (APPENDIX_F S0A).
        numbers = []
        for a in reversed(args):
            if a.startswith('"') or re.search(r'\$\s*(\[.*\])?$', a):
                break
            numbers.append(a)
        if len(numbers) < 2:
            findings.append(('NOTE', ln.n, f'endPause: has no cancel index; '
                             f'end it with 0 -- {short(ln.text)}'))
        elif args[-1] != '0':
            findings.append(('NOTE', ln.n, f'endPause: cancel index is {args[-1]}; '
                             f'end it with 0 -- {short(ln.text)}'))
    return findings


def check_paths(lines):
    findings = []
    for ln in lines:
        for start, lit in ln.strings:
            if ABS_PATH.search(lit) or ABS_PATH_START.match(lit):
                findings.append(('BLOCKING', ln.line_at(start),
                                 f'absolute path in a string: "{short(lit)}"'))
    return findings


def check_overwrite(lines):
    writer = None
    guarded = False
    for ln in lines:
        _t, body = statement(ln.text)
        if writer is None and writes_file(body):
            writer = ln.n
        if re.search(r'\bfileReadable\s*\(', ln.code):
            guarded = True
        if any('UniquePath' in name for name, _o in calls(ln)):
            guarded = True
    if writer is not None and not guarded:
        return [('NOTE', writer, 'writes files with no fileReadable check and no '
                 '*UniquePath* procedure call')]
    return []


# A command inside a function call: round (Get mean: ...), abs (Is ...).
NESTED_CALL = re.compile(r'\b[a-z]\w*[$#]?\s*\(\s*('
                         r'[A-Z][\w\-]*(?: [\w\-()]+)*?\s*:'
                         r'|(?:' + '|'.join(QUERY_WORDS) + r') [a-z]\w*)')
# A query command anywhere in the code. Variable names start in lower case,
# so a capitalized query word outside a string is a command.
QUERY_ANYWHERE = re.compile(r"(?<![\w.$#@'])(?:" + '|'.join(QUERY_WORDS)
                            + r') [a-z(]')


def body_offset(code):
    """Offset where the statement body starts: after an assignment target
    and the noprogress/nocheck/nowarn/demo prefixes."""
    m = ASSIGN.match(code)
    off = m.end() if m else 0
    again = True
    while again:
        again = False
        for p in PREFIXES + ('demo ',):
            if code.startswith(p, off):
                off += len(p)
                again = True
    return off


def check_nested(lines):
    findings = []
    for ln in lines:
        if ln.in_form:
            continue
        code = ln.code
        start = body_offset(code)
        # On a command line, the command's own name may carry a qualifier in
        # parentheses ("Report correlation (Pearson r):"); only text after
        # the name's colon can hold a nested call.
        name_end = start
        if code[start:start + 1].isupper():
            colon = code.find(':', start)
            name_end = colon if colon != -1 else len(code)
        offsets = [m.start(1) for m in NESTED_CALL.finditer(code) if m.start(1) >= name_end]
        offsets += [m.start() for m in QUERY_ANYWHERE.finditer(code) if m.start() != start]
        if offsets:
            findings.append(('BLOCKING', ln.line_at(min(offsets)),
                             f'query command inside an expression -- {short(ln.text)}'))
    return findings


def check_read_tokens(plan_path, hashes):
    """The plan's "RULES_NAME.md: token" lines name real pairings.
    Returns (findings, verified "name token" strings)."""
    if plan_path is None:
        return [], []
    with open(plan_path, encoding='utf-8', errors='replace') as f:
        text = f.read()
    findings, verified, seen = [], [], set()
    for name, token in TOKEN_LINE.findall(text):
        if (name, token) in seen:
            continue
        seen.add((name, token))
        if name not in hashes:
            findings.append(('BLOCKING', 0, f'{name} is not a RULES file in the reference set'))
        elif token_hash(name, token) != hashes[name]:
            findings.append(('BLOCKING', 0, f'{token} is not the read token of {name}'))
        else:
            verified.append(f'{name} {token}')
    if not seen:
        findings.append(('BLOCKING', 0, 'the plan lists no read tokens: add one line '
                         '"RULES_NAME.md: token" for each RULES file read in full'))
    elif not any(v.startswith('RULES_CODE.md ') for v in verified):
        findings.append(('BLOCKING', 0, 'RULES_CODE.md has no verified read token in the plan'))
    return findings, verified


# Words that can stand before "(" in a script without being a function call.
NOT_FUNCTIONS = {'if', 'elsif', 'elif', 'while', 'until', 'for', 'from', 'to',
                 'and', 'or', 'not', 'then', 'else', 'repeat', 'return',
                 'mod', 'div'}


def check_functions(lines, functions):
    """Every function call must be spelled as APPENDIX_B_FUNCTIONS.txt spells it.
    Returns (findings, verified names)."""
    findings, verified = [], {}
    for ln in lines:
        if ln.in_form:
            continue
        code = ln.code
        start = body_offset(code)
        # A command's own name can hold words in parentheses ("Get jitter
        # (local):"); function calls can only follow the name's colon.
        name_end = start
        if code[start:start + 1].isupper():
            colon = code.find(':', start)
            name_end = colon if colon != -1 else len(code)
        for m in FUNCTION_NAME.finditer(code):
            if m.start(1) < name_end and m.start(1) >= start:
                continue
            name = m.group(1)
            if name in NOT_FUNCTIONS:
                continue
            if name in functions:
                verified.setdefault(name, functions[name])
            else:
                findings.append(('BLOCKING', ln.line_at(m.start(1)),
                                 f'{name} is not in {FUNCTIONS_FILE} -- {short(ln.text)}'))
    return findings, verified


# ---------------------------------------------------------------- main

def usage():
    print(__doc__)
    sys.exit(2)


def tally(checks):
    """One line: count per severity, with the checks that contributed."""
    parts = []
    for level in ('BLOCKING', 'NOTE'):
        per = [(title, sum(1 for f in fs if f[0] == level)) for title, fs in checks]
        per = [(t, c) for t, c in per if c]
        total = sum(c for _t, c in per)
        detail = ' (' + ', '.join(f'{t} {c}' for t, c in per) + ')' if per else ''
        parts.append(f'{total} {level}{detail}')
    return 'Tally: ' + '; '.join(parts)


def library_procedures():
    """The library index: embedded in the PKB copy, else the pkb folder beside."""
    if EMBEDDED_INDEX is not None:
        return {k: list(v) for k, v in EMBEDDED_INDEX['procedures'].items()}
    beside = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir, 'pkb')
    return load_procedures(os.path.normpath(beside)) if os.path.isdir(beside) else {}


def main_procedure(names):
    procs = library_procedures()
    if not names:
        usage()
    text, unknown = extract(names, procs)
    for n in unknown:
        print(f'# NOT IN THE EML LIBRARY: {n}')
    sys.stdout.write(text)
    sys.exit(1 if unknown else 0)


def main():
    args = sys.argv[1:]
    if args[:1] == ['--procedure']:
        main_procedure(args[1:])
    if not 1 <= len(args) <= 3:
        usage()
    script, plan, pkb = args[0], None, None
    for a in args[1:]:
        if os.path.isdir(a):
            pkb = a
        elif os.path.isfile(a):
            plan = a
        else:
            print(f'Not a file or folder: {a}')
            sys.exit(2)
    beside = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir, 'pkb')
    if pkb is None and EMBEDDED_INDEX is None and os.path.isdir(beside):
        pkb = os.path.normpath(beside)
    if pkb is not None:
        curated = load_curated(pkb)
        catalogue = load_catalogue(pkb)
        functions = load_functions(pkb)
        token_hashes = load_token_hashes(pkb)
        procs = load_procedures(pkb)
    elif EMBEDDED_INDEX is not None:
        curated = {k: [tuple(e) for e in v]
                   for k, v in EMBEDDED_INDEX['curated'].items()}
        catalogue = {k: [tuple(e) for e in v]
                     for k, v in EMBEDDED_INDEX['catalogue'].items()}
        functions = dict(EMBEDDED_INDEX['functions'])
        token_hashes = dict(EMBEDDED_INDEX['tokens'])
        procs = library_procedures()
    else:
        print('No reference folder given, no embedded index and no pkb folder '
              'beside this file.')
        sys.exit(2)
    types = {t for v in curated.values() for (t, *_r) in v}
    types |= {t for v in catalogue.values() for (t, *_r) in v}

    lines = read_lines(script)
    rows = command_rows(lines, types, sole_owners(curated, catalogue))
    cmd_findings, verified = check_commands(rows, curated, catalogue)
    fn_findings, fn_verified = check_functions(lines, functions)
    tok_findings, tok_verified = check_read_tokens(plan, token_hashes)
    lib_findings, lib_verified = check_library_copies(script, procs)
    task_findings, task_summary = check_task_coverage(plan)
    checks = [
        ('Command references', cmd_findings),
        ('Plan coverage', check_plan(rows, plan)),
        ('Task coverage', task_findings),
        ('Checkpoint files', check_checkpoint_files(script, plan)),
        ('Form numeric defaults', check_form_defaults(lines)),
        ('Non-ASCII text', check_non_ascii(lines)),
        ('Plugin includes', check_includes(lines)),
        ('Library procedure prefix', check_prefix(lines)),
        ('Procedure calls resolve', check_calls(lines, os.path.dirname(os.path.abspath(script)))),
        ('Library copies', lib_findings),
        ('Reserved names', check_reserved(lines)),
        ('Old syntax', check_old_syntax(lines)),
        ('Pause dialogs', check_pause(lines)),
        ('Hardcoded paths', check_paths(lines)),
        ('Hardcoded values', check_hardcoded(lines, plan)),
        ('Overwrite guard', check_overwrite(lines)),
        ('Nested queries', check_nested(lines)),
        ('Functions', fn_findings),
        ('Read tokens', tok_findings),
    ]
    blocking = sum(1 for _c, fs in checks for f in fs if f[0] == 'BLOCKING')
    notes = sum(1 for _c, fs in checks for f in fs if f[0] == 'NOTE')
    print(f'PraatGen lint: {script}: {blocking} BLOCKING, {notes} NOTE, '
          f'{len(rows)} command calls ({len(verified)} verified)')
    for title, fs in checks:
        if not fs and not (title == 'Command references' and verified):
            print(f'{title}: none')
            continue
        nb = sum(1 for f in fs if f[0] == 'BLOCKING')
        print(f'{title}: {nb} BLOCKING, {len(fs) - nb} NOTE')
        for level, n, msg in fs:
            at = f'line {n}: ' if n else ''
            print(f'  {level} {at}{msg}')
        if title == 'Command references':
            for v in verified:
                print(f'  VERIFIED {v}')
    if fn_verified:
        print(f'Functions verified in {FUNCTIONS_FILE}: '
              + ', '.join(sorted(fn_verified)))
    if tok_verified:
        print('Read tokens verified: ' + '; '.join(sorted(tok_verified)))
    if task_summary:
        print('Task coverage in the plan: ' + task_summary)
    if lib_verified:
        print('Library copies verified against the EML library: '
              + ', '.join(sorted(lib_verified)))
    print(tally(checks))
    sys.exit(1 if blocking else 0)


EMBEDDED_INDEX = None  # replaced in the PKB copy by tools/build_lint.py

if __name__ == '__main__':
    main()
