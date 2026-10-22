# EML PraatGen v2.2.2 Release Notes

**2.2.2** (stable)  
**Release date:** 22 October 2026  
**Master Prompt:** 17.1.3  
**PKB snapshot:** 2026-10-22  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.2.1) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.2**    | 2.2.1            |
| Master Prompt  | **17.1.3**   | 17.1.2           |
| PKB snapshot   | 2026-10-22   | 2026-10-15       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## Subagents get their files in their prompt

A subagent may not be able to read your Project Knowledge, even when the
session can. PraatGen now puts everything a subagent's task needs into its
prompt. When a subagent reports that it can't read the files, PraatGen keeps
reading them itself and never tells you Project Knowledge is unreachable
unless its own read failed.

The independent review gets the same treatment. The reviewer receives the
files it checks against and opens its reply with each file's last line. If it
can't, the review counts as not run, PraatGen tells you, and the review runs
again.

## Scripts that live inside a plugin

Add a line `Plugin register: <prefix>` to the plan for a file written into an
existing plugin. The lint then accepts the plugin's own procedure names and
its includes of sibling files, and still checks every library procedure
copied under the plugin's register. A script that writes the Info window to a
file gets a note, because that text can carry non-ASCII characters from other
procedures.

## Undefined values and settings files

Undefined values follow the file's reader. `--undefined--` stays the default,
a file for R gets an empty cell, and a file that must match another program
uses its marker, such as `?` for RespGraph Studio.

Settings files follow the script's scope. A short single-file script keeps its
settings beside it, a multi-file plugin keeps them in its own subfolder of the
apps folder in the Praat preferences folder, and anything in between is your
call. The PRE-FLIGHT asks.

## Smaller changes

- **Older Praat builds come from GitHub.** The Praat site no longer has
  6.4.39, so older builds come from the Praat releases on GitHub.
- **`solve#` doesn't detect singular matrices.** It returns the
  least-squares solution with the smallest norm, and an inverse made with
  `solve##` is a pseudo-inverse. The function reference says to test with
  To SVD and Get rank first.
- **Demo window.** The full window is restored with the outer viewport, and
  animations pause between short segments instead of checking for clicks.
- **Reference corrections.** Five Sound and Matrix queries, path arguments on
  the Save commands, the tick-spacing example, three-series gray values,
  and the Stop and Quit buttons in Rules 19 and 21.

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
