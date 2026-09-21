# EML PraatGen v1.0.6 Release Notes

**1.0.6** (stable)  
**Release date:** 21 September 2026  
**Master Prompt:** 14.20.0  
**PKB snapshot:** 2026-09-21  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (1.0.5) |
| -------------- | ------------ | ---------------- |
| Release        | **1.0.6**    | 1.0.5            |
| Master Prompt  | **14.20.0**  | 14.17.0          |
| PKB snapshot   | **2026-09-21** | 2026-08-05     |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| EML procedures | 263 across 15 files | 263       |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## Copied library procedures carry the `emlPG` prefix

A generated script pastes in the EML library procedures it calls, so the script
runs without the plugin installed. Those copies are now renamed: a script that
calls `@emlDrawViolinPlot` defines and calls `@emlPGDrawViolinPlot`. The body,
the parameters and the local names are unchanged, and a comment above each copy
names its library original.

This matters if you own the EML Praat Tools plugin. A script that `include`s
library files and also carries a copied procedure puts two definitions of one
name in the same parse unit. Praat runs the script and chooses between them
unpredictably. The prefix keeps the two sets of names separate. `emlPG` is
reserved, so the plugin never defines a name that starts with it.

## Sandbox Praat is pinned to 6.6.30

Sandbox Mode installed whatever Praat was newest at the time. It now installs
6.6.30 until Praat 7's permission behavior settles. Measured values are
unaffected: the version-floor probe returns the same numbers on 6.6.30 and 7.0.

## Praat 7.0 reference material

`PRAAT_VERSION_FLOOR.txt` gains a section on what changes above the floor in
Praat 7.0. Writing a file or running a system command now requires your
permission, which Praat asks for with a dialog. This is a prompt rather than a
failure, so it stays out of the version check that generated scripts emit. The
section lists which calls are affected and which are not.

## Matrix division, minimum and comparison

`APPENDIX_B_FUNCTIONS.txt` gains a section on operators that refuse matrix
operands. The `/` operator is one: `m## / x` and `a## / b##` both fail.
Division is available by composition, as `m## * (1 / x)` and
`a## * (b## ^ -1)`. `min ()`, `max ()` and `<` refuse matrix and vector
operands at script level and work through a Matrix object's `Formula:` and
`Get` commands. The section carries the exact error text each operator
produces.

The same file's row and column extraction idioms now use `row#` and `col#`,
which do in one call what the documented pattern did in two.

## Naming and packaging rules for generated plugins

`BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` gains two sections. The first sets
out the naming registers: public procedures, internal helpers, persisted
settings and file names, with the rule that a public name is a promise other
people's saved scripts depend on. The second covers packaging: a generated
plugin ships a build target that produces the installable folder, normalizes
file modes, and verifies itself by installing into a scratch home and
confirming the menu entry appears.

## Corrected plugin install paths

`BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` listed only the Praat 6 preferences
folder for macOS, Windows and Linux. All three moved in Praat 7.0. The file now
gives both, notes that Praat 7 reads `XDG_CONFIG_HOME` on Linux, and records
that Praat 7 still loads plugins from the Praat 6 folder.

---

## Upgrade notes

Replace your project's instructions with `MASTER_PROMPT_CORE_v14_20_0.md`.
Delete `MASTER_PROMPT_CORE_v14_17_0.md`.

Replace the entire `pkb/` folder — 62 files. Delete the old folder rather than
overwriting into it.

Do not rename files; the Master Prompt references them by exact filename.

Sandbox Mode requires `www.fon.hum.uva.nl` in Settings → Capabilities → Allowed
domains, set *before* the conversation starts. It installs `openbox`,
`xcompmgr`, `xdotool` and `imagemagick`.

## Reporting issues

Report to Ian Howell at the Embodied Music Lab
([www.embodiedmusiclab.com](https://www.embodiedmusiclab.com)). Quote both the
Release and Master Prompt versions; they track independently.

- **Script errors:** the task description, the generated script, and the exact
  Praat error message with line number.
- **Reference gaps:** the object type and command name.
- **Arity errors:** Praat's "requires only N arguments" message is ground truth
  — include it verbatim.
