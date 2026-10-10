# EML PraatGen v2.1.0 Release Notes

**2.1.0** (stable)  
**Release date:** 10 October 2026  
**Master Prompt:** 17.0.0  
**PKB snapshot:** 2026-10-10  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.0.0) |
| -------------- | ------------ | ---------------- |
| Release        | **2.1.0**    | 2.0.0            |
| Master Prompt  | **17.0.0**   | 16.0.0           |
| PKB snapshot   | 2026-10-10   | 2026-10-09       |
| PKB files      | **66**       | 71               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5  | Opus 5           |

PraatGen 2.1 reads its whole prompt again at the start of every turn. In chat,
the project instructions were sent with every message, and PraatGen's rules
held. The current Claude app sends them once, and rules that lived only in the
prompt began to slip as a session went on. 2.1 puts the whole prompt back in
front of the model on every turn. Full version history is in
`pkb/PRAATGEN_CHANGELOG.md`.

---

## The whole prompt is read on every turn

The project instructions are now one rule: at the start of every turn, before
anything else, read `PRAATGEN_RULES_FULL.md` in full. That file holds the core
and the six rules files, so the rules are in front of the model each time it
acts. The core now describes this arrangement; the six rules files' text is
unchanged.

Every reply opens with `Rules read this turn: marsh-7316`. The marker is the
file's last line, so it shows PraatGen read the file to the end. Check that the
turn also shows the read of `PRAATGEN_RULES_FULL.md` before anything else,
because a model can repeat the marker from an earlier turn.

## Opus 5 is the recommended model; Opus 5.5 is not

Opus 5 stays the recommendation, and it's the ceiling. Opus 5.5 is not recommended:
like 4.7, it is too agentic for this workflow and settles decisions itself that
PraatGen puts to you. Opus 4.8 down to 4.6 works if you want to conserve
tokens. Sonnet and Haiku are not supported.

## Pitch limits stay canonical unless signal would be lost

Both pitch floors, the filtered-autocorrelation pitch top, the
cross-correlation ceiling, the jitter and shimmer periods and the CPPS search
stay at their canonical values. The pitch top becomes exactly 2 x your highest
F0 only above 400 Hz. The cross-correlation ceiling stays 600 Hz unless your
highest pitch, plus vibrato, exceeds it; then it is set to accommodate your
range. The Harmonicity floor is always 75 Hz. No limit gets a margin or
multiplier. Scripts warn when a measurement comes within 10% of any limit, and
compare your stated range with what was measured.

## The plan quotes your task

The plan opens with your task message word for word, then a table that maps
each measure, input and output you asked for to what produces it. Dropping a
requested measure is a question to you. The lint blocks a plan without the
table or a requested item that nothing produces.

## Library procedures come from the linter

The linter carries an exact copy of every EML library procedure and prints the
ones a script needs, renamed to `emlPG` and otherwise verbatim. The lint blocks
any copied procedure that differs from its source. Non-ASCII characters inside
a verified copy, such as an em dash in an Info window message, are no longer
noted; a line that writes a file still blocks.

## The independent review runs by default

A fresh Opus reviewer reads the code rules and the clinical defaults (and the
drawing standards when the script draws) and checks the clinical parameters,
pitch limits, file output, dialogs, drawing and task coverage. Command,
function and procedure checks stay with the lint. Add NOREVIEW in any message
up to the GO for code to skip the review; it's faster.

## Smaller changes

- **American spelling** in Info window text, dialogs, warnings, CSV headers and
  comments. Praat command names keep Praat's own spelling.
- **References** include the EGG contact quotient sources, among them Herbst et
  al. (2017).
- **`Get standard deviation`** is verified for Intensity and Harmonicity.

## What this costs

PraatGen reads about 256 KB of prompt at the start of every turn. Each turn uses
more of your usage than in 2.0, and the context fills sooner, so long sessions
compact earlier. In exchange, every rule is in front of the model on every
turn.

---

## Upgrade notes

The project instructions have changed. Replace them with the contents of
`PROJECT_INSTRUCTIONS.txt`. Don't paste the core prompt into the instructions;
it's inside `PRAATGEN_RULES_FULL.md`.

Replace the entire `pkb/` folder, 66 files. Delete the old folder rather than
overwriting into it: the six `RULES_*.md` files are gone, and leaving them in
the project would give PraatGen two copies of its rules. One file is new,
`PRAATGEN_RULES_FULL.md`. Upload `TOOL_PRAATGEN_LINT.zip` as it is; don't
unzip it.

The `src/` folder holds the sources of `PRAATGEN_RULES_FULL.md` for
maintainers. Don't upload it to a project.

Do not rename files; the prompt references them by exact filename.

## Reporting issues

Report to Ian Howell at the Embodied Music Lab
([www.embodiedmusiclab.com](https://www.embodiedmusiclab.com)). Quote both the
Release and Master Prompt versions; they track independently.

- **Script errors:** the task description, the generated script, and the exact
  Praat error message with line number.
- **Reference gaps:** the object type and command name.
- **Arity errors:** Praat's "requires only N arguments" message is ground truth
  — include it verbatim.
- **Skipped steps:** which file is missing from the output folder, a reply that
  doesn't open with the marker, or which check the SELF-AUDIT says didn't run.
