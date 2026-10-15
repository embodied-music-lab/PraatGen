# EML PraatGen v2.2.0 Release Notes

**2.2.0** (stable)  
**Release date:** 15 October 2026  
**Master Prompt:** 17.1.2  
**PKB snapshot:** 2026-10-15  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (2.1.0) |
| -------------- | ------------ | ---------------- |
| Release        | **2.2.0**    | 2.1.0            |
| Master Prompt  | **17.1.2**   | 17.0.0           |
| PKB snapshot   | 2026-10-15   | 2026-10-10       |
| PKB files      | 66           | 66               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| Recommended model | Opus 5    | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## SCAFFOLD mode saves tokens while you talk a project through

The new Opus models take initiative. PraatGen 2.1 keeps them on its rules by
rereading its whole prompt, about 256 KB, at the start of every turn, and that
cost comes with every reply, including the answer to a question. Conversations
compact sooner as a result.

In 2.2, SCAFFOLD mode is the way to talk without that cost:

- The turn that starts scaffold reads the whole prompt, and so does the first
  turn of any conversation.
- While scaffold is on, turns that only discuss your project skip the reread.
  They open with "Rules not read this turn: scaffold mode is on."
- Those turns stay with the idea: the research question, what to measure, the
  inputs and outputs, and the stages in plain words. If you ask for commands,
  settings or code, PraatGen asks you to end scaffold first.
- A scaffold turn that runs Praat in the sandbox reads the whole prompt before
  it runs anything.
- You end scaffold in your own words. That turn and every turn after it read
  the whole prompt. If a proposal is on the table, PraatGen checks each
  decision from the discussion against its rules, asks you about any conflict,
  and presents the scaffold review for your APPROVE. If not, it carries on with
  the usual pre-flight, plan and GO.
- If PraatGen can't tell whether scaffold is on, it reads the prompt.

Start a conversation with SCAFFOLD whenever you want to think a project through
before building it.

## Stereo files default to the left channel

Every stereo dialog lists Left channel only, Right channel only, Mix to mono,
with Left as the default, in single-file and batch scripts. The script chooses
the channel from the option's text, so the order of the options can't pick the
wrong channel, and any other value stops the script with an error.

## EGG polarity follows the stronger derivative peak

The polarity test inverts the EGG whenever the derivative's negative peak is
larger than its positive peak. When the two peaks are within a factor of 1.25
of each other, the script applies that decision and warns that the signal is
suspect.

## The reference files say what each command creates

Every command in the COMMANDS files that creates an object has a Returns line
naming the object type. Commands that create several objects say so, and
`COMMANDS_Universal.txt` shows how to capture them with `selected#`.
`COMMANDS_Matrix.txt` adds Eigen (complex), To SVD and the SVD queries. When
the catalogue lists a command that has no manual page, PraatGen checks Praat's
source code and the sandbox, and a sandbox probe of a command that creates
objects confirms what it leaves selected.

## Smaller changes

- **Copied library procedures read each other's results.** A copy that reads
  another procedure's variables, such as `emlMedian.result`, now reads the
  renamed `emlPGMedian.result`. In 2.1.0 such a copy stopped the script with
  "Unknown variable".
- **No praise or grading of what you say.** PraatGen starts with the answer.
- **A variable name in single quotes inside a string is allowed.** The lint no
  longer blocks `writeInfoLine: "F0 is 'f0' Hz"`.

---

## Upgrade notes

Replace the project instructions with the contents of
`PROJECT_INSTRUCTIONS.txt`. They now carry the scaffold exception, and
PraatGen relies on them for it.

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
