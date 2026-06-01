# ============================================================================
# PRAATGEN CHANGELOG
# ============================================================================
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Version history for the PraatGen Master Prompt. Entries are newest-first.
# Referenced from the Master Prompt Core via the CHANGELOG section.
# ============================================================================

### 13.9.1 — 17 May 2026

**MP edits (this pass):**
- **Rule 5C (procedure-local vs caller-scope):** Explicit statement that
  dot-prefix variables are procedure-local; from caller scope, procedure
  outputs are accessed as `procedureName.variableName`. Persistence
  semantics documented.
- **Rule 5C (`empty$#` bug status):** FIXED in Praat 6.4.65 (sandbox
  verified 15 May 2026). Warning made version-conditional; literal-init
  workaround retained for scripts targeting ≤ 6.4.63.
- **Rule 7 (comment hygiene rewrite):** `#` for line-start only, `;` for
  inline only. Hard separation. No `#` after code; no `;` at line start.
  SELF-AUDIT item added.
- **Rule 27 (non-destructive file output rewrite):** `@emlGenerateUniquePath`
  is the last line of defense for all file output. Date stamps alone fail
  uniqueness. Pattern D (interactive overwrite dialog) retired as
  standalone pattern. Overwrite only on explicit user request.
- **STEP 2C Item 4 (AUTONOMOUS):** Added exception clause —
  PKB-encoded methodology decisions are pre-decided, not deferrals.
- **STEP 2C (new subsection, "Pre-delivery domain compliance check"):**
  Mandatory itemized check before `present_files` in AUTO mode, with
  per-command catalog tables for voice quality, formant, statistical,
  Picture window, Demo window, and tutorial domains.
- **Debugging Invariant #17:** AUTO-mode pre-delivery compliance check
  is mandatory.
- **House Rules additions:**
  - `for` loops always increment in Praat (no decrement direction)
  - `and`/`or` do not short-circuit (both sides always evaluated)
  - `nocheck` corrupts interpreter variable state on failure (cannot be
    used as diagnostic branching tool)
  - Zip delivery protocol — single zip with MANIFEST.txt; no loose-file
    delivery; no summary-instead-of-original; verify presence before
    packaging
- **SELF-AUDIT (compressed + full):** `ET:` → `ET recommended:`. System
  cannot detect actual ET state, only what it recommended.
- **House Rule alignment:** Comment-style bullet updated from "# comments
  only" to reflect new Rule 7 (separation of `#` line-start and `;` inline).

**PKB edits (this pass):**
- **COMMANDS_Table.txt:** Box plots entry cleaned up (uncommented from
  prior correction block; contaminated Normal probability plot line
  fixed). ANOVA commands verified present.
- **COMMANDS_PointProcess.txt:** Added `Get number of points`,
  `Get time from index`, `Get low index`, `Get high index`,
  `Get nearest index` with explicit note distinguishing PointProcess
  from TimeTier-family `Get low/high index from time:`.
- **COMMANDS_Pitch.txt:** Added `Get time of maximum:` and
  `Get time of minimum:` (4-parameter form including unit$) with explicit
  contrast against Sound's 3-parameter signature.
- **COMMANDS_Editor.txt:** Added `Close` command with documented
  `nocheck Close` editor-cleanup pattern (narrow safe use of `nocheck`).
- **PRAAT_DEFINITIVE_CATALOGUE.txt:** `FormantModeler: Draw variances of
  shifted tracks` — sandbox-verified 17 May 2026 (Praat 6.4.65 barren).
  Confirmed OPTIONMENU position (5th parameter, between right Variance
  range and left Formant range), and enumerated valid values ("no",
  "up", "down" — case-insensitive). Earlier session memory describing
  OPTIONMENU position as "between formant range and garnish" was wrong;
  catalogue position was correct. Entry annotated with verified enum
  values and provenance.
- **COMMANDS_Sound.txt:** Added four sandbox-verified entries (Praat
  6.4.65, 15 May 2026):
  - `Save as 32-bit WAV file:` — ±1.0 hard-clip data-loss hazard
  - `Save as raw 32-bit big/little-endian file:` — NaN propagation
    hazard on out-of-range input
  - `Combine to stereo` — accepts arbitrary N selected Sounds; selection
    order = channel index
  - `Get mean:` — three-argument form (channel, fromTime, toTime)
    documented alongside two-argument form

**Verified-current (no edit needed):**
- A3: All three channel-handling procedures exist in
  `eml-graph-procedures.praat` v3.18 (`@emlHandleStereo`,
  `@emlApplyChannelChoice`, `@emlCheckChannels`); MP references
  validated.
- A4: Canary value `What_About___Oleicat-67-55Δ` current.
- A10, A11: CSV default delimiter and pauseScript newline limitation
  already in House Rules / Rule 21.
- B4: COMMANDS_DemoWindow.txt — three errata (font lock, viewport
  units/order, rotation as string) already documented in current file.
- B5: COMMANDS_PowerCepstrogram.txt — per-frame CPPS workflow
  already documented; column names still pending Paste Commands.
- B6: APPENDIX_B_FUNCTIONS.txt — reserved identifiers note already
  present.
- B7: COMMANDS_PictureWindow.txt — font state and Text special
  self-containment already documented.
- B11: COMMANDS_Formant.txt — FormantPath Extract Formant segfault
  errata and workaround already documented.
- B15: `eml-annotation-procedures.praat` — single mention of
  `@emlAutoPlaceLegend` is a correctly-worded changelog entry (rename
  history), not dead documentation.

**Identified for future passes:**
- B1, B2: EML_PROCEDURE_REGISTRY.md missing entries and signature
  mismatches — deferred per user (procedures work).
- B12: Some vibrato commands redistributed already (B8, B9 added this
  pass); remaining unspecified commands require original 18 Mar handoff
  document.
- B16: `eml-core-descriptive.praat` PKB v1.0 lags local v1.1
  (@emlShapiroWilk addition) — requires file upload.
- B17: PKB plugin files lag local versions
  (annotation-procedures 3.15→3.17, output 1.3→1.6, graphs-form 1.4→1.7) —
  requires file uploads, not header edits.
- B18: `eml-wizard.praat` missing from PKB — requires file upload.
- C2: Paper scope edits — deferred per user.

**PKB version bump:** 0.9.3 beta 1.

---

### 13.8.3 — 7 May 2026
- **Rule 21 erratum:** `pauseScript:` does not render `newline$` as
  line breaks. Single-line messages only. Multi-line instructions
  require `beginPause` with `comment:` lines. Empirically confirmed
  in Praat 6.4.65.
- **Rule 28 scope:** Explicit statement that Rule 28 applies to ALL
  Picture window output including wireframes and mockups. No casual
  mode.
- **Rule 29D (Multi-channel input):** New sub-rule for multi-channel
  Sound files. Sampling rate is shared across all channels; channel
  roles must be confirmed during PRE-FLIGHT.
- **PRE-FLIGHT Item 3C (Multi-channel check):** Channel assignment,
  sampling rate, and annotation channel must be established before
  code generation.
- **Step 1B (Label solicitation):** When script logic depends on
  exact label strings, those strings must be surfaced during design,
  made configurable, and validated at runtime.
- **Step 1B (Methodological decisions):** Decisions affecting
  scientific interpretation (which channel to segment from, how to
  compute volume change) are the researcher's job, not the compiler's.
- **House Rule (Editor capability check):** Check COMMANDS_Editor.txt
  before engineering workarounds for editor interactions.
- **NEW FILE: COMMANDS_Editor.txt v1.1** — Editor scripting reference
  extracted from Praat source code (FunctionEditor.cpp, SoundArea.cpp,
  SoundAnalysisArea.cpp, TextGridArea.cpp). ~100 commands across 5
  sections. 15 commands empirically verified via Praat 6.4.65 + Xvfb.
  Critical finding: TextGridEditor registers under TextGrid ID, not
  Sound ID — using Sound ID hangs.
- **Rule 24C (Sandbox verification):** Praat can be installed in the
  sandbox for empirical testing. Barren edition for non-GUI commands;
  full edition + Xvfb for editor commands. Allowed domains frozen at
  conversation start (empirically verified). Installation, usage, and
  lifecycle management documented.
- **Debugging Invariant 15:** Editor capability check added.
- **Reference Retrieval Protocol:** COMMANDS_Editor.txt added with
  trigger for `editor:` / `endeditor` blocks and editor interaction
  workflows.

### 13.8.2 — 25 April 2026
- **BEST_PRACTICES_CONFIDENCE_FIGURES.txt v2.0:** §10 rewritten. Former
  §10A–G (measure-specific notes) replaced with locked panel specs.
  Four base panel types (time-series, spectral snapshot, waveform+overlay,
  spectrogram+overlay) with constrained layout, overlay vocabularies,
  and procedure signatures.
- CPP/CPPS: same panel geometry, different input preparation. Smoothing
  on cepstrogram before slice extraction for CPPS. Heatmap prohibited.
- Spectrum: flexible overlay vocabulary (vertical lines, spreads,
  frequency bands, point markers, regression) replacing hardcoded
  M1–M4 layout.
- Formant routing: sustained vowel → spectrum panel; dynamic → spectrogram
  with three-layer stack (spectrogram → speckle → tracks, one color).
- Perturbation: 1.3× padded amplitude bounds, full-height pulse marks
  behind waveform, solid-line-only prohibition.
- Two-rule viewport/axes contract codified (§10.1A): single outer
  viewport + axes reassertion after every draw call. Validated
  empirically.
- Proof-sheet preview workflow (§10.7) for pre-batch layout verification.
- All annotation text black; colors referenced by palette index only.


### 13.8.1 — 23 April 2026
- **APPENDIX_D §0 (new): Canonical Parameter Discipline.** All
  clinical parameter deviations now require signal-loss justification.
  "Extra headroom," "doesn't hurt," and "closer to expected range"
  are explicitly listed as invalid justifications. Narrowing a
  parameter below canonical is treated equivalently to widening one.
  PRE-FLIGHT must ask about range only when the task suggests the
  canonical window may be insufficient — not preemptively adjust.
- **Rule 22B strengthened:** Canonical parameter integrity paragraph
  added, cross-referencing APPENDIX_D §0.
- **House Rules updated:** Voice analysis parameter rule now references
  signal-loss standard.
- **SELF-AUDIT templates updated:** Clinical parameter entries now
  require "all canonical per §0" or explicit signal-loss evidence
  for each deviation.
- **Provenance:** Singing voice quality script (23 April 2026) —
  RCC pitch floor lowered from 75→50 and ceiling narrowed from
  600→500 without signal-loss justification. HNR pitch floor
  deviation (75→50) changed analysis output. All three deviations
  reverted to canonical after review.

### 13.8 — 23 April 2026
- **Rule 4B (Object preservation):** Scripts must never remove objects that existed before the script ran. Only script-created objects may
be cleaned up. Starting state is a contract.
- **WHITELIST_CURRENT.txt fully redistributed and reset.** All accumulated
  entries moved to their target COMMANDS files. No entries remain.
- **COMMANDS_Universal.txt:** New Selection Management section documenting
  `selectObject:`, `plusObject:`, `minusObject:`, `removeObject:`,
  `select all`, and selection query functions (`numberOfSelected`,
  `selected`, `selected$`, `selected#`). Selection-is-a-set interpreter
  behavior note. `nocheck` state corruption errata added to Syntax Notes.
- **COMMANDS_PictureWindow.txt:** Text special, Insert picture from file,
  Text width (world coordinates) uncommented from pending state. Full
  Measure subsection added (8 commands, all catalogue-verified). Paint/Draw
  rounded rectangle with catalogue-verified parameter counts. Font behavior
  notes uncommented. New Photo Object section with Create simple Photo,
  Create Photo, Formula (transparency), Paint image, and two errata.
- **COMMANDS_Table.txt:** New TableOfReal section — To Table (verified),
  12 statistical analysis commands (To PCA, To Discriminant, To SSCP,
  etc.), 5 hidden commands, 1 cross-type command. Header updated to
  "Table + TableOfReal".
- **COMMANDS_SpeechSynthesizer.txt:** KlattGrid section added — Create
  KlattGrid from vowel (12 params) and To Sound (no params). Header
  updated to "SpeechSynthesizer + KlattGrid".
- **COMMANDS_Ltas.txt:** Get number of bins, Get frequency from bin
  number, Get value in bin uncommented from pending state.
- **APPENDIX_B_FUNCTIONS.txt:** Usage notes added for `appVersion()`
  (integer encoding + version guard pattern), `chooseReadFile$`
  (callable anywhere, returns "" on cancel), `unicode()` (special key
  code reference table for Demo window).
- **NEW FILE: BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt** — 7 sections
  covering plugin directory structure, setup.praat registration, Add
  menu command / Add action command full parameter documentation,
  submenu cascade patterns, include path behavior, plugin-conflict
  guards.
- **Reference Retrieval Protocol:** Four updates — new row for
  BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt; COMMANDS_Table.txt trigger
  expanded to include TableOfReal; COMMANDS_SpeechSynthesizer.txt
  trigger expanded to include KlattGrid; COMMANDS_PictureWindow.txt
  trigger expanded to include Photo objects.

### 13.7 — 22 April 2026
- **Rule 5C: Matrix (`##`) variables** — creation (`zero##`,
  `randomGauss##`, `outer##`, `transpose##`, literals), element access,
  dimension queries (`numberOfRows`, `numberOfColumns`), operations
  (`mul##`, `mul#` both directions, `solve#`, `solve##`, `rowSums#`,
  `columnSums#`, `sum`, `mean`), elementwise arithmetic (`+`, `*`,
  scalar `*`). Preference rule over flat vectors and interpolated
  indexed variables. Matrix variables vs. Matrix objects distinction.
  Catalogue ghosts documented (`inner##`, `object##`, `linear##` — not
  exposed to scripting engine). All 17 functions verified empirically
  in Praat 6.4.63.
- **Rule 5C: String vector (`$#`) variables** — creation (literals,
  `readLinesFromFile$#`, `fileNames$#`, `folderNames$#`,
  `splitByWhitespace$#`, `splitBy$#`), element access, `size()`,
  operations (`sort$#`, `sort_numberAware$#`, `shuffle$#`). Batch
  processing pattern (`fileNames$#` as simpler alternative to
  `Create Strings as file list:`). All 14 functions verified
  empirically. Known Praat 6.4.63 bug: `empty$#` crashes (segfault
  in `str32cmp` — NULL pointer in allocated string vector slots).
- **Rule 24B: Empirical verification snippets** — when uncertain about
  syntax or behavior, offer a 2–10 line self-contained snippet for the
  user to paste into Praat. Counts as "asking the user" for Rule 24
  circuit breaker.
- **Rule 24 circuit breaker clarification:** "Two-alternative" includes
  parameter variations of the same approach. Adjusting a threshold
  three times is one approach tried three times, not three approaches.
- **House Rule (`noprogress`):** `noprogress` must precede all analysis
  commands in loops and batch contexts (`To Pitch`, `To Formant`,
  `To Harmonicity`, `To PointProcess`, `To Intensity`, `To Spectrogram`,
  `To PowerCepstrogram`, `Filter (pass Hann band)`, etc.). Applies to
  Demo window animation and batch file processing.
- **NEW FILE: BEST_PRACTICES_DEMO_WINDOW.txt** — 7 sections covering
  animation loop architecture, selective vs. full erasure, `noprogress`
  performance, font state management, coordinate system, aspect ratio
  compensation, and template patterns.
- **COMMANDS_DemoWindow.txt:** Paint rounded rectangle example corrected
  (5 → 6 parameters, missing radius). Animation caveat added to
  selective erasure section. Troubleshooting table updated.
- **WHITELIST_CURRENT.txt redistribution:** Ltas queries, Text special,
  Insert picture from file, Text width, font behavior notes,
  selection-is-a-set moved to target COMMANDS files. Added Paint rounded
  rectangle (6 params), Add action command (10 params), Add menu command
  (6 params). Praat bug logged: `empty$#` segfault in 6.4.63.

### 13.6 — 22 April 2026
- **APPENDIX_B_FUNCTIONS.txt rebuilt from scratch:** Complete rebuild
  from official Praat Functions manual page merged with Formula.cpp
  source verification. 375 unique entries (up from 343). Key additions:
  `folderExists`, `between_by#`, `between_count#`, `empty$#`, `clock`,
  `col#`, `combine#`, `correlation`, `padLeft$`/`padRight$` family,
  `randomImax`, `chooseFolder$`, `chooseReadFile$`, `chooseWriteFile$`.
  Alias pairs documented. `unicode()` key code reference table added.
  `appVersion()` added with version-guard usage pattern.
- **House Rule (Accessible palette):** Okabe-Ito is the default palette
  for all EML graph output. Exact RGB values documented in
  BEST_PRACTICES_DRAWING.txt. B/W is the only alternative. API users
  may override `.line$[n]` / `.fill$[n]` after `@emlSetColorPalette`.
- **COMMANDS_Harmonicity.txt:** Draw parameter count corrected (4
  parameters, no garnish).
- **COMMANDS_Formant.txt:** Added `Speckle:` command (5 parameters).
  Usage note: weaker formants (F4–F5) may not appear with Draw tracks
  — speckle all formants first, then overlay tracks.
- **COMMANDS_Sound.txt:** Draw usage note for Harmonicity overlay.
- **COMMANDS_Intensity.txt:** Draw usage note added.
- **BEST_PRACTICES_DRAWING.txt:** Accessible palette section with
  Okabe-Ito exact RGB values for line, fill, and light-line variants.
- **README.md:** Version 0.9.2-beta.14, Opus 4.6 requirement (not
  4.7 — context tracking failures), PKB snapshot date updated.

### 13.6 — 22 April 2026
- **Model language softened:** "Required model" → "Recommended model."
  Opus 4.6 ET remains the validated choice. Sonnet and Opus 4.7 acknowledged
  as potentially viable for simple projects with caveat that advanced
  generation may fail silently. Haiku removed as a named option. Adaptive
  thinking limitation (no user-controlled ET) noted for Opus 4.7 and Sonnet.
- **Script header model-agnostic:** Removed hardcoded "Claude 4.6 Extended
  Thinking" from research disclosure boilerplate and attribution chain.
  Users note their actual model in their own disclosure.

### 13.5 — 21 April 2026
- **COMMANDS_Formant.txt v2.0:** Combined Formant + FormantPath +
  FormantModeler into a single reference file with routing decision.
  FormantPath is now the default algorithm when formant ceiling is
  uncertain. Formant (burg) with manual ceiling selection is the
  override for protocol-specified ceilings.
- **APPENDIX_D §4 rewrite:** FormantPath (burg) is now §4A (default).
  Formant (burg) is §4B (override). Routing decision at section top.
  Hard rule amended: manual ceiling selection required only when using
  Formant (burg), not when using FormantPath.
- **Rule 37 (Automated parameter optimization):** New rule — prefer
  Praat's automated parameter search commands over manual selection
  when no protocol-specified value exists.
- **Debugging Invariant 12:** Check for automated alternatives before
  adding manual parameter dialogs.
- **Formant query commands expanded:** Get mean, Get standard deviation,
  Get minimum, Get maximum, Get quantile, Get quantile of bandwidth,
  Get time of minimum, Get time of maximum, List formant slope —
  all added to COMMANDS_Formant.txt with verified signatures from
  Praat manual.
- **FormantPath commands promoted** from WHITELIST_CURRENT.txt to
  COMMANDS_Formant.txt: Extract Formant (with segfault bug
  documentation), Get optimal ceiling, Get stress of candidate,
  Get number of candidates, Draw as grid, Set path, Set optimal path.
- **FormantModeler commands promoted** from WHITELIST_CURRENT.txt to
  COMMANDS_Formant.txt: 15 commands covering query, draw, and convert.
- **FormantModeler scope limitation documented:** FormantModeler
  assumes smoothly varying formants and is valid only for sustained
  vowels or single tokens. On connected speech spanning multiple
  vowels, the polynomial model smooths away real transitions and
  flags real vowel targets as outliers. Connected speech requires
  per-vowel segmentation before FormantModeler is applied. Limitation
  documented in COMMANDS_Formant.txt (FormantModeler section header)
  and APPENDIX_D §4D with provenance from /u i u/ empirical test
  (21 April 2026).
- **APPENDIX_D §5B citation dates corrected:** Watts, Awan & Maryn
  2017 (was "Watts & Awan 2020"), Vojtech et al. 2020 (was "2023"),
  Heller Murray et al. 2022 (was "2021"). Reference file
  `praatgen_references_complete.md` added to Project Knowledge.

### 13.4 — 19 April 2026
- **Rule 5E (Command/function boundary):** Praat commands are statements
  (assigned via `=`); functions are expressions (composable). Commands
  cannot appear inside function calls, as arguments to other commands,
  or inside formula expressions. Diagnostic: `Unknown symbol «Get» in
  formula`. Added to Debugging Invariants (item 11) and SELF-AUDIT
  syntax check.

### 13.3 — 9 April 2026
- **Output compression is now default.** Compressed COMMAND PLAN,
  SELF-AUDIT, and inter-turn prose on all generation turns. Full
  verification still runs internally. Reply VERBOSE at any execution
  gate for expanded output. See OUTPUT COMPRESSION section.
- Step 1 mode list updated: VERBOSE is opt-in, compressed is default.
- Step 2 execution gate updated: GO/EXECUTE triggers compressed output.
- Step 3 Phase 3C testing block conditional on compression mode.

### 13.2 — 5 April 2026
- **Rule 5C (Interpolation scope constraint):** Single-quote variable
  name interpolation (`var'.i'`) works only inside procedure bodies
  (dot-prefixed variables). Fails in main script body at any depth.
  Bracket and vector notation work in all scopes. Verified empirically
  with four test scripts.

### 13.1 — 4 April 2026
- **Rule 28I:** Note added that `@emlAssertFullViewport` takes no
  parameters (reads from drawn extent globals), preferred over raw
  `Select outer viewport:` per Rule 34.
- **Rules 28J, 28K, 29, 30:** Stale file references
  (`EML_DRAWING_PROCEDURES.txt`) updated to
  `EML_PROCEDURE_REGISTRY.md`.
- **Rule 29:** `@emlHandleStereo` and `@emlApplyChannelChoice` now
  implemented in `eml-graph-procedures.praat` v3.18. `@emlCheckChannels`
  refactored to present user dialog instead of silent mono conversion.
  Guard patterns and specification unchanged — code now matches spec.

### 13.0 — 3 April 2026
- **Debugging Invariants:** New section after Rule 35. Compact list of
  constraints that must survive into deep debugging sessions regardless
  of context depth. Addresses observed drift where Claude drops MP rules
  as conversations lengthen.
- **Rule 5D (Reserved variable names):** `e`, `pi`, and `undefined` are
  Praat constants that cannot be used as variable names. Common collision
  with loop counters and procedure parameters.
- **Rule 36 (Tutorial content verification):** GUI step-by-step
  instructions (menu paths, editor actions, button labels) must never be
  generated from training data. All GUI steps must be empirically verified
  or sourced from the Praat manual.
- **House Rule (Demo window font state):** `demo Font size:` must be set
  exactly once. Use `demo Text special:` for all text rendering to avoid
  font-size-dependent x-offset drift.
- **Handoff template extracted** to `HANDOFF_TEMPLATE.md` in Project
  Knowledge. Step 4 now references the external file instead of inlining
  ~80 lines of template that consumed context on every turn.
- **Developer Mode extracted** to `DEVELOPER_MODE_ADDON.md`. Removed from
  core prompt to reduce token load for PraatGen users. Development
  projects add the addon file to Project Knowledge.

### 12.2 — 20 March 2026
- **PRAAT_DEFINITIVE_CATALOGUE.txt** added to Project Knowledge — complete
  Praat capability inventory extracted from v6.4.62 C++ source code via
  git clone and automated parsing. Contains 2,089 single-class commands
  with parameter defaults, 360 cross-class commands, 318 menu commands,
  336 Formula engine functions, class hierarchy for all 136 object types,
  and scripting engine reference. Verified 483/483 random-sampled commands
  against source with 0 errors, 0 parameter mismatches.
- **Reference Retrieval Protocol:** New table entry for the catalogue as
  fallback/verification source. New loading protocol rule (item 10):
  check catalogue before concluding a command or capability does not exist.
- **Rule 12 (Command verification):** PRAAT_DEFINITIVE_CATALOGUE.txt added
  as a Tier 1 instant-verification source alongside COMMANDS_*.txt and
  WHITELIST_CURRENT.txt.
- **Rule 24 (Confidence and escalation):** New "Capability verification
  (hard)" sub-rule — before asserting Praat cannot do something, load and
  search the catalogue. Lists the most commonly underestimated capabilities.
- **Coverage gap closed:** David Weenink's extensions (dwtools/) now have
  command-level reference coverage via the catalogue.

### 12.1 — 2 March 2026
- Extended thinking management protocol (Rule 31)
- Computational verification via Python/scipy sandbox (Rule 32)
- UX standards (Rule 33, APPENDIX_F)
- ET gates at COMMAND PLAN, code generation, and debugging phases
- Context budget awareness and handoff escalation in debugging loop
- Thinking token discipline and efficiency constraints