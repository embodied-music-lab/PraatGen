# EML PraatGen v3.0.0 Release Notes

**3.0.0** (stable), a plugin for the Claude app  
**Release date:** 28 November 2026  
**Master Prompt:** 18.0.0  
**PKB snapshot:** 2026-11-28  
**Sandbox Praat:** 6.6.30 (pinned)  
**Praat version floor:** 6.4.39  
**License:** GPL-3.0-or-later — Ian Howell, Embodied Music Lab

| Component         | This release        | Previous (2.2.7) |
| ----------------- | ------------------- | ---------------- |
| Release           | **3.0.0**           | 2.2.7            |
| Runs as           | Claude plugin       | Claude project   |
| Master Prompt     | 18.0.0              | 17.1.7           |
| PKB snapshot      | 2026-11-28          | 2026-11-27       |
| PKB files         | 73                  | 66               |
| EML procedures    | 632 in 22 files     | 264 in 15 files  |
| Praat floor       | 6.4.39              | 6.4.39           |
| Sandbox Praat     | 6.6.30              | 6.6.30           |
| Rules             | 37                  | 37               |
| Recommended model | Opus 5              | Opus 5           |

Full version history is in `pkb/PRAATGEN_CHANGELOG.md`.

For PraatGen in a Claude project in the older format, use release 2.2.7.

---

## Running PraatGen

- **A plugin for the Claude app.** You install PraatGen from this repository's plugin marketplace, with no project to set up and no files to upload. With **Sync automatically** on, you get each fix without reinstalling.
- **Where it runs.** PraatGen runs in Claude app conversations and Cowork tasks. It can't start in an incognito chat, which has no file tools.
- **Ways to start.** Type / and choose praatgen, ask for PraatGen by name, or say yes when Claude suggests it. A message that asks for PraatGen by name and states the task, such as "Use PraatGen to measure jitter in these recordings", starts PraatGen and counts as your first message.
- **The suggestion.** When PraatGen isn't running and you ask for work in its areas, Claude replies with one line and waits: "PraatGen can help with this; start it by typing / and choosing praatgen, or tell me to go ahead without it." If you tell it to go ahead without PraatGen, it doesn't suggest it again in that session.
- **Turning it off.** Type PRAATGEN OFF anywhere in a message, in any capitalization, or use the off command. When you start PraatGen again later in the conversation, it reads its rules and returns to the current work without repeating the introduction.
- **Rules read each turn.** PraatGen reads its whole rules file from the plugin at the start of every turn, with the same scaffold exception as 2.x. The linter runs in place, with nothing to unzip.
- **Memory.** PraatGen never saves its rules, procedures, workarounds, findings or lessons to memory. It saves only a preference you state as your own way of working and ask it to keep.

## Commands

- **Every mode is a / menu command.** The / menu has scaffold, sandbox, auto, debugging, noreview, verbose, sparse, nointro, off and verify, which runs VERIFY YOUR STATE. Each command does exactly what its keyword does and starts PraatGen first if it isn't running, except off.
- **Modes combine however you give them.** Keywords typed after the praatgen pick, after a command, or several in one message apply together, such as SANDBOX AUTO NOINTRO followed by the task.
- **Only you run a mode command.** Claude can't run a mode command on its own.

## Opening

- **The introduction opens with how to turn PraatGen off.** The line on turning PraatGen off comes first, then the tagline.
- **A first message that states the task.** After the line on turning PraatGen off and the tagline, PraatGen restates the task, marks any item you didn't give as missing, and offers to go straight to the PRE-FLIGHT. With SCAFFOLD in the same message, the offer is the scaffold discussion; with AUTO, there's no offer; NOINTRO skips the short opening.
- **A first message that is a question.** PraatGen doesn't answer it yet. It replies "Would you like to build a script now? Or enter the scaffold command, and we can just talk about it." and waits.
- **A start from a yes.** The request you made with the yes, or before it, is your first message, so you don't repeat it. The first reply opens with the line on turning PraatGen off.

## Connected folders

- **Originals stay protected.** PraatGen never overwrites, renames, moves or deletes original recordings or other source data unless you ask in the conversation. It can change or reorganize other files in a connected folder when you ask or the task needs it, and new outputs still go in an output folder it names and asks about first.
- **Linking your computer.** When the session can't reach your computer, PraatGen offers the script-only route first. If you want it to work with your files itself, it tells you how to link the conversation from the + menu in the message box.
- **Asking for a folder.** When PraatGen can reach your computer and a folder would help, it asks for the narrowest folder itself.
- **Recordings of people in a folder connected later.** When you connect a folder holding recordings of people after the PRE-FLIGHT, PraatGen goes over the privacy precautions before it reads any of them.
- **Settings.** The privacy precautions list Ultra among the plans with a model-training setting.

## Scaffold

- **Scaffold answers measurement and settings questions.** A question such as which pitch floor to use for jitter on a bass gets answered in the discussion, from the reference file that covers it, read that turn. Only code waits until scaffold ends.
- **A question answered in scaffold.** When your first message asks a question and you choose scaffold, the scaffold discussion answers it.

## Reviews and delivery

- **Review.** The independent review uses one fixed prompt and reports findings only. PraatGen fixes only faults against the approved plan, and a fix that would change what the script does comes to you as a question before delivery.
- **Recommendations.** When PraatGen offers options, the one it recommends is the method the reference files give. It doesn't recommend a step they don't name, and says so when it mentions one.
- **Questions before delivery.** PraatGen asks each question only you can settle before it delivers the script, one per message, and waits for your answer. The delivery message never ends with questions.
- **Delivery.** PraatGen delivers only when `open_items.md` lists nothing it can still do, and states any limit of the environment with the delivery.
- **Test data offer.** The offer of synthetic test files is the same line in SPARSE and VERBOSE, so VERBOSE no longer closes the delivery with a question.
- **Audit files.** Each version of a script gets its own audit file, `<name>_audit_v<version>.md`, named with the version in the script header. Earlier audit files are never edited.
- **Test list.** In SANDBOX, PraatGen writes `<name>_testlist.md` before the first test run, covering every menu option, both states of every boolean, every pause-dialog button, every warning, every skip or threshold path, a file name with non-ASCII characters and, for a script that loops over files, a batch of 20 or more. The linter checks that every option, boolean and button appears in the list.
- **Recovery.** When PraatGen sees a conversation summary it hasn't checked against the output folder, it runs VERIFY YOUR STATE itself. You can still give the command at any time.

## Scripts

- **Text in CSV files.** Scripts write every text field in a CSV file in double quotes, with any quote inside it doubled, so a comma in a file name no longer shifts the columns. The linter blocks a file name, object name, TextGrid label or form text field joined bare to a "," separator in a line written to a file.
- **UTF-8 output.** Scripts that write file names, labels or your input to a file set Praat's text writing preference to UTF-8 first, so one non-ASCII character no longer turns the whole file into UTF-16.

## EML library

- **Synced with EML Stats & Graphs.** Twenty library files now come from the validated EML Stats & Graphs plugin, for 632 procedures across 22 files. `EML_PROCEDURE_REGISTRY.md` lists every one. A validation paper for EML Stats & Graphs is in process.
- **New files.** `eml-record.txt`, `eml-result-writer.txt`, `eml-report.txt`, `eml-studentized-range.txt`, `eml-wilcoxon-interval.txt`, `eml-anova-kernel.txt`, `eml-categorical.txt` and `eml-psychometrics.txt` join the PKB, and `EML_PROCEDURE_GUIDE.md` section 5.8 describes each. `eml-test-helpers.txt` is gone.
- **CSV results.** Statistics export as tidy long-format CSV rows, and `eml-result-writer.txt` writes broom-style tidy, glance and augment files. The Info-window reporters moved to `eml-report.txt` under the same names.
- **PraatGen's fixes kept.** Tick marks, gridlines, scatter markers, LTAS curves and box-plot outliers still draw on reversed axes, and stereo dialogs still list Left, Right, Mix with Left as the default. Every CSV text field the library writes is quoted. None of these edits touches a statistics procedure.
- **Praat 6.4.39.** The library's statistics, CSV export and drawing procedures gave the same results on Praat 6.4.39 and 6.6.30.

---

## Install / upgrade notes

PraatGen 3.0.0 doesn't use a Claude project. If you're coming from a 2.2.7 project:

1. In Claude, go to **Customize > Plugins > Add > Add marketplace** and enter `embodied-music-lab/PraatGen`. Install PraatGen, and turn on **Sync automatically** so you get each fix.
2. Choose Opus 5 in the conversation's model menu.
3. Type / and choose praatgen, or ask for PraatGen by name.

**Alternative install.** Download [`praatgen.plugin`](https://github.com/embodied-music-lab/PraatGen/releases/latest/download/praatgen.plugin) from the release and use **Customize > Plugins > Add > Upload plugin**. An uploaded copy doesn't update itself.

On a Team or Enterprise plan, the organization owner's "User-created skills" setting can hide the option to add a plugin.

You don't upload `pkb/` or paste `PROJECT_INSTRUCTIONS.txt` anywhere; the plugin carries them. Your 2.2.7 project keeps working with release 2.2.7.

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
