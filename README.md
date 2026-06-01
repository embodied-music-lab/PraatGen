# ⚠️ Best practice: PraatGen was originally trained on Opus 4.6 with Extended Thinking. Opus 4.8 was recently released, and all signs indicate that it excels. Opus 4.7 really wants to behave agentically, which can be great for large-scale code refactors in AUTO SANDBOX mode. Always keep the model you are using in mind. It is a variable.

# NOTE: To start, all of the files you need are in the current zip folder.

# EML PraatGen

**Generate Praat scripts through conversation.**

PraatGen is a Claude AI project that writes syntactically correct Praat scripts from plain-language descriptions. You describe what you want to accomplish — extract F0 contours, batch-process a folder of recordings, build a publication figure, or generate a complex plugin — and PraatGen generates a complete, runnable script with validated commands, proper object handling, and clinical-grade parameter defaults. It can help you ideate your studies, debug its own or your existing code, and collaborate on your research and analysis projects.

While it is helpful to have domain knowledge about the signals you will bring into Praat, no Praat scripting experience is required. In fact, do not try to *think* like Praat. Praat has an object-oriented hierarchy; commands are connected to specific object types rather than organized by tasks or outcomes. Some of the most advanced and useful built-in functions are hidden in the menus by default, so it is likely that you do not even know what Praat is capable of.

Ask PraatGen questions. Push it to do what you want, not what you currently know how to do. In fact, you can ask it to do what you *wish* you knew how to do. Want to validate by generating confidence images of every nth measurement? Great. Ask it to wireframe the layout of any Picture window output. Create animations in the Demo window. Ask it to make art, or to imagine beautiful and elegant presentations of your data. PraatGen rewards divergent thinkers.

**Author:** Ian Howell, Embodied Music Lab — [www.embodiedmusiclab.com](http://www.embodiedmusiclab.com)
**Development:** Prompt engineering and code generation in collaboration with Claude (Anthropic)
**Version:** 0.9.3-beta.01
**Release:** 31 May 2026
**License:** Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab

---

## What PraatGen Does

PraatGen is not a plugin or a standalone application. It is a **Claude Project** — a structured prompt and a set of verified reference files that give Claude deep, accurate knowledge of Praat's scripting language. When you open a conversation in this project, Claude operates as a Praat scripting specialist that:

- **Validates every command** against source-verified reference files covering 136 object types and 3,000+ commands — not from memory, which is unreliable for Praat syntax
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
- **Claude model:** Claude Opus 4.8 is recommended. Opus 4.7 and 4.6 (with Extended Thinking) are also fine. See "Choosing a model" below.
- **Claude modality:** PraatGen presumes most users will use the Claude.ai web or desktop environment. It can be adapted for Claude Code by changing the Master Prompt's references to the PKB files so they point at a local directory; you may also want to separate the Master Prompt from your `CLAUDE.md` file.
- **Praat:** Version 6.4 or later (current stable release). Sandbox Mode pins Praat 6.4.65 for in-environment verification.

### Choosing a model

The model is a variable — keep the one you're using in mind.

- **Opus 4.8** is the current recommendation. It was recently released and, by all signs, excels at this work.
- **Opus 4.7** is also fine, but is more agentic by default — it wants to take initiative. That can be excellent for large-scale code refactors in AUTO SANDBOX mode; in close collaborative work, watch that it doesn't run ahead of your decisions.
- **Opus 4.6 + Extended Thinking** is the original training baseline for PraatGen and remains a solid choice.
- **Sonnet** may handle simpler scripts, but is not the default recommendation; command-verification reliability decreases with complexity, and silent failures are possible.

Extended Thinking helps with complex command planning; PraatGen will tell you during pre-flight when you can safely turn it off.

---

## Setup

### 1. Create a Claude Project

In Claude (claude.ai or the Claude app):
1. Open the sidebar and click **Projects**
2. Click **Create project**
3. Name it (e.g., "EML PraatGen")

### 2. Set the System Prompt

1. In your new project, click **instructions**
2. Paste the entire contents of `MASTER_PROMPT_CORE_v13.9.1.md` into the instructions field
3. Scroll to the bottom and edit the "Canary" text if you wish. PraatGen reports this value back to you in pre-flight as a confidence measure that it read the entire Master Prompt.
4. Save

### 3. Upload the Knowledge Base

1. In your project, click **add files**
2. Upload all files from the `pkb/` folder — these are the verified reference files PraatGen uses to validate commands and functions
3. Do not rename the files; the Master Prompt references them by their exact filenames

### 4. Start a Conversation

Open a new conversation within the project. PraatGen will respond with its readiness message and ask you to describe your task.

---

## How to Use PraatGen

### The Basic Workflow

0. **Verify your model and settings:** Opus 4.8 recommended (4.7 and 4.6 + ET also fine — see "Choosing a model"), with Extended Thinking on for non-trivial work.

1. **Describe your task.** PraatGen asks for four things:
   - What should the script accomplish?
   - What objects are open when the script runs?
   - What information does the script need from the user?
   - What should remain when the script finishes?

2. **Review the pre-flight.** PraatGen verifies it has the right references loaded and flags any ambiguities. It recommends a model tier and Extended Thinking settings. You approve this step or raise concerns.

3. **Reply EXECUTE (or GO).** PraatGen generates a command plan. There is an Extended Thinking gate after the plan — PraatGen tells you whether to keep ET on for code generation. Reply GO and it writes and delivers the script and a self-audit.

4. **Test in Praat.** Copy the script into Praat's script editor and run it. You can also ask PraatGen to present a downloadable `.praat` file in the chat. If it works, you're done.

5. **Report errors if any.** Paste the exact error message (with line number) and tell it you are debugging. PraatGen diagnoses before changing code — no guesswork fixes. You can also screenshot errors; Claude can read the images.

### Output verbosity (SPARSE / VERBOSE)

PraatGen runs in **SPARSE mode by default** — compressed pre-flights, command plans, and self-audits to conserve tokens. Reply **VERBOSE** at any execution gate for fully expanded output, and **SPARSE** to return to compressed. This affects scaffolding only; code, deviation justifications, and debugging hypotheses are never compressed.

### Modes

Reply with any of these in place of (or alongside) your task. Modes compose freely except where noted.

- **SCAFFOLD** — collaborative design review *before* any code. PraatGen walks through the proposed workflow, GUI design, object lifecycle, and edge cases for your approval. Best for batch pipelines, multi-panel figures, and clinical analysis chains.
- **DEBUGGING** — strict targeted-fix mode. Requires your approval for any change, declares the scope of each fix as a binding contract, and avoids elective refactoring. Use this for errors and refactors.
- **SANDBOX** — installs Praat (6.4.65) in Claude's own environment so it can verify commands and test scripts empirically before delivery, instead of asking you to paste verification snippets. Requires `www.fon.hum.uva.nl` in your account's allowed network domains (Settings → Capabilities → Allowed domains); this must be set *before* starting the conversation. PraatGen will tell you if the domain is missing and offer a manual-upload fallback.
- **AUTO** (Autonomous) — suppresses the approval gates and intermediate status reports for batch work: task lists, multi-file refactors, or known sequences of changes. PraatGen executes the whole list and delivers once at the end, with a handoff document. Reply STANDARD or GATES ON to restore normal gating.

**Composition examples:** `SANDBOX AUTO` (install Praat, work through a task list autonomously, test as it goes, deliver once), `SANDBOX DEBUGGING` (strict debugging with empirical verification on hand), `SCAFFOLD SANDBOX` (collaborative design with empirical checks). AUTO and DEBUGGING are mutually exclusive; if a bug surfaces mid-AUTO, PraatGen applies debugging discipline to that one item, then resumes.

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
| `MASTER_PROMPT_CORE_v13.9.1.md` | The system instructions that configure Claude as a Praat scripting specialist. Contains 37 rules governing syntax validation, command verification, clinical defaults, debugging protocol, sandbox/autonomous modes, and code-quality standards. Master Prompt content version: 13.9.1. |
| `README.md` | This file. |

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
| `PRAAT_DEFINITIVE_CATALOGUE.txt` | Complete Praat capability inventory — 136 object types, 3,000+ commands, 336 Formula functions — extracted from v6.4.62 source code. The fallback/verification source. |
| `WHITELIST_CURRENT.txt` | Recently verified commands not yet merged into the primary references |

**Drawing and methodology references:**

| File | Purpose |
|------|---------|
| `BEST_PRACTICES_DRAWING.txt` | Mandatory drawing patterns: Sound+TextGrid, viewport-before-save, stereo guard, text-label safety, spectrum/Ltas/PowerCepstrum axis alignment, accessible color palette (Okabe-Ito exact RGB) |
| `BEST_PRACTICES_CONFIDENCE_FIGURES.txt` | Guidelines for publication-quality statistical figures |
| `BEST_PRACTICES_DEMO_WINDOW.md` | Demo window layout, font-state, viewport, and animation best practices |
| `BEST_PRACTICES_AUTO_TEXTGRID_ANNOTATION.md` | Automatic TextGrid annotation, VAD-based segmentation, speech-to-text pipelines |
| `BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` | Plugin setup, menu/action registration, include-path resolution, conflict guards |
| `EML_PROCEDURE_GUIDE.md` | Methodology rules, test-selection logic, graph-type routing, script-generation/flattening model |
| `EML_PROCEDURE_REGISTRY.md` | Master index of the EML library procedures and which source file contains each |

**EML procedure source files** — Verified implementations that PraatGen reads as algorithmic templates. PraatGen emits flat, self-contained scripts inspired by these procedures — no `include` directives, no companion files:

| File | Coverage |
|------|----------|
| `eml-graph-procedures.praat` | Drawing core: adaptive theming, color palette, axes, gridlines, violin/box primitives, stereo handling |
| `eml-draw-procedures.praat` | Draw orchestrators: F0 contour, waveform, spectrum, LTAS, time series, bar, violin, box, scatter, histogram |
| `eml-annotation-procedures.praat` | Stats-to-graph bridge, brackets, comparison matrix, shared reporters |
| `eml-core-utilities.praat` | Vector operations: ranking, sorting, subsetting, z-scores, binning |
| `eml-core-descriptive.praat` | Descriptive statistics: mean, median, SD, quartiles, skewness, kurtosis, CI |
| `eml-extract.praat` | Table and acoustic-object data extraction |
| `eml-output.praat` | Formatted reporting: APA style, p-value formatting, CSV export |
| `eml-inferential.praat` | Inferential tests and guided test selection: t-tests, correlations, MWU, Wilcoxon, ANOVA, KW, post-hoc, p-value adjustment |
| `eml-graphs.praat` | Graphs entry point (loads the form system and draw layers) |
| `eml-graphs-form.praat` | Form system, guided statistical workflow, config persistence |
| `eml-vibrato-procedures.praat` | Vibrato detection, cycle analysis, summary statistics |
| `eml-demo-procedures.praat` | Demo window layout engine for interactive tutorials |
| `eml-batch-process.praat` | Batch infrastructure: file stamps, stop sentinel, unique-path generation |
| `eml-test-helpers.praat` | Test harness for procedure verification |

For the full procedure catalogue and signatures, see `EML_PROCEDURE_REGISTRY.md`.

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
| **Release** | 0.9.3-beta.01 | The combined package (prompt + PKB). This is the version that matters to users. |
| **Master Prompt** | 13.9.1 | The system instructions. Bumped when rules, workflow, or protocols change. |
| **PKB Snapshot** | 2026-05-31 | The reference file set. Date-stamped when files are added or revised. |

**Release versioning** follows semver conventions:
- **0.x.y** — Beta. Expect changes based on tester feedback.
- **1.0.0** — Stable release. Prompt and PKB verified across a broad range of scripting tasks.
- **x.y.z** — Major.Minor.Patch. Major = breaking workflow changes. Minor = new capabilities or reference files. Patch = corrections.

---

## Known Limitations (Beta)

**Reference coverage gaps.** The `COMMANDS_*.txt` files cover the most commonly used object types thoroughly but are not exhaustive for every parameter variant. The Definitive Catalogue (`PRAAT_DEFINITIVE_CATALOGUE.txt`) provides fallback coverage for all object types but with less contextual annotation. Gaps are filled as they're discovered — report them.

**EML Tools integration.** PraatGen generates flat scripts inspired by the EML library procedures. The EML Tools plugin itself is in pre-release and distributed separately.

**Extended Thinking management.** Complex scripts benefit significantly from Claude's Extended Thinking. The prompt includes gates that recommend when to enable or disable it, but the setting must be managed manually.

**Model dependency.** Sonnet is not recommended for advanced scripts. Opus 4.8 is the current recommendation; Opus 4.7 and 4.6 + ET also work well. Note that 4.7 is more agentic by default — strong for large-scale refactors in AUTO SANDBOX mode, but worth watching in close collaborative work. The model is a variable; keep the one you're using in mind.

**Sandbox prerequisites.** Sandbox Mode requires `www.fon.hum.uva.nl` in your allowed network domains, set *before* the conversation starts (the list is frozen at conversation start). If it's missing, PraatGen offers a manual-upload fallback.

**Context window limits.** Very long debugging sessions can exhaust the context window. PraatGen monitors this and offers handoff documents at the 3rd and 5th debugging iterations, but prevention (careful testing, exact error messages) is better than cure.

**No access to your environment.** Outside Sandbox Mode, PraatGen does not execute scripts; even in Sandbox Mode it runs Praat only in its own environment and never touches your files or installation. All scripts should be tested on representative data before use in research.

---

## Reporting Issues

During the beta period, report issues to Ian Howell at the Embodied Music Lab (www.embodiedmusiclab.com):

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
