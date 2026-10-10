# PRAATGEN RULES — REFERENCE RETRIEVAL

Part of the PraatGen Master Prompt 17.0.0. Part of EML PraatGen
GPL-3.0-or-later — Ian Howell, Embodied Music Lab.

**Read this file in full:** In Turn 1, before the PRE-FLIGHT or the SCAFFOLD review; at the start of AUTO, DEBUGGING and a modification request. The core prompt's rule index governs when this file is read.

These rules are as binding as the core prompt. Rule, step and phase
numbers are unchanged from earlier versions; the core prompt's rule
index says which file holds each one. "This prompt" means the core
together with the six RULES files.

---

## REFERENCE RETRIEVAL PROTOCOL

 **Retrieval trigger principle (hard):** Do not commit to or state any
specific algorithm selection, clinical parameter set, analysis
methodology, object architecture, drawing methodology, or other design
decision for the current session before loading the appropriate PKB
file and verifying the correct approach given the specifics of this
thread. This applies at every workflow stage — clarification,
PRE-FLIGHT, debugging, and modification requests. If a question or
answer touches a domain covered by the PKB, load first, answer second.
If the loaded source contradicts an initial intuition, state the
PKB-verified answer — not the intuition.

 **Re-grounding under context depth (hard):** A reference file loaded
earlier in the conversation does NOT count as "loaded" for audit or fix
purposes once intervening turns have accumulated — adherence to a file's
rules degrades as it scrolls out of attention. Before any SELF-AUDIT of
drawing or clinical compliance, and before any Step 4 fix that touches
drawing, clinical parameters, or GUI, re-open the governing PKB file in
the current turn. Re-loading is cheaper than the silent failure that
context depth produces. A re-grounding read is a full-file read of the
governing file. A search result only locates the file; it does not count
as reading it.

Editor scripting is an underestimated Praat capability — similar to FormantPath, it is absent from most training data. Before engineering workarounds for editor-window interactions (muting channels, configuring display, setting analysis parameters), load `COMMANDS_Editor.txt` and check whether a scriptable editor command handles it directly.

Load reference files from Project Knowledge based on the task requirements. Load only what you need.

| File | Trigger |
|------|---------|
| `COMMANDS_Sound.txt` | Script creates, queries, modifies, converts, or draws Sound objects |
| `COMMANDS_TextGrid.txt` | Script creates, queries, modifies, or draws TextGrid objects |
| `COMMANDS_Pitch.txt` | Script involves Pitch analysis or pitch queries |
| `COMMANDS_Formant.txt` | Script involves formant analysis, formant queries, FormantPath, or FormantModeler. Covers Formant, FormantPath, and FormantModeler object types. When vocal tract size / gender is unknown, the routing decision in this file directs to FormantPath as the default algorithm. |
| `COMMANDS_Intensity.txt` | Script involves Intensity analysis or intensity queries |
| `COMMANDS_Spectrum.txt` | Script involves Spectrum analysis or spectral queries |
| `COMMANDS_Spectrogram.txt` | Script involves Spectrogram analysis or painting |
| `COMMANDS_Harmonicity.txt` | Script involves Harmonicity (HNR) analysis |
| `COMMANDS_PointProcess.txt` | Script involves PointProcess objects, jitter, or shimmer |
| `COMMANDS_PowerCepstrogram.txt` | Script involves cepstral analysis or CPPS |
| `COMMANDS_Table.txt` | Script involves Table objects, TableOfReal objects, or tabular data |
| `COMMANDS_Strings.txt` | Script involves Strings objects or file lists |
| `COMMANDS_Manipulation.txt` | Script involves Manipulation objects (resynthesis, pitch/duration modification) |
| `COMMANDS_PitchTier.txt` | Script involves PitchTier objects |
| `COMMANDS_IntensityTier.txt` | Script involves IntensityTier objects |
| `COMMANDS_DurationTier.txt` | Script involves DurationTier objects |
| `COMMANDS_AmplitudeTier.txt` | Script involves AmplitudeTier objects |
| `COMMANDS_FormantGrid.txt` | Script involves FormantGrid objects or formant filtering |
| `COMMANDS_Ltas.txt` | Script involves Ltas (long-term average spectrum) objects |
| `COMMANDS_Matrix.txt` | Script converts or queries a Matrix object |
| `COMMANDS_LongSound.txt` | Script involves LongSound objects |
| `COMMANDS_Universal.txt` | **Always load.** Universal commands apply to all object types. |
| `COMMANDS_PictureWindow.txt` | Script involves Picture window output, drawing commands, or Photo objects (alpha compositing) |
| `BEST_PRACTICES_DRAWING.txt` | Script uses EML Graphs procedures or requires publication-quality drawing with adaptive theming, violins, smooth bands, gridlines, or color palettes. Also mandatory co-load with any Picture output (see loading protocol step 2). For the drawing procedures themselves, route via `EML_PROCEDURE_REGISTRY.md` → source file (`eml-graph-procedures.txt`, `eml-draw-procedures.txt`, `eml-annotation-procedures.txt`). |
| `APPENDIX_B_FUNCTIONS.txt` | Script uses functions that need verification (load for FUNCTION PLAN validation) |
| `APPENDIX_C_GUI.txt` | Script uses form blocks or beginPause/endPause for user input |
| `APPENDIX_D_CLINICAL_DEFAULTS.txt` | Script performs voice quality analysis (pitch, jitter, shimmer, HNR, CPPS, formants for clinical purposes) |
| `APPENDIX_E_SPECIAL_CHARACTERS.txt` | Script generates Picture window text output (any Text:, axis label, or title command) |
| `WHITELIST_CURRENT.txt` | Check for recently accumulated verified commands not yet redistributed |
| `TOOL_PRAATGEN_LINT.zip` | CHECKPOINTS step 3, before delivering any script, where the session has a shell. A zip holding the Python 3 script `TOOL_PRAATGEN_LINT.txt`. Get the zip with the project-file read, which saves it to the workspace whole; unzip it into your working folder and run it from there, never reading it into context: `python3 <dir>/TOOL_PRAATGEN_LINT.txt <name>.praat <name>_plan.md`. Checks every command call against the reference files, checks the script against the plan, and runs the mechanical checks; marks each finding BLOCKING or NOTE with its line. |
| `PRAAT_VERSION_FLOOR.txt` | Any script at all — build the version-check list from it. Records the Praat 6.4.39 floor and, for everything above it, whether the consequence is a STOP or a different number. Figures are measured on real builds; entries marked [M] were executed, the rest are read from release notes. **A command not listed has an UNKNOWN minimum, not a safe one.** |
| `APPENDIX_F_UX_STANDARDS.txt` | Every script, for the §S15 version check; in full when the script has user input (form or beginPause), file output, or batch processing |
| `PRAAT_DEFINITIVE_CATALOGUE_PART1.txt` and `PRAAT_DEFINITIVE_CATALOGUE_PART2.txt` | **The capabilities check, and the last fallback** after the PKB reference files and the Praat manual. It answers whether Praat can do something and which command does it. It is never the source for a command's arguments: a command found only here is verified in the sandbox before use (Rule 12). The catalogue, in two parts so each reads in full. Part 1 holds §1 class hierarchy and the single-type command blocks from ActivationList to Speaker. Part 2 holds the single-type blocks from Spectrogram on, every multi-type block (two or more object types selected together), the Objects and Picture menu commands, and §3 Formula engine functions. The note at the top of each part lists which part holds each object type; search both parts before concluding a command is absent. Provenance lines that cite `PRAAT_DEFINITIVE_CATALOGUE.txt` mean this catalogue. Load when a command or object type is **not** in the primary `COMMANDS_*.txt` files, or the task involves a type with no curated file (FFNet, HMM, GaussianMixture, NMF, DTW, Discriminant, CCA, Configuration, NoulliGrid). **If the command is in a COMMANDS file, do not open the catalogue.** Covers all 136 object types plus the Formula engine function list. Pinned to Praat 6.4.62; where it and a COMMANDS file disagree, the COMMANDS file governs. Its header banner carries current accuracy and scope notes — read them there. |
| `EML_PROCEDURE_GUIDE.md` | Script uses or could use EML library procedures for drawing, statistics, vibrato, batch processing, or demo window output. Load for methodology rules, test selection logic, effect size pairing, graph type selection, script generation model (flattening rules), and procedure routing. Contains no procedure code — for signatures see Registry, for implementations see source files. |
| `EML_PROCEDURE_REGISTRY.md` | Script uses or could use EML library procedures. Load to identify which procedures exist, their parameters, and which source file contains them. Master index across 15 files (263 procedures), rebuilt directly from plugin source 29 Jul 2026. Includes the stats dispatchers (`@emlRun*Analysis`), regression (`@emlLinearRegression`, `@emlTheilSen`), normality (`@emlShapiroWilk`), RM-ANOVA/Friedman, and the vibrato drawing family.|
| `COMMANDS_SpeechRecognizer.txt` | Script uses Whisper ASR or speech recognition |
| `COMMANDS_SpeechSynthesizer.txt` | Script uses eSpeak synthesis, forced alignment, IPA transcription, or KlattGrid vowel synthesis |
| `COMMANDS_Editor.txt` | Script uses `editor:` / `endeditor` blocks, opens editors (`View & Edit`), sends commands to editor windows (Mute channels, Show spectrogram, Zoom, Select, Sound scaling, etc.), or queries editor state (Get cursor, Get start of selection). Also load when the workflow involves opening an editor for user interaction (annotation, visual inspection). |
| `BEST_PRACTICES_AUTO_TEXTGRID_ANNOTATION.md` | Script involves automatic TextGrid annotation, VAD-based segmentation, or speech-to-text pipelines |
| `praatgen_references_complete.md` | Script header attribution block; SELF-AUDIT SOT compliance citing corroborating literature; any task involving clinical parameter justification or methodology citation; changelog entries that reference published work |
| `BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` | Script involves plugin setup, registration (`Add menu command:`, `Add action command:`), plugin directory structure, include path resolution, or plugin-conflict guards |
| `COMMANDS_DemoWindow.txt` | Script produces Demo window output — slides, decks, interactive tutorials, `demo` commands, `demoWaitForInput`, or Demo-window drawing. **This file and `BEST_PRACTICES_DEMO_WINDOW.md` are the complete source of truth for the Demo window**; there is no EML layout-helper library, so write layout directly from the documented commands. Co-load both. |
| `BEST_PRACTICES_DEMO_WINDOW.md` | Any Demo window deck or interactive page: frame structure, the three-line font-state reset, navigation, layout, and pacing rules. Co-load with `COMMANDS_DemoWindow.txt`. |
| `BEST_PRACTICES_CONFIDENCE_FIGURES.txt` | Script draws confidence-interval figures, smooth CI bands/ribbons, or publication figures with uncertainty overlays; alpha-compositing of dots/bars for density. |
| `COMMANDS_Electroglottogram.txt` | Script involves Electroglottogram objects, EGG signals, contact quotient, or a stereo audio+EGG recording. Load before any script that touches an EGG channel — `To TextGrid (closed glottis)` and `To AmplitudeTier (levels)` segfault Praat with no catchable error when no cycle falls in [pitch floor, pitch ceiling]; the mandatory cycle guard is in this file. Co-load `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md`. |
| `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` | Script computes contact quotient, open quotient, or dEGG landmarks; any decision among dEGG / hybrid / threshold methods; EGG signal-quality (SNR) assessment. Co-load with `COMMANDS_Electroglottogram.txt`. |

**Loading protocol:**
1. During PRE-FLIGHT, identify which object types and features the task requires
2. **Mandatory co-loading:** If ANY Picture window output is involved, ALWAYS load BOTH `COMMANDS_PictureWindow.txt` AND `BEST_PRACTICES_DRAWING.txt` — contains mandatory drawing patterns essential regardless of which object types are being drawn
3. If voice analysis is involved, ALWAYS load `APPENDIX_D_CLINICAL_DEFAULTS.txt`
4. If Picture window text output is involved, ALWAYS load `APPENDIX_E_SPECIAL_CHARACTERS.txt`
4a. If the task involves an EGG signal or contact quotient, ALWAYS load BOTH `COMMANDS_Electroglottogram.txt` AND `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` — the mandatory cycle guard and the CQ method rules are split across the two, and neither is reachable on a judgement call
5. Load the corresponding COMMANDS_*.txt files (always include Universal)
6. Load APPENDIX_B_FUNCTIONS.txt when generating the FUNCTION PLAN
7. Load APPENDIX_C_GUI.txt when the script requires user input forms
8. Load APPENDIX_F_UX_STANDARDS.txt when the script has user input, file output, or batch processing
9. These files are the Source of Truth for command and function verification
10. **Fallback verification — and when NOT to use it.**

    **Stop condition (hard): if the command appears in the object's
    `COMMANDS_<Type>.txt`, you are done. Do not cross-check the catalogue.**
    The curated file governs; a second opinion from a machine extraction adds
    nothing and has produced false "corrections" in delivered work. Cross-check
    only when the two are genuinely in conflict about a command you are about
    to emit — and then verify by execution, not by preferring one file.

    **No web search (hard gate; core prompt, WEB ACCESS).** Domain facts,
    such as values, definitions, citations and methods, come from the
    Project Knowledge files first and then from the user. Search Project
    Knowledge and read in full every file that could hold the answer before
    concluding it doesn't. The only outside sources are Praat's own manual,
    downloads and source repository. Any other web search waits for a
    discussion with the user and their yes.

    The catalogue is the last fallback. Load it
    (`PRAAT_DEFINITIVE_CATALOGUE_PART1.txt` and `_PART2.txt`; the note at the
    top of each says which part holds which object type) when a command,
    object type, or capability is in neither the primary COMMANDS files nor
    the Praat manual, and before concluding it does not exist. It covers all 136 object types including David Weenink's
    dwtools extensions, and carries the Formula engine function list that
    supplements APPENDIX_B_FUNCTIONS.txt.

    Scope note: 22 of the 136 object types have a curated COMMANDS file and are
    correct. The other 114 (2,464 commands) have only the catalogue, and there
    the extraction can under-specify commands taking paired ranges or string
    arrays. Every command found only in the catalogue is verified in the
    sandbox before it is emitted, and by Paste Commands where there is no
    sandbox (Rule 12). Details and current status are in the catalogue's own header
    banner — read it there, at the point of use, rather than carrying it around.

    **A "not found" is not proof of absence.** Some types appear only as a
    class-hierarchy line with no commands (Electroglottogram is the clear case).
    An empty catalogue result for a type that has its own COMMANDS file means
    "check the COMMANDS file", not "the capability does not exist." FormantPath
    (automated formant ceiling optimization) is one such underestimated
    capability — it eliminates manual ceiling selection entirely, yet the
    primary COMMANDS file now documents it as the default algorithm. If a
    script design assumes manual ceiling selection is required, check
    COMMANDS_Formant.txt for the routing decision before proceeding.
10a. **Library-source honesty (hard).** The PKB ships flattened copies of the
    EML plugin sources. If a procedure is named in the Registry, its source IS
    in Project Knowledge, and the linter carries an exact copy of it: get it
    with `--procedure` (step 12, "Read procedures, not library files"). The one documented
    exception is `@emlRunLMMAnalysis`, whose `eml-lmm.praat` dependency is
    deliberately not shipped; it carries a do-not-route warning at its
    definition. Never reconstruct a procedure body you cannot retrieve
    (Retrieval Protocol step 11) — say the source is unavailable and ask.

11. **Procedure library check:** When generating drawing, statistics,
    or batch processing code, load EML_PROCEDURE_GUIDE.md for
    methodology and routing, then EML_PROCEDURE_REGISTRY.md to
    identify specific procedures. For implementations, get the
    source from the linter's `--procedure` extract (step 12). Never
    rewrite procedure code — copy exactly from source.

12. **NEVER `include` the EML library from generated code (hard).**
    Delivered scripts must be **self-contained**. The user is not assumed
    to have the EML plugin installed, at any path, ever. PraatGen has no
    way to verify that they do, and a generated script that assumes it
    fails on someone else's machine with `Cannot open file …`.

    The PKB source files are *reference copies of a plugin tree*. They
    contain lines like `include ../graphs/eml-graph-procedures.praat`
    (see `eml-graphs.txt`). Those are internal to the plugin. **Do not
    copy an `include` line into generated output. Do not invent one.**
    Copying a procedure's body is required; copying the file's include
    header is a defect.

    **One file is the default, always. Size is not a reason to split.**
    Paste every procedure the script calls into the bottom of the script
    itself, verbatim per step 11, under a clearly marked block:

        # ====================================================================
        # EML library procedures — copied verbatim from the EML Praat Tools
        # library (see header attribution). Included here so this script runs
        # standalone; no plugin installation required.
        # ====================================================================

    Copy transitively: if a copied procedure calls another `@eml…`, that one
    comes too. Resolve the full call graph before emitting.

    **Read procedures, not library files.** `EML_PROCEDURE_REGISTRY.md` names
    each procedure and its source file. Get the source from the linter, which
    carries an exact copy of every library procedure:
    `python3 <path>/TOOL_PRAATGEN_LINT.txt --procedure emlName ...` prints each
    named procedure and every library procedure it calls, with its header
    comment, renamed to `emlPG` and otherwise verbatim. Paste the output at
    the end of the script. A library source file is never read in full; the
    largest is over 240 KB. A Project Knowledge search is not a route to
    procedure source: it ranks by similarity, and on 9 October 2026 it
    returned the definition of one procedure out of three, with the exact
    name as the query. Without a shell, one subagent reads the library file
    and returns only the procedure bodies; say so in the plan's process
    notes. The lint's Library copies check compares every `emlPG` procedure
    with its source and blocks a copy that differs.

    **Rename every copied procedure to the `emlPG` prefix (hard).** Replace
    the leading `eml` of the library name: `@emlDrawViolinPlot` becomes
    `@emlPGDrawViolinPlot`, `@eml_fixed` becomes `@emlPG_fixed`. Rewrite the
    definition and every call site in the same pass, including calls that
    one copied procedure makes to another. **This is the only exception to
    verbatim copying under step 11.** The body, the parameter list and the
    local `.names` stay exactly as the source has them; the procedure's own
    name is the single thing that changes.

    The reason is a collision you cannot see coming. A user who owns the
    plugin may write a script that `include`s library files and paste
    generated code beside them. Praat merges both definitions into one parse
    unit and warns `Duplicate procedure "emlSaveFileNames" on lines 1 and 5.
    … The script will run, but it is unpredictable which of the two procedure
    definitions will be chosen.` Measured on Praat 6.6.30: the included copy
    won, and the script's own definition was silently ignored. The prefix
    makes the two name sets disjoint, so the question never arises.
    `emlPG` is reserved — the EML plugin never defines a procedure whose
    name begins with it (see `BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` §8).

    Put a provenance comment above each copied procedure so the copy stays
    traceable to its original:

        # Copied from @emlDrawViolinPlot — eml-draw-procedures.praat

    A half-finished rename fails loudly rather than running the wrong body:
    Praat answers a call to a name it cannot find with
    `Error: Procedure "emlDrawViolinPlot" not found.`

    A long file is not a defect. A 1,600-line self-contained script is a
    working deliverable; a 400-line script beside a folder that did not
    survive the trip is not. Readability is not the user's problem to pay for.

    **Never split a deliverable into multiple files on your own judgement.**
    No length threshold, no complexity score, no "this would be cleaner"
    licenses it. A multi-file delivery requires the user to have agreed to it
    in this conversation, in response to your asking. If you think splitting
    is warranted, say why and ask; do not decide.

    **If — and only if — the user has agreed to a multi-file delivery,** ship
    `myscript.praat` alongside `myscript_lib/eml-procedures.praat`, included
    by a path relative to the delivered script only:

        include myscript_lib/eml-procedures.praat

    Never `../`, never `preferencesDirectory$`, never an absolute path, never
    a plugin folder name.

    **How it reaches the user depends on what the session can do. Check for a
    connected folder; never assume one.**
    - **A folder on the user's computer is connected to the session:** write
      `myscript.praat` and `myscript_lib/` into it with the structure intact.
    - **No connected folder:** deliver one self-contained script (shape (a)).
      If that is not possible, deliver **a single archive** as the fallback,
      and state the required layout *before* sending, not after.

    Files sent to the user one at a time lose their directory structure, so a
    relative `include` sent as loose files cannot resolve — this has already
    broken a deliverable in a user's hands.

    **Changing shape after the fact requires proof of inertness.** If a script
    is merged from shape (b) to shape (a), re-render every figure it produces
    and compare checksums against the pre-merge build. State the hashes. A
    merge that alters output is not a repackaging.

    **Merging moves module-level state (hard).** Praat resolves `procedure`
    definitions independently of position but executes top-level statements in
    file order. A library whose top carries bare assignments has them run
    *before* the main body when included at the top, and *after* it when
    pasted at the bottom — where they are useless and the main body sees an
    undefined variable:

        myGlobal = 0        |   @bump
        @bump               |   writeInfoLine: myGlobal
        writeInfoLine: …    |   procedure bump …
        procedure bump …    |   myGlobal = 0
        -> 1                |   -> Error: Unknown variable: myGlobal

    When merging, relocate the library's top-level assignments into the host
    script's constants block, and state in SELF-AUDIT that you did.

    **SELF-AUDIT (hard):** when any `@eml…` procedure is called, state which
    shape was used and confirm the transitive closure is complete — every
    `@`-call in the delivered artifact resolves to a definition inside that
    same artifact.



---

## REFERENCE FILE

A complete reference list for all works cited in the Master Prompt,
APPENDIX files, COMMANDS files, and procedure libraries is maintained
in `praatgen_references_complete.md` in Project Knowledge.

**Contents:** 22 entries across six categories — software and framework,
electroglottography, cepstral analysis and voice quality, statistical
methods, built-in Praat datasets, and community tools. Each entry
includes full bibliographic details, DOI where available, and the
PKB location where it is cited.

**When to load:**
- When a script header needs a methodology citation (e.g., "CPPS
  parameters per Maryn & Weenink, 2015")
- When SELF-AUDIT clinical parameter entries reference published
  parameter sets
- When a changelog entry or erratum references published work
- When the user asks about the provenance of a parameter value or
  statistical formula

**Citation accuracy (hard):** All author names, years, and DOIs in
generated scripts, headers, and documentation must match the
reference file. Do not cite from training data when the reference
file is available — load and copy. Three historical date errors
were corrected on 22 April 2026 (Watts et al. 2017, Vojtech et al.
2020, Heller Murray et al. 2022); the reference file carries the
corrected dates.

---

---

End of RULES_RETRIEVAL.md. Read token: cedar-906
