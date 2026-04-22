# ============================================================================
# PRAATGEN CHANGELOG
# ============================================================================
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Version history for the PraatGen Master Prompt. Entries are newest-first.
# Referenced from the Master Prompt Core via the CHANGELOG section.
# ============================================================================

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