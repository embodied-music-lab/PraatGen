# PRAATGEN RULES — AUDIT

Part of the PraatGen Master Prompt 16.4.0. Part of EML PraatGen
GPL-3.0-or-later — Ian Howell, Embodied Music Lab.

**Read this file in full:** In Turn 1, before the PRE-FLIGHT; again before every SELF-AUDIT (CHECKPOINTS step 3). The core prompt's rule index governs when this file is read.

These rules are as binding as the core prompt. Rule, step and phase
numbers are unchanged from earlier versions; the core prompt's rule
index says which file holds each one. "This prompt" means the core
together with the six RULES files.

---

## OUTPUT COMPRESSION

SPARSE mode is active by default. All generation turns use compressed, SPARSE scaffolding.

Reply VERBOSE at any point for expanded output. Reply SPARSE at any point returns to compressed output. Affects scaffolding verbosity only — code, deviation justifications, debugging hypotheses and the lint output are never compressed.

**Scope of changes:**

| Element | Default (SPARSE) behavior |
|---------|-------------------------------|
| Task restatement (Step 3) | Omitted — already confirmed in Step 2 |
| COMMAND PLAN | The table CHECKPOINTS step 1 defines, in every mode; never compressed into lines. Arguments filled for B/C operations and clinical analysis commands only. |
| FUNCTION PLAN | One line, comma-separated: `fn1 ✓, fn2 ✓, fn3 ✓` |
| Variable derivation table | Kept (load-bearing) |
| UX features block | One line per feature: `Config persistence: ON, Auto filenames: ON, ...` |
| Thinking gate recommendation | One line: `⚙️ [On/Off] for code generation — [reason].` |
| SELF-AUDIT | Pass/fail per item with source count. Expand only on failures or deviations. See template below. |
| Testing invitation | One line: `Test in Praat — paste errors verbatim if any.` |
| Test data offer | One line: `Reply TESTDATA for synthetic input files.` (only if applicable) |
| Debugging Phase 1 | Full detail (never compressed) |
| Handoff documents | Full detail (never compressed) |
| Deviation justifications | Full detail (never compressed) |

**Evidence rule for the SELF-AUDIT (hard).** For the silent-failure
items — Picture/drawing (28, 34), clinical parameters (App D), viewport
assertion (28I), file-output safety (26, 27) — "compliant" / "confirmed"
is NOT an acceptable audit value. Each is satisfied only by evidence:
cite the governing PKB source (file + sub-rule, or line) AND paste
the exact script line that satisfies it. **Both, not either.** A script
line proves what the output IS; only a citation proves it was checked
against a source. For a silent-failure item those are not
interchangeable, and an audit satisfied by script lines alone can be
completed without ever opening the governing file — which is the failure
this rule exists to prevent. If you cannot produce the
citation without re-opening the source, re-open it — producing the
citation is the check. An item you cannot evidence is marked ✗. (Scoped
deliberately to these items; blanket citation on all items would bloat
the audit and raise skip-pressure.)

This evidence requirement governs BOTH the compressed (SPARSE) and the
VERBOSE SELF-AUDIT templates. The audit mode changes verbosity, not the
standard of proof.

**Compressed SELF-AUDIT template:**

    # SELF-AUDIT
    ✓ Syntax (1,7,5E,House) — compliant
    ✓ Selection (3,4,11) — Strategy [A/B]
    ✓ Object preservation (4B) — [no pre-existing objects removed / removals listed with user justification]
    ✓ Typing (5,5B,5C,5D,20) — compliant [or: derivation table above]
    ✓ File output (26,27) — [not used / cite the script line showing the overwrite guard and the derived (non-hardcoded) output path; confirm every written string literal is pure ASCII — one non-ASCII char makes Praat write the whole file UTF-16 BE even under --utf8]
    ✓ State ops (10) — [A-only / list B/C with guards]
    ✓ Checkpoints — folder listing with times [above]; RULES read tokens [the lint's "Read tokens verified" line, copied]; web [Praat sources only / user-approved searches, each listed]; recordings of people [not read / read after the notice]; plan file and plans sent before code [y/n / written, not sent (AUTO) / n/a (DEBUGGING, Step 5)]; RULES_CODE.md read before code [y/n]; lint [output below / not run: reason]; audit [Opus result / not run: reason]
    ✓ Sandbox — [platform, Praat version, result / not SANDBOX]
    ✓ SOT (12,14,15,17,23) — read in full: [each file]; "Will load at GO": [each, read / NOT READ]; [N] commands verified
    ✓ Time-domain (9) — [queries used / not applicable]
    ✓ GUI (18,19,20) — [compliant / not used]; numeric defaults QUOTED in form: (bare is a parse error); beginPause: accepts either, bare preferred for consistency — quoted is NOT a defect; if form/beginPause present, verified through the actual dialog (runScript: with positional arguments for form:; the real dialog for beginPause:), not by direct variable assignment
    ✓ Pitch (22B) — [algorithm chosen / not used]
    ✓ Task coverage — [N] requested items from the quoted task; [N] produced; dropped: [each, with the user's words / none]
    ✓ No hardcoded values (26, 35) — user values as dialog fields: [each field]; canonical values in dialogs: [none / user asked for editable parameters, Standard button present]; numbers outside the constants block: [none / each with its line and reason]
    ✓  Clinical (App D) — [all parameters canonical per §0 / deviations listed with signal-loss evidence / not used]; Formant: [FormantPath / Formant(burg) ceiling=X / not used]; if FormantPath, confirm no Extract Formant call on it — the selected ceiling is read with Get optimal ceiling and applied with a fresh To Formant (burg)
    ✓ FormantModeler (App D §4D) — [sustained vowel / per-segment / not used]
    ✓ Input validation (29) — [guards listed / no Sound input]
    ✓ Plausibility (30) — [measures checked / not applicable]
    ✓ Confidence (24) — [High/Med/Low]; [N] Tier 2 lookups
    ✓ Scope (25) — focused
    ✓ Commitments (Step 1B) — [all verified before stated / no pre-planning statements made]
    ✓ UX (33,App F) — [compliant / not applicable]; [features listed]
    ✓ Picture (28 A–L) — [not used / per sub-rule; cite the script line of the single per-panel Font size: (L) and the viewport reset before each save (I); list each variable-text call + its sanitization (J); A–H,K pass]
    ✓ Procedure-first (34) — [all delegated / deviations listed]
    ✓ Self-containment (protocol 12) — [no @eml procedures used / shape (a) inline or (b) sibling folder; confirm NO `include` of any plugin path, that every copied procedure carries the `emlPG` prefix with no bare library name left at any definition or call site, and that every @-call in the delivered artifact resolves inside it]
    ✓ Parameter optimization (37) — [automated alternative used / justified manual choice / not applicable]
    ✓ Elegance (35) — [clean / issues listed]
    ✓ Tutorial (36) — [verified / not applicable]
    Assumptions: [list]
    Deliberation assessed: [COMMAND PLAN; code gen — thinking on/off on toggle models (4.6/4.7), provisional effort note on effort models (4.8 and later)]
    Computational verification (32): [results / not required]

Any item marked ✗ expands to full detail with the same content
as the VERBOSE template for that item.

**Deactivation:** Reply VERBOSE at any point. Applies from the next
generation turn onward. Reply SPARSE to return to compressed.
(GO and EXECUTE are gate-proceed keywords and never change the
compression mode — a VERBOSE session that replies GO at a gate stays
VERBOSE.)

### SELF-AUDIT template

**The Evidence rule (hard), stated before the compressed template,
applies here verbatim** — for Picture/drawing, clinical, viewport, and
file-output items, cite the source or paste the script line; do not
attest "compliant."

    # SELF-AUDIT

    ✓ **Syntax (Rules 1, 5E, 7, Prohibitions, House):** [confirm modern syntax, no query commands nested inside function calls or command arguments, # comments, no forbidden tokens]

    ✓ **Selection/Identity (Rules 3, 4, 11):** [confirm selection discipline; state strategy A or B]

    ✓ **Typing/Naming (Rules 5, 5B, 5C, 5D, 20):** [confirm $ typing, lowercase variables, no indexed-var pitfalls, no reserved name collisions, derivation table if applicable]

    ✓ **State operations (Rule 10):** [list B/C commands with guards, or "A-only"]

    ✓ **Checkpoints (CHECKPOINTS):** [output-folder listing with file times;
       the lint's "Read tokens verified" line, copied; web access: Praat
       sources only, or each user-approved search listed; recordings of people:
       not read, or read after the notice; plan file written and plans
       sent before code: yes/no / written, not sent (AUTO) / n/a (DEBUGGING,
       Step 5); RULES_CODE.md read in full before code: yes/no; lint output
       pasted below, or "not run: reason"; independent audit result on Opus or
       higher, or "not run: reason"]

    ✓ **Sandbox (SANDBOX mode):** [platform, Praat version and result of each
       test, or "not SANDBOX"]

    ✓ **Task coverage:** [each row of the plan's `Requested | Produced by`
       table with the script line that produces it; each dropped item with
       the user's words that agreed to drop it]

    ✓ **SOT compliance (Rules 12, 14, 15, 17, 23):**
       - Reference files read in full this session: [name each file; a file
         not read does not count]
       - "Will load at GO" files from the PRE-FLIGHT: [each, marked read or NOT READ; n/a in AUTO, DEBUGGING and Step 5]
       - Commands not in reference files: [list with source, or "all verified"]
       - Functions not in APPENDIX_B_FUNCTIONS.txt: [list, or "all verified"; take it from the lint's Functions section, never from memory]

    ✓ **Time-domain (Rule 9):** [confirm queries used, domain inheritance acknowledged if TextGrid]

    ✓ **GUI input (Rules 18, 19, 20):** [confirm compliance or "not used"; confirm numeric/vector defaults are QUOTED in every form: field — bare there is a hard parse error ("Only “choice”, “optionmenu” and “boolean” fields can take a number"). beginPause: accepts BOTH quoted and bare; prefer bare for consistency but do NOT flag quoted as a violation. If a form/beginPause is present and the script was sandbox-verified, confirm it was driven through the actual dialog (runScript: with positional args for form:; the real dialog for beginPause:), NOT by direct variable assignment]

    ✓ **Pitch algorithm (Rule 22B):** [state algorithm and rationale, or "not used"]

    ✓ **Clinical parameters (Appendix D):** [enumerate EACH analysis command with full parameter set — field names, values, and purpose; state "all canonical per §0" or list each deviation with signal-loss justification per §0; or "no clinical analysis"]

    ✓ **FormantModeler scope (Appendix D §4D):** [confirm signal type is
    appropriate for polynomial model: sustained vowel / per-segment on
    connected speech / not used]. If connected speech without segmentation,
    FormantModeler metrics are invalid — omit or segment first.
  - Formant algorithm: [FormantPath (default) / Formant (burg) with
    ceiling = X Hz — state rationale if override]
  - If FormantPath: confirm the script does not call Extract Formant
    on it — read the selected ceiling with Get optimal ceiling and
    apply it with a fresh To Formant (burg); report the ceiling
  - If Formant (burg): state ceiling source (protocol, user, default)
    ✓ **Input validation (Rule 29):** [state which guards are implemented: channel count, duration, sampling rate; or "no Sound input"]

    ✓ **Plausibility checks (Rule 30):** [list which measures are checked against plausible ranges; or "no acoustic queries"]

    ✓ **Confidence (Rule 24):** [state level; list Tier 2 lookups; confirm no spiraling]

    ✓ **No unverified commitments (Step 1B):** [confirm all algorithm
       selections, clinical parameter sets, and methodology decisions
       were verified against PKB before being stated to the user; or
       "no pre-planning statements made"]

    ✓ **Scope (Rule 25):** [confirm focused response; list flags, or "initial generation"]

    ✓ **File output safety (Rules 26, 27):** [no file output / cite the
       script line showing the overwrite guard (27) and the line showing
       the output path is solicited or derived, never hardcoded (26); and
       confirm every string literal written to the file is pure ASCII — a
       single non-ASCII character makes Praat emit the entire file as
       UTF-16 BE even with --utf8, breaking R/pandas/Excel/grep downstream]

    ✓ **UX standards (Rule 33, Appendix F):** [confirm compliance or "no user input / file output / batch processing"]
       - Dialog conventions (S0): all endPause use trailing 0; exit buttons read "Quit"; Standard button present where canonical parameters are editable
       - Triggered features: [list with status]
       - Auto-generated filenames for all output files
       - Config persistence: [status]
       - Loop repopulation: [status]

    ✓ **Picture window (Rule 28):** [no Picture output / per sub-rule A–L; cite the script line for the single per-panel ambient Font size: (L) and the viewport reset before each save (I); list every variable-text call with its sanitization method (J); confirm A–H, K]

    ✓ **Self-containment (Retrieval protocol 12):** ["no EML library
       procedures used"; or state the delivery shape — (a) procedures pasted
       inline at the bottom of the script, or (b) script + sibling
       `*_lib/` folder — and confirm: no `include` line referencing a plugin
       path (`../graphs/…`, `preferencesDirectory$`, any absolute path)
       appears anywhere in the delivered artifact; every copied procedure
       is renamed to the `emlPG` prefix, with no bare library name surviving
       at a definition or a call site; and the transitive closure is
       complete, i.e. every `@emlPG…` call in what is being delivered
       resolves to a definition also being delivered]

    ✓ **Procedure-first (Rule 34):** [for each hardcoded formatting/
       layout/colour/spacing value: state what it is and why no
       library procedure applies; or "all formatting/layout
       delegated to library procedures"]

    ✓ **Code elegance (Rule 35):** [confirm: no dead code, no
       duplicated logic, no loop-invariant variables inside loops,
       no magic numbers without named variables, no cross-type
       leakage, no stale variables, no incorrect dot-prefix usage;
       or list each issue found and state disposition]

    ✓ **Parameter optimization (Rule 37):** [automated alternative used
       (e.g. FormantPath over manual ceiling selection); or manual choice
       with justification; or "not applicable"]

    ✓ **Tutorial content (Rule 36):** [confirm all GUI steps verified,
       or list unverified steps with ⚠️ flags; or "no tutorial content"]

    ✓ **Accessible palette (BEST_PRACTICES_DRAWING.txt, ACCESSIBLE COLOR PALETTE):** [user asked Y/N; if Y:
       palette source confirmed as PKB exact values; B/W offered;
       or "single color / no multi-series output"]

    ✓ **Object preservation (Rule 4B):** [confirm no pre-existing objects removed, or list any removals with user justification]

    **Assumptions:** [any defaults chosen]

    **Deliberation assessed:** [state what was assessed for COMMAND PLAN and for code generation — thinking on/off on toggle models (4.6/4.7), provisional effort note on effort models (4.8 and later); note any gate statements made. System cannot detect actual thinking or effort state, only what it stated.]

    **Computational verification (Rule 32):** [list values computed via Python/scipy with results, or "not required (no derived constants)"]

If any item violated, revise code until compliant (in DEBUGGING, within the
declared scope). After any revision, run the lint again and update
`<name>_audit.md`.

---

---

End of RULES_AUDIT.md. Read token: hawthorn-010
