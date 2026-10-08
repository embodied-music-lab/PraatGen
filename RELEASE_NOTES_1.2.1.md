# EML PraatGen v1.2.1 Release Notes

**1.2.1** (stable)  
**Release date:** 8 October 2026  
**Master Prompt:** 15.0.0 (unchanged from 1.2.0)  
**PKB snapshot:** 2026-10-08  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (1.2.0) |
| -------------- | ------------ | ---------------- |
| Release        | **1.2.1**    | 1.2.0            |
| Master Prompt  | 15.0.0       | 15.0.0           |
| PKB snapshot   | 2026-10-08   | 2026-10-08       |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| EML procedures | 263 across 15 files | 263 across 15 files |

A correction release. It fixes the long-term average spectrum drawing
procedure on reversed axes and changes no rule, workflow or protocol. What
1.2.0 changed, including how PraatGen works in the merged chat and Cowork app,
is on the [v1.2.0 release page](https://github.com/embodied-music-lab/PraatGen/releases/tag/v1.2.0).
Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## LTAS plots draw on reversed axes

`@emlDrawLTAS` now draws all four of its methods (curve, bars, poles and
speckles) when the frequency axis runs high to low, the level axis runs top to
bottom, or both. Before, a reversed frequency axis left the curve, poles and
speckles blank, and a reversed level axis left the poles and speckles blank,
with no error. Plots on ascending axes are unchanged.

---

## Upgrade notes

If you're on 1.2.0, replace `pkb/eml-draw-procedures.txt` in your project.
Nothing else changed.

If you're on an earlier version, replace your project's instructions with
`MASTER_PROMPT_CORE_v15_0_0.md`, delete any older Master Prompt file, and
replace the entire `pkb/` folder (62 files). Delete the old folder rather than
overwriting into it. To check which version you're on, look for the version
line near the top of your project's instructions.

Do not rename files; the Master Prompt references them by exact filename.

## Reporting issues

Report to Ian Howell at the Embodied Music Lab
([www.embodiedmusiclab.com](https://www.embodiedmusiclab.com)). Quote both the
Release and Master Prompt versions; they track independently.

- **Script errors:** the task description, the generated script, and the exact
  Praat error message with line number.
- **Reference gaps:** the object type and command name.
- **Arity errors:** Praat's "requires only N arguments" message is ground truth
  — include it verbatim.
