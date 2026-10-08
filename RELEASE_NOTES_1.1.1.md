# EML PraatGen v1.1.1 Release Notes

**1.1.1** (stable)  
**Release date:** 29 September 2026  
**Master Prompt:** 14.21.0 (unchanged from 1.1.0)  
**PKB snapshot:** 2026-09-29  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (1.1.0) |
| -------------- | ------------ | ---------------- |
| Release        | **1.1.1**    | 1.1.0            |
| Master Prompt  | 14.21.0      | 14.21.0          |
| PKB snapshot   | 2026-09-29   | 2026-09-23       |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| EML procedures | 263 across 15 files | 263 across 15 files |

A correction release. It fixes reference errors introduced in 1.1.0 and
reversed-axis defects in the library's drawing procedures. It changes no rule,
workflow or protocol. Full version history is in
`pkb/PRAATGEN_CHANGELOG.md`.

**Install this release over 1.1.0.** The FormantPath corrections that 1.1.0
carries are correct and are still the reason to upgrade from 1.0.6; they are
unchanged here.

---

## The reversed-axis circle rule applies to the x-axis only

1.1.0 stated the rule for either axis. `Paint circle:` and `Draw circle:` take
a radius measured along x, so a reversed y-axis does not affect them. An
audiogram, a rank plot, or any other chart that inverts y while leaving x
ascending draws correctly with the world-coordinate forms and should keep using
them. A chart that reverses x still needs the millimeter forms.

## The millimeter circle commands are documented, and their argument is a diameter

1.1.0 required `Paint circle (mm):` and `Draw circle (mm):` without documenting
either command. `COMMANDS_PictureWindow.txt` now carries a verified entry for
both. `Paint circle (mm):` takes four arguments; `Draw circle (mm):` takes
three and no color, so set the color with a preceding `Colour:` command.

The size argument is a **diameter in millimeters**, where the world-coordinate
forms take a **radius in world units**. It is the fourth argument in the Paint
forms and the third in the Draw forms. Substituting the command name alone
resizes every circle, silently, because the result still renders. The
direction depends on the axis range: on a 0 to 100 axis the circle shrinks,
and on any frequency axis it grows, by more than tenfold on a formant plot.
Both files now state this at each call site and give the conversion:

    diameter_mm = 2 * radius_world * innerViewportWidth_mm / xRange

Where a size is being chosen fresh, choose it in millimeters.

## Corrected reference figures

`Down to Table (optimal interval)` takes 14 arguments and now carries a
verified call. 1.1.0 described its arity as unresolved between 14 and 15 and
withheld verification, which raised a false uncertainty in SELF-AUDIT.

The `Extract Formant` measurements now name the synthesized vowel they were
taken on and show the middle-ceiling and optimal-ceiling analyses beside the
result, so they can be reproduced. The substantive finding is unchanged:
`Extract Formant` returns the middle candidate.

The `Extract Formant` segfault entry reads as open-ended. 6.4.30 and 7.0.02 are
the oldest and newest builds tested; a closed range implied a fix after 7.0.02
that has not been established.

The FormantPath candidate search runs 4503.0 to 6717.7 Hz at the default
parameters. Two files carried 4510 and 6722.

The formant plausibility example in `APPENDIX_D_CLINICAL_DEFAULTS.txt` §4A is
scoped to the token it was measured on. It previously asserted a general
plateau across the lower ceilings.

The drawing evidence in `BEST_PRACTICES_DRAWING.txt` records the settings the
counts depend on, including font size, which drives the panel margins and
moves the count by 40% across the usual range.

## Library and function reference

The aligned tick procedures (`@emlDrawAlignedMarksBottom`, `Left` and `Right`)
accept their bounds in either order. A descending range previously drew no
ticks and no values. The gridline procedures do the same.

`@emlDrawScatterPlot` draws on a reversed x- or y-axis, such as a vowel chart.
Its markers use `Paint circle (mm):` at the same size as before; a reversed
x-axis previously stopped the script. On Linux, sprites are off and dots draw
natively, since Praat on Linux draws nothing for `Insert picture from file:`.

`lowerCase$` is documented beside `upperCase$`. Both are absent below 6.4.46 and
work in procedures, the main script body and object `Formula:`.

---

## Upgrade notes

The Master Prompt is unchanged. If you are on 1.1.0, keep
`MASTER_PROMPT_CORE_v14_21_0.md` as it is and replace the `pkb/` folder only.

If you are on 1.0.6 or earlier, replace your project's instructions with
`MASTER_PROMPT_CORE_v14_21_0.md` and delete the older Master Prompt file.

Replace the entire `pkb/` folder — 62 files. Delete the old folder rather than
overwriting into it.

Do not rename files; the Master Prompt references them by exact filename.

Sandbox Mode downloads Praat from `www.fon.hum.uva.nl` and installs `openbox`,
`xcompmgr`, `xdotool` and `imagemagick`. Whether a session can reach that site
isn't settled yet. It depends on the Claude plan and its settings, and those
rules aren't fully documented. An individual Max account reached the site by
default when tested on 8 October 2026; other plans are untested. On Team and
Enterprise plans, the organization owner controls which domains are allowed.
If PraatGen reports the site unavailable, ask it to try the download once
before accepting that. If the download is refused, attach the Praat Linux
archive and PraatGen installs it from there.

Re-run any script generated before 1.1.0 that uses a FormantPath: its F1 and F2
values were read at the middle candidate ceiling, not the optimal one.

## Acknowledgement

The FormantPath, reversed-axis and `upperCase$` corrections shipped in 1.1.0
come from a bug report by Eric Armstrong
([voiceguy.ca](https://voiceguy.ca/about)).

## Reporting issues

Report to Ian Howell at the Embodied Music Lab
([www.embodiedmusiclab.com](https://www.embodiedmusiclab.com)). Quote both the
Release and Master Prompt versions; they track independently.

- **Script errors:** the task description, the generated script, and the exact
  Praat error message with line number.
- **Reference gaps:** the object type and command name.
- **Arity errors:** Praat's "requires only N arguments" message is ground truth
  — include it verbatim.
