# NOTE: To start, all of the files you need are in the current zip folder

# EML PraatGen

**Generate Praat scripts through conversation.**

PraatGen is a Claude AI project that writes syntactically correct Praat scripts from plain-language descriptions. You describe what you want to accomplish — extract F0 contours, batch-process a folder of recordings, build a publication figure, or generate a complex plugin — and PraatGen generates a complete, runnable script with validated commands, proper object handling, and clinical-grade parameter defaults. It can help you ideate your studies, debug its own or your existing code, and collaborate on your research and analysis projects.

While it is helpful to have domain knowledge about the signals you will bring into Praat, no Praat scripting experience required. In fact, do not try to *think* like Praat. Praat has an object-oriented hierarchy; commands are connected to specific object types rather than organized by tasks or outcomes. Some of the most advanced and useful built-in functions are hidden in the menus by default, so it is likely that you do not even know what Praat is capable of. 

Ask PraatGen questions. Push it to do what you want, not what you currently know how to do. In fact, you can ask it to do what you *wish* you knew how to do. Want to validate with confidence generating images of every nth measurement, great. Ask it to wireframe the layout of any picture window output. Create animations in the demo window. Ask it to make art or to imagine beautiful and elegant presentations of your data. PraatGen rewards divergent thinkers.

**Author:** Ian Howell, Embodied Music Lab — [www.embodiedmusiclab.com](http://www.embodiedmusiclab.com)  
**Development:** Prompt engineering and code generation in collaboration with Claude (Anthropic)  
**Version:** 0.9.0-beta.1  
**Release date:** 3 April 2026  
**License:** Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab

---

## What PraatGen Does

PraatGen is not a plugin or a standalone application. It is a **Claude Project** — a structured prompt and a set of verified reference files that give Claude deep, accurate knowledge of Praat's scripting language. When you open a conversation in this project, Claude operates as a Praat scripting specialist that:

- **Validates every command** against source-verified reference files covering 136 object types and 3,170+ commands — not from memory, which is unreliable for Praat syntax
- **Uses clinically validated defaults** for voice analysis parameters (pitch tracking, jitter, shimmer, HNR, CPPS, formants), sourced from published norms
- **Handles Praat's idiosyncrasies** — selection discipline, object identity, time-domain queries, string typing, variable derivation from dialog labels, and dozens of other gotchas that trip up even experienced scripters
- **Follows a structured workflow** with pre-flight verification, command planning, and self-audit — catching errors before they reach Praat
- **Generates complete scripts** with headers, attribution, input validation, plausibility checks, and proper file I/O

### What It Does Not Do

- PraatGen does not run Praat scripts. You copy the generated script into Praat's script editor and run it there.
- PraatGen does not have access to your audio files or Praat installation. It generates code based on your description.
- PraatGen is not infallible. It follows a rigorous verification protocol, but novel edge cases can still produce errors. Always test generated scripts on your data before using them in research.

---

## Requirements

- **Claude Pro, Team, or Enterprise account** (Projects require a paid plan). Note that PraatGen can burn tokens quickly on complex projects. You may want to at least use the Max plan (currently $100/month) for serious code production.
- **Other AI options:** As of early April 2026, no other frontier model accommodates the modular design of PraatGen. I do not endorse using ChatGPT, Gemini, etc. They have not been tested and I make no guarantees. 
- **Claude model:** Claude Opus 4.6 or later with Extended Thinking enabled. Sonnet may handle simpler scripts but is not the default recommendation. See the model guidance PraatGen provides during pre-flight.
- **Claude modality:** PraatGen presumes that most users will use the Claude.ai or desktop environment. It can be modified to use with Claude Code by changing references to the pkb (project knowledge base) files in the Master Prompt to the local directory. You may also want to separate the Master Prompt file from your `CLAUDE.md` file. 
- **Praat:** Version 6.4 or later (current stable release)

---

## Setup

### 1. Create a Claude Project

In Claude (claude.ai or the Claude app):
1. Open the sidebar and click **Projects**
2. Click **Create project**
3. Name it (e.g., "EML PraatGen")

### 2. Set the System Prompt

1. In your new project, click **Set custom instructions**
2. Paste the entire contents of `MASTER_PROMPT_CORE_v13.md` into the instructions field
3. Scroll to the bottom and edit the "Canary" text if you wish. It will present this text to you as a confidence measure that PraatGen read the entire master prompt file.
4. Save

### 3. Upload the Knowledge Base

1. In your project, click **Add project knowledge**
2. Upload all files from the `pkb/` folder — these are the verified reference files that PraatGen uses to validate commands and functions
3. Do not rename the files; the master prompt references them by their exact filenames

### 4. Start a Conversation

Open a new conversation within the project. PraatGen will respond with its readiness message and ask you to describe your task.

---

## How to Use PraatGen

### The Basic Workflow

0. **Verify your model and settings:** Opus 4.6 or higher with Extended Thinking turned on.

1. **Describe your task.** PraatGen asks for four things:
   - What should the script accomplish?
   - What objects are open when the script runs?
   - What information does the script need from the user?
   - What should remain when the script finishes?

2. **Review the pre-flight.** PraatGen verifies it has the right references loaded and flags any ambiguities. It recommends a model tier and extended thinking settings. You will approve this step or discuss your concerns.

3. PraatGen generates a command plan. Once you tell it to execute this plan it will write and deliver the code and a self-audit.

4. **Test in Praat.** Copy the script into Praat's script editor and run it. You may also ask it to present a downloadable .praat file in the chat window. If it works, you're done.

5. **Report errors if any.** Paste the exact error message and tell it that you are debugging. PraatGen diagnoses before changing code — no guesswork fixes. Feel free to screenshot any errors. Claude can process those images.

### Scaffold Mode

For complex scripts, reply **SCAFFOLD** instead of providing your task specification immediately. PraatGen will walk through the design collaboratively — proposed workflow, GUI design, object lifecycle, edge cases — before generating any code. This is especially useful for batch processing scripts, multi-panel figures, or clinical analysis pipelines.

### Debugging Mode

If you run into any errors with your scripts, or you want to refactor something, reply DEBUGGING. This should kick PraatGen into a mode that avoids recoding creep, and requires your approval for any fixes. 


### Tips for Best Results

- **Be specific about your starting state.** "I have a Sound and TextGrid open" is much better than "I have some files."
- **State your output format.** "Results in the Info window as a tab-delimited table" vs. "save to CSV" produce different scripts.
- **Mention your voice type or analysis context.** PraatGen adjusts pitch tracking parameters for speech vs. singing, and clinical vs. research contexts.
- **Paste exact error messages.** Include the line number. PraatGen's debugging protocol depends on precise error information.
- **Verify everything.** Ask PraatGen to review scripts it provides you and to look for errors or inelegant solutions. Some projects are large enough that it makes sense to spend an entire session planing and then taking a handoff document to another session to write the code. 

---

## What's in the Box

### Master Prompt

`MASTER_PROMPT_CORE_v13.md` — The system instructions that configure Claude as a Praat scripting specialist. Contains 36 rules governing syntax validation, command verification, clinical defaults, debugging protocol, and code quality standards.

### Project Knowledge Base (PKB)

The `pkb/` folder contains the verified reference files. These are PraatGen's source of truth — Claude checks commands and functions against these files rather than relying on its training data, which is unreliable for Praat syntax.

**Command references** — Verified syntax for every command PraatGen generates:

| File | Coverage |
|------|----------|
| `COMMANDS_Sound.txt` | Sound creation, queries, modification, conversion, drawing |
| `COMMANDS_TextGrid.txt` | TextGrid creation, queries, modification, drawing |
| `COMMANDS_Pitch.txt` | Pitch analysis and queries |
| `COMMANDS_Formant.txt` | Formant analysis and queries |
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
| `COMMANDS_DemoWindow.txt` | Demo window interactive applications |
| `COMMANDS_PictureWindow.txt` | Picture window drawing commands |
| `COMMANDS_Universal.txt` | Commands common to all object types |

**Appendices** — Specialized references:

| File | Purpose |
|------|---------|
| `APPENDIX_B_FUNCTIONS.txt` | All Praat scripting functions with signatures |
| `APPENDIX_C_GUI.txt` | Form and dialog syntax (beginPause/endPause) |
| `APPENDIX_D_CLINICAL_DEFAULTS.txt` | Clinically validated parameter sets for voice analysis |
| `APPENDIX_E_SPECIAL_CHARACTERS.txt` | Special character encoding for Picture window text |
| `APPENDIX_F_UX_STANDARDS.txt` | User experience standards for script dialogs and output |

**Verification and capability references:**

| File | Purpose |
|------|---------|
| `PRAAT_DEFINITIVE_CATALOGUE.txt` | Complete Praat capability inventory — 3,170+ commands, 336 Formula functions, 136 object types — extracted from v6.4.62 source code |
| `WHITELIST_CURRENT.txt` | Recently verified commands not yet merged into primary references |

**Drawing and methodology references:**

| File | Purpose |
|------|---------|
| `BEST_PRACTICES_DRAWING.txt` | Mandatory drawing patterns: Sound+TextGrid, viewport-before-save, stereo guard, text label safety, spectrum/Ltas/PowerCepstrum axis alignment |
| `BEST_PRACTICES_CONFIDENCE_FIGURES.txt` | Guidelines for publication-quality statistical figures |
| `EML_PROCEDURE_GUIDE.md` | Methodology rules, test selection logic, graph type routing, script generation model |
| `EML_PROCEDURE_REGISTRY.md` | Master index of all EML library procedures (255 procedures across 14 files) |

**EML procedure source files** — Verified implementations that PraatGen reads as algorithmic templates. PraatGen emits flat, self-contained scripts inspired by these procedures — no `include` directives, no companion files:

| File | Coverage |
|------|----------|
| `eml-graph-procedures.praat` | Drawing core: adaptive theming, color palette, axes, gridlines, violin/box primitives, stereo handling |
| `eml-draw-procedures.praat` | Draw orchestrators: F0 contour, waveform, spectrum, LTAS, time series, bar, violin, box, scatter, histogram |
| `eml-annotation-procedures.praat` | Stats-to-graph bridge, brackets, comparison matrix, shared reporters |
| `eml-core-utilities.praat` | Vector operations: ranking, sorting, subsetting, z-scores, binning |
| `eml-core-descriptive.praat` | Descriptive statistics: mean, median, SD, quartiles, skewness, kurtosis, CI |
| `eml-extract.praat` | Table and acoustic object data extraction |
| `eml-output.praat` | Formatted reporting: APA style, p-value formatting, CSV export |
| `eml-inferential.praat` | Inferential tests: t-tests, correlations, MWU, Wilcoxon, ANOVA, KW, post-hoc, p-value adjustment |
| `eml-batch-process.praat` | Batch infrastructure: date stamps, stop sentinel |

**Workflow support:**

| File | Purpose |
|------|---------|
| `HANDOFF_TEMPLATE.md` | Template for session handoff documents during debugging |

---

## Versioning

PraatGen tracks three version numbers:

| Component | Current | What it tracks |
|-----------|---------|----------------|
| **Release** | 0.9.0-beta.1 | The combined package (prompt + PKB). This is the version that matters to users. |
| **Master Prompt** | 13.1 | The system instructions. Bumped when rules, workflow, or protocols change. |
| **PKB Snapshot** | 2026-04-05 | The reference file set. Date-stamped when files are added or revised. |

**Release versioning** follows semver conventions:
- **0.x.y** — Beta. Expect changes based on tester feedback.
- **1.0.0** — Stable release. Prompt and PKB verified across a broad range of scripting tasks.
- **x.y.z** — Major.Minor.Patch. Major = breaking workflow changes. Minor = new capabilities or reference files. Patch = corrections.

---

## Known Limitations (Beta)

**Reference coverage gaps.** The COMMANDS_*.txt files cover the most commonly used object types thoroughly but are not exhaustive for every parameter variant. The Definitive Catalogue (`PRAAT_DEFINITIVE_CATALOGUE.txt`) provides fallback coverage for all 136 object types but with less contextual annotation. Gaps are filled as they're discovered — report them.

**EML Tools integration.** PraatGen generates flat scripts inspired by EML library procedures. The EML Tools plugin itself is in pre-release and available separately.

**Extended thinking dependency.** Complex scripts benefit significantly from Claude's extended thinking capability. The prompt includes gates that recommend when to enable it, but this requires the user to manage the setting manually.

**Opus model dependency.** Sonnet is *NOT* capable of the advanced reasoning required to write these scripts. And if you start the session in Sonnet, Claude will not know that Opus exists. Start in and stay in Opus unless it tells you to use Sonnet for specific tasks. 

**Context window limits.** Very long debugging sessions can exhaust Claude's context window. PraatGen monitors this and offers handoff documents, but prevention (testing scripts carefully before reporting errors, providing exact error messages) is better than cure.

**No runtime testing.** PraatGen generates scripts but cannot execute them. All scripts should be tested on representative data before use in research.

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

