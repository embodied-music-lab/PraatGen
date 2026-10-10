# PRAATGEN RULES — CODE

Part of the PraatGen Master Prompt 17.0.0. Part of EML PraatGen
GPL-3.0-or-later — Ian Howell, Embodied Music Lab.

**Read this file in full:** At GO, before the plans; and again before writing or changing any .praat file (CHECKPOINTS steps 1 and 2). The core prompt's rule index governs when this file is read.

These rules are as binding as the core prompt. Rule, step and phase
numbers are unchanged from earlier versions; the core prompt's rule
index says which file holds each one. "This prompt" means the core
together with the six RULES files.

---

## Praat correctness contract (hard requirements)

### Rule 1: Modern syntax

- No `...` in commands
- Colon only if command takes arguments
- No-argument commands have no colon (e.g., `Get start time`, `Get end time`)

### Rule 1B: Formula syntax (hard)

All Formula commands require the tilde (`~`) prefix before the expression:

**Correct:** `Formula: ~self * 2`
**Incorrect:** `Formula: self * 2`

---

### Rule 3: Selection discipline

Selection-dependent commands must be preceded by explicit selection (`selectObject:`, `plusObject:`, `minusObject:`, `select all`) within previous 2 lines.

---

### Rule 4: Object identity discipline

- Use `numberOfSelected()` + `selected()` / `selected$()` / `selected#()` for iteration
- Capture and reuse object IDs for derived objects
- Do not assume names remain unique after operations

### Rule 4B: Object preservation (hard)

Scripts must never remove objects that existed before the script ran. Only objects created by the script may be removed. The starting state described by the user is a contract — every object present at script start must still be present at script end unless the user explicitly requests its removal.
Implementation: Capture IDs of pre-existing objects before any processing. Never pass those IDs to removeObject:. When cleaning up derived objects (intermediate analysis products, temporary copies), verify against the starting set before removal.
SELF-AUDIT must confirm: "No pre-existing objects removed" or "Pre-existing object [name] removed at user's explicit request."

---

### Rule 5: String/numeric typing

- String variables end with `$`
- No `$` on numeric variables
- File paths are strings

### Rule 5B: Variable naming (hard)

All variable names begin with lowercase letter. No exceptions.

---

### Rule 5C: Indexed variable syntax (hard)

Praat uses bracket notation `[]` for indexed variable access. This applies
to numeric variables, string variables, procedures, and main script body.

**Correct patterns:**

| Pattern | Context | Scope |
|---------|---------|-------|
| `var[i]` | Main body, numeric | Main body |
| `var$[i]` | Main body, string | Main body |
| `data#[i]` | Main body, vector | Main body |
| `.var[.i]` | Procedure, numeric | Local |
| `.var$[.i]` | Procedure, string | Local |
| `.data#[.i]` | Procedure, vector | Local |
| `.var[i]` | Procedure, numeric | References main-body `i` |

**Scope rule:** The `.` prefix on the index variable controls which
scope is referenced, independent of the `.` prefix on the array variable.
Inside a procedure, `.data#[.i]` and `.data#[i]` access different indices.

**Procedure-local vs. caller-scope access (hard):** Dot-prefix variables
(`.var`, `.var$`, `.data#`) are procedure-local. They exist only within
the procedure body and are inaccessible from the script body by name.
From the caller's scope, procedure outputs are accessed via the
qualified form `procedureName.variableName` (no leading dot):

    procedure computeStats: .values#
        .mean = mean (.values#)
        .sd = stdev (.values#)
    endproc

    @computeStats: myData#
    avgValue = computeStats.mean    ; caller accesses output by qualified name
    sdValue = computeStats.sd

Procedure outputs are durable across subsequent procedure calls — they
persist until the same procedure is called again, at which point they
are overwritten. To preserve outputs across calls, copy them to
caller-scope variables immediately after the call.

**Procedure parameter types (verified Praat 6.4.67):** A procedure
parameter accepts numeric, string (`$`), numeric vector (`#`), string
vector (`$#`), and matrix (`##`) types. Each may be passed as a literal or
as a variable already holding that data — matrix and string-vector
parameters are not special-cased:

    procedure demo: .count, .name$, .samples#, .labels$#, .grid##
        ...
    endproc
    @demo: 3, "trial1", {1.2, 3.4}, {"a", "b"}, {{1, 2}, {3, 4}}

**Arithmetic in indexes:** Arithmetic expressions work inside brackets.

    .val = .data#[.i + 1]
    .val = .data#[.i * 2]
    .val = .data#[(.i + 3) / 1]

**No other indexing syntax exists in the main script body.** Single-quote
variable name interpolation (`var'.i'`, `var'.i'_'.j'`) works inside
procedure bodies only (dot-prefixed variables). It fails in the main
script body with "Unknown symbol." See the interpolation scope constraint
below.

# ============================================================================
# STRING VARIABLE NAMING: INDEXED vs INTERPOLATED
# ============================================================================
#
# Praat has two mechanisms for dynamic variable names. The $ placement
# differs between them and mixing them up causes cryptic errors.
#
# INDEXED (bracket notation — Rule 5C):
#   $ goes BEFORE the brackets.
#     myVar$[i]           — correct
#     myVar[i]$           — WRONG (syntax error)
#     .localVar$[.i]      — correct (procedure scope)
#
# INTERPOLATED (single-quote expansion):
#   $ goes at the END of the fully resolved name.
#     myVar'.i'_'.j'$     — correct (expands to myVar1_2$)
#     myVar$'.i'_'.j'     — WRONG (expands to myVar$1_2, Praat sees
#                           myVar$ as complete name, chokes on 1_2)
#
# NUMERIC interpolated variables have no $ issue:
#     myVar'.i'_'.j'      — correct (expands to myVar1_2)
#
# The error message for the wrong pattern is:
#   Missing "=", "+=", "<", or ">" after string variable myVar$1_2
#
# This does NOT indicate a missing operator — it means Praat parsed
# the variable name boundary incorrectly because $ was misplaced.
#
# Provenance: EML session 20 March 2026. Bug hit in annotMatrixCell
# dynamic variables (comparison matrix). 9 occurrences corrected.
# ============================================================================

**Matrix (`##`) variables (hard):**

Praat has native 2D matrix support via the `##` suffix. When data is
logically 2D (rows × columns), use matrix variables — do not flatten
into vectors with computed offsets or simulate with interpolated
indexed variables.

**Creation:**

| Pattern | Result |
|---------|--------|
| `m## = zero## (nRows, nCols)` | All-zero matrix |
| `m## = randomGauss## (nRows, nCols, mu, sigma)` | Random-filled matrix |
| `m## = outer## (a#, b#)` | Outer product of two vectors |
| `m## = transpose## (source##)` | Transposed copy |
| `m## = {{ 1, 2 }, { 3, 4 }}` | Matrix literal (nested braces) |

**Element access:**

    # Read from matrix into scalar:
    val = m## [row, col]

    # Write value into matrix element:
    m## [row, col] = newValue

Inside procedures, dot-prefix rules apply normally:

    .m## = zero## (.nRows, .nCols)
    .val = .m## [.row, .col]       # read
    .m## [.row, .col] = .newVal    # write

**Querying dimensions:**

    nRows = numberOfRows (m##)
    nCols = numberOfColumns (m##)

**Operations (verified 22 April 2026):**

| Function | Purpose |
|----------|---------|
| `mul## (a##, b##)` | Matrix multiplication |
| `mul# (m##, v#)` | Matrix × vector |
| `mul# (v#, m##)` | Vector × matrix (row-vector form) |
| `transpose## (m##)` | Transpose |
| `solve# (a##, y#)` | Solve A·x = y |
| `solve## (a##, y##)` | Solve A·X = Y (matrix RHS) |
| `rowSums# (m##)` | Row sums → vector |
| `columnSums# (m##)` | Column sums → vector |
| `sum (m##)` | Sum all elements |
| `mean (m##)` | Mean of all elements |

**Arithmetic operators (elementwise):**

    c## = a## + b##       # elementwise addition
    c## = a## * b##       # elementwise multiplication (NOT matrix multiply)
    c## = a## * 3         # scalar multiplication

**CAUTION:** The `*` operator between two matrices is ELEMENTWISE, not
matrix multiplication. Use `mul## (a##, b##)` for proper matrix
multiplication. This is a common error.

**Preference rule:** For 2D data, prefer `##` matrices over:
- Flat vectors with computed offsets (`allData# [groupStart[i] + j]`)
- Interpolated indexed variables (`.val'.i'_'.j'`)
- Parallel vectors simulating columns

Flat vectors with computed offsets remain appropriate in main-body code
when single-quote interpolation would be needed for the 2D case (per
the interpolation scope constraint below), but inside procedures,
native `##` matrices are always preferred.

**Matrix variables vs. Matrix objects:** Matrix variables (`##`) are
script-level data structures — they exist in memory, require no
selection, and support direct element access. Matrix objects are
Praat objects in the Objects window (created via `Create simple
Matrix:`, `To Matrix`, etc.) — they require selection and are queried
via commands. Do not confuse the two. For intermediate computation,
matrix variables are faster and simpler. For interoperability with
Praat's object ecosystem (drawing, Formula, converting to/from other
types), use Matrix objects. There is no `object##()` function to
convert between them — use query commands in a loop.

**Not available in scripting (catalogue ghosts):** The following
functions appear in the Praat source code but are NOT exposed to the
scripting Formula engine. Do not use them:
- `inner## (a##, b##)` — "Unknown function" error
- `object## (id)` — "Unknown function" error
- `linear## (nRows, nCols, supplier)` — syntax unknown, unverifiable

**String vector (`$#`) variables (hard):**

Praat has native string arrays via the `$#` suffix. Variable naming
follows the same conventions as string variables: `$` marks string
type, `#` marks vector type.

**Creation:**

| Pattern | Result |
|---------|--------|
| `a$# = { "hello", "goodbye" }` | String vector literal |
| `a$# = readLinesFromFile$# (path$)` | File lines → string vector |
| `a$# = fileNames$# ("folder/*.wav")` | File listing → string vector |
| `a$# = folderNames$# ("folder/*")` | Folder listing → string vector |
| `a$# = splitByWhitespace$# (text$)` | Tokenize by whitespace |
| `a$# = splitBy$# (text$, separator$)` | Tokenize by specific separator |

**FIXED in Praat 6.4.65 (sandbox-verified 15 May 2026).** Earlier versions (≤ 6.4.63) crash with `empty$# (n)` — segfault in `str32cmp` due to NULL pointer instead of empty string in allocated slots. For scripts targeting Praat 6.4.65 or later, `empty$# (n)` works correctly. For scripts that must support Praat ≤ 6.4.63, use the literal-initialization workaround:

    a$# = { "", "", "", "", "" }

For dynamic sizes on older Praat, create with any content and overwrite in a loop.

**Element access:**

    val$ = a$# [1]             # read
    a$# [3] = "new value"      # write

Inside procedures, dot-prefix rules apply:

    .sv$# = { "alpha", "beta" }
    .val$ = .sv$# [.i]         # read
    .sv$# [.i] = "text"        # write

**Querying dimensions:**

    n = size (a$#)

**Operations (verified 22 April 2026):**

| Function | Purpose |
|----------|---------|
| `sort$# (a$#)` | Alphabetical sort (Unicode order) |
| `sort_numberAware$# (a$#)` | Sort with number awareness ("file2" before "file10") |
| `shuffle$# (a$#)` | Random permutation |

**Batch processing pattern:** `fileNames$#` returns a string vector
directly — no Strings object creation or cleanup needed:

    files$# = fileNames$# (inputFolder$ + "/*.wav")
    for iFile from 1 to size (files$#)
        filePath$ = inputFolder$ + "/" + files$# [iFile]
        soundId = Read from file: filePath$
        # ... processing ...
        removeObject: soundId
    endfor

This is simpler than the `Create Strings as file list:` pattern
(which creates a Strings object requiring `Get string:` queries and
`removeObject:` cleanup). Both work; prefer `fileNames$#` for new
scripts when `sort_numberAware$#` ordering is acceptable.

**No string matrices:** Praat does not have `$##` (2D string arrays).
For 2D string data, use interpolated indexed variables inside
procedures (`.cell'.i'_'.j'$`) or parallel string vectors.

**Interpolation scope constraint (hard):** Single-quote variable name
interpolation works inside procedure bodies only (dot-prefixed
variables). It fails in the main script body with "Unknown symbol."

| Pattern | Procedure body | Main body |
|---------|----------------|-----------|
| `.var'.i'` (single) | WORKS | n/a |
| `var'.i'` (single) | n/a | **FAILS** |
| `.var'.i'_'.j'` (double) | WORKS | n/a |
| `var'.i'_'.j'` (double) | n/a | **FAILS** |
| `var[i]` (bracket) | WORKS | WORKS |
| `var#[i]` (vector) | WORKS | WORKS |

Interpolation depth is irrelevant — scope is the only factor.

In main script body, always use bracket notation (`var[i]`) or vector
notation (`var#[i]`). Never use single-quote interpolation for variable
names in main body code. For multi-dimensional indexing in main body,
use flat vectors with computed offsets:
`allData#[groupStart[i] + j]`.

Inside procedures, single-quote interpolation at any depth is valid
and is the standard pattern for the EML library's drawing primitives
(e.g., `.y'.e'`, `.d'.e'` in `@emlDrawViolin`).

Provenance: Empirical testing, 5 April 2026. Four test scripts
confirmed across single/double depth × procedure/main scope.

---

### Rule 5D: Reserved variable names (hard)

Praat reserves the following identifiers as constants. They cannot be
used as variable names, procedure parameter names, or loop counter names:

- `e` — Euler's number (2.71828...)
- `pi` — Pi (3.14159...)
- `undefined` — The undefined value

Attempting to assign to these produces: `You cannot use "e" as the name
of a variable (e is the constant 2.71...)`.

Common collisions: loop counters (`for e from 1 to n`), generic
procedure parameter names (`.e`), single-letter iterators in nested
loops. Use descriptive names instead.

---

### Rule 5E: Command/function boundary (hard)

Praat has two distinct return-value mechanisms that are not
interchangeable:

**Commands** (`Get total duration`, `Get mean:`, `Get value at time:`,
`Count:`, `Get number of strings`, etc.) are **statements**. They
execute on a line by themselves and assign their return value to a
variable via `=`. They cannot appear inside function calls, as
arguments to other commands, or inside formula expressions.

**Functions** (`sin()`, `min()`, `fixed$()`, `length()`,
`randomUniform()`, `hertzToSemitones()`, etc.) are **expressions**.
They compose freely inside other expressions, function calls, and
command arguments.

The boundary is syntactic, not semantic. A command that "gets a
number" is still a command — it cannot be used where a function is
expected.

**Correct patterns:**

    # Query → variable → use in expression
    totalDuration = Get total duration
    appendInfoLine: "Duration: ", fixed$ (totalDuration, 2), " s"

    # Query → variable → use as command argument
    nIntervals = Get number of intervals: 1
    for iInterval from 1 to nIntervals

    # Functions compose freely
    semitones = 12 * log2 (freq / 261.63)
    label$ = replace$ (left$ (name$, 10), "_", " ", 0)

**Incorrect patterns (all fail at runtime):**

    # Command nested inside function — "Unknown symbol «Get»"
    appendInfoLine: fixed$ (Get total duration, 2)

    # Command as argument to another command
    Extract part: 0, Get total duration, "rectangular", 1, "no"

    # Command inside formula
    Formula: ~self / Get maximum: 0, 0, "sinc70"

**Diagnostic:** The error message `Unknown symbol «Get» in formula`
(or `«Count»`, `«Number»`, etc.) always indicates a command used
where a function is expected. The fix is always the same: extract to
a variable on the preceding line.

**Note:** This constraint applies even when the command takes no
arguments and looks syntactically like a function. `Get total duration`
returns a number, but it is a command, not a function — it requires
object selection, executes as a statement, and cannot be composed.

---


### Rule 6: Procedures

- No procedure definitions inside other procedures (Praat parses them but breaks scope on return)
- Calls to other procedures from within a procedure body are standard and expected
- Calls use @ProcedureName
- No return-value patterns from other languages

**Positional binding (hard):** Call values bind to parameters by position,
in order. Praat has no named arguments — the Nth value in the call fills the
Nth parameter in the definition. A value in the wrong position fills the
wrong parameter (no error if the types happen to match). Generated calls
must match the definition's parameter order exactly.

**Call may precede definition:** A procedure definition resolves regardless
of its position in the file, so a call written textually before the
definition still runs. Procedures may be placed anywhere; conventional
placement is all at the top or all at the bottom of the script, not inline
at the call site.

**Undotted variables are global inside procedures — read AND write (hard):**
A procedure, even one with no parameters, can read an undotted (global)
main-script variable directly, and can also overwrite it; the change
persists after the procedure returns. This is a silent-mutation hazard.
Generated procedures should take their inputs as dotted, procedure-local
parameters rather than reaching for main-script globals, and must not write
to an undotted variable unless that side effect is explicitly intended.
Dotted (`.var`) variables remain procedure-local.

**`include` for cross-script reuse:** `include path.praat` is a preprocessor
directive — no colon, an unquoted path, and the path cannot be a variable.
It resolves relative to the script's location and pulls the included file's
procedure definitions into scope.

(Procedure parameter types and the qualified-name output mechanism are in
Rule 5C. Verified Praat 6.4.67.)

---

### Rule 7: Comments

Praat has two comment syntaxes with non-overlapping roles. The Master Prompt enforces a hard separation between them.

- **Line-start comments (whole-line):** `#` only. `#` must be the first non-space character on the line. Use `#` for all standalone comments — file headers, section headers, multi-line explanatory blocks, single-line annotations on their own line.
- **Inline comments (after code):** `;` only. `;` is the only comment marker that may follow code on the same line.
- **Never mix them.** `;` is never used at the start of a line. `#` is never used inline (it parses as code and produces a runtime error).

SELF-AUDIT must verify comment hygiene: every line-start comment uses `#`; every inline comment (if any are present) uses `;`; no `#` after code on the same line; no `;` at the start of a line.

---

### Rule 8: Version stability

Prefer stable constructs. Avoid editor-only commands unless required. Prefer numeric indexing over naming-based addressing.

---

### Rule 9: Time-domain queries (hard)

Never access `xmin`/`xmax` directly. Objects may not start at 0.

Obtain bounds via queries after selection:
- `Get start time` → domain start (may be non-zero)
- `Get end time` → domain end
- `Get total duration` → length only

**Absolute positions** (boundaries, midpoints): Require both start and end time.
**Durations only:** `Get total duration` suffices.

**TextGrid domain inheritance:** TextGrids created from other objects inherit the source's time domain, not 0.
**Formula context exception:** Inside `Formula:` expressions (prefixed
with `~`), the bare attributes `xmin`, `xmax`, `nx`, `dx`, `ymin`,
`ymax`, `ny`, `dy`, `ncol`, `nrow` refer to the object being modified
and ARE the correct access pattern. Rule 9's prohibition applies to
script-level code only, not Formula expressions. Use `Self.xmin` if a
script variable of the same name exists. To reference another object's
attributes inside a Formula, use `object[id].xmin` or
`object["Sound name"].nx`.
---

### Rule 10: State-dependent operation discipline (hard)

Operations are classified:

| Category | Examples | Behavior |
|----------|----------|----------|
| **A (Idempotent)** | `Set interval text:`, `Rename:`, `Formula:`, `selectObject:` | Always safe |
| **B (Additive)** | `Insert boundary:`, `Add point:`, `Insert interval:` | Fail if exists |
| **C (Destructive)** | `Remove boundary:`, `Remove point:`, `Remove interval:` | Fail if absent |

**Required guards for B/C:**

Before any B/C operation, either:
1. **Query-then-act:** Check state first, use conditional logic
2. **Design for idempotence:** Prefer A-category alternatives where possible

**Insert boundary: special requirements:**
- Query tier's time domain
- Verify `time > domainStart + 0.00001` AND `time < domainEnd - 0.00001`
- Skip or adjust if at domain edges

COMMAND PLAN must classify each command as A/B/C.

---

### Rule 11: Selection-set stability (hard)

When iterating with `numberOfSelected()` + `selected()`:

**Strategy A (preferred):** Snapshot IDs first: `ids# = selected# ("Sound")`, iterate list.

**Strategy B:** Reassert selection at top of each loop iteration.

If task says "process all open objects," script must create selection set (e.g., `select all`) — don't depend on preselection.

SELF-AUDIT must state which strategy.

---

### Rule 18: User input via `form` blocks (hard)

**Placement:** Before any executable code. One per script.

**Syntax:** `form: "Title"` ... `endform` (no colon on endform)

**Keyword casing (hard):** All form field type keywords are lowercase. No camelCase, no PascalCase.

**Numeric default values are quoted strings in `form:` (hard).** In a
`form:` block, the default for every `real`/`positive`/`integer`/`natural`
and every vector field (`realvector`/`positivevector`/`integervector`)
MUST be a quoted string: `natural: "Phase tier", "1"`. A bare number is a
parse error — `Only "choice", "optionmenu" and "boolean" fields can take a
number` (verified Praat 6.4.67). Only `boolean`, `choice`, and `optionmenu`
take a bare number in `form:`. **The asymmetry reverses in `beginPause:`**,
where numeric defaults are written bare — see Rule 19 and APPENDIX_C. The
common failure is pattern-matching an adjacent `boolean` (legitimately bare)
when adding a numeric field. SELF-AUDIT must confirm default-type per block.

**Lowercase keywords:**
`real`, `positive`, `integer`, `natural`, `word`, `sentence`, `text`, `boolean`,
`choice`, `optionmenu`, `option`, `comment`, `infile`, `outfile`, `folder`,
`realvector`, `positivevector`, `integervector`, `naturalvector`

`naturalvector` is **beginPause only** — the `form:` parser rejects it
("Unknown parameter type inside form"). The form field set is 18 keywords;
the beginPause set is 19. `left` and `right` are NOT field keywords
(verified Praat 6.4.67) and must not be emitted as field declarations.

**`left`/`right` as a label prefix (ranges).** Although they are not field
*types*, `left` / `right` as the FIRST WORD of a numeric field's label
place two boxes on one row (the range idiom), in both `form:` and
`beginPause:`. The two boxes bind separate variables by the normal Rule 20
algorithm applied to the full label (`left Time range (s)` →
`left_Time_range`, `right Time range (s)` → `right_Time_range`). Bare
`left`/`right` are also predefined constants (`left` = 1, `right` = 2). See
the APPENDIX_C "Side-by-side fields (ranges)" section.

**Full syntax reference:** Load APPENDIX_C_GUI.txt for complete field types, defaults, and examples.

**UI preference:** Use `infile:`, `outfile:`, `folder:` for paths — not `sentence:`.

**Variable derivation:** See Rule 20. COMMAND PLAN must include variable derivation table when form or beginPause used.

---

### Rule 19: User input via `beginPause`/`endPause` (hard)

**Placement:** Anywhere in executable code. Multiple allowed per script.

**Structure:**

    beginPause: "Title"
        # field declarations (same types as form, same lowercase keywords)
        # conditional logic permitted between fields
    clicked = endPause: "Button1", "Button2", defaultButton

**Numeric default values: bare is PREFERRED in `beginPause:`, but the
asymmetry is one-directional.** Sandbox-verified against Praat 6.6.30
(Linux x64v3), 29 July 2026:

| Block | Bare `1` | Quoted `"1"` |
|---|---|---|
| `form:` | **Parse error** — `Only “choice”, “optionmenu” and “boolean” fields can take a number` | Required |
| `beginPause:` | Works (house preference) | **Also works** — parses, renders, and binds correctly |

So: in `form:`, numeric and vector defaults MUST be quoted; bare is a hard
error that stops the script. In `beginPause:`, write them bare —
`natural: "Phase tier", 1` — for consistency with the rest of the library,
but **quoted is not a defect and must not be flagged as one.** An earlier
edition of this rule (13.9.3) stated the beginPause half as "must be bare";
that was an overclaim, and the SELF-AUDIT item derived from it would have
flagged compliant code. String/path field defaults are quoted in both.
SELF-AUDIT confirms the `form:` requirement, which is the one that breaks.

**Requirements:**
- Always capture `endPause` return value (button index, 1-based)
- Handle cancel path explicitly
- Use browse-type fields (`infile:`, `outfile:`, `folder:`) for paths

**Suppress Stop button:** Add cancel button index as final argument.

**Standard cancel handling pattern:**

 clicked = endPause: "Quit", "Continue", 2, 0
    if clicked = 1
        exitScript: "User cancelled."
    endif

**Cancel-button behavior (hard):** The cancel-button argument (final
numeric parameter to `endPause:`) designates one button as the cancel
button. This has three effects:

1. The Stop button is suppressed (same as using 0)
2. Closing the window is equivalent to clicking the cancel button
3. **Field variables are NOT updated** when the cancel button is
   clicked — they retain their prior values or remain undefined

The cancel button **does** write its index to `clicked`. It does not
interrupt the script. You must still handle the cancel path explicitly.

Source: Praat manual, Scripting 6.6 — "if the user closes the window,
this will be the same as clicking Cancel, namely that clicked will be 1
... and the variables learning_rate, directions and directions$ will
not be changed (i.e. they might remain undefined)."

**Preferred pattern (APPENDIX_F S0):** Use 0 as the final argument
(suppress Stop, no cancel designation) and handle all buttons
explicitly through `clicked`. This avoids the field-variable gotcha:

    clicked = endPause: "Quit", "Continue", 2, 0
    if clicked = 1
        exitScript: "User quit."
    endif

**Cancel-button pattern (also valid):** When you want window-close to
map to a specific button AND you want field variables preserved on
that path:

    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        # Field variables were NOT updated — safe to exit
        exitScript: "User cancelled."
    endif
    # Field variables WERE updated — safe to use them

**Caution with cancel-button designation:** If the cancel button is
clicked, field variables from that dialog retain whatever values they
had before the dialog opened. If they were undefined, they remain
undefined. Any code path after a cancel click that uses those variables
will fail silently or error. Always exit or skip processing on the
cancel path.

**Full syntax reference:** Load APPENDIX_C_GUI.txt for endPause signatures and examples.

---

### Rule 20: Variable derivation from GUI labels (hard)

**Algorithm (applies to both form and beginPause — verified Praat 6.4.67):**
1. **Truncate the label at the first `(`.** Everything from `(` onward is
   discarded, including any text after the closing paren.
   `"Pitch floor (Hz)"` → `"Pitch floor"`; `"Floor (Hz) max"` → `"Floor"`.
2. Trim leading/trailing whitespace.
3. Lowercase the **first character only**; preserve the case of all other
   characters. `"Max F0"` → `max_F0`; `"ABC def"` → `aBC_def`.
4. Replace **each** space with one underscore (consecutive spaces are NOT
   collapsed). `"Pitch  ceiling"` → `pitch__ceiling`.
5. Keep every other character verbatim.
6. Type suffix:
   - string fields (`word`, `sentence`, `text`, `infile`, `outfile`,
     `folder`) → `$`
   - vector fields (`realvector`, `positivevector`, `integervector`,
     `naturalvector`) → `#`
   - `choice:`/`optionmenu:` → TWO variables: `name` (numeric index) and
     `name$` (option text)
   - numeric (`real`/`positive`/`integer`/`natural`) and `boolean` → no suffix
   - `comment`/`option` → no variable

**Referenceability (hard):** A label containing an operator character
(`-`, `/`, `'`, etc.) or starting with a digit derives to a name that
EXISTS in Praat's symbol table but CANNOT be referenced in script code.
When generating a form, keep labels to letters, digits, and spaces (plus a
trailing parenthetical for units) so the derived variable is usable. A
derived name is referenceable only if, before the type suffix, it matches
`^[A-Za-z][A-Za-z0-9_]*$`.

**Height parameters are excluded from derivation.**

COMMAND PLAN must include variable derivation table when form or beginPause used.

---

### Rule 21: `pauseScript` (hard)

**Purpose:** Modal message with OK button. No input collected.

**Syntax:** `pauseScript: "Message"` or with concatenation.

**Rules:** `pauseScript:` displays a single-line message only — `newline$` in the message string is silently ignored by the dialog renderer (empirically confirmed, Praat 6.4.65). For multi-line user instructions, use `beginPause` with `comment:` fields:

    beginPause: "Instructions"
        comment: "Line 1 of instructions"
        comment: "Line 2 of instructions"
    clicked = endPause: "Stop", "Continue", 2, 0
    if clicked = 1
        exitScript: "User stopped."
    endif

No C-style escapes. Use `beginPause` if input needed.

---

### Rule 22: Info window output (hard)

**Commands:**
- `writeInfoLine:` — clears window, writes with newline
- `appendInfoLine:` — appends with newline
- `writeInfo:` / `appendInfo:` — without trailing newline

**Pattern:** `writeInfoLine:` once to clear, then `appendInfoLine:` for subsequent lines.

**Formatting:**
- `tab$` for columns
- `string$()` or `fixed$()` for numeric conversion
- Include header row with units

**Output richness standard:** Info window output for analysis/extraction scripts should include all of the following that apply:
1. Script identification line (what the script does)
2. Source identification (file path, object name, or batch count)
3. Column headers with units
4. Data rows
5. Summary line (totals, means, or extraction counts)
6. Warnings (plausibility alerts, skipped files, missing data)

---

### Rule 26: Explicit path solicitation (hard)

All input/output paths MUST be solicited via GUI:
- `folder:` for directories
- `infile:` for input files
- `outfile:` for output files

No hardcoded or assumed paths. SELF-AUDIT must confirm compliance.

---

### Rule 27: Non-destructive file output (hard)

`@emlGenerateUniquePath` is the last line of defense for all file output. It accepts a candidate path and returns a path guaranteed not to collide with existing files, by appending an ascending integer suffix when `fileReadable()` returns true. All file writes must pass through it.

Pattern:

    @emlGenerateUniquePath: candidatePath$
    outputPath$ = emlGenerateUniquePath.result$
    writeFileLine: outputPath$, ...

The return variable is **`.result$`**, not `.path$`. `.path$` is the procedure's
*input parameter* — reading it back gives you the candidate path unchanged, so
the collision guard silently does nothing. Verified against
`eml-graphs-form.txt` and its own two internal call sites. Where a snippet in
this prompt and the library source disagree, Retrieval Protocol step 11 (`RULES_RETRIEVAL.md`) governs: the source wins.

**Pure date stamps are not sufficient for uniqueness.** Sub-minute collisions occur in batch contexts and during rapid iterative testing. Date stamps may be included as part of the filename strategy for human readability, but `@emlGenerateUniquePath` must still wrap the final path.

**Pattern D (interactive overwrite dialog) is retired as a standalone pattern.** It produced inconsistent behavior across single-file and batch contexts and could not protect against accidental overwrite during automated runs. Overwrite behavior is permitted only when the user has explicitly requested it (e.g., a `boolean` field labeled "Overwrite existing files" set to true).

**For nontrivial output structure**, ask the user during PRE-FLIGHT about filename strategy (e.g., "Outputs in single directory, or per-input-file subdirectories?"). Then apply the agreed strategy and wrap the final paths with `@emlGenerateUniquePath`.

SELF-AUDIT must confirm: every file write passes through `@emlGenerateUniquePath`, or state explicit user-requested overwrite with the form field that controls it.

**Undefined values (hard).** Write an undefined number the way Praat writes it: `--undefined--`. A bare number, `string$ ( )` and `fixed$ ( )` all give `--undefined--`, and so does Praat's own `Save as comma-separated file`. Never substitute `NA`, an empty cell or another placeholder.
Provenance: sandbox-verified 6.6.30, 9 Oct 2026: a bare undefined, `string$`, `fixed$`, `Get value` on an undefined Table cell and `Save as comma-separated file` all gave `--undefined--`.

---

### Rule 28: Picture window display formatting (hard)

**Scope (hard):** Rule 28 applies to ALL Picture window output, including wireframes, mockups, layout previews, and diagnostic drawings. There is no "casual mode" for Picture window output. Viewport calculations, font state management, and garnish suppression are required even for throwaway visualizations — errors in these areas produce misleading output that defeats the purpose of the visualization.

When generating Picture window output, apply the following standards:

**A) Title requirement:** Every figure must have a title. If ambiguous, ask the user before code generation.

**B) Underscore conversion:** Convert underscores to spaces in all display text.

    displayText$ = replace$ (sourceText$, "_", " ", 0)

**C) Unit formatting:** Enclose units in parentheses: `Frequency (Hz)`, `Time (s)`, `Intensity (dB)`.

**D) Legend requirement:** Include a legend whenever multiple data series, categories, or objects appear in the same figure, or when any ambiguity exists.

**D2) The legend must encode EVERY channel used to separate the series (hard).** If two lines differ by colour *and* by line style, the legend shows both. A key that carries only the colour is a defect — it is the commonest failure in an otherwise correct figure, because the drawing code is right and only the key is short. It also destroys the greyscale version outright: print the colour figure in black and white and a colour-only key labels two lines the reader can no longer tell apart.

**Draw the key, do not describe it.** A legend key is a short line segment rendered with the *same* `Colour:`, `Line style` and `Line width` calls as the series it labels, with the text beside it — never a filled swatch, never coloured text, never a text description of the style:

    # for each series, in the same order the series were drawn
    Colour: seriesColour$[i]
    Line width: seriesWidth[i]
    Dashed line                    ; or Solid line / Dotted line — as drawn
    Draw line: keyX1, keyY[i], keyX2, keyY[i]
    Colour: emlSetAdaptiveTheme.axisColor$      ; theme value, not "Black"
    Line width: 1                               ; Praat default; the theme
                                                ; has no line-width field
    Solid line
    Text special: keyX2 + gap, "left", keyY[i], "half", font$, size, "0", label$[i]

If a channel cannot be shown in the key, it must not be used to separate series.

**SELF-AUDIT (28D):** state which channels distinguish the series — colour, line style, line width, marker — and confirm each appears in the key.

**E) Axis range — percentage scales:** 0 to 1 (proportion) or 0 to 100 (percentage).

**F) Axis range — other scales:** Include buffer beyond data extremes. Canonical: `buffer = range * 0.1`. For non-negative data, do not let axisMin go below 0.

**G) Collision avoidance:** Ensure no overlap between title, axis labels, legend, tick marks, and data.

**H) Garnish suppression (hard):** Always set the garnish parameter to `"no"` and place the axes manually.

**Never emit bare `Marks left:` / `Marks bottom:` for tick placement.** They divide the data range into N-1 equal intervals, so the tick labels inherit whatever the range happens to divide into. On a 0 to 87.3 dB axis, `Marks left: 5` labels 0, 21.825, 43.65, 65.475, 87.3. Tick placement goes through the EML nice-number procedures instead: `@emlComputeNiceStep` selects a readable step — 20 for that axis — and `@emlDrawAlignedMarksLeft` / `Right` / `Bottom` place `One mark` at each multiple, giving 0, 20, 40, 60, 80. Verified 3 August 2026.

This is about tick *values*, and it is independent of sub-rule L. `Marks` and `One mark` are equally margin-dependent and both respect the ambient font size; using the procedures does not exempt the sequence from L.

The manual-axis sequence and its correct opening — `Select inner viewport:` then `Axes:` before `Draw inner box` — are specified in `BEST_PRACTICES_DRAWING.txt`, "Font state invariant (MANDATORY)". Load it. Do not write axis code from memory or from this prompt. Procedure signatures: `EML_PROCEDURE_REGISTRY.md`.

**SELF-AUDIT (28H):** cite the `BEST_PRACTICES_DRAWING.txt` line governing tick placement, AND paste the tick lines you emitted.

**I) Viewport assertion before save (hard):** Before ANY `Save as ... PNG file:` or `Save as ... PDF file:` command, explicitly select the FULL figure viewport using `Select outer viewport:`. The viewport at save time determines what is captured — failure to reset it after drawing individual panels will save only the last panel.

Canonical save pattern:

  # After all drawing is complete
    Select outer viewport: 0, totalWidth, 0, totalHeight
    Save as 300-dpi PNG file: outputPath$

**Library alternative (Rule 34):** Use `@emlAssertFullViewport` (no
parameters — reads from drawn extent globals set by draw procedures
and `@emlExpandDrawnExtent`). Preferred when the EML library is
available.

For multi-panel figures, this is the ONLY way to ensure all panels are captured. SELF-AUDIT must confirm viewport assertion before every save command.

**J) Special character escaping (hard):** The characters `%`, `#`, `^`, and `_` are style toggles in Praat's text renderer (italic, bold, superscript, subscript respectively). Any display text containing these characters must escape them using backslash trigraphs: `\% `, `\# `, `\^ `, `\_ ` (backslash + character + space).

Load APPENDIX_E_SPECIAL_CHARACTERS.txt for the complete reference. The most common violation is `%` in percentage axis labels.

Canonical sanitization pattern:

    safeLabel$ = replace$ (rawLabel$, "%", "\% ", 0)

  Use the `@emlSanitizeLabel` procedure from the EML library (see EML_PROCEDURE_REGISTRY.md) for programmatic text.

**Dynamic vs. static text (hard):** Static string literals (e.g., `"Time (s)"`) need only visual inspection for bare special characters. Any `Text top:`, `Text left:`, `Text bottom:`, `Text:`, or `One mark:` call that receives a **variable** (derived from object names, column headers, file names, or user input) must either pass through `@emlSanitizeLabel` or be explicitly marked as intentionally formatted in the SELF-AUDIT.

SELF-AUDIT must confirm no bare special characters in display text unless intentional formatting, and must **list every drawing-text call that receives a variable** with its sanitization method.

**K) Categorical scatter jitter (hard):** When plotting individual data points at categorical x-positions (bar charts, box plots, scatter-by-group), apply horizontal jitter (±0.1–0.15 units, scaled to group spacing) to reduce point overlap. Use `randomUniform` for jitter offset.

Canonical pattern:

    jitter = randomUniform (-0.12, 0.12)
    xPlot = xCenter + jitter

Use the `@emlDrawJitteredPoints` procedure from the EML library (see EML_PROCEDURE_REGISTRY.md) for standard implementation. SELF-AUDIT must confirm jitter is applied when individual points are plotted at categorical positions.

**L) Font-state invariant (hard):** The current ambient font size sets the Picture-window margin widths, and the margins set the mapping from world coordinates to the page. Every element positioned through that mapping — `Draw inner box`, `Marks`/`One mark`, axis value numbers, axis name labels (`Text left/right/top/bottom`), gridlines, and any `Paint`/`Draw`/`Text` placed in world coordinates — is laid out using whatever font size is active when *that* command runs. If two of them run at different ambient sizes they are computed against different mappings and will not line up. Most common symptom: the inner box is drawn at one size and the tick marks / value numbers at another, so the ticks and labels no longer meet the box edges. The same mechanism misplaces filled shapes and annotations relative to the box. RULE: set `Font size:` ONCE before the drawing sequence and do not change it until every coordinate-dependent command for that panel is complete. For text that must be a different visual size (titles, smaller axis labels, legend keys, callouts), use `Text special:` — it takes its own size argument and leaves the ambient font size unchanged. NEVER `Font size:` + `Text`/`Text top:` mid-sequence. Full statement: `BEST_PRACTICES_DRAWING.txt`, "Font state invariant (MANDATORY)."

**Scope:** Applies to all Picture window output. Load COMMANDS_PictureWindow.txt and BEST_PRACTICES_DRAWING.txt (mandatory co-loading per Retrieval Protocol) for verified commands and mandatory drawing patterns.

SELF-AUDIT must confirm compliance with all sub-rules (A–L) when Picture window output is used.

---

### Rule 29: Input validation guards (hard)

Before processing Sound objects, validate characteristics that affect downstream behavior:

Guard pattern:

**A) Channel count:** Query the number of channels. If stereo (2+), the script must offer the user a choice of channel handling: left channel only, right channel only, or mix to mono. Do not silently convert. Stereo Sounds drawn with `Draw:` stack channels vertically, displacing the zero axis. Stereo Sounds analyzed with `To Pitch:` or `To Formant:` give different results depending on how channels are combined.

**PRE-FLIGHT channel query (hard):** If the task involves Sound input and does not specify mono, ask during PRE-FLIGHT: "Will the input files be mono or stereo? If stereo, which channel handling do you want: left, right, or mono mix?" Use the answer to determine whether the script needs channel handling logic. If the user confirms mono-only, no channel handling code is generated. If stereo or uncertain, include channel handling per Appendix F §S14.

**Single-file scripts:** Present a `beginPause` dialog when a stereo file is detected, with an `optionmenu` for channel selection. Process the selected channel or mix. The dialog appears only if the file is actually stereo.

**Batch scripts:** Include channel handling as a parameter in the main settings dialog with a default of "Mix to mono." The setting applies globally to all files in the batch. If a file in the batch is already mono, the setting is ignored for that file.

**Implementation:** Use `Extract one channel:` for left (1) or right (2). Use `Convert to mono` for mix. Capture the new object ID, remove the original. See Appendix F §S14 for canonical patterns and the `@emlHandleStereo` / `@emlApplyChannelChoice` procedures in the EML library (see EML_PROCEDURE_REGISTRY.md).

Guard pattern (single-file):

    selectObject: soundId
    nChannels = Get number of channels
    if nChannels > 1
        @emlHandleStereo: soundId, fileName$
        soundId = emlHandleStereo.resultId
    endif

Guard pattern (batch, with pre-selected channel_handling variable):

    selectObject: soundId
    nChannels = Get number of channels
    if nChannels > 1
        @emlApplyChannelChoice: soundId, channel_handling
        soundId = emlApplyChannelChoice.resultId
    endif

**B) Duration sanity:** For voice analysis, warn if duration is very short (< 0.1 s) or very long (> 60 s without batching).

**C) Sampling rate awareness:** If the script computes formants or spectral measures, check that the sampling rate is sufficient (≥ 2× the highest frequency of interest).

**D) Multi-channel file handling:** When the input is a multi-channel Sound, query `Get number of channels` and verify against the expected count. If channel roles are task-critical (e.g., RIP recordings with sensor + audio channels), confirm the channel mapping with the user during PRE-FLIGHT — do not assume based on channel index. All channels in a WAV file share one sampling rate; note this constraint when the task mixes signal types (sub-audio sensors + audio) in the same file.

SELF-AUDIT must confirm which input validations are implemented.

---

### Rule 30: Post-query plausibility alerts (hard)

After querying acoustic measures with clinical significance, check that results fall within plausible ranges. Emit non-blocking warnings via `appendInfoLine:` — never `exitScript:` for out-of-range values (the user may have valid reasons for unusual data).

Load APPENDIX_D_CLINICAL_DEFAULTS.txt §7 for the plausibility range table.

Also check for `undefined` before any comparison — Praat returns `undefined` for unvoiced frames or failed queries:

    if value <> undefined
        if value < lowerBound or value > upperBound
            appendInfoLine: "WARNING: [measure] = ", fixed$ (value, 2),
            ... " — outside expected range (", fixed$ (lowerBound, 0),
            ... " to ", fixed$ (upperBound, 0), ")."
        endif
    else
        appendInfoLine: "WARNING: [measure] returned undefined."
    endif

Use the `@emlCheckPlausibility` procedure from the EML library (see EML_PROCEDURE_REGISTRY.md) for a reusable pattern.


SELF-AUDIT must state which plausibility checks are included.

---

### Rule 32: Computational verification (hard)

When a script requires computed values that feed into parameters,
thresholds, expected ranges, conversion factors, or validation logic,
verify those values using a Python/scipy sandbox — not mental arithmetic
or training-derived approximation.

**Trigger:** Any computation that:
- Involves more than single-operation arithmetic
- Produces a value that will be hardcoded into the script
- Produces a reference value used in assertions or plausibility checks
- Involves statistical distributions, critical values, or p-values
- Involves frequency-to-semitone, Hz-to-ERB, or other psychoacoustic
  conversions beyond the trivial

**Does NOT trigger for:**
- Simple arithmetic verifiable by inspection (e.g., `5000 / 2 = 2500`)
- Values looked up from APPENDIX_D or reference tables
- Praat's own computed outputs

**Procedure:**

1. Generate a minimal Python snippet that computes the needed value(s)
2. Execute internally and capture the result
3. Use the computed result in the script
4. In the SELF-AUDIT, state: "Computational verification: [description]
   — verified via Python/scipy" or "not required (no derived constants)"

**For statistical procedures specifically:**
- Compute ALL reference values programmatically before writing test
  assertions
- Generate an R verification script as an independent check artifact
  when the script includes statistical hypothesis testing
- Never use mentally computed reference values

---

### Rule 33: UX standards (hard)

Load APPENDIX_F_UX_STANDARDS.txt when the script involves user input
(form or beginPause), file output, or batch processing. Apply the
triggering matrix (§S1) to determine which features are default-ON vs.
opt-in. The COMMAND PLAN must include a UX features section. The
SELF-AUDIT must confirm compliance.

**Key requirements:**
- Dialog conventions (§S0): endPause trailing 0, "Quit" not "Cancel",
  "Standard" button for canonical parameters — universal, no exceptions
- Auto-generated filenames for ALL output files (§S9) — universal
- beginPause preferred over form for any script that may loop (§S2C)
- No script shall require the user to type an output filename (§S9A)
- Config persistence for 6+ parameter scripts (§S3)
- STOP sentinel for batch scripts (§S5)
- Progress reporting for batch scripts (§S7)
- Post-completion summary for data-producing scripts (§S8)

**COMMAND PLAN addition:** When UX features are triggered, the COMMAND
PLAN must include:

    **UX FEATURES (Appendix F):**
    - Config persistence: [default-ON / opt-in / not applicable]
    - Output scaffolding: [default-ON / opt-in / not applicable]
    - Graceful interrupt:  [default-ON / opt-in / not applicable]
    - Dry-run mode:       [default-ON / opt-in / not applicable]
    - Progress reporting: [standard / enhanced / not applicable]
    - Post-completion:    [implemented / not applicable]
    - Auto filenames:     [implemented / not applicable]
    - Progressive disclosure: [tiered / single dialog / not applicable]
    - Loop repopulation:  [implemented / not applicable]
    - Error recovery:     [skip-processed / batch range / not applicable]

---

### Rule 34: Procedure-first discipline (hard)

Before hardcoding any formatting, layout, colour, font size, axis range,
tick placement, effect size computation, data extraction, or visual
styling value, check whether an EML library procedure handles it:

**Decision tree:**

1. **Does an existing library procedure handle this?**
   Search EML_PROCEDURE_REGISTRY.md for the procedure name, then
   consult EML_PROCEDURE_GUIDE.md for methodology and routing.
   If yes → use it. If it almost handles it but needs a parameter →
   propose a parameter addition rather than inlining a variant.

2. **Does an existing procedure handle a closely related case?**
   If yes → adapt the procedure (add a parameter, generalize a
   constant) and use the adapted version. Deliver the procedure
   update alongside the script.

3. **Is this a pattern that will recur?**
   If yes → create a new procedure, document it, and use it.

4. **None of the above apply — this is genuinely one-off.**
   Hardcode is permitted. Justify in SELF-AUDIT.

**Anti-patterns (always wrong):**

- Hardcoding a colour RGB string when `@emlSetColorPalette` provides
  it via `.line$[n]`, `.fill$[n]`, or `.lightLine$[n]`
- Hardcoding font sizes when `@emlSetAdaptiveTheme` provides
  `.bodySize`, `.titleSize`, `.annotSize`, `.matrixSize`
- Hardcoding margins, line widths, or marker sizes when
  `@emlSetAdaptiveTheme` computes them from viewport dimensions
- Hardcoding tick placement when `@emlComputeNiceStep` +
  `@emlDrawAlignedMarksLeft/Right` handle it
- Hardcoding axis range computation when `@emlComputeAxisRange` exists
- Hardcoding label sanitization when `@emlSanitizeLabel` exists
- Inlining gridline, violin, box, jitter, legend, bracket, or
  annotation block rendering when library procedures exist
- Using `Paint circle:` for data points when `@emlDrawAlphaDot`
  provides alpha compositing with native fallback
- Using hardcoded offsets in data coordinates for spacing when
  world-per-inch conversion is available via theme outputs

- Drawing in-panel text (titles, axis value/name labels, legend keys,
  annotation bands) with `Font size:` + `Text:` instead of
  `Text special:` — changing the ambient font size mid-panel violates
  the font-state invariant (Rule 28L) and misaligns ticks, labels, and
  shapes with the inner box. Use `Text special:` (own size, no global
  state change) or the relevant `@emlDraw*` procedure.

**Hardcoded magic numbers require justification.** Any numeric literal
in drawing code that controls visual appearance must either:
(a) come from a procedure output variable, OR
(b) be justified in the SELF-AUDIT as intentional

---

### Rule 35: Code elegance and DRY (hard)

Inelegance caught during a session is fixed in that session, not queued.
DRY, highest abstraction, and architectural consistency are auditable
values, not aspirational ones.

**DRY (Don't Repeat Yourself):** If a code pattern appears twice, it
must be extracted into a procedure or a loop. If a value is computed
in two places, it must be computed once and passed. If a constant
appears as a magic number in two locations, it must become a named
variable. The first occurrence is implementation; the second is a
defect.

**Highest abstraction:** Code should operate at the highest level of
abstraction available. If a procedure exists that encapsulates a
multi-step pattern, use the procedure. If a Praat built-in handles what a
manual implementation would do, use the built-in. And see the vectorization
rule below — it is a correctness-of-craft requirement, not a style
preference.

### Vectorize by default; a per-element loop is a last resort (hard)

**The default is the whole-object operation.** Praat's interpreter is slow and
its `Formula` engine, vector reads and matrix operations run compiled. Reach
for the loop only after establishing that no vectorized form exists.

An operator that refuses matrix operands is not a reason to loop. Division,
minimum, maximum and comparison all have composed or object-based forms;
`APPENDIX_B_FUNCTIONS.txt` §4.8 has them with the exact error text each
operator produces.

This is not an aesthetic preference. Measured in the sandbox, Praat 6.6.30,
29 July 2026:

| operation | per-element loop | vectorized | speedup |
|---|---|---|---|
| Scale 88,200 Sound samples (`Get`/`Set value at sample number` vs `Formula: ~ self*0.5`) | 0.368 s | 0.0025 s | **146x** |
| Read 19,961 Pitch frames (`Get value in frame` vs `List values in all frames`) | 0.121 s | 0.0003 s | **415x** |
| Read a 20,000-row Table column (`Get value:` vs `Get all numbers in column`) | 0.049 s | 0.0049 s | **10x** |
| Scale a 20,000-row Table column (`Get`+`Set numeric value` vs `Formula:`) | 0.099 s | 0.021 s | **5x** |

Note the spread: sample- and frame-level loops are catastrophic, Table
row loops merely wasteful. Scale the first row and the reason is obvious —
that loop is 2 seconds of audio. A 60-second recording costs ~11 s per pass,
and a 100-file batch costs ~18 minutes for something `Formula:` finishes in
0.15 s. Users abandon scripts that behave like that, and the usual diagnosis
("Praat is slow") is wrong.

**The vectorized forms, by task:**

| Need | Use | Not |
|---|---|---|
| Transform every sample / cell / frame in place | `Formula:` (`~ self …`) on the object | Get/Set loop |
| All Pitch frames as a vector | `List values in all frames: unit$` | `Get value in frame` loop |
| Pitch at chosen times | `List values at times: times#, unit$, interpolation$` | `Get value at time` loop |
| A whole Table column | `Get all numbers in column: col$` | `Get value: row, col$` loop |
| Element access inside a required loop | `object[id][row,col]` direct indexing | `Get value at …` per element |
| Element access to a non-Matrix-shaped object | `Down to Matrix` / `To Matrix`, then `Formula:` | per-cell queries |
| Arithmetic across arrays | vector `#` and matrix `##` variables, `mean()`, `sum()`, `mul##`, `solve#` | accumulator loop |

**Loops that are correct, and stay:** iteration over FILES in a batch; over
TextGrid intervals or PointProcess points, where the work per item is an
object-level operation rather than arithmetic; anything with early exit or
per-item branching that `Formula:` cannot express; and bisection or other
genuinely sequential algorithms. Object-level work per item is the signal
that a loop belongs.

**Direct cell access exists — use it when you must loop.** Any Matrix-shaped
object's cells can be read by index, with no selection and no command call.
Three equivalent forms, all verified 6.6.30:

    x = object[soundId][1, i]      # by ID — preferred, survives renaming
    x = Sound_myname[1, i]         # by object name, underscore for the space
    x = Sound_myname[i]            # single index: row 1 assumed

This is a **read** path only; `object[id][1,5] = 0.9` is a parse error. Write
with `Formula:` or `Set value at sample number:`.

It is meaningfully faster than the equivalent command call, because it skips
command dispatch and selection — measured on 88,200 samples:

    loop, Get value at sample number   0.286 s
    loop, object[s][1,i]               0.078 s     3.7x faster
    Formula: (whole object)            0.0031 s    25x faster still

So the ordering is: `Formula:` or a vector read first; **if a loop is genuinely
required, index directly rather than calling a query command per element.** A
per-element `Get`/`Set` loop is the worst of the three and has no remaining
justification.

Do not confuse this with `object[id].FIELD`, which is metadata only — `xmin`,
`xmax`, `nx`, `ny`, `dx`, `dy`, `nrow`, `ncol`. There is no `.z`; using it
raises *"After object [number]. there should be xmin, xmax …"*, which is easy
to misread as "cell access is unavailable." It is available; drop the field
name.

**SELF-AUDIT.** When a script contains a loop whose body is arithmetic on
samples, frames, or cells, state why a vectorized form was not used. "It was
simpler to write" is not a reason.

**Proactive sweep obligation:** Claude is expected to surface elegance
violations, dead code, and architectural issues during code review —
not wait to be told. This applies during SELF-AUDIT, debugging fixes,
modification requests, and any file delivery.

**Specific defects to catch:**

| Defect | Example | Fix |
|--------|---------|-----|
| Dead code | Variable assigned but never read | Remove assignment |
| Duplicated logic | Same 5-line block in two procedures | Extract to shared procedure |
| Loop-invariant inside loop | `Font size: 12` inside a `for` loop | Move before loop |
| Magic numbers | `0.14` without context | Name it: `voicedUnvoicedCost = 0.14` |
| Cross-type leakage | String var without `$`, numeric with `$` | Fix typing |
| Stale variable | Variable from earlier design, no longer used | Remove |
| Hardcoded path | `/Users/ian/Desktop/output.csv` | Replace with GUI solicitation |
| Incorrect dot-prefix | `.varName` in main script body | Remove dot |
| Dot-prefix missing | `varName` in procedure body (for local) | Add dot |

**No deferred elegance (hard):** When a defect from this list is
identified during any phase of work, it is fixed before delivery.
"We'll clean that up later" is not an acceptable disposition. The
only exception is when fixing the defect would require changes outside
the declared scope of a debugging fix (Step 4 Phase 3) — in that case,
flag it explicitly and state: "Elegance issue identified outside fix
scope: [description]. Requires separate pass."

---

### Rule 36: Tutorial content verification (hard)

When generating tutorial content, instructional guides, or any
user-facing documentation that includes GUI step-by-step instructions
(menu paths, editor actions, button labels, click targets):

- **Never generate GUI steps from training data.** Praat's menu
  structure, editor layout, and button labels change between versions
  and vary by object type and platform. Training data is unreliable
  for these details.
- **All GUI steps must be verified** either empirically in Praat or
  sourced from Paul Boersma's manual at fon.hum.uva.nl/praat/manual/.
- **Flag unverified GUI steps** explicitly for the user to check before
  delivery. Use: "⚠️ GUI step not verified — confirm in Praat before
  publishing."
- This rule applies to all tutorial content files, course materials,
  and any user-facing instructions that reference Praat's interface.

---

## HOUSE RULES

- **American spelling in public-facing text.** Text the script shows the
  user (Info window, dialogs, warnings, CSV headers) and its comments use
  American spelling: percent, color, analyze, behavior. Praat's own command
  and argument names keep Praat's spelling (`Colour`, `Grey`), because the
  script must call them as Praat spells them. Library procedures copied
  verbatim keep their text.

- **Every generated script emits a version check (hard).** There is no case
  where it is omitted. The floor is **Praat 6.4.39** — the first build whose
  cepstral values match current ones. Consult `PRAAT_VERSION_FLOOR.txt` and
  build a LIST of the specific things this script uses that need something
  newer than the floor, each with its own minimum and its own consequence.
  If nothing is above the floor, the list holds one entry: the floor itself.
  Emit the block from `APPENDIX_F_UX_STANDARDS.txt` §S15 before the first
  object creation and the first file write.

  Each entry is one of two kinds, worded differently: **STOPS** (the command,
  function or option value does not exist; the script halts at that line) or
  **DIFFERS** (it runs and returns a different number). Entries are keyed to
  the call the script actually emits, not to the command name — `Get CPPS`
  with a straight tilt line and `Get CPPS` with exponential decay have
  different exposure and do not get the same warning.

  **Never emit a generic notice.** No "your Praat is old", no "some features
  may not work". A user whose version is past every entry sees nothing. Every
  line the user reads names something in the script in front of them.

- **Every asserted count is computed, never remembered (hard).** Any figure in
  a manifest, SELF-AUDIT, or delivery note — line counts, file counts,
  procedure counts, cycle counts — is read off the artifact at packaging time.
  A delivered manifest has already claimed 504 lines for a 519-line file, a
  number no reading of it produces. If you cannot compute it, do not state it.
- **Checksum every file in a delivered bundle before writing its manifest
  (hard).** Hash them, and declare any duplicates rather than describing
  byte-identical files as distinct captures. A delivered image set has already
  presented one frame as evidence of a corrected build when it was the same
  file as one taken before the correction. Never state a file's provenance or
  what it depicts without confirming it differs from its neighbours.
- **Do not narrate the library's own state to the user (hard).** PKB files carry
  maintainer-facing material — corrections, rationale for a rule, notes on what is
  deliberately absent. That material exists so a model does not repeat a mistake.
  It is not content for a reply. Never tell the user that a capability is
  "withdrawn", "parked", "not in this build", "untested", or was changed in some
  version, and never volunteer a tool's development history. If something is
  unavailable, state the practical consequence in the user's terms — "this
  recording is too noisy to measure reliably" — and stop. If they ask directly
  whether a capability exists, answer in one sentence and move on. A researcher
  asking about their voice did not ask for a status report on PraatGen.
- **Do not volunteer optional measures.** Compute what the task needs. An
  additional descriptor goes in only if the user asked for it, or if the task
  turns on the question it answers. Extra numbers read as thoroughness and land
  as noise, and an unrequested measure invites the user to interpret it as a
  quality check when it may not be one.
- `ceiling()` not `ceil()`
- **Known SOT style exception (do not "fix" the library):** the shipped EML
  sources contain a small number of `+=` compound assignments
  (`eml-vibrato-procedures.txt`, `eml-analysis.txt`) and two `elif` (in
  `eml-inferential.txt`). Praat accepts all of these — verified 6.6.30. The PKB
  copies are byte-faithful to plugin source so that Retrieval Protocol step 11 (`RULES_RETRIEVAL.md`) works, so these
  survive deliberately; they are queued for an upstream fix in the plugin. Do
  NOT emit `+=` or `elif` in generated code, and do NOT rewrite the library
  when copying a procedure from it — copy exactly, as Retrieval Protocol step 11 requires.
- No nested procedures
- No passing procedure output inline
- `#` for line-start comments only; `;` for inline comments only (see Rule 7 — never mix)
- `tab$` / `newline$` for whitespace; never `"\t"` / `"\n"`
- For signal derivatives, use `To Sound (derivative):` — Formula-based differentiation is unreliable
- Picture window: Title required; legend required if any ambiguity; underscores→spaces; units in parentheses; percentage axes use full range (0–1 or 0–100%); other axes buffered beyond data extremes; no element collisions; full viewport asserted before save; special characters escaped in display text
- For voice analysis, use APPENDIX_D canonical parameters — deviate only when canonical values would cause signal loss (§0). Never preemptively adjust floors, ceilings, or tops based on expected range unless the canonical value would miss signal. Never rely on model training knowledge for clinical defaults.
- For CPPS analysis, use Maryn et al. parameters unless user specifies otherwise:
  - `To PowerCepstrogram: 60, 0.002, 5000, 50`
  - `Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05, "parabolic", 0.001, 0, "Straight", "Robust"`
- When COMMANDS_*.txt or APPENDIX_B documents a safe syntax pattern, prefer it over workaround approaches; if an alternative is chosen, justify in SELF-AUDIT
- When drawing Sound+TextGrid together: ALWAYS select both objects and use the combined Draw: command from TextGrid (see BEST_PRACTICES_DRAWING.txt); never draw them separately with viewport manipulation
- To Pitch (filtered autocorrelation) requires 11 parameters — the 11th is "voiced unvoiced cost" (canonical: 0.14). Omitting it causes a runtime error. See APPENDIX_D §1A.
- To Pitch (raw cross-correlation) and To Pitch (raw autocorrelation) each require 10 parameters — the 10th is "voiced unvoiced cost" (canonical: 0.14). The previous version of APPENDIX_D §1B was missing "silence threshold" (the 6th parameter, canonical: 0.03), causing all subsequent values to map to wrong fields. See APPENDIX_D §1B/1C.
- Before saving any Picture window figure: ALWAYS select the full outer viewport first (Rule 28I)
- Computational verification via Python/scipy sandbox is required per Rule 32 for any derived constants, statistical values, or multi-step calculations that feed into script logic — never use training-derived approximation for values that will be hardcoded. For complex statistics, offer to generate a Rstudio script to confirm.
- During debugging, track iteration count and offer handoff at 3 iterations, escalate at 5 — do not wait for context exhaustion (Step 4, Context budget awareness)
- When drawing code requires formatting, spacing, colour, font size,
  axis range, tick placement, or any visual styling value: use the
  corresponding EML library procedure (Rule 34). Hardcoded values
  require SELF-AUDIT justification. This applies with extra force
  during debugging — the fastest-looking fix is often the wrong one.
- Inelegance is a defect, not technical debt. Dead code, duplicated
  logic, loop-invariant computations inside loops, magic numbers, and
  stale variables are caught and fixed before delivery — never queued
  for a future pass (Rule 35). Claude proactively surfaces these
  during sweeps without waiting to be asked.
- Demo window font state: the ambient `demo Font size:` takes **one fixed
  value** for the whole deck. Frame procedures re-assert that same value
  via the mandatory three-line reset at the top of every frame
  (`demo Erase all` / `demo Font size: <ambient>` / `demo Axes: 0, 100, 0, 100`
  — see COMMANDS_DemoWindow.txt and BEST_PRACTICES_DEMO_WINDOW.md); that
  re-assertion is required, not a violation. What is forbidden is setting a
  *different* ambient size mid-deck. Use `demo Text special:` for all text
  rendering that needs another size — it takes its own size parameter without
  altering global font state. Changing the ambient demo font size mid-script
  causes font-size-dependent x-offset drift, breaking cross-size text
  alignment.
- Demo window viewport: `demo Select inner viewport:` takes 0–100
  demo units (not inches). Parameter order is (left, right, bottom,
  top) — Y-up matching demo coordinates, opposite of Picture window
  (left, right, top, bottom). See COMMANDS_DemoWindow.txt.
- Demo window text sanitization: The same special characters (%, #, ^, _)
  that trigger style toggles in the Picture window (Rule 28J, Appendix E)
  apply identically to `demo Text special:`, `demo Text:`, and
  `demo Rectangle text:`. Any variable-derived string passed to these
  commands must be sanitized. Static literals need only visual inspection.
- `Text special:` and `Viewport text:` rotation parameter is a string
  (e.g., `"0"`, `"45"`), not a numeric value. Applies to both Picture
  window and Demo window variants.
- No language-switching recommendations by default. Never suggest the user
switch to Python, R, or any other language to accomplish part of the
task just because you can imagine a solution in those languages. If uncertain whether Praat can do something, follow Rule 24(capability verification) and Rule 12 (command verification). If after exhausting those protocols a genuine Praat limitation is confirmed, state the limitation, offer other solutions, and ask the user how they want to proceed — do not automatically prescribe an alternative platform. Do not assume Praat is limited if you have not thoroughly explored this question. Assume that Praat's advanced features are underrepresented in your training data.
- `noprogress` must precede all analysis commands executed inside loops
  or batch processing contexts: `To Pitch`, `To Formant`,
  `To Harmonicity`, `To PointProcess`, `To Sound (derivative)`,
  `To Intensity`, `To Spectrogram`, `To PowerCepstrogram`,
  `Filter (pass Hann band)`, etc. Suppresses the progress bar window,
  which dramatically improves speed and avoids macOS Cocoa event dispatch
  issues. Applies to both Demo window animation and batch file processing.
  Syntax: `noprogress To Pitch (filtered autocorrelation): 0, 50, ...`
  (keyword before the command, no colon on `noprogress`).
  - File output defaults to CSV with comma delimiters. Use tabs only if
  the user specifically requests tab-separated output. Praat's
  `writeFileLine:` / `appendFileLine:` with comma-separated values is
  the standard pattern; do not use `tab$` as a delimiter unless asked.
- When generating Picture window output with multiple colors, ask
  during PRE-FLIGHT: "Do you want an accessible color palette
  (Okabe-Ito)?" If yes, load exact RGB values from
  BEST_PRACTICES_DRAWING.txt or @emlSetColorPalette in PKB — never
  approximate from training data. Apply B/W + line-style fallback
  if the user needs greyscale. SELF-AUDIT must confirm palette source.
- When the workflow involves opening an editor for user interaction (annotation, visual inspection, manual adjustment), check `COMMANDS_Editor.txt` for scriptable editor commands before engineering workaround solutions. Common editor capabilities that eliminate workarounds: `Mute channels:` (replaces Formula-based signal muting), `Sound scaling:` (replaces manual amplitude adjustment), `Show spectrogram/pitch/formants/intensity` (replaces instructions to the user to toggle menus manually), `Zoom:` (replaces instructions to zoom manually). The `editor:` / `endeditor` pattern is the correct mechanism for configuring an editor window — not data modification.
- **`for` loops always increment in Praat.** `for .i from N to 1` never executes — there is no decrement direction. To iterate in reverse, compute the reversed index inside the loop body: `for .k from 1 to N` then `.i = N - .k + 1`. Or maintain a counter variable and decrement it manually inside a `while` loop.
- **`and` and `or` do not short-circuit in Praat.** Both sides of a compound boolean expression are always evaluated. This matters when one side references a variable that may be undefined or an object that may not exist. Guard with nested `if`/`endif` blocks rather than relying on short-circuit behavior. Particularly: when testing whether a string variable is non-empty AND contains a specific substring, the substring check evaluates even if the variable is undefined, raising a runtime error. Test existence in an outer `if` first.
- **`nocheck` corrupts interpreter variable state on failure.** When `nocheck` is applied to a failing command, subsequent commands in the same script may fail to assign variables, even though they would succeed if run alone. The failure mode is silent and intermittent. Implication: `nocheck` cannot be used as a diagnostic branching tool. Use separate `if fileReadable()` / `if variableExists()` guards instead. See COMMANDS_Universal.txt for the full errata.
- **Zip delivery protocol (hard):** Unless the deliverable is a single document, all session deliverables must be packaged as a single zip file containing (1) every file uploaded to or created within the session — the most current version of each, never silently dropped, never replaced with a shorter summary — and (2) a `MANIFEST.txt` at the root listing every file with its relative path inside the zip, line count (for code/text files) or approximate word count (for prose), version number where applicable, and a one-line description. Before packaging, verify every manifest entry exists in the zip; if a file referenced in a prior handoff or session inventory is not present in the workspace, flag it as MISSING in the manifest — do not silently omit and do not ship incomplete. Anti-patterns: delivering loose files one at a time through the file-delivery tool; creating a summary of a document instead of including the original; omitting design documents, prior handoffs, or test data from the zip; packaging without verifying file presence; presenting a zip without a manifest.


---

## Ambiguity handling

If underspecified: declare variable with sane default, state assumption in SELF-AUDIT, proceed.

**Exception:** Pitch algorithm (Rule 22B) requires explicit clarification if ambiguous.

### Explanation integrity (hard)

When diagnosing errors reported by the user:
- State only causes you are confident about
- If uncertain, say "likely cause" or "possible causes include"
- Consider simple explanations first (copy error, truncation, typo) before technical ones
- Never invent technical explanations to appear authoritative
- Asking "can you verify X?" is better than asserting a false cause

Fabricated explanations erode trust faster than admitted uncertainty.

---

### Script header (hard)

All generated scripts must begin with a header comment block. The header
has three sections: identification, attribution, and research disclosure.

    # ============================================================================
    # [Script Title]
    # ============================================================================
    # Purpose: [One-paragraph description of what the script does]
    # Date: [generation date]
    # Version: 1.0
    #
    # ATTRIBUTION
    # Framework: EML PraatGen by Ian Howell
    #            Embodied Music Lab — www.embodiedmusiclab.com
    #            https://github.com/embodied-music-lab/PraatGen
    # Code generation: Claude (Anthropic)
    # Script author: [Your name here] — created and verified by this individual
    #
    # RESEARCH USE DISCLOSURE
    # If this script is used in research or publication, disclose AI use
    # per your target journal's policy. Suggested language:
    #
    #   "Praat analysis scripts were developed using the EML PraatGen
    #    Scripting Assistant (Howell, Embodied Music Lab) with code
    #    generation by Claude (Anthropic). All scripts were reviewed,
    #    tested, and validated by [your name]."
    #
    # The script author assumes responsibility for the correctness and
    # appropriate application of this code.
    # ============================================================================

The title and purpose should reflect the specific task. Date should be the
current session date.

**Version numbering:**
- 1.0 for initial generation
- 1.1, 1.2, ... for corrections and bug fixes
- 2.0 for major modifications or feature additions

**Attribution chain (hard):**
- Ian Howell / EML: framework creator (prompt, reference architecture, procedures)
- Claude (Anthropic): code generation engine
- Script author: the person who requested, tested, and takes responsibility

All three roles MUST appear in every script header.

---

## WORKFLOW PATTERNS: File and directory I/O

### Pattern A: Single file from user

    form: "Analyze sound file"
        infile: "Sound file", ""
    endform
    soundId = Read from file: sound_file$

### Pattern B: Batch process folder

    form: "Batch process sounds"
        folder: "Input folder", ""
        word: "File extension", "wav"
    endform

    fileList = Create Strings as file list: "files", input_folder$ + "/*." + file_extension$
    nFiles = Get number of strings
    if nFiles = 0
        removeObject: fileList
        exitScript: "No ." + file_extension$ + " files found."
    endif

    for iFile from 1 to nFiles
        selectObject: fileList
        fileName$ = Get string: iFile
        filePath$ = input_folder$ + "/" + fileName$
        soundId = Read from file: filePath$
        # ... processing ...
        removeObject: soundId
    endfor
    removeObject: fileList

### Pattern C: Paired file loading (Sound + TextGrid)

    form: "Process annotated sounds"
        folder: "Sound folder", ""
        folder: "TextGrid folder", ""
        word: "Sound extension", "wav"
    endform

    fileList = Create Strings as file list: "files", sound_folder$ + "/*." + sound_extension$
    nFiles = Get number of strings

    for iFile from 1 to nFiles
        selectObject: fileList
        fileName$ = Get string: iFile
        baseName$ = fileName$ - ("." + sound_extension$)
        soundPath$ = sound_folder$ + "/" + fileName$
        gridPath$ = textGrid_folder$ + "/" + baseName$ + ".TextGrid"
        soundId = Read from file: soundPath$
        if fileReadable (gridPath$)
            gridId = Read from file: gridPath$
        else
            writeInfoLine: "WARNING: No TextGrid for " + baseName$
            removeObject: soundId
        endif
        # ... processing ...
        removeObject: soundId
        if variableExists ("gridId")
            removeObject: gridId
        endif
    endfor
    removeObject: fileList

### Pattern D: Safe file overwrite check

    if fileReadable (outputPath$)
        beginPause: "File exists"
            comment: "The file already exists:"
            comment: outputPath$
        clicked = endPause: "Cancel", "Overwrite", 2, 0
        if clicked = 1
            exitScript: "User cancelled."
        endif
    endif

**Path note:** Use forward slashes (`/`). Praat converts automatically.

---

## Output format (generation turns)

### Header requirement (hard)

Every COMPLETE script output must include the full header block as specified
in "Script header (hard)" above. Do not use an abbreviated or alternative
header format in the Output format section — the canonical header is defined
in one place only.

---

End of RULES_CODE.md. Read token: juniper-278
