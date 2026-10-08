# EML library corrections found from PraatGen

Maintainer-only. Not shipped to users.

The PKB carries flattened copies of the EML Praat Tools sources. Verified
defects are fixed in the PKB copy and logged here, for reconciliation against
the live plugin.

Each entry gives the procedure, the defect, the verified fix, and the evidence.
Each entry states whether it has been applied to the PKB copies.

---

## 1. Reversed-axis tick placement draws no scale

**Procedures:** `@emlDrawAlignedMarksBottom`, `@emlDrawAlignedMarksLeft`,
`@emlDrawAlignedMarksRight`
**Source:** `eml-graph-procedures.txt` lines 1171, 1026 and 1098 (as of 1.1.1)
**Status: APPLIED to the PKB copies, 23 September 2026.**
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
**Source:** `eml-draw-procedures.txt` lines 1955–1957, drawn at 2003 and 2207
**Found:** 23 September 2026, PraatGen 1.1.1 work
**Status: APPLIED to the PKB copies, 28 September 2026.**

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
**Status: APPLIED to the PKB copies, 28 September 2026.**

Same loop shape as entry 1, same fix: normalize the bounds at entry. Before the
patch a y-descending scatter lost its horizontal gridlines with no error. After
it, gridlines draw on every axis direction. Unpatched upstream.

## 2c. Sprites on Linux

**Procedure:** `@emlInitAlphaSprites`
**Status: APPLIED to the PKB copies, 28 September 2026.**

The PKB copy predated the plugin's platform gate. The gate is ported unchanged:
on Linux, sprites stay unavailable and dots use the native fallback.

## 3. LTAS drawing is blank on reversed axes

**Procedure:** `@emlDrawLTAS`
**Source:** `eml-draw-procedures.txt` 413 (as of 1.2.0)
**Status: APPLIED to the PKB copies, 8 October 2026 (release 1.2.1).**

With the frequency axis reversed, the curve, poles and speckles drew nothing;
with the level axis reversed, the poles and speckles drew nothing. Bars drew
on every direction. No error in any case. The pole and speckle range tests
and clamps take `.freqMin`/`.freqMax` and `.powerMin`/`.powerMax` in the order
given: a reversed pair excludes every bin, or clamps every pole to zero length.
`Draw: ... "Curve"` on the Ltas draws nothing when its frequency bounds descend.

**Fix:**
- Range tests and clamps use ordered bounds `.fLo`, `.fHi`, `.pLo`, `.pHi`.
- Speckles use `Paint circle (mm):` at a diameter of
  `2 * 0.006 * inner viewport width * 25.4`, the size the old world radius
  gave on an ascending axis.
- On a descending frequency axis only, the curve is drawn by hand: bin
  centers in range, values clamped to the level axis, joined in bin order.
  On an ascending axis it matches the native curve to within anti-aliasing.

**Evidence:** every method on ascending, reversed-frequency, reversed-level and
both-reversed axes, plus a sub-range with clipping, Praat 6.6.30 and 7.0.02,
8 Oct 2026. Ascending renders are byte-identical before and after. Reversed
renders carry the same ink as ascending (speckles 15012 vs 15014 px; curve
15339 vs 15356 px).

## 3b. Related, lower priority

**`@emlDrawBox`** (`eml-graph-procedures.txt` 1784) computes
`.outlierRadius = .width * 0.2`. Both library callers build an ascending
categorical axis (`.axisXMin = 0.5`, `.axisXMax = nGroups + 0.5`), so no library
path reaches it with a reversed x. Exposed only to a direct caller.

---

## Praat-level behavior, not a library defect

`Paint circle:` and `Draw circle:` take a radius measured along x and render
nothing on a descending x-axis, with no error, given a positive radius. A
non-positive radius is a separate and loud failure on either axis direction.
Verified with bare Praat commands and no library code. This belongs in the
PraatGen drawing reference rather than in this ledger, and it is recorded here
only to keep the two kinds of finding apart.
