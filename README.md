⚠️ Best practice: PraatGen is structured to work within the claude.ai project framework. All LLMs are not equal in training or their harnesses. PraatGen's structure will NOT work if ported directly over to another LLM, if the PKB is flattened, or if the master prompt instructions are fed in once. If you would like to work on a port reach out and I'll be happy to answer structural questions. Any errors arising from off-label use are to be expected. 
PraatGen was originally trained on Opus 4.6 with Extended Thinking. All signs indicate that Opus 4.8 at high effort excels. Opus 4.7 really wants to behave agentically, and has been superseded by Opus 5. I am currently using Opus 5 most of the time and so far it works well. Always keep the model you are using in mind. It is a variable.

# EML PraatGen

**Generate Praat scripts through conversation.**

PraatGen is a Claude AI project that writes syntactically correct Praat scripts from plain-language descriptions. You describe what you want to accomplish — extract F0 contours, batch-process a folder of recordings, build a publication figure, or generate a complex plugin — and PraatGen generates a complete, runnable script with validated commands, proper object handling, and clinical-grade parameter defaults. It can help you ideate your studies, debug its own or your existing code, and collaborate on your research and analysis projects.

While it is helpful to have domain knowledge about the signals you will bring into Praat, no Praat scripting experience is required. In fact, do not try to *think* like Praat. Praat has an object-oriented hierarchy; commands are connected to specific object types rather than organized by tasks or outcomes. Some of the most advanced and useful built-in functions are hidden in the menus by default, so it is likely that you do not even know what Praat is capable of.

Ask PraatGen questions. Push it to do what you want, not what you currently know how to do. In fact, you can ask it to do what you *wish* you knew how to do. Want to validate by generating confidence images of every nth measurement? Great. Ask it to wireframe the layout of any Picture window output. Create animations in the Demo window. Ask it to make art, or to imagine beautiful and elegant presentations of your data. PraatGen rewards divergent thinkers.

**Author:** Ian Howell, Embodied Music Lab — [www.embodiedmusiclab.com](http://www.embodiedmusiclab.com)
**Development:** Prompt engineering and code generation in collaboration with Claude (Anthropic)
**Version:** 1.1.0
**Release:** 23 September 2026
**License:** Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab

---

## What PraatGen Does

PraatGen is not a plugin or a standalone application. It is a **Claude Project** — a structured prompt and a set of verified reference files that give Claude deep, accurate knowledge of Praat's scripting language. When you open a conversation in this project, Claude operates as a Praat scripting specialist that:

- **Validates every command** against source-verified reference files covering 136 object types and 3,300+ registered commands — not from memory, which is unreliable for Praat syntax
- **Uses clinically validated defaults** for voice analysis parameters (pitch tracking, jitter, shimmer, HNR, CPPS, formants), sourced from published norms
- **Handles Praat's idiosyncrasies** — selection discipline, object identity, time-domain queries, string typing, variable derivation from dialog labels, and dozens of other gotchas that trip up even experienced scripters
- **Follows a structured workflow** with pre-flight verification, command planning, and self-audit — catching errors before they reach Praat
- **Generates complete scripts** with headers, attribution, input validation, plausibility checks, and proper file I/O
- **Can verify itself empirically** by installing Praat in its own sandbox to test commands and run scripts before delivery (see Sandbox Mode)

### What It Does Not Do

- By default, PraatGen does not run your scripts on your machine — you copy the generated script into Praat's script editor and run it there. (In Sandbox Mode, Claude can install and run Praat in *its own* environment for verification, but it still has no access to your files or your Praat installation.)
- PraatGen does not have access to your audio files or your local Praat installation. It generates code based on your description.
- PraatGen is not infallible. It follows a rigorous verification protocol, but novel edge cases can still produce errors. Always test generated scripts on your data before using them in research.

---

## Requirements

- **Claude Pro, Team, Max, or Enterprise account** (Projects require a paid plan). PraatGen can burn tokens quickly on complex projects; for serious code production, the Max plan is recommended.
- **Other AI options:** As of mid-2026, no other frontier model accommodates the modular design of PraatGen. Use with ChatGPT, Gemini, etc. is untested and unsupported — no guarantees.
- **Claude model:** Claude Opus 5 is the current recommendation; Opus 4.8 also performs well. Opus 4.6 (with Extended Thinking) remains a solid token-conscious choice. Sonnet and Haiku are not supported. See "Choosing a model" below.
- **Claude modality:** PraatGen presumes most users will use the Claude.ai web or desktop environment. It can be adapted for Claude Code by changing the Master Prompt's references to the PKB files so they point at a local directory; you may also want to separate the Master Prompt from your `CLAUDE.md` file.
- **Praat:** Version 6.4 or later (current stable release). Sandbox Mode installs the current stable Praat build, resolved at fetch time (no pinned version), for in-environment verification.

### Choosing a model

The model is a variable — keep the one you're using in mind.

- **Opus 5** is the current recommendation and what the author uses most of the time.
- **Opus 4.8** also performs well.
- **Opus 4.7** is fine but more agentic by default; it wants to take initiative. That suits large-scale refactors in AUTO SANDBOX mode, but in close collaborative work watch that it doesn't run ahead of your decisions. Superseded by Opus 5.
- **Opus 4.6 + Extended Thinking** is the original development-and-validation baseline for PraatGen and remains solid, particularly if you are token-conscious.
- **Sonnet and Haiku are not supported.** Simple scripts may succeed, but command-verification reliability decreases with complexity and silent failures are possible.

**A note on thinking and effort.** Extended thinking as a user-facing on/off toggle was retired in Opus 4.8. On 4.6/4.7, where the toggle still exists, PraatGen will tell you during pre-flight when you can safely turn thinking off. On 4.8 and later, the same pre-flight and Phase 3B assessments read as effort guidance instead — and that guidance is provisional, so take it as a starting point rather than a rule:

- Currently there does not appear to be an advantage to setting effort higher than the default ("high").
- Setting it higher can actually derail a project, largely through context exhaustion.
- There is some evidence that effort may be set lower once the command plan is established.

Please experiment with this setting and find what works best for your own workflows. As better evidence accumulates this guidance will get sharper.

---

## Setup

### 1. Create a Claude Project

In Claude (claude.ai or the Claude app):
1. Open the sidebar and click **Projects**
2. Click **Create project**
3. Name it (e.g., "EML PraatGen")

### 2. Set the System Prompt

1. In your new project, click **instructions**
2. Paste the entire contents of `MASTER_PROMPT_CORE_v14_21_0.md` into the instructions field
3. Scroll to the bottom and edit the "Canary" text if you wish. PraatGen reports this value back to you in pre-flight as a confidence measure that it read the entire Master Prompt.
4. Save

### 3. Upload the Knowledge Base

1. In your project, click **add files**
2. Upload all 61 files from the `pkb/` folder — these are the verified reference files PraatGen uses to validate commands and functions
3. Do not rename the files; the Master Prompt references them by their exact filenames

### 4. Start a Conversation

Open a new conversation within the project. PraatGen will respond with its readiness message and ask you to describe your task.

---

## How to Use PraatGen

### The Basic Workflow

0. **Verify your model and settings:** Opus 5 recommended (4.8 also strong; 4.6 with Extended Thinking fine — see "Choosing a model"). Default effort ("high") is a sensible starting point; see the note on thinking and effort.

1. **Describe your task.** PraatGen asks for four things:
   - What should the script accomplish?
   - What objects are open when the script runs?
   - What information does the script need from the user?
   - What should remain when the script finishes?

2. **Review the pre-flight.** PraatGen verifies it has the right references loaded and flags any ambiguities. It notes a model tier and, where relevant, thinking or effort settings. You approve this step or raise concerns.

3. **Reply EXECUTE (or GO).** PraatGen generates a command plan, then scores its complexity. On 4.6/4.7 that is a gate: it tells you whether to keep Thinking on for code generation and waits for GO. On 4.8+ it is advisory — a one-line note on whether the plan looks complete enough that a lower effort setting may serve — and generation continues in the same turn.

4. **Test in Praat.** PraatGen delivers the script as a downloadable `.praat` file rather than a code block — open it in Praat's script editor and run it. (The file matters: copying source out of a rendered code block can substitute curly quotes and en-dashes for the plain characters Praat needs.) If it works, you're done.

5. **Report errors if any.** Paste the exact error message (with line number) and tell it you are debugging. PraatGen diagnoses before changing code — no guesswork fixes. You can also screenshot errors; Claude can read the images.

### Output verbosity (SPARSE / VERBOSE)

PraatGen runs in **SPARSE mode by default** — compressed pre-flights, command plans, and self-audits to conserve tokens. Reply **VERBOSE** at any execution gate for fully expanded output, and **SPARSE** to return to compressed. This affects scaffolding only; code, deviation justifications, and debugging hypotheses are never compressed.

### Modes

Reply with any of these in place of (or alongside) your task. Modes compose freely except where noted.

- **SCAFFOLD** — collaborative design review *before* any code. PraatGen walks through the proposed workflow, GUI design, object lifecycle, and edge cases for your approval. Best for batch pipelines, multi-panel figures, and clinical analysis chains.
- **DEBUGGING** — strict targeted-fix mode. Requires your approval for any change, declares the scope of each fix as a binding contract, and avoids elective refactoring. Use this for errors and refactors.
- **SANDBOX** — installs the current stable Praat build in Claude's own environment so it can verify commands and test scripts empirically before delivery, instead of asking you to paste verification snippets. Requires `www.fon.hum.uva.nl` in your account's allowed network domains (Settings → Capabilities → Allowed domains); this must be set *before* starting the conversation. PraatGen will tell you if the domain is missing and offer a manual-upload fallback.
- **AUTO** (Autonomous) — suppresses the approval gates and intermediate status reports for batch work: task lists, multi-file refactors, or known sequences of changes. PraatGen executes the whole list and delivers once at the end, with a handoff document. Reply STANDARD or GATES ON to restore normal gating.
- **NOINTRO** — put this in your *first* message to skip the opening menu. PraatGen goes straight to PRE-FLIGHT if you have supplied the four items (task, starting state, inputs, outputs), and otherwise asks only for what is missing. It suppresses the greeting and nothing else — every rule still applies.

**Composition examples:** `SANDBOX AUTO` (install Praat, work through a task list autonomously, test as it goes, deliver once), `SANDBOX DEBUGGING` (strict debugging with empirical verification on hand), `SCAFFOLD SANDBOX` (collaborative design with empirical checks). AUTO and DEBUGGING are mutually exclusive; if a bug surfaces mid-AUTO, PraatGen applies debugging discipline to that one item, then resumes.

### Work survives a long session: the output folder

**PraatGen writes as it goes.** The current script, test results, and open items are
kept in its output folder and updated in the same turn as the work that changed them
— not held in the conversation to be restated later. The folder survives both a
context compaction and a page reload, so there is always a current copy to come back
to that does not depend on anything being remembered.

You get the finished script as a downloadable `.praat` file (step 4 above). That
delivery is for you; the folder is what PraatGen reads back from. You can ask for
anything in it at any point.

### When you see "compacting", or after a reload or error: VERIFY YOUR STATE

Long conversations get **compacted** — Claude replaces the earlier part of the
conversation with a summary, and you see the word "compacting" while it happens.
Sessions also get interrupted: an error telling you to reload the page, a response
that fails partway and regenerates, a long gap before you come back. In any of
these, work rebuilt from memory can quietly lose corrections you already made.

**Say `VERIFY YOUR STATE`.** PraatGen re-reads what is actually saved in its output
folder — the current script, notes, open items — and reports where that disagrees
with its own recollection, before touching anything. The saved file wins: it
reconciles by reading, and never regenerates delivered work from memory. In Sandbox
Mode it also checks whether its Praat environment is still alive, since a reload can
coincide with the container being recycled.

Use it whenever you are unsure what landed. The command is yours to give, because
PraatGen cannot reliably tell from the inside that anything happened.

### Tips for Best Results

- **Be specific about your starting state.** "I have a Sound and TextGrid open" is much better than "I have some files."
- **State your output format.** "Results in the Info window as a tab-delimited table" vs. "save to CSV" produce different scripts.
- **Mention your voice type or analysis context.** PraatGen adjusts pitch-tracking parameters for speech vs. singing, and clinical vs. research contexts. (Singing above ~C4, in particular, needs a raised pitch ceiling/top — tell it the range.)
- **Paste exact error messages.** Include the line number. PraatGen's debugging protocol depends on precise error information.
- **Verify everything.** Ask PraatGen to review scripts it provides and to look for errors or inelegant solutions. Some projects are large enough that it makes sense to spend a session planning, take a handoff document, and write the code in a fresh session.
- **Accessible color palettes.** When generating multi-color figures, PraatGen asks if you want an accessible palette (Okabe-Ito, safe for color-vision deficiency). The exact RGB values are loaded from the PKB, not approximated. B/W with line-style redundancy is also available.

---

## What's in the Box

### Top-level files

| File | Purpose |
|------|---------|
| `MASTER_PROMPT_CORE_v14_21_0.md` | The system instructions that configure Claude as a Praat scripting specialist. Contains 37 rules governing syntax validation, command verification, clinical defaults, debugging protocol, sandbox/autonomous modes, and code-quality standards. Master Prompt content version: 14.21.0. |
| `README.md` | This file. |
| `RELEASE_NOTES_1.1.0.md` | What changed in this release and the upgrade notes. Read the upgrade notes before replacing an existing installation. Also published as the body of the v1.1.0 GitHub Release. |
| `LICENSE` | GPL-3.0-or-later. |

### Project Knowledge Base (PKB)

The `pkb/` folder contains the verified reference files. These are PraatGen's source of truth — Claude checks commands and functions against these files rather than relying on its training data, which is unreliable for Praat syntax.

**Command references** — Verified syntax for every command PraatGen generates:

| File | Coverage |
|------|----------|
| `COMMANDS_Sound.txt` | Sound creation, queries, modification, conversion, drawing |
| `COMMANDS_TextGrid.txt` | TextGrid creation, queries, modification, drawing |
| `COMMANDS_Pitch.txt` | Pitch analysis and queries |
| `COMMANDS_Formant.txt` | Formant analysis and queries (Formant, FormantPath, FormantModeler) |
| `COMMANDS_Intensity.txt` | Intensity analysis and queries |
| `COMMANDS_Spectrum.txt` | Spectrum analysis |
| `COMMANDS_Spectrogram.txt` | Spectrogram analysis and painting |
| `COMMANDS_Harmonicity.txt` | Harmonicity (HNR) analysis |
| `COMMANDS_PointProcess.txt` | PointProcess, jitter, shimmer |
| `COMMANDS_PowerCepstrogram.txt` | Cepstral analysis and CPPS |
| `COMMANDS_Table.txt` | Table creation and manipulation |
| `COMMANDS_Strings.txt` | Strings objects and file lists |
| `COMMANDS_Manipulation.txt` | Pitch/duration resynthesis |
| `COMMANDS_PitchTier.txt` | PitchTier objects |
| `COMMANDS_IntensityTier.txt` | IntensityTier objects |
| `COMMANDS_DurationTier.txt` | DurationTier objects |
| `COMMANDS_AmplitudeTier.txt` | AmplitudeTier objects |
| `COMMANDS_FormantGrid.txt` | FormantGrid objects |
| `COMMANDS_Ltas.txt` | Long-term average spectrum |
| `COMMANDS_LongSound.txt` | LongSound objects |
| `COMMANDS_Electroglottogram.txt` | EGG analysis |
| `COMMANDS_SpeechRecognizer.txt` | Whisper ASR and speech recognition |
| `COMMANDS_SpeechSynthesizer.txt` | eSpeak synthesis, forced alignment, IPA transcription, KlattGrid |
| `COMMANDS_Editor.txt` | Editor scripting: `editor:`/`endeditor`, mute channels, display/analysis configuration, cursor and selection queries |
| `COMMANDS_DemoWindow.txt` | Demo window interactive applications |
| `COMMANDS_PictureWindow.txt` | Picture window drawing commands |
| `COMMANDS_Universal.txt` | Commands common to all object types |

**Appendices** — Specialized references:

| File | Purpose |
|------|---------|
| `APPENDIX_B_FUNCTIONS.txt` | All Praat scripting functions — rebuilt from the official Praat Functions manual page + `Formula.cpp` source verification |
| `APPENDIX_C_GUI.txt` | Form and dialog syntax (`form`/`endform`, `beginPause`/`endPause`) |
| `APPENDIX_D_CLINICAL_DEFAULTS.txt` | Clinically validated parameter sets for voice analysis |
| `APPENDIX_E_SPECIAL_CHARACTERS.txt` | Special-character encoding for Picture/Demo window text |
| `APPENDIX_F_UX_STANDARDS.txt` | UX standards for script dialogs, file output, and batch processing |

**Verification and capability references:**

| File | Purpose |
|------|---------|
| `PRAAT_VERSION_FLOOR.txt` | The Praat 6.4.39 version floor, which features are known to need something newer, and which are verified safe at the floor |
| `PRAAT_DEFINITIVE_CATALOGUE.txt` | Complete Praat capability inventory — 136 object types, 3,300+ registered commands (2,536 single-class + 405 cross-class + 364 menu), 365 Formula engine functions — extracted from v6.4.62 source code. The fallback/verification source; carries a staleness banner and known-gap list. |
| `WHITELIST_CURRENT.txt` | Recently verified commands not yet merged into the primary references |

**Drawing and methodology references:**

| File | Purpose |
|------|---------|
| `BEST_PRACTICES_DRAWING.txt` | Mandatory drawing patterns: Sound+TextGrid, viewport-before-save, stereo guard, text-label safety, spectrum/Ltas/PowerCepstrum axis alignment, accessible color palette (Okabe-Ito exact RGB) |
| `BEST_PRACTICES_CONFIDENCE_FIGURES.txt` | Guidelines for publication-quality statistical figures |
| `BEST_PRACTICES_DEMO_WINDOW.md` | Demo window layout, font-state, viewport, and animation best practices |
| `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` | Contact quotient from EGG: the three CQ methods and when each is valid, EGG signal-to-noise measurement, method selection by phonation task, and the mandatory segfault guard. Co-loads with `COMMANDS_Electroglottogram.txt` |
| `BEST_PRACTICES_AUTO_TEXTGRID_ANNOTATION.md` | Automatic TextGrid annotation, VAD-based segmentation, speech-to-text pipelines |
| `BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` | Plugin setup, menu/action registration, include-path resolution, conflict guards, naming registers, packaging and the install folder name |
| `EML_PROCEDURE_GUIDE.md` | Methodology rules, test-selection logic, graph-type routing, script-generation/flattening model |
| `EML_PROCEDURE_REGISTRY.md` | Master index of the EML library procedures and which source file contains each |

**EML procedure source files** — Verified implementations that PraatGen reads as algorithmic templates. PraatGen emits flat, self-contained scripts inspired by these procedures — no `include` directives, no companion files:

| File | Coverage |
|------|----------|
| `eml-graph-procedures.txt` | Drawing core: adaptive theming, color palette, axes, gridlines, violin/box primitives, stereo handling |
| `eml-draw-procedures.txt` | Draw orchestrators: F0 contour, waveform, spectrum, LTAS, time series, bar, violin, box, scatter, histogram |
| `eml-annotation-procedures.txt` | Stats-to-graph bridge, brackets, comparison matrix, shared reporters (incl. regression and normality reports) |
| `eml-core-utilities.txt` | Vector operations: ranking, sorting, subsetting, z-scores, binning |
| `eml-core-descriptive.txt` | Descriptive statistics: mean, median, SD, quartiles, skewness, kurtosis, CI, Shapiro-Wilk |
| `eml-extract.txt` | Table and acoustic-object data extraction; column-role inference |
| `eml-output.txt` | Formatted reporting: APA style, p-value formatting, CSV export, dialog wrappers, plain-language explanations |
| `eml-inferential.txt` | Inferential tests: t-tests, correlations, MWU, Wilcoxon, ANOVA, KW, post-hoc, p-adjustment, OLS and Theil-Sen regression |
| `eml-analysis.txt` | High-level `@emlRun*Analysis` dispatchers — the layer the menu wrappers call |
| `eml-graphs.txt` | Graphs entry point (loads the form system and draw layers) |
| `eml-graphs-form.txt` | Form system, guided statistical workflow, config persistence |
| `eml-vibrato-procedures.txt` | Vibrato detection, cycle analysis, summary statistics, 8-panel publication figure |
| `eml-batch-process.txt` | Batch infrastructure: file stamps, stop sentinel, unique-path generation |
| `eml-egg-procedures.txt` | EGG support: mandatory cycle guard (segfault protection) |
| `eml-test-helpers.txt` | Test harness for procedure verification |

These are flattened `.txt` copies of the plugin tree's `.praat` sources; the
`include ../graphs/….praat` lines and the registry's `**File:**` paths refer to
the plugin layout, not to the flat PKB. For the full procedure catalogue and signatures, see `EML_PROCEDURE_REGISTRY.md` (263 procedures across 15 files).

Each PKB source carries the **plugin's** version number verbatim. If a PKB file's version differs from the plugin file it was copied from, the PKB has drifted and should be re-synced.

**Workflow support:**

| File | Purpose |
|------|---------|
| `HANDOFF_TEMPLATE.md` | Template for session handoff documents during long sessions and debugging |
| `DEVELOPER_MODE_ADDON.md` | Developer-mode extensions for EML Tools contributors |
| `praatgen_references_complete.md` | Full bibliographic reference list for all works cited across the prompt, appendices, and procedure libraries |
| `PRAATGEN_CHANGELOG.md` | Master Prompt version history, newest-first |

---

## Versioning

PraatGen tracks three version numbers:

| Component | Current | What it tracks |
|-----------|---------|----------------|
| **Release** | 1.1.0 | The combined package (prompt + PKB). This is the version that matters to users. Tracked separately from the Master Prompt version. |
| **Master Prompt** | 14.21.0 | The system instructions. Bumped when rules, workflow, or protocols change. |
| **PKB Snapshot** | 2026-09-23 | The reference file set. Date-stamped when files are added or revised. |

**Release versioning** follows semver conventions:
- **x.y.z** — Major.Minor.Patch. Major = breaking workflow changes. Minor = new capabilities or reference files. Patch = corrections.
- The **Release** number and the **Master Prompt** number are independent tracks. The release covers the whole package; the Master Prompt number covers the instruction set inside it. Both are stated on every release so a bug report is unambiguous.
- **1.1.0 (23 September 2026)** is the current stable release. It ships Master Prompt 14.21.0. FormantPath analysis now reads the selected candidate by querying Get optimal ceiling and applying it with a fresh To Formant (burg); Extract Formant on a FormantPath returned the middle-ceiling candidate rather than the optimal one, and generated scripts no longer call it. Circle drawing on a chart with a reversed axis — vowel charts, by convention — now uses Paint circle (mm): / Draw circle (mm):, since the world-coordinate forms render nothing and raise no error there. The function reference entry for upperCase$ (string$) now states its real boundary — absent on Praat 6.4.39 and earlier, available from 6.4.46 — replacing the earlier unconfirmed report of it failing in procedure context.
- **1.0.6 (21 September 2026)** shipped Master Prompt 14.20.0. Library procedures copied into a generated script are renamed to the `emlPG` prefix so they cannot collide with the plugin; the sandbox Praat version is pinned to 6.6.30; the function reference gains the matrix division and comparison forms; the plugin reference gains naming registers, packaging rules and corrected install paths.
- **1.0.5 (5 August 2026)** shipped Master Prompt 14.17.0. The Praat version floor moved to 6.4.39; the version check emitted into a script names the specific calls that will stop it or return different numbers on the user's build; spectrum, Ltas and PowerCepstrum patterns place ticks with the nice-number procedures.
- **1.0.4 (31 July 2026)** shipped Master Prompt 14.12.0, folded in the 30 July benchmark dry-run fixes, and added the Praat 6.4.15 version floor with a non-blocking update prompt. The PKB was reconciled against the EML plugin source, the procedure registry updated from that source, and every library file syntax-checked against Praat 6.6.30.
- Changes landing on `main` after a release are described in `pkb/PRAATGEN_CHANGELOG.md`; the release notes describe cut releases only.

---

## Known Limitations

**Reference coverage gaps.** The `COMMANDS_*.txt` files cover the most commonly used object types thoroughly but are not exhaustive for every parameter variant. The Definitive Catalogue (`PRAAT_DEFINITIVE_CATALOGUE.txt`) provides fallback coverage for all object types but with less contextual annotation. Gaps are filled as they're discovered — report them.

**EML Tools integration.** PraatGen generates **self-contained** scripts. Where it uses an EML library procedure, the procedure body is copied into the delivered script (or into a folder shipped alongside it) — generated code never `include`s the plugin, and you are never assumed to have it installed. The EML Tools plugin itself is distributed separately.

**Thinking / effort management.** Complex scripts benefit from deliberation, and the prompt includes gates that assess it — but the setting is yours to manage manually, and on 4.8+ the guidance is provisional (see "Choosing a model").

**Model dependency.** Sonnet and Haiku are not supported for advanced scripts. Opus 5 is the current recommendation; Opus 4.8 also performs well, and 4.6 with Extended Thinking remains solid. Note that 4.7 is more agentic by default — strong for large-scale refactors in AUTO SANDBOX mode, but worth watching in close collaborative work. The model is a variable; keep the one you're using in mind.

**Sandbox prerequisites.** Sandbox Mode requires `www.fon.hum.uva.nl` in your allowed network domains, set *before* the conversation starts (the list is frozen at conversation start). If it's missing, PraatGen offers a manual-upload fallback.

**Context window limits.** Very long debugging sessions can exhaust the context window. PraatGen monitors this and offers handoff documents at the 3rd and 5th debugging iterations, but prevention (careful testing, exact error messages) is better than cure.

**No access to your environment.** Outside Sandbox Mode, PraatGen does not execute scripts; even in Sandbox Mode it runs Praat only in its own environment and never touches your files or installation. All scripts should be tested on representative data before use in research.

---

## Reporting Issues

Report issues to Ian Howell at the Embodied Music Lab (www.embodiedmusiclab.com):

- **Script errors:** Include the task description, the generated script, and the exact Praat error message with line number.
- **Reference gaps:** If PraatGen can't find a command it should know about, note the object type and command name.
- **Workflow friction:** If the structured workflow feels cumbersome for your use case, describe what you'd prefer.

---

## Attribution

If PraatGen contributes to published research, please cite:

> Howell, I. (2026). EML PraatGen [Computer software]. Embodied Music Lab. www.embodiedmusiclab.com

And disclose AI use per your target journal's policy. Suggested language:

> "Praat scripts were developed using EML PraatGen (Howell, Embodied Music Lab) with code generation by Claude (Anthropic). All scripts were reviewed, tested, and validated by [your name]."

---

## License

Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
