#!/usr/bin/env python3
"""Regenerate pkb/EML_PROCEDURE_REGISTRY.md from the EML library sources.

Usage (from work/):
    python3 tools/build_procedure_registry.py                  # read pkb/eml-*.txt
    python3 tools/build_procedure_registry.py --src PLUGIN_DIR # read a plugin tree
    python3 tools/build_procedure_registry.py --check          # exit 1 if the file is stale

PLUGIN_DIR is the folder that holds stats/, graphs/ and scripts/ (for example
.../EMLPraatTools-main/plugin_EML_StatsGraphs). The egg and vibrato libraries
have no plugin-tree source here, so they are always read from pkb/.

Every row is derived from the source: the name and parameter list come from the
`procedure` line (continuation lines joined), the purpose from the header
comment block directly above it, the scope from the name (`eml_` prefix =
internal, `eml` prefix = public), the version from the file's `# Version:` line.
The section table SECTIONS below is the only hand-kept data: it fixes the order,
the title and the plugin-tree path of each file. Adding a library file means
adding one row there.
"""
import argparse
import datetime
import os
import re
import sys

WORK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKB = os.path.join(WORK, "pkb")
OUT = os.path.join(PKB, "EML_PROCEDURE_REGISTRY.md")

# (pkb stem, section title, plugin-tree path, subdir in a plugin checkout or None)
SECTIONS = [
    ("eml-core-descriptive", "Stats: Descriptive", "stats/eml-core-descriptive.praat", "stats"),
    ("eml-core-utilities", "Stats: Utilities", "stats/eml-core-utilities.praat", "stats"),
    ("eml-extract", "Stats: Extraction", "stats/eml-extract.praat", "stats"),
    ("eml-output", "Stats: Output", "stats/eml-output.praat", "stats"),
    ("eml-studentized-range", "Stats: Studentized Range", "stats/eml-studentized-range.praat", "stats"),
    ("eml-anova-kernel", "Stats: Two-Way ANOVA Kernel", "stats/eml-anova-kernel.praat", "stats"),
    ("eml-wilcoxon-interval", "Stats: Wilcoxon Intervals", "stats/eml-wilcoxon-interval.praat", "stats"),
    ("eml-inferential", "Stats: Inferential", "stats/eml-inferential.praat", "stats"),
    ("eml-psychometrics", "Stats: Psychometrics", "stats/eml-psychometrics.praat", "stats"),
    ("eml-categorical", "Stats: Categorical", "stats/eml-categorical.praat", "stats"),
    ("eml-result-writer", "Stats: Result Writer", "stats/eml-result-writer.praat", "stats"),
    ("eml-record", "Stats: Script Recorder", "stats/eml-record.praat", "stats"),
    ("eml-report", "Stats: Shared Reporters", "stats/eml-report.praat", "stats"),
    ("eml-analysis", "Stats: Analysis Dispatchers", "stats/eml-analysis.praat", "stats"),
    ("eml-graph-procedures", "Graphs: Core", "graphs/eml-graph-procedures.praat", "graphs"),
    ("eml-draw-procedures", "Graphs: Draw", "graphs/eml-draw-procedures.praat", "graphs"),
    ("eml-annotation-procedures", "Graphs: Annotation & Bridges", "graphs/eml-annotation-procedures.praat", "graphs"),
    ("eml-graphs", "Scripts: Graphs Main", "scripts/eml-graphs.praat", "scripts"),
    ("eml-graphs-form", "Scripts: Graphs Form & Workflow", "graphs/eml-graphs-form.praat", "graphs"),
    ("eml-batch-process", "Scripts: Batch Processing", "scripts/eml-batch-process.praat", "scripts"),
    ("eml-vibrato-procedures", "Vibrato", "vibrato/eml-vibrato-procedures.praat", None),
    ("eml-egg-procedures", "EGG: Electroglottogram", "egg/eml-egg-procedures.praat", None),
]

# Procedures left out of the registry (not in the PKB by author ruling).
EXCLUDE_NAMES = {"emlDrawLMMForest"}
EXCLUDE_PREFIXES = ("emlTest",)

# Prose that follows a section's table.
SECTION_NOTES = {
    "eml-output": (
        "All `@emlWizardExplain*` helpers set `emlWizardExplain$`, consumed by the "
        "next `@emlReportLine` / `@emlReportLineString` call. They are no-ops when "
        "`emlWizardMode = 0` (callers gate on the flag). They live in "
        "`eml-output.praat`, a **core** file — they are not part of the excluded "
        "wizard script."
    ),
}

PROC_RE = re.compile(r"^procedure\s+([A-Za-z_]\w*)\s*:?\s*(.*)$")
LABEL_RE = re.compile(
    r"^(Input|Inputs|Output|Outputs|Arguments|Argument|Args|Parameters|Returns|"
    r"Precondition|Preconditions|Notes?|Calls|Dependencies|Usage|Example|Provenance|Access pattern):?",
    re.I)


def read_lines(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read().split("\n")


def file_version(lines):
    for ln in lines[:120]:
        m = re.match(r"^#\s*Version:\s*([0-9][\w.]*)", ln)
        if m:
            return m.group(1)
    return "?"


def join_params(lines, i, rest):
    """Parameter text of the procedure line at i, with `...` continuations joined."""
    text = re.sub(r"\s+#.*$", "", rest).strip()
    j = i + 1
    while text.endswith("...") or (j < len(lines) and lines[j].lstrip().startswith("...")):
        if j >= len(lines) or not lines[j].lstrip().startswith("..."):
            break
        text = text.rstrip(".").rstrip() if text.endswith("...") else text
        text += " " + re.sub(r"\s+#.*$", "", lines[j].lstrip()[3:]).strip()
        j += 1
    text = text.replace("...", "").strip()
    return ", ".join(p.strip() for p in text.split(",") if p.strip())


def header_block(lines, i):
    """Contiguous comment lines directly above line i (text only, in order)."""
    j = i - 1
    while j >= 0 and not lines[j].strip():
        j -= 1
    out = []
    while j >= 0 and lines[j].lstrip().startswith("#"):
        out.append(lines[j].lstrip()[1:].strip())
        j -= 1
    return list(reversed(out))


def is_rule(s):
    return bool(s) and set(s) <= set("-=─ ")


SIG_RE = re.compile(r"^(?:[:\u2014\u2013-]*\s*)(?:\.\w+[$#]*,?\s*)*(?:->\s*\.\w+[$#]*)?\s*(?:\(private\))?\s*[-\u2014:]*\s*")
LEAD_RE = re.compile(r"^(?:/\s*@\w+\s*)?(?:punch\s+)?(?:item\s+\d+(?:\.\d+)?[^.:]{0,30}[.:]\s*)?", re.I)
CUT_RE = re.compile(r"\s(Output|Outputs|Input|Inputs|Example|Format|Arguments|Returns):")


def finish(words):
    """Shape collected header lines into one short purpose phrase."""
    words = [w for w in words]
    if words:
        words[0] = SIG_RE.sub("", words[0], count=1)
        words = [w for w in words if w]
    if words:
        words[0] = LEAD_RE.sub("", words[0], count=1)
        words = [w for w in words if w]
    para = " ".join(words).strip()
    para = CUT_RE.split(para)[0]
    guarded = re.sub(r"\b(e\.g|i\.e|vs|cf|etc)\.", lambda m: m.group(0).replace(".", "\x00"), para)
    m = re.search(r"(?<=[a-z)\"'])\.(\s|$)", guarded)
    if m:
        para = para[: m.start()]
    para = para.rstrip(".").strip()
    if len(re.findall(r"[A-Za-z]{3,}", para)) < 2:
        return ""
    if len(para) > 160:
        para = para[:160].rsplit(" ", 1)[0] + " ..."
    return para


def purpose_from_header(name, block):
    block = [b for b in block if not is_rule(b)]
    start = None
    for k, b in enumerate(block):
        if b.startswith("@" + name) and not re.match(r"@%s\w" % re.escape(name), b):
            start = k
            break
    if start is not None:
        first = re.sub(r"^@%s\s*[:—–-]*\s*" % re.escape(name), "", block[start]).strip()
        body = ([first] if first else []) + block[start + 1:]
    else:
        body = [b for b in block]
        # A banner such as "2. ONE-WAY ANOVA" is the only description some
        # procedures carry; use its text without the number.
        text = [b for b in body if b]
        if len(text) == 1:
            return re.sub(r"^\d+\.\s*", "", text[0]).strip()
    words = []
    for b in body:
        if not b or LABEL_RE.match(b):
            if words:
                break
            continue
        words.append(b)
    return finish(words)


def purpose_from_body(lines, i):
    """Fallback for a procedure with no header block: the comment lines that open its body."""
    j = i + 1
    while j < len(lines) and lines[j].lstrip().startswith("..."):
        j += 1
    words = []
    while j < len(lines) and lines[j].lstrip().startswith("#"):
        t = lines[j].lstrip()[1:].strip()
        if is_rule(t) or not t:
            if words:
                break
        else:
            words.append(t)
        j += 1
    return finish(words)


def parse_file(path):
    lines = read_lines(path)
    procs = []
    for i, ln in enumerate(lines):
        m = PROC_RE.match(ln)
        if not m:
            continue
        name = m.group(1)
        if name in EXCLUDE_NAMES or name.startswith(EXCLUDE_PREFIXES):
            continue
        params = join_params(lines, i, m.group(2))
        purpose = purpose_from_header(name, header_block(lines, i))
        if not purpose:
            purpose = purpose_from_body(lines, i)
        procs.append({
            "name": name,
            "purpose": purpose or "(see source header)",
            "params": params or "(none)",
            "scope": "internal" if name.startswith("eml_") else "public",
        })
    return file_version(lines), procs


def cell(s):
    return s.replace("|", "\\|")


def source_path(stem, subdir, src):
    if src and subdir:
        return os.path.join(src, subdir, stem + ".praat")
    return os.path.join(PKB, stem + ".txt")


PREAMBLE = """# EML Stats & Graphs — Procedure Registry

Generated: {date} | Source: plugin_EML_StatsGraphs (stats, graphs, scripts) + vibrato and egg libraries | Built by `tools/build_procedure_registry.py`

# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab

> **Path convention.** Every `**File:**` entry uses the *plugin tree* path
> (`stats/…`, `graphs/…`, `*.praat`). In Project Knowledge these ship
> **flattened**: `graphs/eml-graph-procedures.praat` is the file
> `eml-graph-procedures.txt` (drop the subdir, `.praat`→`.txt`). Retrieve an
> implementation with the linter's `--procedure` extract, never by reading
> the whole file or by a Project Knowledge search (`RULES_RETRIEVAL.md`, step 12).
> `include ../graphs/….praat` lines inside sources are plugin-tree references
> and are not expected to resolve in the flat PK layout.

> **Generated code must never `include` these files (hard).** The paths above
> describe a plugin tree that the end user is NOT assumed to have. When a
> generated script uses a library procedure, copy the procedure body into the
> delivered script (or into a sibling folder shipped with it) — never emit
> `include ../graphs/….praat`, `preferencesDirectory$`, or any absolute path.
> Copy transitively: a copied procedure's own `@eml…` calls come too. See
> `RULES_RETRIEVAL.md`, Retrieval Protocol step 12.

> **The `Parameters` column is inputs only — it does NOT list return
> variables.** A procedure that returns a value does so through a local
> `.something` / `.something$` in its own namespace, and that name is often NOT
> the input parameter name. `@emlGenerateUniquePath` is the trap: it takes
> `.path$` and returns `.result$`, so `emlGenerateUniquePath.path$` compiles,
> reads back the unchanged candidate path, and silently defeats the collision
> guard. **Read the `Outputs:` line in the procedure's own header comment, or
> the procedure body, before consuming a return value.** Never infer the return
> variable from this table or from a snippet elsewhere in the PKB — Retrieval Protocol step 11 (`RULES_RETRIEVAL.md`)
> applies: the source file governs.

> **Version discipline.** Each `**File:**` version below is the PLUGIN's version,
> copied verbatim into the PKB file header. PKB version == plugin version, always.
> A mismatch means the PKB has drifted and must be re-synced from source — that
> check is the whole point of carrying the number.

---
"""

TAIL = """---
**Total: {total} procedures** ({pub} public, {internal} internal) across {files} files.

**Withdrawn at 1.1:** `@emlEggSpectralThreshold`. Untested on real material — every figure behind it came from synthetic additive white Gaussian noise. Not distributed; do not reconstruct it. See `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` §4.

All entries above are backed by source shipped in the PKB.

**Removed at 14.1.0:** the Demo-window layout-helper library (`eml-demo-procedures`, 31 procedures). It was never the source of truth for driving the Demo window — `COMMANDS_DemoWindow.txt` and `BEST_PRACTICES_DEMO_WINDOW.md` are, and neither depends on it. It was a convenience wrapper around documented `demo` commands, dated April 2026, of uncertain current quality, and its source could not be reconciled. Write Demo layout from the documented commands instead.

**Deliberately NOT in the PKB:** `stats/eml-lmm.praat` (linear mixed models, excluded by author ruling) and its private numerical dependencies `stats/eml-linalg.praat` and `stats/eml-optimizer.praat`, and `@emlDrawLMMForest`, the one procedure in `graphs/eml-draw-procedures.praat` that reads them. Also not in the PKB: `scripts/eml-wizard.praat`, `stats/eml-demo-tables.praat`, `graphs/eml-draw-qq.praat`, the test helpers (`eml-test-helpers`) and the menu wrapper scripts.
"""


def build(src):
    parts = []
    total = pub = internal = files = 0
    seen = {}
    for stem, title, plugin_path, subdir in SECTIONS:
        path = source_path(stem, subdir, src)
        if not os.path.exists(path):
            sys.exit("missing source: " + path)
        version, procs = parse_file(path)
        for p in procs:
            if p["name"] in seen:
                sys.exit("duplicate procedure %s in %s and %s" % (p["name"], seen[p["name"]], stem))
            seen[p["name"]] = stem
        n_int = sum(1 for p in procs if p["scope"] == "internal")
        n_pub = len(procs) - n_int
        total += len(procs)
        pub += n_pub
        internal += n_int
        files += 1
        counts = "%d procedure%s" % (len(procs), "" if len(procs) == 1 else "s")
        if n_int:
            counts += " (%d public, %d internal)" % (n_pub, n_int)
        parts.append("## %s\n**File:** `%s` (v%s) — %s\n" % (title, plugin_path, version, counts))
        if procs:
            parts.append("| Procedure | Purpose | Parameters | Scope |\n|-----------|---------|------------|-------|")
            for p in procs:
                parts.append("| `@%s` | %s | %s | %s |" % (p["name"], cell(p["purpose"]), cell(p["params"]), p["scope"]))
            parts.append("")
        if stem in SECTION_NOTES:
            parts.append(SECTION_NOTES[stem] + "\n")
    date = datetime.date.today().strftime("%-d %B %Y")
    text = PREAMBLE.format(date=date) + "\n" + "\n".join(parts) + "\n" + TAIL.format(
        total=total, pub=pub, internal=internal, files=files)
    return text, dict(procedures=total, public=pub, internal=internal, files=files)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", help="plugin tree (folder with stats/, graphs/, scripts/); default: pkb/eml-*.txt")
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--check", action="store_true", help="compare with the existing file; ignore the date line")
    a = ap.parse_args()
    text, counts = build(a.src)
    if a.check:
        old = open(a.out, encoding="utf-8").read() if os.path.exists(a.out) else ""
        strip = lambda t: re.sub(r"^Generated: .*$", "", t, flags=re.M)
        if strip(old) != strip(text):
            print("registry is stale")
            return 1
        print("registry is current")
        return 0
    with open(a.out, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("wrote %s" % a.out)
    print("procedures=%(procedures)d public=%(public)d internal=%(internal)d files=%(files)d" % counts)
    return 0


if __name__ == "__main__":
    sys.exit(main())
