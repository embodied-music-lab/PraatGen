# EML PraatGen v2.2.3 Release Notes

**2.2.3** (stable)  
**Release date:** 1 November 2026  
**Master Prompt:** 17.1.4  
**PKB snapshot:** 2026-11-01  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.2.2) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.3**    | 2.2.2            |
| Master Prompt  | **17.1.4**   | 17.1.3           |
| PKB snapshot   | 2026-11-01   | 2026-10-22       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## Matrix formulas

`COMMANDS_Matrix.txt` now covers `Formula:`, `Create simple Matrix`, `Create
Matrix`, reading and setting cells, rows and columns, and the statistics
queries, each checked in Praat 6.6.30. Sessions load it for any script that
uses a Matrix. The lint knows that `Create simple Matrix` makes a Matrix.

## Corrections

- **Unvoiced pitch frames.** In the vector from `List values in all frames`,
  an unvoiced frame tests true for `= undefined`. The Pitch reference said
  the opposite.
- **Older Praat builds.** The sandbox downloads them from GitHub's release
  download path and builds the filename itself, because the release pages
  return 403.

---

## Upgrade notes

Replace the project instructions with the contents of
`PROJECT_INSTRUCTIONS.txt`. Only the version line changed.

Replace the entire `pkb/` folder, 66 files. Delete the old folder rather than
overwriting into it. Upload `TOOL_PRAATGEN_LINT.zip` as it is; don't unzip it.

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
  doesn't open with the marker or the scaffold line, or which check the
  SELF-AUDIT says didn't run.
