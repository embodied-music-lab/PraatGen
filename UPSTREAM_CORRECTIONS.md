# EML library corrections found from PraatGen

Maintainer-only. Not shipped to users.

The PKB carries flattened copies of the EML Praat Tools sources. Verified
defects are fixed in the PKB copy and logged here, for reconciliation against
the live plugin.

Each entry gives the procedure, the defect, the verified fix, and the evidence.
Each entry states whether it has been applied to the PKB copies.

The PKB copies were replaced on 28 November 2026 (PraatGen 3.0.0) with the
current `plugin_EML_StatsGraphs/` sources: 20 files, each copied verbatim apart
from a 5-line PKB block after the header comment. Every fix still needed was
re-applied to the new bodies and marked `# Provenance: PraatGen-only edit`.
"Current source" lines below are lines in the plugin source files
(`graphs/eml-graph-procedures.praat`, `graphs/eml-draw-procedures.praat`,
`scripts/eml-batch-process.praat`, `stats/eml-output.praat`,
`stats/eml-extract.praat`); "PKB" lines are lines in the PKB copy after the
sync. The edits are scripted in `release3/pkb_sync_probes/apply_pkb_fixes.py`
and probed in a real Praat 6.6.30 (`release3/pkb_sync_probes/`).

---

## 1. Reversed-axis tick placement draws no scale

**Procedures:** `@emlDrawAlignedMarksBottom`, `@emlDrawAlignedMarksLeft`,
`@emlDrawAlignedMarksRight`
**Current source:** `eml-graph-procedures.praat` 3.32. Bottom: procedure 3200,
step computed at 3219, loop start 3231. Left: 2983, 3010, 3027. Right: 3084,
3109, 3124. No bound normalization at entry. `@emlComputeNiceStep` (2051) keeps
its `if .range <= 0` guard (2060).
**Status: APPLIED to the PKB copies, 23 September 2026. Re-applied in the
28 November 2026 sync** (PKB `eml-graph-procedures.txt` 3019, 3129, 3254).
**Found:** 23 September 2026, PraatGen 1.1.1 work

A caller that passes a descending range gets no tick marks and no axis value
numbers, on either axis, with no error. `@emlComputeNiceStep` receives
`.xMax - .xMin`, which is negative, trips its own `if .range <= 0` guard and
returns a step of 1. The placement loop then starts above its end condition:

    .xPos = ceiling (.xMin / .xStep) * .xStep     ; 3000
    while .xPos <= .xMax + .xTol                  ; 3000 <= 200 — false

**Fix:** normalize the bounds at procedure entry.

    procedure emlDrawAlignedMarksBottom: .xMin, .xMax, .targetTicks, .useMinor
        if .xMax < .xMin
            .swap = .xMin
            .xMin = .xMax
            .xMax = .swap
        endif

Same shape in `@emlDrawAlignedMarksLeft` and `@emlDrawAlignedMarksRight` for
`.yMin` / `.yMax`. All three siblings need it; the Right variant is used by
dual-axis panels.

**`@emlComputeNiceStep` needs no change.** With the bounds normalized the range
it receives is already positive. Its `range <= 0` guard stays as the defensive
branch it was written to be.

**Applying `abs()` in the step computation instead does not work.** Verified:
the rendered panel is byte-identical to the unfixed one. The loop is the blocker.
`abs()` is not the fix for item 2 either — see there.

**Evidence.** Praat 6.6.30 full, 300 dpi, `Select inner viewport: 1, 5, 1, 4`,
`Font size: 10`, `Axes: 3000, 200, 1000, 200`, ticks via the two procedures,
counting pixels below mid-grey:

    6.6.30  ascending   17286 -> 17286   patch is a no-op on ascending input
            descending  10197 -> 17286   fixed, matches ascending exactly
    7.0.02  ascending   19890 -> 19890   unchanged
            descending  10467 -> 19890   fixed, matches ascending exactly

    Right variant, 6.6.30:  ascending 11400, descending 11400 after the patch

The 17286 / 19890 split is the default typeface, not the build: with the font
unset, 6.6.30 fell back to a serif face and 7.0.02 to a sans face. Naming the
font makes the two builds pixel-identical — `Times` gives 17286 on both,
`Helvetica` gives 19890 on both. Each build's descending panel matches its own
ascending control either way.

`One mark bottom:` and `One mark left:` place correctly on a descending axis
under bare Praat, so the placement primitive is sound and only the loop bounds
need normalizing.

---

## 2. Scatter marker radius goes negative on a descending x range

**Procedure:** `@emlDrawScatterPlot`
**Current source:** `eml-draw-procedures.praat` 1.26, `@emlDrawScatterPlot` at
4655: `.markerRadius`, `.xRange`, `.radiusWorld` at 4822-4824 and `.markerHalfIn`
at 4829-4831. `eml-graph-procedures.praat`: `@emlDrawMarker` at 4397 (skips
`.halfIn <= 0` at 4427; its `Paint circle (mm):` fallback passes
`.halfIn * 25.4` at 4455); `@emlSetAlphaDotGeometry` at 6830;
`@emlDrawAlphaDot` at 6899 with `Paint circle:` fallbacks at 6914 and 6932.
**Found:** 23 September 2026, PraatGen 1.1.1 work
**Status: APPLIED to the PKB copies, 28 September 2026. Re-applied in the
28 November 2026 sync, adapted to the current structure:**
- `@emlDrawScatterPlot` computes `.markerHalfIn = abs (.radiusWorld /
  emlPatWorldPerInchX)` when `emlPatWorldPerInchX <> 0` (PKB
  `eml-draw-procedures.txt` 4858-4862), which is `.markerRadius` times the inner
  viewport width on either axis direction.
- `@emlDrawMarker`'s mm fallback passes `2 * .halfIn * 25.4`, a diameter (PKB
  `eml-graph-procedures.txt` 4529-4530).
- `@emlSetAlphaDotGeometry` publishes `.dotDiamMM = 2 * abs (.dotHalf /
  .wuPerInchX) * 25.4` (PKB 6926, 6964), and both fallbacks in
  `@emlDrawAlphaDot` draw with `Paint circle (mm):` at that diameter (PKB 7003,
  7023).

Probe, Praat 6.6.30 Linux, `@emlDrawScatterPlot` on a 12-point table (EPS
output). Ungrouped, every reversal gives 12 markers of one size (radius
38.88 EPS units, as ascending). Upstream source: 0 markers for x reversed and
both reversed, 12 markers at half the radius (19.44) for y reversed. Direct
`@emlDrawMarker` with y reversed: radius 30.0 fixed, 15.0 upstream. Direct
`@emlDrawAlphaDot` fallback with x reversed: draws at 38.88 fixed; upstream
stops with `Argument "Radius" must be greater than 0.0.` Ascending output is
byte-identical to upstream. Sprites cannot be probed on Linux.

    .markerRadius = emlSetAdaptiveTheme.markerSize * .sizeScale
    .xRange = .axisXMax - .axisXMin
    .radiusWorld = .markerRadius * .xRange

The bounds come from the caller at lines 1915–1916; `@emlComputeAxisRange` runs
only when both are zero. A descending range makes `.radiusWorld` negative, and
the outcome then depends on the marker branch at line 2000:

- **Alpha sprites present** — `@emlDrawAlphaDot` draws through
  `Insert picture from file:`, which accepts inverted bounds. On macOS the
  sprites draw at the correct position and size on every axis direction
  (probe result below), so this branch is correct.
- **Sprites absent** — `Paint circle:` receives the negative value and the
  script stops with `Argument "Radius" must be greater than 0.0.`

`@emlDrawAlphaDot` inherits the same value through `.stampHalfX` in both of its
fallback branches.

**Fix: move the marker to `Paint circle (mm):`.** `abs()` does NOT work and
must not be used here — see below.

The library already has this convention. `@emlDrawSpaghettiPlot` sets
`.dotSize = emlSetAdaptiveTheme.markerSize * 1.5` with a floor of 1.0 and
passes it to `Paint circle (mm):`. `@emlDrawJitteredPoints` documents its
`markerSize` argument as "point diameter in mm." The theme computes
`.markerSize = max (0.4, min (1.2, .baseUnit * 0.25))`, already a
millimetre-scale quantity. The scatter path is the outlier: it multiplies that
value by the world x-range.

**Why `abs()` is wrong.** It makes `.radiusWorld` positive, so the script stops
aborting — and the value is still a world radius, which `Paint circle:`
suppresses on a descending x-axis. The result is a chart with a box and no
markers, silently. That converts a loud failure into the exact silent failure
this work exists to prevent.

**Evidence.** Praat 6.6.30 full, 300 dpi, `Select inner viewport: 1, 5, 1, 4`,
`Font size: 10`, two dots, counting pixels below mid-grey:

    ascending, world radius 42          10423   dots drawn
    descending, abs() giving +42         8400   box only, no dots, no error
    descending, Paint circle (mm): 3    10366   dots drawn
    ascending,  Paint circle (mm): 3    10367   dots drawn

**Decision and applied fix.** Marker size does not track the axis range now.
The world radius divided by world units per inch is `.markerRadius` times the
inner viewport width in inches, whatever the axis range. So the millimeter
form can reproduce today's physical size exactly, and `.sizeScale` keeps its
meaning. The PKB copy now does this:

- `@emlSetAlphaDotGeometry` publishes `.dotDiamMM = 2 * abs (.dotHalf /
  .wuPerInchX) * 25.4`, the one source for the native dot size.
- The two native branches of the scatter loop and both fallbacks in
  `@emlDrawAlphaDot` draw with `Paint circle (mm):` at that diameter.
- The sprite geometry is unchanged. It draws correctly on reversed axes
  on macOS (see the probe result below).

Rendered through the full `@emlDrawScatterPlot` on 6.6.30 and 7.0.02: the
ascending chart is pixel-identical before and after the patch (27489 dark
pixels both). Reversed x, reversed y and both reversed all draw every marker
at the same size, grouped and ungrouped.

**For the plugin.** The live plugin reaches the same markers through
`@emlDrawMarker`. The same reasoning gives the fix there: compute `.markerHalfIn`
as `.markerRadius` times the inner width (never negative), and have the
circle fallback pass `2 * .halfIn * 25.4` as the diameter.

**Reachability.** `@emlGraphsWorkflow` swaps `scatterXMin` and `scatterXMax`
when they descend (`eml-graphs-form.txt` 5159-5166), along with five sibling
ranges, before dispatching at 5407. The menu path is therefore safe. A direct
call to `@emlDrawScatterPlot` is not, which is what a generated script makes.

**Two scatter procedures now exist.** The PKB copy of `@emlDrawScatterPlot`
and the live plugin's version differ in how they handle a descending range and
in how they draw markers. Any patch to the PKB copy creates a third version.
The reconcile has to pick one behavior for both trees.

**Upstream state, EMLPraatTools b4f2db98 (26 September 2026).** The live plugin
has moved on from the PKB copy, and the defect has changed shape there:

- The menu now **refuses** a descending range (`@emlGraphsAxisPairRefusal`,
  `eml-graphs-form.praat` 1913) instead of swapping it. Direct calls still
  reach `@emlDrawScatterPlot` unguarded; the radius arithmetic is unchanged
  (`eml-draw-procedures.praat` 4822-4824).
- On Linux, markers now go through `@emlDrawMarker`. The scatter divides by
  `emlPatWorldPerInchX` only when it is positive, so on a descending x the
  negative world radius is passed through as `.halfIn`, and `@emlDrawMarker`
  skips any `.halfIn <= 0` without counting it. On a descending y only,
  `.sy < 0` sends the marker to its `Paint circle (mm):` fallback, which passes
  `.halfIn * 25.4` — a radius — as the diameter.
- Rendered, 6.6.30 full, Helvetica 10, three dots, dot pixels above a box-only
  baseline: ascending 5399; x descending 0; y descending 1339 (area 0.248 of
  ascending, i.e. half the diameter); both descending 0.
- The sprite path cannot be tested on Linux. The plugin's own platform gate
  (`@emlInitAlphaSprites`, 6589-6653) records that `Insert picture from file:`
  draws nothing on Linux builds, and disables sprites there. The PKB copy
  predates that gate.
- Sprite path on macOS: correct on all four axis directions. Each sprite sat
  on its data point at the size of a `Paint circle (mm):` reference, with
  `.stampHalfX` and `.stampHalfY` negative on the reversed axes. Provenance:
  `eml_sprite_probe.praat`, Ian Howell's Mac, 8 Oct 2026.
- The tick procedures (entry 1) are unpatched upstream.

---

## 2b. Gridlines draw nothing on a descending range

**Procedures:** `@emlDrawGridlines`, `@emlDrawHorizontalGridlines`,
`@emlDrawVerticalGridlines`
**Current source:** `eml-graph-procedures.praat` 2416, 2501 and 2550; no swap at
entry; loop starts at 2444, 2514, 2453 and 2559.
**Status: APPLIED to the PKB copies, 28 September 2026. Re-applied in the
28 November 2026 sync** (PKB `eml-graph-procedures.txt` 2424, 2521, 2577).

Same loop shape as entry 1, same fix: normalize the bounds at entry. Before the
patch a y-descending scatter lost its horizontal gridlines with no error. After
it, gridlines draw on every axis direction. Unpatched upstream.

## 2c. Sprites on Linux

**Procedure:** `@emlInitAlphaSprites`
**Current source:** `eml-graph-procedures.praat` 6645-6648: `if not (macintosh or
windows)` / `emlAlphaSpritesInitialized = 1` / `goto SPRITES_INIT_DONE`.
**Status: PARTLY fixed upstream; PKB edit re-applied 28 November 2026.**
Upstream `@eml_csvQuote` (2130-2139) folds each cell to ASCII, then quotes and
doubles it only when it holds a comma, a double quote or a newline, so most
text cells are written bare:

    procedure eml_csvQuote: .s$
        @emlAsciiFold: .s$
        .folded$ = emlAsciiFold.result$
        if index (.folded$, ",") > 0 or index (.folded$, """") > 0
        ... or index (.folded$, newline$) > 0
            .result$ = """" + replace$ (.folded$, """", """""", 0) + """"
        else
            .result$ = .folded$
        endif
    endproc

**PKB edit (`pkb/eml-output.txt`, `@eml_csvQuote`):** every cell that doesn't
read as a number is quoted, with inner quotes doubled; a cell that reads as a
number (`number (.folded$) <> undefined`) stays bare. The ASCII fold is kept.
No other procedure changes. Evidence: Praat 6.6.30 barren, 28 Nov 2026,
`@emlCSVInit`, `@emlCSVAdd`, `@emlCSVAddStr` and `@emlExportStatsCSV` wrote
`"voice data","descriptives","Soprano","","mean",523.25` and
`"voice data","t-test","A vs B","","method","Welch, two-sided"`; Praat's
`Read Table from comma-separated file` read 3 rows back with the values intact.

The PKB edit of 27 November 2026 applied to a procedure that no longer exists.

The original defect: the row writer joined its eight text fields (table, data column, group
column, both group names, test, effect type, effect label) with bare commas.
A column or group name holding a comma shifted every later column, and a
name holding a double quote broke the quoting of the row. This breaks the
PraatGen rule for CSV text fields (Rule 27).

**Fix:** each text field is written in double quotes, with every quote
inside it doubled: `.q$ + replace$ (.text$, .q$, .qq$, 0) + .q$`, where
`.q$` is `""""` and `.qq$` is `""""""`. The numeric fields are unchanged.

**Evidence:** Praat 6.6.30 barren, 27 Nov 2026. Two rows through
`@emlCSVInit`, `@emlCSVAddRow` and `@emlExportStatsCSV`, with the names
`F0, Hz`, `Smith, Jo`, `say "hi"`, `chantée`, `a—b` and `歌`. Fixed: Python's
csv module reads 20 columns in every row and every name exactly; Praat's
`Read Table from comma-separated file` reads 2 rows of 20 columns, with the
commas kept and the double quotes deleted, as Praat's CSV reader does with
any quote. Unfixed: Python reads 22 columns in the first row, and Praat
stops with "Row 2 incomplete."

**Related, now moot.** Every cell is
ASCII-folded by `@emlAsciiFold` before it is written (`eml-output.praat` has no
`Text writing preferences` line), so a non-ASCII group name no longer reaches
the file.

---

## 6. `eml_isMissingToken` copied into the PKB

**Procedure:** `@eml_isMissingToken`
**Current source:** `eml-extract.praat` 2.0, defined at 4148:

    procedure eml_isMissingToken: .s$
        .isMissing = 0
        .low$ = replace_regex$ (.s$, "([A-Z])", "\l\1", 0)
        if .low$ = "na" or .low$ = "n/a" or .low$ = "n.a." or .low$ = "nan"
        ... or .low$ = "null" or .low$ = "nil" or .low$ = "-" or .low$ = "--"
        ... or .low$ = "." or .low$ = "?" or .low$ = "missing"
        ... or .low$ = "--undefined--" or .low$ = "undefined"
            .isMissing = 1
        endif
    endproc

**Status: FIXED upstream. No PKB edit after the 28 November 2026 sync.** The
22 October 2026 PKB addition copied this procedure from the plugin into a
v1.4 copy of `eml-extract.txt` that lacked it. The synced copy carries the
plugin's own definition and the addition is gone.

---

## 7. `emlDrawLMMForest` removed from the PKB copy

**Procedure:** `@emlDrawLMMForest`
**Current source:** `eml-draw-procedures.praat` 1.26, 7655 to the end of the file.
**Status: PraatGen-only removal, 28 November 2026.** The procedure reads
`emlLMM.*`, `emlWaldCI.*` and `emlModelMatrix.*` globals from `eml-lmm`,
`eml-linalg` and `eml-optimizer`, which the author excluded from the PKB. The
PKB copy of `eml-draw-procedures.txt` carries a `# Provenance: PraatGen-only
edit` line at the spot (7669). The file's header comment (lines 42-45, 62-63)
and the comment at 433 still name the procedure, as in the source.

---

## Praat-level behavior, not a library defect

`Paint circle:` and `Draw circle:` take a radius measured along x and render
nothing on a descending x-axis, with no error, given a positive radius. A
non-positive radius is a separate and loud failure on either axis direction.
Verified with bare Praat commands and no library code. This belongs in the
PraatGen drawing reference rather than in this ledger, and it is recorded here
only to keep the two kinds of finding apart.
