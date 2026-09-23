# EML PraatGen v1.1.0 Release Notes

**1.1.0** (stable)  
**Release date:** 23 September 2026  
**Master Prompt:** 14.21.0  
**PKB snapshot:** 2026-09-23  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (1.0.6) |
| -------------- | ------------ | ---------------- |
| Release        | **1.1.0**    | 1.0.6            |
| Master Prompt  | **14.21.0**  | 14.20.0          |
| PKB snapshot   | **2026-09-23** | 2026-09-21     |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| EML procedures | 263 across 15 files | 263 across 15 files |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## FormantPath analysis now reads the optimal ceiling correctly

Extract Formant on a FormantPath returns the analysis at the middle candidate
ceiling, not the optimal one that Get optimal ceiling reports — on a fresh
FormantPath as much as one that has had Set path: or Set optimal path: applied
to it. A generated script no longer calls Extract Formant on a FormantPath. It
queries Get optimal ceiling and runs a plain To Formant (burg) at that ceiling
instead. This changes the F1 and F2 values a FormantPath-based script reports:
they move from whatever the middle candidate ceiling produced to the values at
the recording's actual optimal ceiling, which will usually differ.

Extract Formant on a FormantPath also segfaults once Set path: or Set optimal
path: has been called on the same object, across Praat 6.4.30 through 7.0.02 —
a wider range than previously documented. Both Set commands overwrite the
FormantPath's stored candidate index with the candidate's ceiling frequency
instead, and the corrupted value is written to disk and survives a reload.
Down to Table (optimal interval) is unaffected by either issue and remains the
documented route to per-candidate output.

**Scripts generated before this release carry middle-ceiling formants**, not
optimal-ceiling ones, anywhere they used a FormantPath. Re-run those scripts
under this release to get corrected values.

The selected ceiling is a search result and can land on a value that breaks
formant tracking. A generated script now checks the result against the same
formant bands it already applies to every other measure and warns when the
value falls outside them. It substitutes nothing and does not stop.

## Circles on a reversed axis

Paint circle: and Draw circle: compute their radius in world x-coordinates. On
an axis that runs high-to-low — the normal case for a vowel chart, which
reverses both axes by convention — the radius comes out negative, and Praat
draws nothing without raising an error. BEST_PRACTICES_DRAWING.txt now
requires Paint circle (mm): and Draw circle (mm): whenever either axis is
reversed.

## upperCase$ availability corrected

APPENDIX_B_FUNCTIONS.txt previously reported upperCase$ (string$) as broken
when called from a procedure. It is not broken: the function is absent from
Praat builds through 6.4.39 and present from 6.4.46 onward, the same boundary
as several other case-conversion and app-info functions. See
PRAAT_VERSION_FLOOR.txt §2.

## Acknowledgement

All three corrections come from a bug report by Eric Armstrong
([voiceguy.ca](https://voiceguy.ca/about)).

---

## Upgrade notes

Replace your project's instructions with `MASTER_PROMPT_CORE_v14_21_0.md`.
Delete `MASTER_PROMPT_CORE_v14_20_0.md`.

Replace the entire `pkb/` folder — 62 files. Delete the old folder rather than
overwriting into it.

Do not rename files; the Master Prompt references them by exact filename.

Sandbox Mode requires `www.fon.hum.uva.nl` in Settings → Capabilities → Allowed
domains, set *before* the conversation starts. It installs `openbox`,
`xcompmgr`, `xdotool` and `imagemagick`.

Re-run any previously generated script that uses a FormantPath: its F1/F2
values were read at the middle candidate ceiling, not the optimal one.

## Reporting issues

Report to Ian Howell at the Embodied Music Lab
([www.embodiedmusiclab.com](https://www.embodiedmusiclab.com)). Quote both the
Release and Master Prompt versions; they track independently.

- **Script errors:** the task description, the generated script, and the exact
  Praat error message with line number.
- **Reference gaps:** the object type and command name.
- **Arity errors:** Praat's "requires only N arguments" message is ground truth
  — include it verbatim.
