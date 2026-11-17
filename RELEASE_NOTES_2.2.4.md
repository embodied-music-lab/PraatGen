# EML PraatGen v2.2.4 Release Notes

**2.2.4** (stable)  
**Release date:** 17 November 2026  
**Master Prompt:** 17.1.4  
**PKB snapshot:** 2026-11-17  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.2.3) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.4**    | 2.2.3            |
| Master Prompt  | 17.1.4       | 17.1.4           |
| PKB snapshot   | 2026-11-17   | 2026-11-01       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## Command reference corrections

Every entry below was run in Praat 6.6.30 and 6.4.39 and compared with 7.0.03.

- **Argument lists.** Twelve commands had the wrong number of arguments or
  none listed, including Table's `Collapse rows`, `Sort rows` and `Rows to
  columns`, `Extract channels`, `Add points`, `Shift times to`, and the
  TextGrid and PitchTier `Draw` commands.
- **Object types.** Sections for other object types, and for commands that
  need two or three objects selected together, now carry an object type line,
  so the lint checks each command against the selection it really needs.
- **Editor commands.** Names follow Praat's current menus, such as `Add on
  tier 1`, `Paste before selection` and `Remove`, and five settings commands
  have their full argument lists.
- **Placeholder lines.** Lines ending in `?` are now real entries or comments.
- **Lint.** It reads function names only from the functions reference's entry
  lines, and its object type lines can name a co-selection.

---

## Upgrade notes

The project instructions didn't change.

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
