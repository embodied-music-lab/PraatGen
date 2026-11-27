# EML PraatGen v2.2.6 Release Notes

**2.2.6** (stable), for projects in the older Claude project format (addresses that start `claude.ai/project/`)  
**Release date:** 26 November 2026  
**Master Prompt:** 17.1.6  
**PKB snapshot:** 2026-11-26  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.2.5) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.6**    | 2.2.5            |
| Master Prompt  | 17.1.6       | 17.1.6           |
| PKB snapshot   | 2026-11-26   | 2026-11-26       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

A version for the new Claude project format is in development. Use 2.2.6 in projects at `claude.ai/project/`.

---

## Lint

- **Functions Praat refuses.** A function that Praat's own lists include but
  Praat refuses when run, such as `inner##`, `linear$##` or `randomPoisson#`,
  is now a BLOCKING finding that names the working alternative. The lint
  also reads the `$##` spelling, which it used to skip.

## README

- The top of the page has one short note on which version you need. The
  linter zip note is in the setup steps.

---

## Upgrade notes

The project instructions didn't change.

Replace `TOOL_PRAATGEN_LINT.zip` and `PRAATGEN_CHANGELOG.md` in your project,
or replace the entire `pkb/` folder, 66 files. Upload the zip as it is; don't
unzip it.

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
