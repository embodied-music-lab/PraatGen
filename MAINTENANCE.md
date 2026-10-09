# PraatGen maintenance checks

Checks for the maintainer, not for a generating session. Deliberately **not**
in `pkb/` — nothing here should ever be retrieved into a script-writing
conversation.

---

## 1. Self-contradiction sweep

**The defect class.** A file states a prohibition, then uses the prohibited
construct in a block that is not labelled WRONG. The prohibition and the
counter-example live in the same file, so no cross-file comparison finds them,
and a model that loads the file and scrolls to the pattern matching its task
gets the wrong answer from the right source.

This class has produced two shipped defects:

- Master Prompt Rule 28H emitted `Marks left:` / `Marks bottom:`, which
  `BEST_PRACTICES_DRAWING.txt` prohibits and Rule 34 lists as an anti-pattern.
- `BEST_PRACTICES_DRAWING.txt`'s own "Pattern for Spectrum" used the same two
  commands, three hundred lines below its own prohibition. A model that loaded
  the file and followed the spectrum pattern — which is what a spectrum task
  does — got the prohibited form from the authoritative source.

Cross-file sweeps miss it. Run this one **within** files, and against the
library source they point at.

**Run it.**

    python3 tools/sweep_self_contradiction.py

Exit code 1 and a printed table if anything is found. Triage every hit — the
check is deliberately noisy and false positives are expected:

- Occurrences inside blocks labelled `WRONG`, `anti-pattern`, or `never` are
  correct and are already filtered.
- A command reference legitimately lists prohibited commands; the entry needs
  a DO-NOT-EMIT note, not deletion. See `COMMANDS_PictureWindow.txt`.
- A worked example demonstrating what the prohibited form produces is correct.
- Hits in `eml-*.txt` are **plugin source**. Fix a verified defect in the PKB
  copy, mark the edit with a `# Provenance: PraatGen-only edit` line, and log
  it in `UPSTREAM_CORRECTIONS.md` so the reconcile with the plugin picks it up.

**Extending it.** `BANNED` in the script maps a regex to the rule it violates.
Add an entry whenever a new hard prohibition enters the PKB. A prohibition
with no sweep entry is one nobody will notice being broken.

---

## 2. Master Prompt code blocks versus their PKB sources

The core prompt and the RULES files carry a small number of Praat code blocks. Each is a
copyable answer that can drift from the source it summarises, and nothing
cross-checks them automatically.

    python3 tools/list_mp_code_blocks.py

Read each against the PKB file or library procedure it reflects. Check
procedure names, argument order and argument count against the source, not
against `EML_PROCEDURE_REGISTRY.md` — the registry lists inputs only, and
return variables must be read from the procedure body.

The standing preference is that a block that has drifted once gets **replaced
by a pointer**, not by a corrected block. A pointer cannot go stale and it
forces the load. Rule 28H is the worked example of this; Rule 27's
`@emlGenerateUniquePath` block is the other acceptable shape — it keeps the
code and states explicitly that the library source governs where the two
disagree.

---

## 2B. The Master Prompt is a core plus six RULES files

Since 16.0.0 the project instructions are `MASTER_PROMPT_CORE_v*.md`, and the
rest of the rules live in `pkb/RULES_*.md`. Each RULES file is canonical for
the rules it holds: edit it directly. The core's rule index says which file
holds which rule; update it whenever a rule moves or a new one is added, and
keep rule numbers unchanged across files. `tools/split_prompt_v16.py` is the
one-time migration from 15.1.0, kept for provenance.

When a rule needs to bind at a particular workflow step, put it in the RULES
file that step reads, not in the core. The core stays short so that what it
says stays in view.

## 2C. The linter

`pkb/TOOL_PRAATGEN_LINT.zip` is generated from `tools/praatgen_lint.py` with
the command index embedded. It holds one file, `TOOL_PRAATGEN_LINT.txt`. It
ships zipped because the Claude app returns at most 256 KiB of a text project
file and saves nothing to disk, while a zip upload is saved to disk whole.
Regenerate it after any change to the linter, a `COMMANDS_*.txt` file or the
catalogue, and check that it is current before a release:

    python3 tools/build_lint.py
    python3 tools/build_lint.py --check

## 2D. The catalogue

The catalogue is in the PKB as two parts, `PRAAT_DEFINITIVE_CATALOGUE_PART1.txt`
and `PRAAT_DEFINITIVE_CATALOGUE_PART2.txt`, because the Claude app returns at
most 256 KiB of a text project file and the whole catalogue is larger. Each
part opens with a note saying which part holds which object type. Everything
after the note is the catalogue text, unchanged. Edit the parts directly. To
replace the catalogue with a new extraction, split it, then check the parts and
rebuild the linter:

    python3 tools/split_catalogue.py split NEW_CATALOGUE.txt
    python3 tools/split_catalogue.py --check
    python3 tools/build_lint.py

`join OUT.txt` rebuilds the whole file from the parts.

A new hard prohibition with a mechanical signature belongs in the linter as
well as the sweep, so that sessions catch it before delivery.

---

## 3. Version and release discipline

- The **release number** is incremented only when a release is cut.
  It is not bumped per Master Prompt change.
- The **Master Prompt number** versions the instruction set, core and RULES
  files together, and moves with rule changes. `main` is normally ahead of the last cut release; README
  and the changelog say so.
- Every Master Prompt change gets a `PRAATGEN_CHANGELOG.md` entry and an
  update to the version line in the core's CHANGELOG section. A change to a
  RULES file counts as a Master Prompt change.

## 4. What belongs in a changelog and what belongs in a PKB file

PKB files are read by a model that needs the current rule. They state what is
true now. They do not carry the history of how a rule was arrived at, which
earlier version was wrong, or what a previous session got wrong — that is
noise at the point of use and it invites a reader to weigh a superseded form.

The changelog carries the history. Corrections, reversals and the reasoning
behind them go there, in full.

## 5. Corrections found in the EML library copies

The PKB ships flattened copies of the EML Praat Tools sources.

When PraatGen work turns up a defect in one of those procedures, fix it in the
PKB copy and record it in `UPSTREAM_CORRECTIONS.md`: procedure, source line,
defect, verified fix, and the evidence. Mark the edit in the PKB file with a
`# Provenance: PraatGen-only edit` line. The ledger is the handoff to the
plugin maintainer and the checklist for reconciling the two trees.

Keep Praat-level behavior out of it. A constraint that holds with no library
code involved belongs in the PraatGen reference files.
