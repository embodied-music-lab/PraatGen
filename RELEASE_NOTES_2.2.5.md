# EML PraatGen v2.2.5 Release Notes

**2.2.5** (stable), for projects in the older Claude project format (addresses that start `claude.ai/project/`)  
**Release date:** 26 November 2026  
**Master Prompt:** 17.1.6  
**PKB snapshot:** 2026-11-26  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.2.4) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.5**    | 2.2.4            |
| Master Prompt  | 17.1.6       | 17.1.4           |
| PKB snapshot   | 2026-11-26   | 2026-11-17       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

A version for the new Claude project format is in development. Use 2.2.5 in projects at `claude.ai/project/`.

---

## Questions about your data

- **Answers from the signals.** When no command answers a question about your
  data, PraatGen doesn't call it undeterminable. It offers to look for a way to
  answer it from the signals, tests candidate measures in the sandbox, and
  proposes the result, with its numbers, for you to confirm.
- **Channel assignment.** When a file's channels carry different kinds of
  signal, such as EGG and microphone, PRE-FLIGHT asks for the mapping and
  offers to identify the channels from the signals.

## Sandbox

- **Praat download.** The sandbox installs the pinned Praat 6.6.30 from
  Praat's GitHub releases, since the Praat website hosts only current builds.
  PraatGen never asks you to change network or environment settings. If GitHub
  is refused too, it offers a manual-upload fallback.

## Measures and models

- **Jitter and shimmer variants.** A requested jitter or shimmer measure is
  never left out because another measure determines it. ddp and dda stay out
  of the default output and are reported whenever you or your protocol ask for
  them.
- **Opus 5.5** is supported. Watch that it doesn't run ahead of your
  decisions. Opus 5 remains the recommendation.

---

## Upgrade notes

Replace the project instructions with `PROJECT_INSTRUCTIONS.txt`. Only its
version line changed.

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
