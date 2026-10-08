# EML PraatGen v1.2.0 Release Notes

**1.2.0** (stable)  
**Release date:** 8 October 2026  
**Master Prompt:** 15.0.0  
**PKB snapshot:** 2026-10-08  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component      | This release | Previous (1.1.1) |
| -------------- | ------------ | ---------------- |
| Release        | **1.2.0**    | 1.1.1            |
| Master Prompt  | **15.0.0**   | 14.21.0          |
| PKB snapshot   | 2026-10-08   | 2026-09-29       |
| Praat floor    | 6.4.39       | 6.4.39           |
| Sandbox Praat  | 6.6.30       | 6.6.30           |
| Rules          | 37           | 37               |
| EML procedures | 263 across 15 files | 263 across 15 files |

Claude's chat and Cowork are now one app. A PraatGen session runs in a
workspace with a shell, file tools and, sometimes, a link to your computer.
Anthropic is rolling the change out in stages, so this release works in the
older setup and the newer one alike: PraatGen checks what the session can do
instead of assuming. Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

---

## Installing Praat for testing

PraatGen tries the Praat download page once, at the first moment it needs to
test something. If the page loads, it installs Praat. If the request is
refused, it quotes the refusal and offers the manual upload: you download the
Praat Linux archive and attach it. It no longer tells you testing is
unavailable without having tried.

Whether a session can reach `www.fon.hum.uva.nl` depends on your Claude plan
and settings, and those rules aren't fully documented. An individual Max
account reached the site by default when tested on 8 October 2026; other
plans are untested. On Team and Enterprise plans, the organization owner
controls which domains are allowed.

Before installing the graphical tools, PraatGen checks the operating system
and root access and tries the package install. If that fails, it installs the
barren edition of Praat and tells you what that leaves untested. The install
commands now apply the 6.6.30 version pin.

## Prefer Praat 6.6.30

When you install Praat for writing and testing scripts, prefer 6.6.30. Direct
downloads: [Mac](https://www.fon.hum.uva.nl/praat/praat6630_mac.dmg),
[Windows](https://www.fon.hum.uva.nl/praat/praat6630_win-x64v3.zip)
([ARM](https://www.fon.hum.uva.nl/praat/praat6630_win-arm64.zip)),
[Linux](https://www.fon.hum.uva.nl/praat/praat6630_linux-x64v3.tar.gz).

- No PraatGen feature requires 7.0.02 or later. The newest version-dependent
  feature PraatGen uses is already in 6.6.30, and the 7.0.01 and 7.0.02
  additions (the CPP object, `Sound: To CPP...`, Corpus and CGN extraction)
  aren't used anywhere in PraatGen.
- Praat 7.0.02 and later have a security feature that slows development. A
  script that writes a file or runs a system command stops to ask your
  permission, every run.
- Anything that runs on 6.6.30 also runs on the current version. On 7.x you
  answer the permission prompt and the script carries on.

Generated scripts still support Praat 6.4.39 and later.

## SANDBOX means every script is tested

With SANDBOX, PraatGen tests every script in Praat before delivering it,
including running it through its real dialogs. Without SANDBOX, it can still
install Praat when it needs to check a command.

## Delivery

A file counts as delivered only when PraatGen sends it to you; saving it in its
workspace isn't delivery. If a folder on your computer is connected to the
session, a script that comes with a library folder is written there with the
folder structure intact. Otherwise you get one self-contained script.

Test results name the platform and the Praat version they ran on. The Linux
workspace is the reference for a pass. Behavior that depends on the platform,
such as file dialogs, fonts, `Insert picture from file:` and Demo window size,
counts as verified only on the platform where it ran.

## Questions and checks

The pre-flight report, with its questions and the go-ahead gate, is the last
thing in its turn, so it can't be moved or buried. When PraatGen re-checks a
rule, it reads the whole reference file; a search result only finds the file.

Your account preferences and saved memory load into project sessions, and
preferences load even with memory switched off for a chat. Where they conflict
with PraatGen on format, length, gates or how questions are asked, PraatGen's
rules win.

## Models and subagents

A PraatGen session runs on Opus or higher; on Sonnet or Haiku it stops and asks
you to switch to Opus. An Opus session may hand specific
tasks to a subagent on a smaller model, and everything a subagent produces
goes through the session's own checks before it reaches you. Opus 4.8 is
treated as an effort model throughout.

## Reference correction

`COMMANDS_Table.txt`: `Formula:` on a Table takes the column name first,
then the formula. The reference listed it with one argument, which Praat
refuses.

---

## Upgrade notes

The Master Prompt has changed. Replace your project's instructions with
`MASTER_PROMPT_CORE_v15_0_0.md` and delete any older Master Prompt file. This
applies whatever version you are on now; to check, look for the version line
near the top of your project's instructions.

Replace the entire `pkb/` folder — 62 files. Delete the old folder rather than
overwriting into it.

Do not rename files; the Master Prompt references them by exact filename.

Re-run any script generated before 1.1.0 that uses a FormantPath: its F1 and F2
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
