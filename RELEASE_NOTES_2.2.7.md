# EML PraatGen v2.2.7 Release Notes

**2.2.7** (stable), for projects in the older Claude project format (addresses that start `claude.ai/project/`)  
**Release date:** 27 November 2026  
**Master Prompt:** 17.1.7  
**PKB snapshot:** 2026-11-27  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.2.6) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.7**    | 2.2.6            |
| Master Prompt  | 17.1.7       | 17.1.6           |
| PKB snapshot   | 2026-11-27   | 2026-11-26       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

A version for the new Claude project format is in development. Use 2.2.7 in projects at `claude.ai/project/`.

---

## Scripts

- **Info window style.** Scripts write the Info window in one house style: a
  bordered header, titled sections, aligned label and value lines, progress
  bars for batches, and marks for passes, failures and warnings. Data tables
  use padded columns when the data also goes to a file, and stay
  tab-separated when the Info window is the only output.
- **EGG channel.** To find the EGG channel in a stereo file, PraatGen compares
  the HNR of each channel's derivative, names the test that way in every
  option and report, and reports both values for each file. It adds no
  calibration step.

---

## Upgrade notes

Paste `PROJECT_INSTRUCTIONS.txt` into your project instructions again. Only its
version line changed.

Replace `PRAATGEN_RULES_FULL.md`, `APPENDIX_F_UX_STANDARDS.txt`,
`BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` and `PRAATGEN_CHANGELOG.md` in your
project, or replace the entire `pkb/` folder, 66 files.

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
