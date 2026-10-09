# EML PraatGen v2.0.0 Release Notes

**2.0.0** (stable)  
**Release date:** 9 October 2026  
**Master Prompt:** 16.0.0  
**PKB snapshot:** 2026-10-09  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (1.2.1) |
| -------------- | ------------ | ---------------- |
| Release        | **2.0.0**    | 1.2.1            |
| Master Prompt  | **16.0.0**   | 15.0.0           |
| PKB snapshot   | 2026-10-09   | 2026-10-08       |
| PKB files      | **71**       | 62               |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| EML procedures | 263 across 15 files | 263 across 15 files |

PraatGen 2.0 is rebuilt for the Claude app as it now works, where a session
writes files, runs tools and works through long chains of steps. In a long
session of that kind, the rules read at the start fall out of view. In 2.0, the rules
arrive at the step that needs them, every step leaves a file you can see, and
the script is checked by a tool and a fresh reviewer before you get it. Full
version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## A short core and six rules files

The project instructions are now a short core, about an eighth of the old
Master Prompt. The core holds the workflow, the pre-flight, the model rules
and an index. The rest of the rules moved word for word into six `RULES_*.md`
files in the reference folder, with their numbers unchanged. The core tells
PraatGen to read each file in full at the step that needs it. Before the
pre-flight it reads the retrieval, planning, code, audit and sandbox files,
plus the reference files the task's questions depend on. It reads planning and
code again at GO, code again before writing the script, and the audit file
before the SELF-AUDIT. The modes file loads when you use a mode.

## The pre-flight asks better questions

Before stating any decision, the pre-flight thinks your task through against
each canonical value: your singing range, vibrato, your hardware and the
comparisons you'll make. It states canonical values and required methods as
decisions and never asks whether to follow a standard. It asks where a value
would lose signal, or where a change would cost comparability with published
norms, and states both consequences. On sustained vowels with vibrato, it
discusses vibrato rate and extent with you.

## You approve the plan before any code is written

After your GO, PraatGen sends the full command plan and function plan in the
chat and stops, on every model. The plans list any assumptions with a default;
a bare GO accepts them. You review the plan, correct it if needed, and reply GO
again for the code. This adds one reply per script. In AUTO mode there's no
stop.

## Every step leaves a file

For each script, PraatGen's output folder holds the plan
(`<name>_plan.md`, with an unedited copy of the plan as sent), the script,
the linter output (`<name>_lint.txt`) and the audit (`<name>_audit.md`), with
`open_items.md` kept current. The linter confirms the plan was sent before the
script was written. The plan is a
table that names the reference file verifying each command. You receive the
plans as a message before any code is written.

## Checks before delivery

- **Linter.** `TOOL_PRAATGEN_LINT.zip` holds a linter that runs on every script. It checks every
  command against the reference files, checks every function call against
  `APPENDIX_B_FUNCTIONS.txt`, and checks the script against its plan.
  It also runs the mechanical audit checks, such as quoted `form:` defaults,
  plain-ASCII file output, no plugin includes, the `emlPG` prefix and
  hardcoded paths. PraatGen fixes every blocking finding before delivery.
- **Verification order.** PraatGen checks a command against the PKB reference
  files first, then the Praat manual, then the catalogue. The catalogue is the
  last fallback, and a command found only there is verified in the sandbox
  before use, or by Paste Commands without a sandbox. The linter blocks a
  catalogue-only command until one of those confirms it.
- **Read check.** The plan lists each rules file read in full with its code
  word, and the linter confirms every pairing. The SELF-AUDIT copies the
  linter's confirmed list.
- **Fresh reviewer.** A separate Opus session reads the reference files the
  plan cites and checks the script against them. PraatGen fixes what it finds.
- **SELF-AUDIT.** The audit shows the linter output and the reviewer's
  result. If a check couldn't run, the audit says which one and why.

The linter checks command names, argument counts, function names and the mechanical items.
It doesn't check what the arguments mean; the reviewer and the reference
files cover that.

## Analysis rules

- **EGG polarity.** PraatGen tests polarity from the derivative's peaks and
  inverts an inverted EGG automatically, reporting the ratio. You can fix
  polarity yourself instead. The CQ plausibility bound no longer counts as a
  polarity check, because an inverted EGG reads as 1 minus the true CQ.
- **CPPS.** The 60-330 Hz peak search stays at the published value. Raising it
  for higher voices is a pre-flight question that says the result won't
  compare with published norms.
- **Range warnings.** Limits derived from your stated range warn when the
  measurement crosses your stated range. Fixed limits warn when a measurement
  comes within 10% of them.
- **Jitter and shimmer.** Every script that measures them points to the Praat
  manual's comparison with other programs.
- **Undefined values** are written as Praat writes them, `--undefined--`.

## Web access and your recordings

- **No web search without you.** PraatGen's sources are the reference files
  and you. Its only outside sources are Praat's own manual, downloads and
  source code. Any other web search needs an exhausted search of the reference
  files, a discussion with you and your yes.
- **Recordings stay on your computer by default.** You run the script in Praat
  yourself. If you connect a folder, PraatGen asks for the narrowest one, never
  changes your files, and proposes an output folder name before creating it.
  Before it reads recordings of people, it explains the privacy precautions
  every time, including the Claude settings to check, and you decide.

## The workflow takes priority

The Claude app gives each session its own standing instructions, such as
holding findings until the end of a turn or searching the web first. Where
these conflict with PraatGen's workflow, gates or SELF-AUDIT, PraatGen's rules
win. The introduction is reorganized: the four things PraatGen needs come
first, and modes and models are tables.

## Weaker models stay away from scripts

Sonnet and Haiku never draft, edit, review or verify Praat code. Haiku is
never used, even as a subagent. A PraatGen session may hand Sonnet only
mechanical tasks, such as locating a file or running a given command. The reviewer always runs on Opus or higher.

## What this costs

PraatGen reads more files per task than before: the rules files at their
steps, plus the reviewer's own reading. A typical script uses more of your
usage than in 1.x. In exchange, the rules are in front of the model when it
acts.

## Requirements

PraatGen 2.0 needs a session that can read a project file in full, which the
current Claude app can. If it can't, PraatGen says so in the pre-flight.

---

## Upgrade notes

The Master Prompt has changed. Replace your project's instructions with
`MASTER_PROMPT_CORE_v16_0_0.md` and delete any older Master Prompt file.

Replace the entire `pkb/` folder, 71 files. Delete the old folder rather
than overwriting into it. Ten files are new: six `RULES_*.md` files,
`TOOL_PRAATGEN_LINT.zip`, `COMMANDS_Matrix.txt`, and the catalogue's two parts,
`PRAAT_DEFINITIVE_CATALOGUE_PART1.txt` and `PRAAT_DEFINITIVE_CATALOGUE_PART2.txt`.
They replace `PRAAT_DEFINITIVE_CATALOGUE.txt`. Upload the zip as it is; don't
unzip it. Without the rules files, PraatGen 2.0 is missing most of its rules.

**Two files changed form to fit the Claude app.** The app returns at most
256 KiB of a text project file. The catalogue is now two parts, so each part
reads in full; the text is unchanged. The linter ships as a zip, which the app
saves to disk whole so the session can run it.

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
- **Skipped steps:** which file is missing from the output folder, or which
  check the SELF-AUDIT says didn't run.
