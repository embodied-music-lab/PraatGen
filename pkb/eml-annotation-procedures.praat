# ============================================================================
# EML GRAPHS — ANNOTATION + STATS BRIDGE PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Version: 3.7
# Date: 4 April 2026
#
# v3.7: Pairwise effect size performance fix — k-group bridge paths AND
#        reporter pairwise loops now use @eml_getGroupData (pre-extracted
#        vectors) instead of per-pair @emlExtractGroupVectors calls.
#        Bridge: 6 paths updated (ANOVA sig/NS matrix+bracket, KW sig/NS
#        matrix+bracket). Reporter: @emlReportAnovaComparison d-matrix
#        and CSV loops updated (uses emlTukeyHSD.sortMap for index mapping).
#        Eliminates all per-pair table scans in k-group comparisons.
#        Reporter group descriptives inline if/elsif chain (30 lines)
#        replaced with @eml_getGroupData call.
#        Matrix panel legend swatch label reads annotAlpha instead of
#        hardcoded "p < .05". Dynamic label built by
#        @emlMeasureMatrixLayout, stored as emlMatrixLayout_pLegend$,
#        read by @emlDrawMatrixPanel at 2 sites (width + render).
# v3.6: @emlDrawMatrixPanel now calls @emlExpandDrawnExtent (from
#        eml-graph-procedures.praat) to register the matrix panel
#        viewport with the extent tracker, so @emlAssertFullViewport
#        captures the matrix panel when saving figures. Suppressed
#        panels (goto END_PANEL) correctly skip the update.
# v3.4: @emlReportBridgeStats restored as thin dispatcher — reads bridge
#        globals (.nGroups, .testType$), routes to shared reporters. Same
#        3-arg signature as original. Fixes "Procedure not found" error
#        when drawing annotated figures from eml-graphs.praat.
# v3.3: @emlReportTwoWayAnova added — shared reporter for two-way ANOVA.
#        Full ANOVA table (A, B, A×B, Error, Total), partial eta-squared,
#        "Why:" line, CSV rows (one per effect).
# v3.2: @emlReportPairedComparison added — shared reporter for paired t-test
#        and Wilcoxon signed-rank test. Uses correct output variable names
#        (.tPlus/.tMinus not .wPlus/.wMinus). "Why:" lines included.
#        CSV rows via @emlCSVAddRow. Parametric/nonparametric/both routing.
# v3.1: "Why:" pedagogical commentary added to all four shared reporters
#        (@emlReportTwoGroupComparison parametric + nonparametric,
#        @emlReportAnovaComparison, @emlReportKWComparison,
#        @emlReportCorrelationAnalysis Pearson + Spearman). Text sourced
#        from wizard @wizardRun* procedures. Always shown in Info window,
#        naturally excluded from CSV export (CSV rows are structured data).
# v3.0: @emlReportBridgeStats replaced by four shared reporter procedures
#        (@emlReportTwoGroupComparison, @emlReportAnovaComparison,
#        @emlReportKWComparison, @emlReportCorrelationAnalysis). These
#        produce identical Info window output regardless of entry point
#        (stats wrapper or graphs tool) and populate CSV rows via
#        @emlCSVAddRow for export. Uses @emlReport* primitives from
#        eml-output.praat for all formatting.
# v2.9: Matrix panel spacing tightened — clearance and gap now anchored
#        to annotInch/fontInch (panel's own font sizes) instead of
#        bodyInch (graph's body font). Non-rotated header multiplier
#        reduced from 1.8 to 1.2 (matching rotated path). Proportional
#        ratios match @emlDrawTitle for visual consistency.
# v2.8: Matrix subtitle fix — "Upper: adjusted p" added to subtitle when
#        effect sizes shown. Previously only showed "Lower: [effect label]"
#        with no description of what the upper triangle contains.
# v2.7: annotMatrixPosthoc$ global — set by @emlBridgeGroupComparison at
#        all 6 test paths (Welch t-test, Mann-Whitney U, Tukey HSD,
#        Dunn's test with configurable correction method). Cleared by
#        @emlClearAnnotations. Subtitle in @emlDrawMatrixPanel now reads
#        "Tukey HSD · Lower: |Cohen's d|" (with effect) or just the
#        test name (without). Info window report shows "Test:" (2-group)
#        or "Post-hoc:" (k-group) line. Hardcoded "holm" in @emlDunnTest
#        call replaced by annotCorrectionMethod$ global (initialized to
#        "holm" in eml-graphs.praat, overridable by stats callers).
# v2.6: Dead @emlDrawComparisonMatrix overlay removed (−208 lines, replaced
#        by @emlDrawMatrixPanel since v1.4). .showEffect gate added to 5
#        hardcoded matrix population sites (3 effect label, 2 D-value) —
#        2-group NP/P matrix paths and ANOVA k-group significant path now
#        respect the toggle. .showNS gate added to all 6 matrix population
#        sites — upper-triangle cells show "—" when non-significant and
#        showNS = 0 (lower-triangle effect sizes unaffected).
#        New @emlMeasureMatrixLayout procedure — separates measurement
#        (rotate-then-truncate, vertical stacking, legend min width) from
#        @emlDrawMatrixPanel rendering. Matrix panel is now a pure renderer.
# v2.4: Effect size threshold branching — matrix panel now uses
#        correct thresholds per effect type: Cohen's d (0.8/0.5/0.2)
#        vs rank-biserial r (0.5/0.3/0.1). Cohen's d stored as
#        abs() in matrix (consistent with rank-biserial r). Matrix
#        subtitle reads "(magnitude)" to clarify unsigned display
#        while omnibus retains signed d. Removed >10 group hard
#        error — stats and Info window report now run for any group
#        count; matrix panel's own viewport-based display tiers
#        handle visual degradation. Column header-to-data padding
#        increased (0.3 → 0.8 fontInch) for non-rotated headers.
# v2.3: @emlPlaceElements replaces @emlAutoPlaceLegend — universal
#        quadrant-density + bracket-penalty corner selection for
#        legend and annotation block placement. All graph types
#        now use adaptive placement.
# v2.2: annotMatrixEffectLabel$ now stores full label ("Cohen's d" or
#        "rank-biserial r") instead of bare letter. Subtitle no longer
#        hardcodes "Cohen's" prefix — was producing "Cohen's r" for
#        nonparametric tests.
#
# v2.0: @emlReportBridgeStats: 2-group path now includes group descriptives
#        (N, Mean, SD, Median) matching the k-group report format.
# v1.9: @emlFormatAnnotLabel: new .effectLabel$ parameter — bracket labels
#        now show context-appropriate symbol ("d" for Cohen's d, "r" for
#        rank-biserial r) instead of hardcoded "d". All 9 callsites updated.
#        @emlBridgeGroupComparison: .forceMatrix replaced by .layoutMode
#        (1=auto, 2=brackets, 3=matrix). Auto defaults to matrix at k>=3.
#        KW omnibus string now includes epsilon-squared (e2 = H/(n-1)).
#        New @emlReportBridgeStats procedure — writes full statistical
#        report (omnibus + descriptives + p-value matrix + effect matrix)
#        to Info window, callable from both graph dispatch and stats wrappers.
# v1.8: Nonparametric k-group matrix (KW/Dunn's) now computes pairwise
#        rank-biserial |r| for the lower triangle, mirroring the ANOVA
#        path's per-pair Cohen's d. Bracket output also includes r when
#        effect sizes are requested. Subtitle auto-selects "r" label.
# v1.7: @emlDrawMatrixPanel subtitle now shows three-way conditional:
#        "Upper: adjusted p-values · Lower: Cohen's d" (parametric),
#        "Upper: adjusted p-values · Lower: rank-biserial r" (nonparam),
#        or "Adjusted p-values" (no effect sizes). Previously subtitle
#        was suppressed entirely when hasEffect = 0.
# v1.6: Bracket headroom circular dependency fix — algebraic solve for
#        post-expansion wpiY with overflow guard. Matrix panel top-down
#        sizing (1.0–1.3× responsive zone, content minimum cap). Swatch
#        squareness fix — computed in inches, converted to grid units.
# v1.4: @emlDrawMatrixPanel: new .colorMode$ parameter — B/W mode uses
#        medium grey bg for significant p-values, black bg + white text
#        for large effect sizes, dark grey + white for medium. Title and
#        subtitle spacing increased (titleY 0.5, subtitleY 1.5, headerY
#        2.2, dataTop 2.8) to prevent collision at 10 groups. Legend
#        row centered on grid midpoint instead of left-aligned.
# v1.3: @emlDrawAnnotationBlock and @emlDrawAnnotation: replaced charW
#        estimation (length * fixedWidth) with exact text measurement via
#        Text width (world coordinates): — queries the rendering engine
#        for actual rendered string width in the current font/size/axes.
#        Fixes box sizing for proportional fonts (the fundamental flaw in
#        all prior charW-based approaches). Symmetric vertical padding.
#        @emlDrawRegressionLine: white halo (width 3.5) drawn under the
#        colored line for visibility against dense data.
#        Semi-transparent backgrounds via alpha sprite for annotation block
#        (falls back to opaque white if sprites unavailable).
# v1.2: charW estimation attempts (superseded by v1.3).
# v1.1: Spearman label split (Info window plain text vs Picture window
#        markup). New @emlDrawAnnotationBlock for multi-line text boxes
#        with background fill and corner positioning. New @emlOppositeCorner.
#        annotBlockN/annotBlockLabel$/annotBlockDraw$ data structures.
#
# Annotation drawing procedures and bridge layer connecting EML Stats
# results to annotated EML Graphs figures. Provides bracket annotations
# (pairwise comparisons), free-text annotations (omnibus stats), and
# regression line overlays.
#
# Include chain:
#   eml-graphs.praat includes this file AFTER eml-graph-procedures.praat
#   and AFTER all stats library files. This file calls stats procedures
#   and uses drawing procedures from eml-graph-procedures.praat.
#
# Architecture:
#   - Global parallel arrays carry annotation data between bridge
#     procedures (which populate them) and drawing procedures (which
#     render them). Same pattern as legendN/legendColor$/legendLabel$.
#   - Bridge procedures run the appropriate statistical test, then
#     populate the annotation arrays. The main script orchestrates:
#     bridge -> stack -> draw data -> draw annotations -> draw axes.
#
# Procedures:
#   @emlClearAnnotations        — reset all annotation arrays
#   @emlFormatStars             — p-value to star notation
#   @emlFormatAnnotLabel        — format bracket label from p, d, style
#   @emlStackBrackets           — assign vertical tiers to brackets
#   @emlDrawBracket             — render one significance bracket
#   @emlDrawAnnotation          — render positioned text box
#   @emlDrawAnnotations         — umbrella: draw all annotations
#   @emlDrawRegressionLine      — render regression line on scatter plot
#   @emlPlaceElements            — pick best corners for legend + annotation block
#   @emlComputeAnnotationHeadroom — compute extra y-space for brackets
#   @emlMeasureMatrixLayout      — measure matrix panel geometry (rotate, truncate, stack)
#   @emlBridgeGroupComparison   — run group test, populate brackets
#   @emlBridgeCorrelation       — run correlation, populate regression
#   @emlReportBridgeStats       — thin dispatcher: graphs tool → shared reporter
#   @emlReportPairedComparison  — shared reporter: paired comparison
#   @emlReportTwoWayAnova       — shared reporter: two-way ANOVA
# ============================================================================


# ============================================================================
# ANNOTATION DATA STRUCTURES (global parallel arrays)
# ============================================================================
#
# These globals are set by bridge procedures, consumed by drawing
# procedures. They must be initialized before each draw cycle via
# @emlClearAnnotations.
#
# Bracket annotations (group comparisons):
#   annotBracketN                — number of brackets to draw
#   annotBracketI[1..N]          — left group index (1-based)
#   annotBracketJ[1..N]          — right group index (1-based)
#   annotBracketP[1..N]          — p-value
#   annotBracketD[1..N]          — effect size (Cohen's d, r, or epsilon2)
#   annotBracketLabel$[1..N]     — display text
#   annotBracketTier[1..N]       — y-tier assigned by @emlStackBrackets
#
# Free-text annotations (omnibus stats, correlation):
#   annotTextN                   — number of text boxes
#   annotTextX[1..N]             — x position (data coordinates)
#   annotTextY[1..N]             — y position (data coordinates)
#   annotTextLabel$[1..N]        — display text
#   annotTextAnchor$[1..N]       — alignment: "left", "centre", "right"
#
# Regression line (correlation):
#   annotRegressionN             — 0 or 1
#   annotRegressionSlope         — slope
#   annotRegressionIntercept     — intercept
#   annotRegressionR             — Pearson r (or Spearman rho)
#   annotRegressionP             — p-value
#   annotRegressionLabel$        — display label
#
# Format options (set from dialog):
#   annotStyle$                  — "p-value", "stars", "both"
#   annotAlpha                   — significance threshold
#   annotShowNS                  — 0 or 1
#   annotShowEffect              — 0 or 1
#   annotMatrixPosthoc$          — test name for subtitle/report
#                                  ("Welch t-test", "Mann-Whitney U",
#                                  "Tukey HSD", "Dunn's test (holm)")
#   annotCorrectionMethod$       — p-value correction for Dunn's test
#                                  (default "holm", set by stats callers)
#
# Multi-line annotation block (scatter stats + formula):
#   annotBlockN                  — number of lines in block
#   annotBlockLabel$[1..N]       — line text (max 20 lines)
#   annotBlockDraw$[1..N]        — Picture-window version (with markup)
# ============================================================================


# ----------------------------------------------------------------------------
# @emlClearAnnotations
# Reset all annotation arrays to empty state. Call at the top of each
# draw cycle before bridge procedures.
# ----------------------------------------------------------------------------
procedure emlClearAnnotations
    annotBracketN = 0
    annotTextN = 0
    annotBlockN = 0
    annotRegressionN = 0
    annotRegressionSlope = 0
    annotRegressionIntercept = 0
    annotRegressionR = 0
    annotRegressionP = 0
    annotRegressionLabel$ = ""
    # Comparison matrix
    annotMatrixN = 0
    annotMatrixOmnibus$ = ""
    annotMatrixEffectLabel$ = ""
    annotMatrixPosthoc$ = ""
    emlMatrixLayout_pLegend$ = "p < .05"
endproc


# ----------------------------------------------------------------------------
# @emlFormatStars
# Convert p-value to star notation.
# Arguments: .p (p-value)
# Output: .result$ (star string)
# ----------------------------------------------------------------------------
procedure emlFormatStars: .p
    if .p < 0.001
        .result$ = "***"
    elsif .p < 0.01
        .result$ = "**"
    elsif .p < 0.05
        .result$ = "*"
    else
        .result$ = "n.s."
    endif
endproc


# ----------------------------------------------------------------------------
# @emlFormatAnnotLabel
# Format the display label for a bracket annotation.
# Arguments: .p, .d, .style$, .showEffect, .effectLabel$
#   .p            — p-value
#   .d            — effect size value (Cohen's d, rank-biserial r, etc.)
#   .style$       — "p-value", "stars", or "both"
#   .showEffect   — 0 or 1
#   .effectLabel$ — symbol to display (e.g., "d", "r", "ε²")
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlFormatAnnotLabel: .p, .d, .style$, .showEffect, .effectLabel$
    .result$ = ""

    if .style$ = "stars"
        @emlFormatStars: .p
        .result$ = emlFormatStars.result$
    elsif .style$ = "both"
        @emlFormatStars: .p
        @emlFormatP: .p
        .stars$ = emlFormatStars.result$
        .pText$ = emlFormatP.formatted$
        .result$ = .stars$ + " (" + .pText$ + ")"
    else
        # Default: p-value
        @emlFormatP: .p
        .result$ = emlFormatP.formatted$
    endif

    if .showEffect = 1 and .d <> undefined
        .dText$ = fixed$ (.d, 2)
        .result$ = .result$ + ", " + .effectLabel$ + " = " + .dText$
    endif
endproc


# ----------------------------------------------------------------------------
# @emlStackBrackets
# Assign vertical tier to each bracket so none overlap.
# Algorithm: greedy, narrowest-first.
#   1. Compute span = |groupJ - groupI| for each bracket
#   2. Process brackets in ascending span order
#   3. For each bracket, find lowest tier where it does not overlap
#      any already-placed bracket
#   "Overlap" = two brackets share any x-range AND same tier
#
# Input: reads annotBracketN, annotBracketI[], annotBracketJ[]
# Output: writes annotBracketTier[1..N] (1-based, 1 = lowest)
# No arguments — reads/writes global annotBracket* arrays.
# ----------------------------------------------------------------------------
procedure emlStackBrackets
    if annotBracketN = 0
        # Nothing to do
    elsif annotBracketN = 1
        annotBracketTier[1] = 1
    else
        # Compute spans and build sort index
        for .b from 1 to annotBracketN
            .span[.b] = abs (annotBracketJ[.b] - annotBracketI[.b])
            .order[.b] = .b
            annotBracketTier[.b] = 0
        endfor

        # Insertion sort by span ascending (max 45 pairs for 10 groups)
        for .i from 2 to annotBracketN
            .keyIdx = .order[.i]
            .keySpan = .span[.keyIdx]
            .j = .i - 1
            .sorting = 1
            while .j >= 1 and .sorting = 1
                if .span[.order[.j]] > .keySpan
                    .order[.j + 1] = .order[.j]
                    .j = .j - 1
                else
                    .sorting = 0
                endif
            endwhile
            .order[.j + 1] = .keyIdx
        endfor

        # Assign tiers in span order (narrowest first)
        for .s from 1 to annotBracketN
            .b = .order[.s]
            .bLeft = min (annotBracketI[.b], annotBracketJ[.b])
            .bRight = max (annotBracketI[.b], annotBracketJ[.b])

            .tier = 1
            .placed = 0
            while .placed = 0
                .conflict = 0
                # Check all already-placed brackets at this tier
                for .c from 1 to annotBracketN
                    if annotBracketTier[.c] = .tier and .c <> .b
                        .cLeft = min (annotBracketI[.c], annotBracketJ[.c])
                        .cRight = max (annotBracketI[.c], annotBracketJ[.c])
                        # Overlap: ranges share x-space
                        if .bLeft <= .cRight and .bRight >= .cLeft
                            .conflict = 1
                        endif
                    endif
                endfor
                if .conflict = 0
                    annotBracketTier[.b] = .tier
                    .placed = 1
                else
                    .tier = .tier + 1
                endif
            endwhile
        endfor
    endif
endproc


# ----------------------------------------------------------------------------
# @emlDrawBracket
# Render one significance bracket in the current axes.
#
# Geometry:
#        label$
#   ┌──────────────────────────────┐
#   |                              |
# groupI                         groupJ
#
# Three segments: left descender, horizontal bar, right descender.
# Centered text above the horizontal bar.
#
# Arguments:
#   .xI         — x-position of left group (data coordinates)
#   .xJ         — x-position of right group (data coordinates)
#   .yBase      — y-position of lowest bracket tier
#   .tierHeight — vertical spacing between tiers (data coordinates)
#   .tier       — which tier (1-based)
#   .label$     — text to display above bracket
#   .fontSize   — text size for label
#   .lineColor$ — RGB colour string for bracket lines
# ----------------------------------------------------------------------------
procedure emlDrawBracket: .xI, .xJ, .yBase, .tierHeight, .tier, .label$, .fontSize, .lineColor$
    .yBar = .yBase + (.tier - 1) * .tierHeight + .tierHeight * 0.5
    .descenderLen = .tierHeight * 0.3
    .yBottom = .yBar - .descenderLen
    .yText = .yBar + .tierHeight * 0.15

    Colour: .lineColor$
    Line width: 1.0

    # Left descender
    Draw line: .xI, .yBottom, .xI, .yBar
    # Horizontal bar
    Draw line: .xI, .yBar, .xJ, .yBar
    # Right descender
    Draw line: .xJ, .yBottom, .xJ, .yBar

    # Label centered above bar
    .xMid = (.xI + .xJ) / 2
    Font size: .fontSize
    Colour: "{0.1, 0.1, 0.1}"
    Text: .xMid, "centre", .yText, "bottom", .label$

    Colour: "Black"
endproc


# ----------------------------------------------------------------------------
# @emlDrawAnnotation
# Render a free-positioned text box with optional background fill.
# For omnibus stats, correlation results, etc.
#
# Arguments:
#   .x        — x position (data coordinates)
#   .y        — y position (data coordinates)
#   .anchor$  — alignment: "left", "centre", "right"
#   .label$   — text to display
#   .fontSize — text size
#   .hasBg    — 1 = draw white background rectangle, 0 = text only
#   .xRange   — x-axis range (for text box width estimation)
#   .yRange   — y-axis range (for text box height estimation)
# ----------------------------------------------------------------------------
procedure emlDrawAnnotation: .x, .y, .anchor$, .label$, .fontSize, .hasBg, .xRange, .yRange
    if .hasBg = 1
        # Measure actual rendered width (exact, font-aware)
        Font size: .fontSize
        .textW = Text width (world coordinates): .label$
        # Safety margin: screen font metrics differ slightly from PNG export
        .textW = .textW * 1.05

        # Font-size-based spacing via world-per-inch
        .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .wpiX = .xRange / .innerW
        .wpiY = .yRange / .innerH
        .fontInch = .fontSize / 72
        .sf = emlSetAdaptiveTheme.spacingFactor
        .padX = .fontInch * (0.2 + 0.2 * .sf) * .wpiX
        .padY = .fontInch * (0.2 + 0.2 * .sf) * .wpiY

        if .anchor$ = "right"
            .boxLeft = .x - .textW - .padX
            .boxRight = .x + .padX
        elsif .anchor$ = "centre"
            .boxLeft = .x - .textW / 2 - .padX
            .boxRight = .x + .textW / 2 + .padX
        else
            .boxLeft = .x - .padX
            .boxRight = .x + .textW + .padX
        endif
        .boxBottom = .y - .padY
        .boxTop = .y + .padY

        Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
        Colour: "{0.7, 0.7, 0.7}"
        Line width: 0.5
        Draw rectangle: .boxLeft, .boxRight, .boxBottom, .boxTop
    endif

    Font size: .fontSize
    Colour: "{0.1, 0.1, 0.1}"
    Text: .x, .anchor$, .y, "half", .label$

    Colour: "Black"
    Line width: 1.0
endproc


# ----------------------------------------------------------------------------
# @emlDrawAnnotations
# Umbrella: draw all pending annotations. Call after the main drawing
# procedure (with drawAxes suppressed) and before @emlDrawAxesWithHeadroom.
#
# Arguments:
#   .xMin, .xMax   — current axis x bounds
#   .yDataMax      — top of actual data range (brackets sit above this)
#   .yRange        — yMax - yMin of the data
#   .bracketColor$ — RGB colour string for bracket lines
#   .fontSize      — text size for annotation labels
# ----------------------------------------------------------------------------
procedure emlDrawAnnotations: .xMin, .xMax, .yDataMax, .yRange, .bracketColor$, .fontSize
    # --- Brackets ---
    if annotBracketN > 0
        # Physically grounded tier geometry via world-per-inch
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .wpiY = .yRange / .innerH
        .fontInch = .fontSize / 72
        .sf = emlSetAdaptiveTheme.spacingFactor
        .tierHeight = .fontInch * (1.5 + 0.9 * .sf) * .wpiY
        .yBase = .yDataMax + .fontInch * (0.5 + 0.5 * .sf) * .wpiY

        for .b from 1 to annotBracketN
            @emlDrawBracket: annotBracketI[.b], annotBracketJ[.b],
            ... .yBase, .tierHeight, annotBracketTier[.b],
            ... annotBracketLabel$[.b], .fontSize, .bracketColor$
        endfor
    endif

    # --- Text boxes ---
    if annotTextN > 0
        for .t from 1 to annotTextN
            @emlDrawAnnotation: annotTextX[.t], annotTextY[.t],
            ... annotTextAnchor$[.t], annotTextLabel$[.t],
            ... .fontSize, 1,
            ... .xMax - .xMin, .yRange
        endfor
    endif
endproc


# ----------------------------------------------------------------------------
# @emlDrawRegressionLine
# Draw a regression line across the scatter plot axes.
# Computes y at xMin and xMax from the linear equation, clamps to
# axis bounds, draws a thin coloured line.
#
# Arguments:
#   .xMin, .xMax    — axis x bounds
#   .slope          — regression slope
#   .intercept      — regression intercept
#   .yAxisMin       — axis y minimum (for clamping)
#   .yAxisMax       — axis y maximum (for clamping)
#   .lineColor$     — RGB colour string
# ----------------------------------------------------------------------------
procedure emlDrawRegressionLine: .xMin, .xMax, .slope, .intercept, .yAxisMin, .yAxisMax, .lineColor$
    .y1 = .slope * .xMin + .intercept
    .y2 = .slope * .xMax + .intercept

    .drawXMin = .xMin
    .drawXMax = .xMax

    # Clamp: if y1 out of bounds, find x where line enters axis range
    if .y1 < .yAxisMin
        if .slope <> 0
            .drawXMin = (.yAxisMin - .intercept) / .slope
        endif
        .y1 = .yAxisMin
    elsif .y1 > .yAxisMax
        if .slope <> 0
            .drawXMin = (.yAxisMax - .intercept) / .slope
        endif
        .y1 = .yAxisMax
    endif

    if .y2 < .yAxisMin
        if .slope <> 0
            .drawXMax = (.yAxisMin - .intercept) / .slope
        endif
        .y2 = .yAxisMin
    elsif .y2 > .yAxisMax
        if .slope <> 0
            .drawXMax = (.yAxisMax - .intercept) / .slope
        endif
        .y2 = .yAxisMax
    endif

    # White halo for visibility against data points
    Colour: "White"
    Line width: 3.5
    Draw line: .drawXMin, .y1, .drawXMax, .y2

    # Regression line
    Colour: .lineColor$
    Line width: 2.5
    Draw line: .drawXMin, .y1, .drawXMax, .y2

    Colour: "Black"
    Line width: 1.0
endproc


# ----------------------------------------------------------------------------
# @emlPlaceElements
# Universal placement algorithm for legend and annotation block.
# Scores all four corners by data density + bracket occupation,
# then assigns corners to up to 2 floating elements.
#
# Arguments:
#   .qTL, .qTR, .qBL, .qBR — quadrant data counts (pre-computed by caller)
#   .xMid                   — x-axis midpoint (for mapping bracket positions)
#   .nElements              — 1 (legend only) or 2 (annotation block + legend)
#
# Bracket penalty: reads global annotBracketN / annotBracketI[] /
#   annotBracketJ[] to add occupation weight to top quadrants.
#   Brackets always live at the top of the plot.
#
# Output:
#   .corner1$ — emptiest corner (for annotation block, or sole legend)
#   .corner2$ — diagonal opposite of corner1 (for legend when 2 elements)
# ----------------------------------------------------------------------------
procedure emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, .nElements
    # Add bracket penalties to top quadrants
    if variableExists ("annotBracketN")
        if annotBracketN > 0
            for .b from 1 to annotBracketN
                # Each bracket endpoint penalizes its quadrant
                if annotBracketI[.b] < .xMid
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
                if annotBracketJ[.b] < .xMid
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
            endfor
        endif
    endif

    # Find emptiest corner (lowest score wins)
    .minScore = .qTL
    .corner1$ = "top-left"

    if .qTR < .minScore
        .minScore = .qTR
        .corner1$ = "top-right"
    endif
    if .qBL < .minScore
        .minScore = .qBL
        .corner1$ = "bottom-left"
    endif
    if .qBR < .minScore
        .minScore = .qBR
        .corner1$ = "bottom-right"
    endif

    # Second element goes to diagonal opposite
    if .nElements >= 2
        @emlOppositeCorner: .corner1$
        .corner2$ = emlOppositeCorner.result$
    else
        .corner2$ = .corner1$
    endif
endproc


# ----------------------------------------------------------------------------
# @emlComputeAnnotationHeadroom
# Compute how much extra y-axis space is needed for bracket annotations.
# Call after @emlStackBrackets and after @emlSetAdaptiveTheme.
#
# Arguments:
#   .yDataRange  — yMax - yMin of the actual data
#   .fontSize    — annotation font size (for wpiY geometry)
#
# Output:
#   .headroom    — additional y-space needed above data max
#   .maxTier     — highest tier assigned (0 if no brackets)
#   .overflow    — 1 if brackets cannot fit in viewport, 0 otherwise
# ----------------------------------------------------------------------------
procedure emlComputeAnnotationHeadroom: .yDataRange, .fontSize
    .maxTier = 0
    if annotBracketN > 0
        for .b from 1 to annotBracketN
            if annotBracketTier[.b] > .maxTier
                .maxTier = annotBracketTier[.b]
            endif
        endfor
    endif

    .overflow = 0
    if .maxTier > 0
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .fontInch = .fontSize / 72
        .sf = emlSetAdaptiveTheme.spacingFactor
        # Must match bracket geometry: baseGap + tiers * tierHeight + topPad
        .baseGap = 0.5 + 0.5 * .sf
        .tierMult = 1.5 + 0.9 * .sf
        .kTotal = .baseGap + .maxTier * .tierMult + .baseGap
        .fontK = .fontInch * .kTotal
        if .fontK >= .innerH
            # Brackets cannot physically fit — flag overflow
            .headroom = .yDataRange * 0.5
            .overflow = 1
        else
            # Solve for post-expansion headroom algebraically:
            # headroom = fontK * yDataRange / (innerH - fontK)
            # This accounts for the fact that brackets are drawn using
            # the expanded y-range (including headroom), not the original.
            .headroom = .fontK * .yDataRange / (.innerH - .fontK)
        endif
    else
        .headroom = 0
    endif
endproc


# ----------------------------------------------------------------------------
# @emlOppositeCorner
# Return the diagonally opposite corner. Used to separate the stats
# annotation block from the legend.
# Argument: .corner$ ("top-left", "top-right", "bottom-left", "bottom-right")
# Output: .result$
# ----------------------------------------------------------------------------
procedure emlOppositeCorner: .corner$
    if .corner$ = "top-left"
        .result$ = "bottom-right"
    elsif .corner$ = "top-right"
        .result$ = "bottom-left"
    elsif .corner$ = "bottom-left"
        .result$ = "top-right"
    else
        .result$ = "top-left"
    endif
endproc


# ----------------------------------------------------------------------------
# @emlDrawAnnotationBlock
# Render a multi-line text box with background fill in a specified corner.
# Reads from annotBlockN / annotBlockDraw$[1..N] globals.
#
# Arguments:
#   .corner$   — "top-left", "top-right", "bottom-left", "bottom-right"
#   .xMin, .xMax, .yMin, .yMax — current axis bounds
#   .fontSize  — text size for annotation lines
#
# Draws directly; no output variables.
# Uses annotBlockDraw$[] for Picture window text (may contain %% markup).
# Caller is responsible for populating annotBlockN and annotBlockDraw$[].
# ----------------------------------------------------------------------------
procedure emlDrawAnnotationBlock: .corner$, .xMin, .xMax, .yMin, .yMax, .fontSize
    if annotBlockN = 0
        # Nothing to draw
    else
        .xRange = .xMax - .xMin
        .yRange = .yMax - .yMin

        # Line height and spacing in world coordinates via world-per-inch
        .innerW = emlSetAdaptiveTheme.innerRight - emlSetAdaptiveTheme.innerLeft
        .innerH = emlSetAdaptiveTheme.innerBottom - emlSetAdaptiveTheme.innerTop
        .wpiX = .xRange / .innerW
        .wpiY = .yRange / .innerH
        .fontInch = .fontSize / 72
        .lineH = .fontInch * 1.4 * .wpiY

        # Set font size before measuring — query uses current font metrics
        Font size: .fontSize

        # Measure actual rendered width of each line (exact, font-aware)
        # Use annotBlockLabel$ (plain text) not annotBlockDraw$ (markup)
        # because %% markup chars affect Text width measurement
        .textW = 0
        for .i from 1 to annotBlockN
            .w = Text width (world coordinates): annotBlockLabel$[.i]
            if .w > .textW
                .textW = .w
            endif
        endfor
        # Safety margin: screen font metrics differ slightly from PNG export
        .textW = .textW * 1.05

        .textH = annotBlockN * .lineH
        # Padding and insets: scale with spacingFactor
        .sf = emlSetAdaptiveTheme.spacingFactor
        .padX = .fontInch * (0.3 + 0.2 * .sf) * .wpiX
        .padY = .lineH * (0.2 + 0.15 * .sf)
        .boxW = .textW + 2 * .padX
        .boxH = .textH + 2 * .padY

        # Inset from axes — unified with legend and matrix boxes
        .insetX = emlSetAdaptiveTheme.boxInsetInches * .wpiX
        .insetY = emlSetAdaptiveTheme.boxInsetInches * .wpiY

        # Position based on corner
        if .corner$ = "top-left"
            .boxLeft = .xMin + .insetX
            .boxRight = .boxLeft + .boxW
            .boxTop = .yMax - .insetY
            .boxBottom = .boxTop - .boxH
            .textX = .boxLeft + .padX
        elsif .corner$ = "top-right"
            .boxRight = .xMax - .insetX
            .boxLeft = .boxRight - .boxW
            .boxTop = .yMax - .insetY
            .boxBottom = .boxTop - .boxH
            .textX = .boxLeft + .padX
        elsif .corner$ = "bottom-left"
            .boxLeft = .xMin + .insetX
            .boxRight = .boxLeft + .boxW
            .boxBottom = .yMin + .insetY
            .boxTop = .boxBottom + .boxH
            .textX = .boxLeft + .padX
        else
            # bottom-right
            .boxRight = .xMax - .insetX
            .boxLeft = .boxRight - .boxW
            .boxBottom = .yMin + .insetY
            .boxTop = .boxBottom + .boxH
            .textX = .boxLeft + .padX
        endif

        # Background fill (semi-transparent if sprites available)
        if variableExists ("emlAlphaSpritesInitialized")
            if emlAlphaSpritesInitialized = 1 and emlInitAlphaSprites.available = 1
                .bgFile$ = emlInitAlphaSprites.dir$ + "bg_white_a70_40.png"
                if fileReadable (.bgFile$)
                    Insert picture from file: .bgFile$, .boxLeft, .boxRight, .boxBottom, .boxTop
                else
                    Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
                endif
            else
                Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
            endif
        else
            Paint rectangle: "White", .boxLeft, .boxRight, .boxBottom, .boxTop
        endif
        Colour: "{0.7, 0.7, 0.7}"
        Line width: 0.5
        Draw rectangle: .boxLeft, .boxRight, .boxBottom, .boxTop

        # Draw lines top-to-bottom
        Colour: "{0.1, 0.1, 0.1}"
        .yLine = .boxTop - .padY - .lineH / 2
        for .i from 1 to annotBlockN
            Text: .textX, "left", .yLine, "half", annotBlockDraw$[.i]
            .yLine = .yLine - .lineH
        endfor

        # Reset
        Colour: "Black"
        Line width: 1.0
    endif
endproc


# ============================================================================
# @emlMeasureMatrixLayout
# ============================================================================
# Measure matrix panel geometry: label rotation/truncation, vertical
# stacking, cell sizing, legend minimum width. Called before
# @emlDrawMatrixPanel — the panel is a pure renderer reading these results.
#
# Rotate-then-truncate order:
#   1. Measure each label against available width
#   2. If ANY label overflows → rotate all column headers 45°
#   3. After rotation, if ANY label STILL overflows → truncate with "…"
#   This matches the graph x-axis behavior in @emlFitCategoricalLabels.
#
# Reads globals:
#   annotMatrixN, annotMatrixLabel$[], annotMatrixEffectLabel$
#   emlSetAdaptiveTheme.* (font sizes, inner viewport, spacing)
#
# Arguments:
#   .vpLeft, .vpRight, .vpTop, .vpBottom — panel viewport (inches)
#   .fontSize — base text size for labels and cells
#
# Output (module-level globals):
#   emlMatrixLayout_scaledFont     — possibly compressed font
#   emlMatrixLayout_fontInch       — scaledFont / 72
#   emlMatrixLayout_cellW          — cell width (viewport units)
#   emlMatrixLayout_gridW          — total grid width
#   emlMatrixLayout_gridLeft       — grid left edge
#   emlMatrixLayout_gridRight      — grid right edge
#   emlMatrixLayout_gridCenter     — grid horizontal center
#   emlMatrixLayout_rotateHeaders  — 1 = rotate column headers 45°
#   emlMatrixLayout_showText       — 1 = show text, 0 = shading only
#   emlMatrixLayout_suppressed     — 1 = too narrow to display at all
#   emlMatrixLayout_titleY         — vertical position of title
#   emlMatrixLayout_subtitleY      — vertical position of subtitle
#   emlMatrixLayout_headerY        — vertical position of column headers
#   emlMatrixLayout_dataTop        — top of data grid
#   emlMatrixLayout_rowH           — row height
#   emlMatrixLayout_labelGap       — gap between labels and grid
#   emlMatrixLayout_labelRight     — right edge of row label column
#   emlMatrixLayout_maxLabelSpace  — max width for row labels
#   emlMatrixLayout_yMax           — total content height
#   emlMatrixLayout_hasEffect      — 1 = effect sizes present
#   emlMatrixLayout_legendMinWidthInches — minimum legend width from content
#   annotMatrixLabel$[]            — truncated in place
# ============================================================================
procedure emlMeasureMatrixLayout: .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize
    .nG = annotMatrixN
    emlMatrixLayout_suppressed = 0
    emlMatrixLayout_showText = 1
    emlMatrixLayout_rotateHeaders = 0
    emlMatrixLayout_hasEffect = 0
    emlMatrixLayout_legendMinWidthInches = 0

    if .nG < 2
        emlMatrixLayout_suppressed = 1
    endif

    if emlMatrixLayout_suppressed = 1
        goto END_MEASURE_MATRIX
    endif

    if annotMatrixEffectLabel$ <> ""
        emlMatrixLayout_hasEffect = 1
    endif

    .vpW = .vpRight - .vpLeft
    .vpH = .vpBottom - .vpTop

    # ----------------------------------------------------------------
    # Grid geometry — aligned to graph inner box
    # ----------------------------------------------------------------
    .innerLeftX = emlSetAdaptiveTheme.innerLeft
    .innerRightX = emlSetAdaptiveTheme.innerRight
    .innerBoxW = .innerRightX - .innerLeftX

    # Font setup
    .scaledFont = .fontSize
    .fontInch = .scaledFont / 72

    # ----------------------------------------------------------------
    # Set viewport for text measurement (must precede content sizing)
    # ----------------------------------------------------------------
    Font size: emlSetAdaptiveTheme.bodySize
    Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    Axes: 0, .vpW, .vpH, 0

    # ----------------------------------------------------------------
    # Content-aware cell sizing
    # ----------------------------------------------------------------
    # Measure the widest cell content at current font size.
    # Cell content is already populated by the bridge.
    Font size: .scaledFont
    .maxContentW = 0
    for .i from 1 to .nG - 1
        for .j from .i + 1 to .nG
            .cellText$ = annotMatrixCell'.i'_'.j'$
            # Strip "p = " / "p < " prefix as the panel renderer does
            if left$ (.cellText$, 4) = "p = "
                .measureText$ = mid$ (.cellText$, 5, length (.cellText$) - 4)
            elsif left$ (.cellText$, 4) = "p < "
                .measureText$ = "< " + mid$ (.cellText$, 5, length (.cellText$) - 4)
            else
                .measureText$ = .cellText$
            endif
            .w = Text width (world coordinates): .measureText$
            if .w > .maxContentW
                .maxContentW = .w
            endif
            # Also measure effect size text if present
            if emlMatrixLayout_hasEffect = 1
                .dVal = annotMatrixD'.i'_'.j'
                if .dVal <> undefined
                    .dText$ = fixed$ (abs (.dVal), 2)
                    .w = Text width (world coordinates): .dText$
                    if .w > .maxContentW
                        .maxContentW = .w
                    endif
                endif
            endif
        endfor
    endfor
    # Padding: content must not touch cell edges
    .contentMinCellW = .maxContentW * 1.15

    # Cell width: max of geometry-based and content-based minimums
    .referenceCellW = .innerBoxW / 10
    .maxCellW = .referenceCellW * 1.5
    .geomMinCellW = .fontInch * 3.0
    .naturalCellW = .innerBoxW / .nG
    .cellW = min (.maxCellW, max (.geomMinCellW, .naturalCellW))

    # Content floor: if content is wider than geometry allows, expand
    if .contentMinCellW > .cellW
        .cellW = .contentMinCellW
    endif

    .gridW = .nG * .cellW

    # If grid exceeds inner box: try font compression first
    if .gridW > .innerBoxW
        # Can we fit by compressing font?
        .tryFont = .scaledFont * (.innerBoxW / .gridW) * 0.95
        if .tryFont >= 5
            .scaledFont = .tryFont
            .fontInch = .scaledFont / 72
            # Re-measure content at compressed font
            Font size: .scaledFont
            .maxContentW = 0
            for .i from 1 to .nG - 1
                for .j from .i + 1 to .nG
                    .cellText$ = annotMatrixCell'.i'_'.j'$
                    if left$ (.cellText$, 4) = "p = "
                        .measureText$ = mid$ (.cellText$, 5, length (.cellText$) - 4)
                    elsif left$ (.cellText$, 4) = "p < "
                        .measureText$ = "< " + mid$ (.cellText$, 5, length (.cellText$) - 4)
                    else
                        .measureText$ = .cellText$
                    endif
                    .w = Text width (world coordinates): .measureText$
                    if .w > .maxContentW
                        .maxContentW = .w
                    endif
                endfor
            endfor
            .contentMinCellW = .maxContentW * 1.15
            .cellW = max (.contentMinCellW, .innerBoxW / .nG)
            .gridW = .nG * .cellW
        endif
    endif

    # Final overflow check: if content still can't fit → shading only
    if .gridW > .innerBoxW
        .cellW = .innerBoxW / .nG
        .gridW = .innerBoxW
        emlMatrixLayout_showText = 0
    endif

    # Center grid on inner box when narrower; fill when full
    if .gridW >= .innerBoxW
        .gridLeft = .innerLeftX
        .gridW = .innerBoxW
        .cellW = .gridW / .nG
    else
        .gridLeft = .innerLeftX + (.innerBoxW - .gridW) / 2
    endif
    .gridRight = .gridLeft + .gridW
    .gridCenter = (.gridLeft + .gridRight) / 2

    # Final tier check: too narrow for even shading?
    if .cellW < .fontInch * 1.0
        emlMatrixLayout_suppressed = 1
        goto END_MEASURE_MATRIX
    endif

    # Row labels — external to grid, right-justified in left margin
    .labelGap = .fontInch * 0.7
    .labelRight = .gridLeft - .labelGap
    .maxLabelSpace = (.gridLeft - .vpLeft) * 0.85

    # Row height
    .rowH = .fontInch * 2.1

    # ----------------------------------------------------------------
    # ROTATE-THEN-TRUNCATE (correct order)
    # ----------------------------------------------------------------
    # Step 1: Check rotation BEFORE any truncation
    .colLabelPad = .cellW * 0.85
    Font size: .scaledFont
    .maxLabelW = 0
    for .j from 1 to .nG
        .lblW = Text width (world coordinates): annotMatrixLabel$[.j]
        if .lblW > .maxLabelW
            .maxLabelW = .lblW
        endif
        if .lblW > .colLabelPad
            emlMatrixLayout_rotateHeaders = 1
        endif
    endfor

    # Step 2: Truncate — tightest constraint wins
    .maxMatrixLabelW = min (.maxLabelSpace, .cellW * 0.85)
    for .j from 1 to .nG
        .lblW = Text width (world coordinates): annotMatrixLabel$[.j]
        if .lblW > .maxMatrixLabelW
            .lo = 1
            .hi = length (annotMatrixLabel$[.j])
            .origML$ = annotMatrixLabel$[.j]
            while .lo < .hi - 1
                .mid = round ((.lo + .hi) / 2)
                .tryML$ = left$ (.origML$, .mid) + "…"
                .tryMLW = Text width (world coordinates): .tryML$
                if .tryMLW <= .maxMatrixLabelW
                    .lo = .mid
                else
                    .hi = .mid
                endif
            endwhile
            annotMatrixLabel$[.j] = left$ (.origML$, .lo) + "…"
        endif
    endfor

    # Re-measure maxLabelW after truncation (for header height calc)
    .maxLabelW = 0
    for .j from 1 to .nG
        .lblW = Text width (world coordinates): annotMatrixLabel$[.j]
        if .lblW > .maxLabelW
            .maxLabelW = .lblW
        endif
    endfor

    # ----------------------------------------------------------------
    # Title/subtitle vertical layout — responsive to content
    # Spacing anchored to the font sizes actually used in the panel
    # (annotSize for omnibus title, matrixSize for subtitle), not
    # the graph's bodySize. Matches @emlDrawTitle proportional ratios.
    # ----------------------------------------------------------------
    .annotInch = emlSetAdaptiveTheme.annotSize / 72
    .clearance = .annotInch * 0.5
    .gap = .fontInch * 0.4
    .titleY = .clearance + .annotInch / 2
    .subtitleY = .titleY + .annotInch / 2 + .gap + .fontInch / 2

    # ----------------------------------------------------------------
    # Header spacing — responsive to rotation and label dimensions
    # ----------------------------------------------------------------
    .lineH = .fontInch * 2.0

    if emlMatrixLayout_rotateHeaders
        .rotatedH = .maxLabelW * 0.707
        .headerY = .subtitleY + .fontInch / 2 + .lineH * 1.2 + .rotatedH * 0.80
    else
        .headerY = .subtitleY + .fontInch / 2 + .lineH * 1.2
    endif
    .dataTop = .headerY + .fontInch * 0.8

    # Shading-only: no headers, collapse header gap
    if emlMatrixLayout_showText = 0
        .dataTop = .subtitleY + .lineH * 0.8
    endif

    # ----------------------------------------------------------------
    # Bottom extent — includes legend if effect sizes present
    # ----------------------------------------------------------------
    if emlMatrixLayout_hasEffect = 1
        .legendGap = .fontInch * 1.5
        .legendSwatchSize = .fontInch * 2.0
        .legendBottomPad = .fontInch * 0.5
        .yMax = .dataTop + .nG * .rowH
        ... + .legendGap + .legendSwatchSize + .legendBottomPad
    else
        .yMax = .dataTop + .nG * .rowH + .fontInch * 0.5
    endif

    # Shading-only: expand grid to fill inner box
    if emlMatrixLayout_showText = 0
        .gridLeft = .innerLeftX
        .cellW = .innerBoxW / .nG
        .gridW = .innerBoxW
        .gridRight = .gridLeft + .gridW
        .gridCenter = (.gridLeft + .gridRight) / 2
    endif

    # ----------------------------------------------------------------
    # Legend minimum width from content (TODO-003)
    # ----------------------------------------------------------------
    if emlMatrixLayout_hasEffect = 1
        Font size: .scaledFont
        .textGap = .fontInch * 1.0
        .itemGap = .fontInch * 2.5
        .swatchW = .fontInch * 2.0
        # Build dynamic p-legend label from annotAlpha
        if annotAlpha < 0.01
            .pLegend$ = "p < " + replace$ (fixed$ (annotAlpha, 3), "0.", ".", 1)
        else
            .pLegend$ = "p < " + replace$ (fixed$ (annotAlpha, 2), "0.", ".", 1)
        endif
        emlMatrixLayout_pLegend$ = .pLegend$
        .tw1 = Text width (world coordinates): .pLegend$
        .tw2 = Text width (world coordinates): "large"
        .tw3 = Text width (world coordinates): "medium"
        .tw4 = Text width (world coordinates): "small"
        .padInch = .fontInch * 1.0
        emlMatrixLayout_legendMinWidthInches = 4 * (.swatchW + .textGap)
        ... + .tw1 + .tw2 + .tw3 + .tw4 + 3 * .itemGap + 2 * .padInch
    endif

    # ----------------------------------------------------------------
    # Store all results in module-level globals
    # ----------------------------------------------------------------
    emlMatrixLayout_scaledFont = .scaledFont
    emlMatrixLayout_fontInch = .fontInch
    emlMatrixLayout_cellW = .cellW
    emlMatrixLayout_gridW = .gridW
    emlMatrixLayout_gridLeft = .gridLeft
    emlMatrixLayout_gridRight = .gridRight
    emlMatrixLayout_gridCenter = .gridCenter
    emlMatrixLayout_titleY = .titleY
    emlMatrixLayout_subtitleY = .subtitleY
    emlMatrixLayout_headerY = .headerY
    emlMatrixLayout_dataTop = .dataTop
    emlMatrixLayout_rowH = .rowH
    emlMatrixLayout_labelGap = .labelGap
    emlMatrixLayout_labelRight = .labelRight
    emlMatrixLayout_maxLabelSpace = .maxLabelSpace
    emlMatrixLayout_yMax = .yMax

    # Restore font state
    Font size: emlSetAdaptiveTheme.bodySize

    label END_MEASURE_MATRIX
endproc


# ----------------------------------------------------------------------------
# @emlDrawMatrixPanel
# Render a pairwise comparison matrix as a table panel below the plot.
# Uses its own viewport — does not draw inside the plot axes.
#
# Split-triangle layout:
#   Upper triangle = p-values (significant highlighted, NS muted)
#   Lower triangle = |Cohen's d| with 3-tier magnitude coloring
#   Diagonal = em-dash
#
# Color mode:
#   "color" — blue sig p-values, amber/gold effect size tiers
#   "bw"    — medium grey sig p-values, black/dark-grey effect tiers
#             with white text for large and medium effects
#
# Reads annotMatrixN, annotMatrixLabel$[], annotMatrixOmnibus$,
# annotMatrixCell'.i'_'.j'$, annotMatrixSig'.i'_'.j',
# annotMatrixD'.i'_'.j'
#
# Arguments:
#   .vpLeft     — left edge of panel viewport (inches)
#   .vpRight    — right edge of panel viewport (inches)
#   .vpTop      — top edge of panel viewport (inches, = bottom of plot)
#   .vpBottom   — bottom edge of panel viewport (inches)
#   .fontSize   — text size for labels and cells
#   .colorMode$ — "color" or "bw"
# ----------------------------------------------------------------------------
procedure emlDrawMatrixPanel: .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize, .colorMode$
    .nG = annotMatrixN

    # ----------------------------------------------------------------
    # Pure renderer — reads all geometry from @emlMeasureMatrixLayout.
    # No measurement, no label truncation, no rotation decisions here.
    # ----------------------------------------------------------------

    if emlMatrixLayout_suppressed = 1
        if emlMatrixLayout_showText = 0 and .nG >= 2
            appendInfoLine: "NOTE: Viewport too narrow for comparison matrix "
            ... + "— panel suppressed."
        endif
        goto END_PANEL
    endif

    # Read measured layout
    .hasEffect = emlMatrixLayout_hasEffect
    .scaledFont = emlMatrixLayout_scaledFont
    .fontInch = emlMatrixLayout_fontInch
    .cellW = emlMatrixLayout_cellW
    .gridW = emlMatrixLayout_gridW
    .gridLeft = emlMatrixLayout_gridLeft
    .gridRight = emlMatrixLayout_gridRight
    .gridCenter = emlMatrixLayout_gridCenter
    .showText = emlMatrixLayout_showText
    .rotateHeaders = emlMatrixLayout_rotateHeaders
    .titleY = emlMatrixLayout_titleY
    .subtitleY = emlMatrixLayout_subtitleY
    .headerY = emlMatrixLayout_headerY
    .dataTop = emlMatrixLayout_dataTop
    .rowH = emlMatrixLayout_rowH
    .labelGap = emlMatrixLayout_labelGap
    .labelRight = emlMatrixLayout_labelRight
    .yMax = emlMatrixLayout_yMax

    .vpW = .vpRight - .vpLeft
    .vpH = .vpBottom - .vpTop

    # ----------------------------------------------------------------
    # Top-down viewport sizing
    # ----------------------------------------------------------------
    .contentH = .yMax
    .maxH = .contentH * 1.3
    if .vpH > .maxH
        .vpBottom = .vpTop + .maxH
    elsif .vpH < .contentH
        .vpBottom = .vpTop + .contentH
    endif
    .vpH = .vpBottom - .vpTop

    # Font state invariant: bodySize before viewport assertion
    Font size: emlSetAdaptiveTheme.bodySize
    Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    Axes: 0, .vpW, .yMax, 0

    # ----------------------------------------------------------------
    # Color definitions
    # ----------------------------------------------------------------
    if .colorMode$ = "bw"
        .pSigBg$      = "{0.72, 0.72, 0.72}"
        .pSigText$    = "{0.08, 0.08, 0.08}"
        .pNsBg$       = "{0.92, 0.92, 0.92}"
        .pNsText$     = "{0.45, 0.45, 0.45}"
        .dLargeBg$    = "{0.12, 0.12, 0.12}"
        .dLargeText$  = "{1.0, 1.0, 1.0}"
        .dMediumBg$   = "{0.45, 0.45, 0.45}"
        .dMediumText$ = "{1.0, 1.0, 1.0}"
        .dSmallBg$    = "{0.92, 0.92, 0.92}"
        .dSmallText$  = "{0.50, 0.50, 0.50}"
    else
        .pSigBg$      = "{0.82, 0.90, 0.97}"
        .pSigText$    = "{0.08, 0.08, 0.08}"
        .pNsBg$       = "{0.96, 0.96, 0.96}"
        .pNsText$     = "{0.38, 0.38, 0.38}"
        .dLargeBg$    = "{0.92, 0.82, 0.55}"
        .dLargeText$  = "{0.35, 0.25, 0.01}"
        .dMediumBg$   = "{1.0, 0.93, 0.76}"
        .dMediumText$ = "{0.40, 0.31, 0.01}"
        .dSmallBg$    = "{0.96, 0.96, 0.96}"
        .dSmallText$  = "{0.50, 0.50, 0.50}"
    endif

    # ----------------------------------------------------------------
    # Title (omnibus) — centered on grid
    # ----------------------------------------------------------------
    if annotMatrixOmnibus$ <> ""
        Colour: "{0.15, 0.15, 0.15}"
        Text special: .gridCenter, "centre", .titleY, "half",
        ... emlFont$, emlSetAdaptiveTheme.annotSize, "0",
        ... annotMatrixOmnibus$
    endif

    # ----------------------------------------------------------------
    # Subtitle — centered on grid
    # ----------------------------------------------------------------
    if .hasEffect = 1
        Colour: "{0.55, 0.55, 0.55}"
        if annotMatrixPosthoc$ <> ""
            .sub$ = annotMatrixPosthoc$ + " · Upper: adjusted p · Lower: "
            ... + annotMatrixEffectLabel$ + " (magnitude)"
        else
            .sub$ = "Upper: adjusted p · Lower: "
            ... + annotMatrixEffectLabel$ + " (magnitude)"
        endif
        Text special: .gridCenter, "centre", .subtitleY, "half",
        ... emlFont$, .fontSize, "0", .sub$
    elsif annotMatrixPosthoc$ <> ""
        Colour: "{0.55, 0.55, 0.55}"
        .sub$ = annotMatrixPosthoc$
        Text special: .gridCenter, "centre", .subtitleY, "half",
        ... emlFont$, .fontSize, "0", .sub$
    endif

    # ----------------------------------------------------------------
    # Column headers — rotation decided by @emlMeasureMatrixLayout
    # ----------------------------------------------------------------
    if .showText = 1
        Colour: "{0.08, 0.08, 0.08}"
        for .j from 1 to .nG
            .cx = .gridLeft + (.j - 1) * .cellW + .cellW / 2
            if .rotateHeaders
                Text special: .cx, "left", .headerY, "half",
                ... emlFont$, .scaledFont, "45",
                ... annotMatrixLabel$[.j]
            else
                Text special: .cx, "centre", .headerY, "half",
                ... emlFont$, .scaledFont, "0",
                ... annotMatrixLabel$[.j]
            endif
        endfor
    endif

    # ----------------------------------------------------------------
    # Data rows
    # ----------------------------------------------------------------
    for .i from 1 to .nG
        .ry = .dataTop + (.i - 1) * .rowH + .rowH / 2 + .fontInch * 0.15

        # Row label — right-justified in left margin (normal mode only)
        if .showText = 1
            Colour: "{0.08, 0.08, 0.08}"
            Text special: .labelRight, "right", .ry, "half",
            ... emlFont$, .scaledFont, "0",
            ... annotMatrixLabel$[.i]
        endif

        # Cells
        for .j from 1 to .nG
            .cx = .gridLeft + (.j - 1) * .cellW + .cellW / 2
            .cellPad = min (.cellW, .rowH) * 0.04
            .cellL = .gridLeft + (.j - 1) * .cellW + .cellPad
            .cellR = .gridLeft + (.j - 1) * .cellW + .cellW - .cellPad
            .cellT = .dataTop + (.i - 1) * .rowH + .cellPad
            .cellB = .dataTop + (.i - 1) * .rowH + .rowH - .cellPad

            if .i = .j
                if .showText = 1
                    Colour: "{0.7, 0.7, 0.7}"
                    Text special: .cx, "centre", .ry, "half",
                    ... emlFont$, .scaledFont, "0", "—"
                endif

            elsif .i < .j
                .ii = .i
                .jj = .j
                .sig = annotMatrixSig'.ii'_'.jj'
                .cellText$ = annotMatrixCell'.ii'_'.jj'$

                if left$ (.cellText$, 4) = "p = "
                    .cellText$ = mid$ (.cellText$, 5, length (.cellText$) - 4)
                elsif left$ (.cellText$, 4) = "p < "
                    .cellText$ = "< " + mid$ (.cellText$, 5, length (.cellText$) - 4)
                endif

                if .sig = 1
                    Paint rectangle: .pSigBg$, .cellL, .cellR, .cellT, .cellB
                    Colour: .pSigText$
                else
                    Paint rectangle: .pNsBg$, .cellL, .cellR, .cellT, .cellB
                    Colour: .pNsText$
                endif
                if .showText = 1
                    Text special: .cx, "centre", .ry, "half",
                    ... emlFont$, .scaledFont, "0", .cellText$
                endif

            else
                .ii = .j
                .jj = .i
                if .hasEffect = 1
                    .dVal = annotMatrixD'.ii'_'.jj'
                    if .dVal <> undefined
                        .absD = abs (.dVal)
                        .dText$ = fixed$ (.absD, 2)

                        if annotMatrixEffectLabel$ = "rank-biserial r"
                            .threshLarge = 0.5
                            .threshMedium = 0.3
                        else
                            .threshLarge = 0.8
                            .threshMedium = 0.5
                        endif

                        if .absD >= .threshLarge
                            Paint rectangle: .dLargeBg$, .cellL, .cellR, .cellT, .cellB
                            Colour: .dLargeText$
                        elsif .absD >= .threshMedium
                            Paint rectangle: .dMediumBg$, .cellL, .cellR, .cellT, .cellB
                            Colour: .dMediumText$
                        else
                            Paint rectangle: .dSmallBg$, .cellL, .cellR, .cellT, .cellB
                            Colour: .dSmallText$
                        endif
                        if .showText = 1
                            Text special: .cx, "centre", .ry, "half",
                            ... emlFont$, .scaledFont, "0", .dText$
                        endif
                    endif
                endif
            endif
        endfor
    endfor

    # ----------------------------------------------------------------
    # Grid lines
    # ----------------------------------------------------------------
    Colour: "{0.75, 0.75, 0.75}"
    Line width: 0.5

    for .col from 1 to .nG - 1
        .lx = .gridLeft + .col * .cellW
        Draw line: .lx, .dataTop, .lx, .dataTop + .nG * .rowH
    endfor
    for .row from 1 to .nG - 1
        .ly = .dataTop + .row * .rowH
        Draw line: .gridLeft, .ly, .gridRight, .ly
    endfor

    # ----------------------------------------------------------------
    # Color legend — uses content-based min width (TODO-003)
    # ----------------------------------------------------------------
    if .hasEffect = 1
        .legendY = .dataTop + .nG * .rowH + .fontInch * 1.5

        .swatchW = .fontInch * 2.0
        .guY = .yMax / .vpH
        .swatchH = .swatchW * .guY

        # Measure rendered label widths at scaledFont
        Font size: .scaledFont
        .textGap = .fontInch * 1.0
        .itemGap = .fontInch * 2.5
        .textW1 = Text width (world coordinates): emlMatrixLayout_pLegend$
        .textW2 = Text width (world coordinates): "large"
        .textW3 = Text width (world coordinates): "medium"
        .textW4 = Text width (world coordinates): "small"

        .totalLegendW = 4 * (.swatchW + .textGap) + .textW1 + .textW2
        ... + .textW3 + .textW4 + 3 * .itemGap

        # Legend asserts its own minimum width from content;
        # grid width is no longer the sole ceiling
        .legendCeiling = max (.gridW, emlMatrixLayout_legendMinWidthInches)
        if .totalLegendW > .legendCeiling
            .scale = .legendCeiling / .totalLegendW
            .itemGap = .itemGap * .scale
            .textGap = .textGap * .scale
            .swatchW = .swatchW * .scale
            .swatchH = .swatchW * .guY
            .textW1 = .textW1 * .scale
            .textW2 = .textW2 * .scale
            .textW3 = .textW3 * .scale
            .textW4 = .textW4 * .scale
            .totalLegendW = .legendCeiling
        endif

        .legendStart = .gridCenter - .totalLegendW / 2

        .lx1 = .legendStart
        Paint rectangle: .pSigBg$, .lx1, .lx1 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx1 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", emlMatrixLayout_pLegend$

        .lx2 = .lx1 + .swatchW + .textGap + .textW1 + .itemGap
        Paint rectangle: .dLargeBg$, .lx2, .lx2 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx2 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", "large"

        .lx3 = .lx2 + .swatchW + .textGap + .textW2 + .itemGap
        Paint rectangle: .dMediumBg$, .lx3, .lx3 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx3 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", "medium"

        .lx4 = .lx3 + .swatchW + .textGap + .textW3 + .itemGap
        Paint rectangle: .dSmallBg$, .lx4, .lx4 + .swatchW,
        ... .legendY - .swatchH / 2, .legendY + .swatchH / 2
        Colour: "{0.45, 0.45, 0.45}"
        Text special: .lx4 + .swatchW + .textGap, "left", .legendY, "half",
        ... emlFont$, .scaledFont, "0", "small"
    endif

    # Reset
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize

    # Update extent tracker so @emlAssertFullViewport captures this panel
    @emlExpandDrawnExtent: .vpLeft, .vpRight, .vpTop, .vpBottom

    label END_PANEL
endproc


# ============================================================================
# BRIDGE PROCEDURES
# ============================================================================


# ----------------------------------------------------------------------------
# @emlBridgeGroupComparison
# For bar chart, violin, box plot, and grouped violin: detect number of
# groups, run the appropriate statistical test, populate bracket or matrix
# annotations.
#
# When .forceMatrix = 1 OR nGroups >= 4: populates annotMatrix* globals.
# When .forceMatrix = 0 AND nGroups <= 3: populates annotBracket* arrays.
#
# Arguments:
#   .tableId     — Table object ID
#   .dataCol$    — numeric data column name
#   .factorCol$  — group/factor column name
#   .alpha       — significance threshold (e.g., 0.05)
#   .style$      — "p-value", "stars", or "both"
#   .showNS      — 1 = show non-significant brackets, 0 = hide
#   .showEffect  — 1 = show effect sizes, 0 = hide
#   .testType$   — "parametric" or "nonparametric"
#   .forceMatrix — 1 = always use matrix output, 0 = auto (brackets ≤3)
#
# Output: populates annotBracket* or annotMatrix* global arrays.
#   Also sets:
#     .omnibus$  — formatted omnibus test result string (for Info window)
#     .error$    — "" on success, diagnostic message on failure
# ----------------------------------------------------------------------------
procedure emlBridgeGroupComparison: .tableId, .dataCol$, .factorCol$, .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode
    # .layoutMode: 1 = auto, 2 = force brackets, 3 = force matrix
    .omnibus$ = ""
    .error$ = ""

    # --- Count groups ---
    @emlCountGroups: .tableId, .factorCol$
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
    endif

    .nGroups = emlCountGroups.nGroups

    if .error$ = "" and .nGroups < 2
        .error$ = "Need at least 2 groups for comparison"
    endif

    if .error$ = "" and .nGroups > 10
        appendInfoLine: "NOTE: ", .nGroups, " groups detected. "
        ... + "Comparison matrix may be difficult to read at this size."
    endif

    # Determine output mode: brackets or matrix
    if .layoutMode = 3
        .useMatrix = 1
    elsif .layoutMode = 2
        .useMatrix = 0
    else
        # Auto: brackets for k=2, matrix for k>=3
        .useMatrix = 0
        if .nGroups >= 3
            .useMatrix = 1
        endif
    endif

    # =================================================================
    # 2-GROUP COMPARISON
    # =================================================================

    if .error$ = "" and .nGroups = 2
        .label1$ = emlCountGroups.groupLabel$[1]
        .label2$ = emlCountGroups.groupLabel$[2]

        @emlExtractGroupVectors: .tableId, .dataCol$, .factorCol$, .label1$, .label2$

        if emlExtractGroupVectors.error$ <> ""
            .error$ = emlExtractGroupVectors.error$
        else
            .v1# = emlExtractGroupVectors.group1#
            .v2# = emlExtractGroupVectors.group2#

            if .testType$ = "nonparametric"
                # Mann-Whitney U + rank-biserial r
                @emlRankBiserialR: .v1#, .v2#, 2
                if emlRankBiserialR.error$ <> ""
                    .error$ = emlRankBiserialR.error$
                else
                    .pVal = emlRankBiserialR.p
                    .effectVal = emlRankBiserialR.r
                    .u1 = emlRankBiserialR.u1

                    @emlFormatP: .pVal
                    .omnibus$ = "Mann-Whitney: U = " + fixed$ (.u1, 1)
                    ... + ", " + emlFormatP.formatted$
                    ... + ", r = " + fixed$ (.effectVal, 2)
                    annotMatrixPosthoc$ = "Mann-Whitney U"

                    if .useMatrix
                        @emlFormatAnnotLabel: .pVal, undefined, .style$, 0, ""
                        annotMatrixN = 2
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "rank-biserial r"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        annotMatrixLabel$[1] = .label1$
                        annotMatrixLabel$[2] = .label2$
                        annotMatrixCell1_2$ = emlFormatAnnotLabel.result$
                        annotMatrixD1_2 = undefined
                        if .showEffect = 1
                            annotMatrixD1_2 = .effectVal
                        endif
                        if .pVal < .alpha
                            annotMatrixSig1_2 = 1
                        else
                            annotMatrixSig1_2 = 0
                        endif
                        if annotMatrixSig1_2 = 0 and .showNS = 0
                            annotMatrixCell1_2$ = "—"
                        endif
                    else
                        annotBracketN = 1
                        annotBracketI[1] = 1
                        annotBracketJ[1] = 2
                        annotBracketP[1] = .pVal
                        annotBracketD[1] = .effectVal
                        @emlFormatAnnotLabel: .pVal, .effectVal, .style$, .showEffect, "r"
                        annotBracketLabel$[1] = emlFormatAnnotLabel.result$
                        annotBracketTier[1] = 1

                        if .pVal >= .alpha and .showNS = 0
                            annotBracketN = 0
                        endif
                    endif
                endif
            else
                # Welch t-test + Cohen's d
                @emlTTest: .v1#, .v2#, 2, 0
                if emlTTest.error$ <> ""
                    .error$ = emlTTest.error$
                else
                    .pVal = emlTTest.p
                    .tVal = emlTTest.t
                    .dfVal = emlTTest.df

                    @emlCohenD: .v1#, .v2#
                    .effectVal = undefined
                    if emlCohenD.error$ = ""
                        .effectVal = emlCohenD.d
                    endif

                    @emlFormatP: .pVal
                    .omnibus$ = "Welch t: t(" + fixed$ (.dfVal, 1) + ") = "
                    ... + fixed$ (.tVal, 2)
                    ... + ", " + emlFormatP.formatted$
                    if .effectVal <> undefined
                        .omnibus$ = .omnibus$
                        ... + ", d = " + fixed$ (.effectVal, 2)
                    endif
                    annotMatrixPosthoc$ = "Welch t-test"

                    if .useMatrix
                        @emlFormatAnnotLabel: .pVal, undefined, .style$, 0, ""
                        annotMatrixN = 2
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "Cohen's d"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        annotMatrixLabel$[1] = .label1$
                        annotMatrixLabel$[2] = .label2$
                        annotMatrixCell1_2$ = emlFormatAnnotLabel.result$
                        annotMatrixD1_2 = undefined
                        if .showEffect = 1
                            annotMatrixD1_2 = .effectVal
                        endif
                        if .pVal < .alpha
                            annotMatrixSig1_2 = 1
                        else
                            annotMatrixSig1_2 = 0
                        endif
                        if annotMatrixSig1_2 = 0 and .showNS = 0
                            annotMatrixCell1_2$ = "—"
                        endif
                    else
                        annotBracketN = 1
                        annotBracketI[1] = 1
                        annotBracketJ[1] = 2
                        annotBracketP[1] = .pVal
                        annotBracketD[1] = .effectVal
                        @emlFormatAnnotLabel: .pVal, .effectVal, .style$, .showEffect, "d"
                        annotBracketLabel$[1] = emlFormatAnnotLabel.result$
                        annotBracketTier[1] = 1

                        if .pVal >= .alpha and .showNS = 0
                            annotBracketN = 0
                        endif
                    endif
                endif
            endif
        endif
    endif

    # =================================================================
    # K-GROUP COMPARISON (3-10 groups)
    # =================================================================

    if .error$ = "" and .nGroups >= 3

        if .testType$ = "nonparametric"
            # --- Kruskal-Wallis + Dunn's post-hoc ---
            @emlKruskalWallis: .tableId, .dataCol$, .factorCol$
            if emlKruskalWallis.error$ <> ""
                .error$ = emlKruskalWallis.error$
            else
                .hVal = emlKruskalWallis.h
                .pOmnibus = emlKruskalWallis.p
                .dfOmnibus = emlKruskalWallis.df
                .totalN = emlKruskalWallis.n
                .epsilonSq = .hVal / (.totalN - 1)

                @emlFormatP: .pOmnibus
                .omnibus$ = "Kruskal-Wallis: H(" + string$ (.dfOmnibus) + ") = "
                ... + fixed$ (.hVal, 2)
                ... + ", " + emlFormatP.formatted$
                ... + ", e2 = " + fixed$ (.epsilonSq, 3)

                # Map bridge group indices to pre-extracted vector indices
                # (@emlKruskalWallis called @emlExtractMultipleGroups;
                # mapping stable across subsequent @emlDunnTest extraction)
                if .showEffect = 1
                    for .ii from 1 to .nGroups
                        .extractIdx[.ii] = 0
                        for .gg from 1 to .nGroups
                            if emlCountGroups.groupLabel$[.ii]
                            ... = emlExtractMultipleGroups.groupLabel$[.gg]
                                .extractIdx[.ii] = .gg
                            endif
                        endfor
                    endfor
                endif

                # Pairwise post-hoc
                if .pOmnibus < .alpha
                    @emlDunnTest: .tableId, .dataCol$, .factorCol$, annotCorrectionMethod$
                    if emlDunnTest.error$ = ""
                        annotMatrixPosthoc$ = "Dunn's test ("
                        ... + annotCorrectionMethod$ + ")"
                        if .useMatrix
                            # --- MATRIX OUTPUT (split triangle) ---
                            # Upper triangle: p-values only (text)
                            # Lower triangle: rank-biserial |r| (numeric, rendered by panel)
                            annotMatrixN = .nGroups
                            annotMatrixOmnibus$ = .omnibus$
                            if .showEffect = 1
                                annotMatrixEffectLabel$ = "rank-biserial r"
                            else
                                annotMatrixEffectLabel$ = ""
                            endif
                            for .i from 1 to .nGroups
                                annotMatrixLabel$[.i] = emlCountGroups.groupLabel$[.i]
                            endfor
                            for .i from 1 to .nGroups - 1
                                for .j from .i + 1 to .nGroups
                                    .pairP = emlDunnTest.pMatrix##[.i, .j]

                                    # p-value text only (no effect in cell)
                                    @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                                    annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$
                                    if .pairP < .alpha
                                        annotMatrixSig'.i'_'.j' = 1
                                    else
                                        annotMatrixSig'.i'_'.j' = 0
                                    endif
                                    if annotMatrixSig'.i'_'.j' = 0 and .showNS = 0
                                        annotMatrixCell'.i'_'.j'$ = "—"
                                    endif

                                    # Rank-biserial r stored numerically for lower triangle
                                    annotMatrixD'.i'_'.j' = undefined
                                    if .showEffect = 1
                                        @eml_getGroupData: .extractIdx[.i]
                                        .v1# = eml_getGroupData.data#
                                        @eml_getGroupData: .extractIdx[.j]
                                        @emlRankBiserialR: .v1#, eml_getGroupData.data#, 2
                                        if emlRankBiserialR.error$ = ""
                                            annotMatrixD'.i'_'.j' = abs (emlRankBiserialR.r)
                                        endif
                                    endif
                                endfor
                            endfor
                        else
                            # --- BRACKET OUTPUT ---
                            annotBracketN = 0
                            for .i from 1 to .nGroups - 1
                                for .j from .i + 1 to .nGroups
                                    .pairP = emlDunnTest.pMatrix##[.i, .j]

                                    # Rank-biserial r per pair if effect display requested
                                    .pairD = undefined
                                    if .showEffect = 1
                                        @eml_getGroupData: .extractIdx[.i]
                                        .v1# = eml_getGroupData.data#
                                        @eml_getGroupData: .extractIdx[.j]
                                        @emlRankBiserialR: .v1#, eml_getGroupData.data#, 2
                                        if emlRankBiserialR.error$ = ""
                                            .pairD = abs (emlRankBiserialR.r)
                                        endif
                                    endif

                                    if .pairP < .alpha or .showNS = 1
                                        annotBracketN = annotBracketN + 1
                                        .bIdx = annotBracketN
                                        annotBracketI[.bIdx] = .i
                                        annotBracketJ[.bIdx] = .j
                                        annotBracketP[.bIdx] = .pairP
                                        annotBracketD[.bIdx] = .pairD
                                        @emlFormatAnnotLabel: .pairP, .pairD, .style$, .showEffect, "r"
                                        annotBracketLabel$[.bIdx] = emlFormatAnnotLabel.result$
                                    endif
                                endfor
                            endfor
                            @emlStackBrackets
                        endif

                        # Omnibus as text annotation (both modes)
                        annotTextN = 1
                        annotTextX[1] = 0
                        annotTextY[1] = 0
                        annotTextLabel$[1] = .omnibus$
                        annotTextAnchor$[1] = "right"
                    endif
                else
                    # Omnibus not significant
                    if .useMatrix
                        annotMatrixN = .nGroups
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "rank-biserial r"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        for .i from 1 to .nGroups
                            annotMatrixLabel$[.i] = emlCountGroups.groupLabel$[.i]
                        endfor
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                annotMatrixCell'.i'_'.j'$ = "n.s."
                                annotMatrixSig'.i'_'.j' = 0
                                if .showNS = 0
                                    annotMatrixCell'.i'_'.j'$ = "—"
                                endif
                                annotMatrixD'.i'_'.j' = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .extractIdx[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .extractIdx[.j]
                                    @emlRankBiserialR: .v1#, eml_getGroupData.data#, 2
                                    if emlRankBiserialR.error$ = ""
                                        annotMatrixD'.i'_'.j' = abs (emlRankBiserialR.r)
                                    endif
                                endif
                            endfor
                        endfor
                    else
                        annotTextN = 1
                        annotTextX[1] = 0
                        annotTextY[1] = 0
                        annotTextLabel$[1] = .omnibus$
                        annotTextAnchor$[1] = "right"
                    endif
                endif
            endif


        else
            # --- One-way ANOVA + Tukey HSD ---
            @emlOneWayAnova: .tableId, .dataCol$, .factorCol$, 1
            if emlOneWayAnova.error$ <> ""
                .error$ = emlOneWayAnova.error$
            else
                .fVal = emlOneWayAnova.fValue
                .pOmnibus = emlOneWayAnova.p
                .dfB = emlOneWayAnova.dfBetween
                .dfW = emlOneWayAnova.dfWithin

                @emlFormatP: .pOmnibus
                .omnibus$ = "One-way ANOVA: F(" + string$ (.dfB) + ", "
                ... + string$ (.dfW) + ") = "
                ... + fixed$ (.fVal, 2)
                ... + ", " + emlFormatP.formatted$
                annotMatrixPosthoc$ = "Tukey HSD"

                # --------------------------------------------------------
                # Index mapping: encounter order → ANOVA alphabetical order
                # emlCountGroups uses encounter order (matches x-axis)
                # emlOneWayAnova inherits Tukey alphabetical sort
                # Build .anovaMap[displayIdx] = anovaIdx so that
                # pMatrix##[.anovaMap[.i], .anovaMap[.j]] gives the
                # p-value for display row .i vs display column .j.
                # --------------------------------------------------------
                for .i from 1 to .nGroups
                    .anovaMap[.i] = 0
                    for .g from 1 to .nGroups
                        if emlCountGroups.groupLabel$[.i]
                        ... = emlOneWayAnova.groupName$[.g]
                            .anovaMap[.i] = .g
                        endif
                    endfor
                    if .anovaMap[.i] = 0
                        .error$ = "Group mapping failed: "
                        ... + emlCountGroups.groupLabel$[.i]
                    endif
                endfor

                # Map bridge group indices to pre-extracted vector indices
                # (@emlOneWayAnova called @emlExtractMultipleGroups internally;
                # @eml_getGroupData reads those outputs without table scans)
                if .error$ = "" and .showEffect = 1
                    for .ii from 1 to .nGroups
                        .extractIdx[.ii] = 0
                        for .gg from 1 to .nGroups
                            if emlCountGroups.groupLabel$[.ii]
                            ... = emlExtractMultipleGroups.groupLabel$[.gg]
                                .extractIdx[.ii] = .gg
                            endif
                        endfor
                    endfor
                endif

                # Pairwise from Tukey
                if .error$ = "" and .pOmnibus < .alpha and emlOneWayAnova.nPairs > 0
                    if .useMatrix
                        # --- MATRIX OUTPUT (split triangle) ---
                        # Upper triangle: p-values only (text)
                        # Lower triangle: Cohen's d (numeric, rendered by panel)
                        annotMatrixN = .nGroups
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "Cohen's d"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        for .i from 1 to .nGroups
                            annotMatrixLabel$[.i] = emlCountGroups.groupLabel$[.i]
                        endfor
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                .pairP = emlOneWayAnova.pMatrix##[.anovaMap[.i], .anovaMap[.j]]

                                # p-value text only (no effect in cell)
                                @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                                annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$
                                if .pairP < .alpha
                                    annotMatrixSig'.i'_'.j' = 1
                                else
                                    annotMatrixSig'.i'_'.j' = 0
                                endif
                                if annotMatrixSig'.i'_'.j' = 0 and .showNS = 0
                                    annotMatrixCell'.i'_'.j'$ = "—"
                                endif

                                # Cohen's d stored numerically for lower triangle
                                annotMatrixD'.i'_'.j' = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .extractIdx[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .extractIdx[.j]
                                    @emlCohenD: .v1#, eml_getGroupData.data#
                                    if emlCohenD.error$ = ""
                                        annotMatrixD'.i'_'.j' = abs (emlCohenD.d)
                                    endif
                                endif
                            endfor
                        endfor
                    else
                        # --- BRACKET OUTPUT ---
                        annotBracketN = 0
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                .pairP = emlOneWayAnova.pMatrix##[.anovaMap[.i], .anovaMap[.j]]

                                # Cohen's d per pair if effect display requested
                                .pairD = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .extractIdx[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .extractIdx[.j]
                                    @emlCohenD: .v1#, eml_getGroupData.data#
                                    if emlCohenD.error$ = ""
                                        .pairD = emlCohenD.d
                                    endif
                                endif

                                if .pairP < .alpha or .showNS = 1
                                    annotBracketN = annotBracketN + 1
                                    .bIdx = annotBracketN
                                    annotBracketI[.bIdx] = .i
                                    annotBracketJ[.bIdx] = .j
                                    annotBracketP[.bIdx] = .pairP
                                    annotBracketD[.bIdx] = .pairD
                                    @emlFormatAnnotLabel: .pairP, .pairD, .style$, .showEffect, "d"
                                    annotBracketLabel$[.bIdx] = emlFormatAnnotLabel.result$
                                endif
                            endfor
                        endfor
                        @emlStackBrackets
                    endif

                    # Omnibus as text annotation (both modes)
                    annotTextN = 1
                    annotTextX[1] = 0
                    annotTextY[1] = 0
                    annotTextLabel$[1] = .omnibus$
                    annotTextAnchor$[1] = "right"
                else
                    # Omnibus not significant or no pairs
                    if .useMatrix
                        annotMatrixN = .nGroups
                        annotMatrixOmnibus$ = .omnibus$
                        if .showEffect = 1
                            annotMatrixEffectLabel$ = "Cohen's d"
                        else
                            annotMatrixEffectLabel$ = ""
                        endif
                        for .i from 1 to .nGroups
                            annotMatrixLabel$[.i] = emlCountGroups.groupLabel$[.i]
                        endfor
                        for .i from 1 to .nGroups - 1
                            for .j from .i + 1 to .nGroups
                                .pairP = emlOneWayAnova.pMatrix##[.anovaMap[.i], .anovaMap[.j]]
                                @emlFormatAnnotLabel: .pairP, undefined, .style$, 0, ""
                                annotMatrixCell'.i'_'.j'$ = emlFormatAnnotLabel.result$
                                annotMatrixSig'.i'_'.j' = 0
                                if .showNS = 0
                                    annotMatrixCell'.i'_'.j'$ = "—"
                                endif
                                annotMatrixD'.i'_'.j' = undefined
                                if .showEffect = 1
                                    @eml_getGroupData: .extractIdx[.i]
                                    .v1# = eml_getGroupData.data#
                                    @eml_getGroupData: .extractIdx[.j]
                                    @emlCohenD: .v1#, eml_getGroupData.data#
                                    if emlCohenD.error$ = ""
                                        annotMatrixD'.i'_'.j' = abs (emlCohenD.d)
                                    endif
                                endif
                            endfor
                        endfor
                    else
                        annotTextN = 1
                        annotTextX[1] = 0
                        annotTextY[1] = 0
                        annotTextLabel$[1] = .omnibus$
                        annotTextAnchor$[1] = "right"
                    endif
                endif
            endif
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlBridgeCorrelation
# For scatter plot: run correlation, populate regression line and text
# annotation arrays.
#
# Arguments:
#   .tableId     — Table object ID
#   .colX$       — x-axis column name
#   .colY$       — y-axis column name
#   .alpha       — significance threshold
#   .style$      — "p-value", "stars", or "both"
#   .corrType$   — "pearson" or "spearman"
#
# Output: populates annotRegression* and annotText* global arrays.
#   Also sets:
#     .result$   — formatted correlation result string (for Info window)
#     .error$    — "" on success
# ----------------------------------------------------------------------------
procedure emlBridgeCorrelation: .tableId, .colX$, .colY$, .alpha, .style$, .corrType$
    .result$ = ""
    .error$ = ""

    # Extract both columns
    @emlExtractColumn: .tableId, .colX$
    if emlExtractColumn.error$ <> ""
        .error$ = emlExtractColumn.error$
    else
        .xData# = emlExtractColumn.data#
        .nX = emlExtractColumn.n
    endif

    if .error$ = ""
        @emlExtractColumn: .tableId, .colY$
        if emlExtractColumn.error$ <> ""
            .error$ = emlExtractColumn.error$
        else
            .yData# = emlExtractColumn.data#
            .nY = emlExtractColumn.n
        endif
    endif

    if .error$ = "" and .nX <> .nY
        .error$ = "X and Y columns have different valid row counts"
    endif

    if .error$ = ""
        if .corrType$ = "spearman"
            @emlSpearmanCorrelation: .xData#, .yData#, 2
            if emlSpearmanCorrelation.error$ <> ""
                .error$ = emlSpearmanCorrelation.error$
            else
                .rVal = emlSpearmanCorrelation.rho
                .pVal = emlSpearmanCorrelation.p
                .rLabelInfo$ = "rs = "
                .rLabelDraw$ = "%%r%_s = "
            endif
        else
            @emlPearsonCorrelation: .xData#, .yData#, 2
            if emlPearsonCorrelation.error$ <> ""
                .error$ = emlPearsonCorrelation.error$
            else
                .rVal = emlPearsonCorrelation.r
                .pVal = emlPearsonCorrelation.p
                .rLabelInfo$ = "r = "
                .rLabelDraw$ = "r = "
            endif
        endif
    endif

    if .error$ = ""
        # Format r with no leading zero
        .rText$ = fixed$ (abs (.rVal), 2)
        .firstChar$ = left$ (.rText$, 1)
        .zeroChar$ = "0"
        if .firstChar$ = .zeroChar$
            .rText$ = right$ (.rText$, length (.rText$) - 1)
        endif
        if .rVal < 0
            .rText$ = "-" + .rText$
        endif

        @emlFormatP: .pVal
        .pText$ = emlFormatP.formatted$
        .result$ = .rLabelInfo$ + .rText$ + ", " + .pText$
        .drawResult$ = .rLabelDraw$ + .rText$ + ", " + .pText$

        # Regression line (always from Pearson r, even for Spearman)
        .meanX = mean (.xData#)
        .meanY = mean (.yData#)
        .sdX = stdev (.xData#)
        .sdY = stdev (.yData#)

        if .sdX > 0
            if .corrType$ = "spearman"
                # Need Pearson r for the regression line
                @emlPearsonCorrelation: .xData#, .yData#, 2
                .rForLine = emlPearsonCorrelation.r
            else
                .rForLine = .rVal
            endif

            annotRegressionN = 1
            annotRegressionSlope = .rForLine * (.sdY / .sdX)
            annotRegressionIntercept = .meanY - annotRegressionSlope * .meanX
            annotRegressionR = .rVal
            annotRegressionP = .pVal
            annotRegressionLabel$ = .drawResult$
        else
            annotRegressionN = 0
        endif

        # Text annotation (position set by caller after axes computed)
        annotTextN = 1
        annotTextX[1] = 0
        annotTextY[1] = 0
        annotTextLabel$[1] = .drawResult$
        annotTextAnchor$[1] = "left"
    endif
endproc



# ============================================================================
# @emlReportBridgeStats — thin dispatcher for graphs tool
# ============================================================================
# Called by eml-graphs.praat after @emlBridgeGroupComparison has run.
# Routes to the correct shared reporter based on bridge globals.
# Same 3-argument signature as the original monolithic reporter.
# ============================================================================
procedure emlReportBridgeStats: .tableId, .dataCol$, .groupCol$
    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nGroups = emlBridgeGroupComparison.nGroups
    .testType$ = emlBridgeGroupComparison.testType$

    @emlCSVInit

    if .nGroups = 2
        # 2-group: extract descriptives, route to TwoGroupComparison
        .g1$ = emlCountGroups.groupLabel$ [1]
        .g2$ = emlCountGroups.groupLabel$ [2]

        selectObject: .tableId
        @emlExtractGroupVectors: .tableId, .dataCol$, .groupCol$, .g1$, .g2$
        .v1# = emlExtractGroupVectors.group1#
        .v2# = emlExtractGroupVectors.group2#
        .n1 = emlExtractGroupVectors.n1
        .n2 = emlExtractGroupVectors.n2

        @emlMean: .v1#
        .mean1 = emlMean.result
        @emlSD: .v1#
        .sd1 = emlSD.result
        @emlMedian: .v1#
        .med1 = emlMedian.result

        @emlMean: .v2#
        .mean2 = emlMean.result
        @emlSD: .v2#
        .sd2 = emlSD.result
        @emlMedian: .v2#
        .med2 = emlMedian.result

        @emlReportTwoGroupComparison: .tableName$, .dataCol$, .groupCol$,
        ... .g1$, .g2$,
        ... .n1, .mean1, .sd1, .med1,
        ... .n2, .mean2, .sd2, .med2, .testType$

    elsif .testType$ = "parametric"
        # k-group parametric: ANOVA (bridge ran with doTukey=1)
        @emlReportAnovaComparison: .tableName$, .dataCol$, .groupCol$,
        ... .tableId, .nGroups, 1

    else
        # k-group nonparametric: Kruskal-Wallis
        # Bridge runs Dunn's only when p < alpha
        if emlKruskalWallis.p < emlBridgeGroupComparison.alpha
            .doDunn = 1
        else
            .doDunn = 0
        endif
        @emlReportKWComparison: .tableName$, .dataCol$, .groupCol$,
        ... .nGroups, .doDunn
    endif
endproc


# ============================================================================
# SHARED REPORTERS
# ============================================================================
# These procedures produce identical Info window output regardless of
# whether the user started from a stats wrapper or the graphs tool.
# They read from test result globals — callers must run the relevant
# test procedures BEFORE calling these reporters.
#
# Each reporter also populates CSV rows via @emlCSVAddRow (from
# eml-output.praat) so @emlExportStatsCSV can write results to file.
# ============================================================================


# ============================================================================
# @emlReportTwoGroupComparison
# ============================================================================
procedure emlReportTwoGroupComparison: .tableName$, .dataCol$, .groupCol$, .group1$, .group2$, .n1, .mean1, .sd1, .median1, .n2, .mean2, .sd2, .median2, .testType$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .group1$
    .displayG1$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .group2$
    .displayG2$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Two-Group Comparison"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Group column", .displayGroup$
    @emlReportBlank
    @emlReportDescriptiveHeader
    @emlReportDescriptiveRow: .displayG1$, .n1, .mean1, .sd1, .median1
    @emlReportDescriptiveRow: .displayG2$, .n2, .mean2, .sd2, .median2

    if .testType$ = "parametric" or .testType$ = "both"
        @emlFormatP: emlTTest.p
        @emlFormatEffectLabel: emlCohenD.d, "d"
        @emlReportBlank
        @emlReportSection: emlTTest.method$
        if emlTTest.method$ = "Welch"
            appendInfoLine: "  Why: Compares means of two independent "
            ... + "groups (robust to unequal variances)."
        else
            appendInfoLine: "  Why: Compares means of two independent "
            ... + "groups (assumes equal variances)."
        endif
        @emlReportLine: "t", emlTTest.t, 3
        @emlReportLine: "df", emlTTest.df, 1
        @emlReportLineString: "p", emlFormatP.formatted$
        @emlReportLine: "Mean difference", emlTTest.meanDiff, 4
        @emlReportBlank
        @emlReportSection: "Effect Size"
        @emlReportLine: "Cohen's d", emlCohenD.d, 3
        @emlReportLine: "Hedges' g", emlCohenD.g, 3
        @emlReportLineString: "Magnitude", emlFormatEffectLabel.label$
        @emlCSVAddRow: .tableName$, .dataCol$, .groupCol$,
        ... .group1$, .group2$, emlTTest.method$,
        ... emlTTest.t, emlTTest.df, emlTTest.p,
        ... emlCohenD.d, "Cohen's d", emlFormatEffectLabel.label$,
        ... .n1, .n2, .mean1, .sd1, .median1,
        ... .mean2, .sd2, .median2
    endif

    if .testType$ = "nonparametric" or .testType$ = "both"
        @emlFormatP: emlMannWhitneyU.p
        @emlFormatEffectLabel: abs (emlRankBiserialR.r), "r"
        @emlReportBlank
        @emlReportSection: "Mann-Whitney U Test"
        appendInfoLine: "  Why: Compares distributions of two "
        ... + "independent groups without assuming normality."
        @emlReportLine: "U1", emlMannWhitneyU.u1, 1
        @emlReportLine: "U2", emlMannWhitneyU.u2, 1
        if emlMannWhitneyU.z <> undefined
            @emlReportLine: "z", emlMannWhitneyU.z, 3
        endif
        @emlReportLineString: "p", emlFormatP.formatted$
        @emlReportLineString: "Method", emlMannWhitneyU.method$
        @emlReportBlank
        @emlReportSection: "Nonparametric Effect Size"
        @emlReportLine: "Rank-biserial r", emlRankBiserialR.r, 3
        @emlReportLineString: "Magnitude", emlFormatEffectLabel.label$
        if emlMannWhitneyU.z <> undefined
            .mwuDf = emlMannWhitneyU.z
        else
            .mwuDf = 0
        endif
        @emlCSVAddRow: .tableName$, .dataCol$, .groupCol$,
        ... .group1$, .group2$, "Mann-Whitney U",
        ... emlMannWhitneyU.u1, .mwuDf, emlMannWhitneyU.p,
        ... emlRankBiserialR.r, "rank-biserial r",
        ... emlFormatEffectLabel.label$,
        ... .n1, .n2, .mean1, .sd1, .median1,
        ... .mean2, .sd2, .median2
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportAnovaComparison
# ============================================================================
procedure emlReportAnovaComparison: .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doTukey
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "One-Way ANOVA"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Group column", .displayGroup$
    @emlReportLine: "Groups", .nGroups, 0

    # ANOVA table
    @emlReportBlank
    @emlReportSection: "ANOVA Table"
    appendInfoLine: "  Why: Tests whether group means differ "
    ... + "when normality and equal variances hold."
    appendInfoLine: ""
    appendInfoLine: left$ ("Source" + "                ", 14),
    ... left$ ("SS" + "            ", 12),
    ... left$ ("df" + "      ", 6),
    ... left$ ("MS" + "            ", 12),
    ... left$ ("F" + "          ", 10),
    ... "p"
    appendInfoLine: left$ ("Between" + "                ", 14),
    ... left$ (fixed$ (emlOneWayAnova.ssBetween, 4) + "            ", 12),
    ... left$ (string$ (emlOneWayAnova.dfBetween) + "      ", 6),
    ... left$ (fixed$ (emlOneWayAnova.msBetween, 4) + "            ", 12),
    ... left$ (fixed$ (emlOneWayAnova.fValue, 4) + "          ", 10),
    ... fixed$ (emlOneWayAnova.p, 6)
    appendInfoLine: left$ ("Within" + "                ", 14),
    ... left$ (fixed$ (emlOneWayAnova.ssWithin, 4) + "            ", 12),
    ... left$ (string$ (emlOneWayAnova.dfWithin) + "      ", 6),
    ... left$ (fixed$ (emlOneWayAnova.msWithin, 4) + "            ", 12)
    appendInfoLine: left$ ("Total" + "                ", 14),
    ... left$ (fixed$ (emlOneWayAnova.ssTotal, 4) + "            ", 12),
    ... left$ (string$ (emlOneWayAnova.dfTotal) + "      ", 6)

    @emlReportBlank
    @emlFormatP: emlOneWayAnova.p
    @emlReportLineString: "F", fixed$ (emlOneWayAnova.fValue, 4)
    @emlReportLineString: "p", emlFormatP.formatted$
    .etaSq = emlOneWayAnova.etaSquared
    @emlReportLineString: "Effect size", "eta-squared = " + fixed$ (.etaSq, 4)

    @emlCSVAddRow: .tableName$, .dataCol$, .groupCol$,
    ... "omnibus", "omnibus", "One-way ANOVA",
    ... emlOneWayAnova.fValue, emlOneWayAnova.dfBetween, emlOneWayAnova.p,
    ... .etaSq, "eta-squared", "",
    ... 0, 0, 0, 0, 0, 0, 0, 0

    # Group descriptives
    @emlReportBlank
    @emlReportSection: "Group Descriptives"
    @emlReportDescriptiveHeader
    for .iGroup from 1 to .nGroups
        .gName$ = replace$ (emlExtractMultipleGroups.groupLabel$ [.iGroup], "_", " ", 0)
        @eml_getGroupData: .iGroup
        .gN = eml_getGroupData.n
        .gData# = eml_getGroupData.data#
        @emlMean: .gData#
        .gMean = emlMean.result
        @emlSD: .gData#
        .gSD = emlSD.result
        @emlMedian: .gData#
        .gMedian = emlMedian.result
        @emlReportDescriptiveRow: .gName$, .gN, .gMean, .gSD, .gMedian
    endfor

    # Tukey pairwise
    if .doTukey
        @emlReportBlank
        @emlReportSection: "Tukey HSD Pairwise Comparisons (p-values)"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlOneWayAnova.groupName$ [.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
        endfor
        appendInfoLine: .headerLine$
        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlOneWayAnova.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlOneWayAnova.pMatrix## [.iGroup, .jGroup]
                    if .pVal < 0.001
                        .cellText$ = "< .001"
                    else
                        .cellText$ = fixed$ (.pVal, 4)
                    endif
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

        # Pairwise Cohen's d
        @emlReportBlank
        @emlReportSection: "Pairwise Effect Sizes (Cohen's d)"
        appendInfoLine: ""
        .dHeaderLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlOneWayAnova.groupName$ [.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .dHeaderLine$ = .dHeaderLine$ + left$ (.colName$ + "            ", 12)
        endfor
        appendInfoLine: .dHeaderLine$
        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlOneWayAnova.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .dRowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    @eml_getGroupData: emlTukeyHSD.sortMap[.iGroup]
                    .v1# = eml_getGroupData.data#
                    @eml_getGroupData: emlTukeyHSD.sortMap[.jGroup]
                    @emlCohenD: .v1#, eml_getGroupData.data#
                    if emlCohenD.error$ = ""
                        .cellText$ = fixed$ (emlCohenD.d, 3)
                    else
                        .cellText$ = "err"
                    endif
                endif
                .dRowLine$ = .dRowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .dRowLine$
        endfor

        # CSV rows for pairwise
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .pVal = emlOneWayAnova.pMatrix## [.iGroup, .jGroup]
                .g1Label$ = emlOneWayAnova.groupName$ [.iGroup]
                .g2Label$ = emlOneWayAnova.groupName$ [.jGroup]
                @eml_getGroupData: emlTukeyHSD.sortMap[.iGroup]
                .v1# = eml_getGroupData.data#
                .n1 = eml_getGroupData.n
                @eml_getGroupData: emlTukeyHSD.sortMap[.jGroup]
                .v2# = eml_getGroupData.data#
                .n2 = eml_getGroupData.n
                .pairD = 0
                @emlCohenD: .v1#, .v2#
                if emlCohenD.error$ = ""
                    .pairD = emlCohenD.d
                endif
                @emlMean: .v1#
                .m1 = emlMean.result
                @emlSD: .v1#
                .s1 = emlSD.result
                @emlMedian: .v1#
                .md1 = emlMedian.result
                @emlMean: .v2#
                .m2 = emlMean.result
                @emlSD: .v2#
                .s2 = emlSD.result
                @emlMedian: .v2#
                .md2 = emlMedian.result
                @emlCSVAddRow: .tableName$, .dataCol$, .groupCol$,
                ... .g1Label$, .g2Label$, "Tukey HSD",
                ... 0, 0, .pVal, .pairD, "Cohen's d", "",
                ... .n1, .n2,
                ... .m1, .s1, .md1, .m2, .s2, .md2
            endfor
        endfor
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportKWComparison
# ============================================================================
procedure emlReportKWComparison: .tableName$, .dataCol$, .groupCol$, .nGroups, .doDunn
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Kruskal-Wallis H Test"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Group column", .displayGroup$
    @emlReportLine: "Groups", .nGroups, 0
    @emlReportLine: "Total N", emlKruskalWallis.n, 0

    @emlReportBlank
    @emlReportSection: "Omnibus Test"
    appendInfoLine: "  Why: Nonparametric comparison of three or "
    ... + "more groups — no normality assumption needed."
    @emlReportLine: "H", emlKruskalWallis.h, 4
    @emlReportLine: "df", emlKruskalWallis.df, 0
    @emlFormatP: emlKruskalWallis.p
    @emlReportLineString: "p", emlFormatP.formatted$
    @emlReportLine: "Epsilon-squared", emlKruskalWallis.epsilonSq, 4
    @emlFormatEffectLabel: emlKruskalWallis.epsilonSq, "eta_squared"
    @emlReportLineString: "Effect magnitude", emlFormatEffectLabel.label$

    @emlCSVAddRow: .tableName$, .dataCol$, .groupCol$,
    ... "omnibus", "omnibus", "Kruskal-Wallis",
    ... emlKruskalWallis.h, emlKruskalWallis.df, emlKruskalWallis.p,
    ... emlKruskalWallis.epsilonSq, "epsilon-squared",
    ... emlFormatEffectLabel.label$,
    ... 0, 0, 0, 0, 0, 0, 0, 0

    # Group mean ranks
    @emlReportBlank
    @emlReportSection: "Group Mean Ranks"
    appendInfoLine: ""
    .grpHeader$ = left$ ("Group" + "                ", 14)
    ... + left$ ("N" + "      ", 6) + "Mean Rank"
    appendInfoLine: .grpHeader$
    for .iGroup from 1 to .nGroups
        .gName$ = replace$ (emlKruskalWallis.groupName$ [.iGroup], "_", " ", 0)
        if length (.gName$) > 12
            .gName$ = left$ (.gName$, 12)
        endif
        appendInfoLine: left$ (.gName$ + "                ", 14),
        ... left$ (string$ (emlKruskalWallis.groupN [.iGroup]) + "      ", 6),
        ... fixed$ (emlKruskalWallis.meanRank [.iGroup], 2)
    endfor

    if .doDunn
        if emlDunnTest.error$ = ""
            .adjLabel$ = emlDunnTest.method$
            @emlReportBlank
            @emlReportSection: "Dunn's Post-Hoc (adjusted p, " + .adjLabel$ + ")"
            appendInfoLine: ""
            .headerLine$ = left$ ("" + "                ", 14)
            for .jGroup from 1 to .nGroups
                .colName$ = replace$ (emlDunnTest.groupName$ [.jGroup], "_", " ", 0)
                if length (.colName$) > 10
                    .colName$ = left$ (.colName$, 10)
                endif
                .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
            endfor
            appendInfoLine: .headerLine$
            for .iGroup from 1 to .nGroups
                .rowName$ = replace$ (emlDunnTest.groupName$ [.iGroup], "_", " ", 0)
                if length (.rowName$) > 12
                    .rowName$ = left$ (.rowName$, 12)
                endif
                .rowLine$ = left$ (.rowName$ + "                ", 14)
                for .jGroup from 1 to .nGroups
                    if .iGroup = .jGroup
                        .cellText$ = "---"
                    else
                        .pVal = emlDunnTest.pMatrix## [.iGroup, .jGroup]
                        if .pVal < 0.001
                            .cellText$ = "< .001"
                        else
                            .cellText$ = fixed$ (.pVal, 4)
                        endif
                    endif
                    .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
                endfor
                appendInfoLine: .rowLine$
            endfor

            @emlReportBlank
            @emlReportSection: "Dunn's z-statistics"
            appendInfoLine: ""
            appendInfoLine: .headerLine$
            for .iGroup from 1 to .nGroups
                .rowName$ = replace$ (emlDunnTest.groupName$ [.iGroup], "_", " ", 0)
                if length (.rowName$) > 12
                    .rowName$ = left$ (.rowName$, 12)
                endif
                .rowLine$ = left$ (.rowName$ + "                ", 14)
                for .jGroup from 1 to .nGroups
                    if .iGroup = .jGroup
                        .cellText$ = "---"
                    else
                        .zVal = emlDunnTest.zMatrix## [.iGroup, .jGroup]
                        .cellText$ = fixed$ (.zVal, 3)
                    endif
                    .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
                endfor
                appendInfoLine: .rowLine$
            endfor

            # CSV rows
            for .iGroup from 1 to .nGroups - 1
                for .jGroup from .iGroup + 1 to .nGroups
                    .pVal = emlDunnTest.pMatrix## [.iGroup, .jGroup]
                    .zVal = emlDunnTest.zMatrix## [.iGroup, .jGroup]
                    @emlCSVAddRow: .tableName$, .dataCol$, .groupCol$,
                    ... emlDunnTest.groupName$ [.iGroup],
                    ... emlDunnTest.groupName$ [.jGroup],
                    ... "Dunn (" + .adjLabel$ + ")",
                    ... .zVal, 0, .pVal,
                    ... 0, "", "",
                    ... 0, 0, 0, 0, 0, 0, 0, 0
                endfor
            endfor
        else
            appendInfoLine: newline$ + "Dunn's test error: " + emlDunnTest.error$
        endif
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportCorrelationAnalysis
# ============================================================================
procedure emlReportCorrelationAnalysis: .tableName$, .colX$, .colY$, .n, .testType$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .colX$
    .displayX$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .colY$
    .displayY$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Correlation Analysis"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column X", .displayX$
    @emlReportLineString: "Column Y", .displayY$
    @emlReportLine: "N", .n, 0

    if .testType$ = "pearson" or .testType$ = "both"
        if emlPearsonCorrelation.error$ = ""
            @emlFormatP: emlPearsonCorrelation.p
            @emlReportBlank
            @emlReportSection: "Pearson Correlation"
            appendInfoLine: "  Why: Measures linear association between "
            ... + "two continuous variables."
            @emlReportLine: "r", emlPearsonCorrelation.r, 4
            @emlReportLine: "t", emlPearsonCorrelation.t, 3
            @emlReportLine: "df", emlPearsonCorrelation.df, 0
            @emlReportLineString: "p", emlFormatP.formatted$
            @emlCSVAddRow: .tableName$, .colX$, .colY$,
            ... "", "", "Pearson",
            ... emlPearsonCorrelation.r, emlPearsonCorrelation.df,
            ... emlPearsonCorrelation.p,
            ... emlPearsonCorrelation.r, "r", "",
            ... .n, .n, 0, 0, 0, 0, 0, 0
        else
            appendInfoLine: newline$ + "Pearson error: " + emlPearsonCorrelation.error$
        endif
    endif

    if .testType$ = "spearman" or .testType$ = "both"
        if emlSpearmanCorrelation.error$ = ""
            @emlFormatP: emlSpearmanCorrelation.p
            @emlReportBlank
            @emlReportSection: "Spearman Correlation"
            appendInfoLine: "  Why: Measures monotonic association — "
            ... + "no normality assumption needed."
            @emlReportLine: "rho", emlSpearmanCorrelation.rho, 4
            @emlReportLine: "t", emlSpearmanCorrelation.t, 3
            @emlReportLine: "df", emlSpearmanCorrelation.df, 0
            @emlReportLineString: "p", emlFormatP.formatted$
            @emlCSVAddRow: .tableName$, .colX$, .colY$,
            ... "", "", "Spearman",
            ... emlSpearmanCorrelation.rho, emlSpearmanCorrelation.df,
            ... emlSpearmanCorrelation.p,
            ... emlSpearmanCorrelation.rho, "rho", "",
            ... .n, .n, 0, 0, 0, 0, 0, 0
        endif
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportPairedComparison
# ============================================================================
procedure emlReportPairedComparison: .tableName$, .col1$, .col2$, .n,
... .mean1, .sd1, .median1, .mean2, .sd2, .median2, .testType$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .col1$
    .displayC1$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .col2$
    .displayC2$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Paired Comparison"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column 1", .displayC1$
    @emlReportLineString: "Column 2", .displayC2$
    @emlReportLine: "N (pairs)", .n, 0
    @emlReportBlank

    appendInfoLine: "  ", .displayC1$, ": Mean = ", fixed$ (.mean1, 3),
    ... ", SD = ", fixed$ (.sd1, 3),
    ... ", Median = ", fixed$ (.median1, 3)
    appendInfoLine: "  ", .displayC2$, ": Mean = ", fixed$ (.mean2, 3),
    ... ", SD = ", fixed$ (.sd2, 3),
    ... ", Median = ", fixed$ (.median2, 3)

    if .testType$ = "parametric" or .testType$ = "both"
        if emlTTestPaired.error$ = ""
            @emlFormatP: emlTTestPaired.p
            @emlReportBlank
            @emlReportSection: "Paired t-test"
            appendInfoLine: "  Why: Tests whether the mean difference "
            ... + "between paired observations differs from zero."
            @emlReportLine: "t", emlTTestPaired.t, 3
            @emlReportLine: "df", emlTTestPaired.df, 0
            @emlReportLineString: "p", emlFormatP.formatted$
            @emlReportLine: "Mean difference", emlTTestPaired.meanDiff, 4
            @emlReportLine: "SD of differences", emlTTestPaired.sdDiff, 4

            if emlMatchedPairsR.error$ = ""
                @emlFormatEffectLabel: abs (emlMatchedPairsR.r), "r"
                @emlReportBlank
                @emlReportSection: "Effect Size"
                @emlReportLine: "Matched-pairs r", emlMatchedPairsR.r, 3
                @emlReportLineString: "Magnitude", emlFormatEffectLabel.label$
            endif

            @emlCSVAddRow: .tableName$, .col1$, .col2$,
            ... .col1$, .col2$, "Paired t-test",
            ... emlTTestPaired.t, emlTTestPaired.df, emlTTestPaired.p,
            ... emlMatchedPairsR.r, "matched-pairs r", "",
            ... .n, .n, .mean1, .sd1, .median1,
            ... .mean2, .sd2, .median2
        else
            appendInfoLine: newline$ + "Paired t-test error: "
            ... + emlTTestPaired.error$
        endif
    endif

    if .testType$ = "nonparametric" or .testType$ = "both"
        if emlWilcoxonSignedRank.error$ = ""
            @emlFormatP: emlWilcoxonSignedRank.p
            @emlReportBlank
            @emlReportSection: "Wilcoxon Signed-Rank Test"
            appendInfoLine: "  Why: Nonparametric test for paired "
            ... + "observations — no normality assumption needed."
            @emlReportLine: "T+", emlWilcoxonSignedRank.tPlus, 1
            @emlReportLine: "T-", emlWilcoxonSignedRank.tMinus, 1
            if emlWilcoxonSignedRank.z <> undefined
                @emlReportLine: "z", emlWilcoxonSignedRank.z, 3
            endif
            @emlReportLineString: "p", emlFormatP.formatted$

            if emlMatchedPairsR.error$ = ""
                @emlFormatEffectLabel: abs (emlMatchedPairsR.r), "r"
                @emlReportBlank
                @emlReportSection: "Nonparametric Effect Size"
                @emlReportLine: "Matched-pairs r", emlMatchedPairsR.r, 3
                @emlReportLineString: "Magnitude", emlFormatEffectLabel.label$
            endif

            if emlWilcoxonSignedRank.z <> undefined
                .wsrDf = emlWilcoxonSignedRank.z
            else
                .wsrDf = 0
            endif
            @emlCSVAddRow: .tableName$, .col1$, .col2$,
            ... .col1$, .col2$, "Wilcoxon signed-rank",
            ... emlWilcoxonSignedRank.tPlus, .wsrDf,
            ... emlWilcoxonSignedRank.p,
            ... emlMatchedPairsR.r, "matched-pairs r", "",
            ... .n, .n, .mean1, .sd1, .median1,
            ... .mean2, .sd2, .median2
        else
            appendInfoLine: newline$ + "Wilcoxon error: "
            ... + emlWilcoxonSignedRank.error$
        endif
    endif

    @emlReportFooter
endproc


# ============================================================================
# @emlReportTwoWayAnova
# ============================================================================
procedure emlReportTwoWayAnova: .tableName$, .dataCol$, .factor1$, .factor2$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .factor1$
    .displayF1$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .factor2$
    .displayF2$ = emlUnderscoreToSpace.result$

    @emlReportHeader: "Two-Way ANOVA"
    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Data column", .displayData$
    @emlReportLineString: "Factor 1", .displayF1$
    @emlReportLineString: "Factor 2", .displayF2$

    @emlReportBlank
    @emlReportSection: "ANOVA Table"
    appendInfoLine: "  Why: Tests main effects of two factors "
    ... + "and their interaction."
    appendInfoLine: ""
    appendInfoLine: left$ ("Source" + "                    ", 20),
    ... left$ ("SS" + "            ", 12),
    ... left$ ("df" + "      ", 6),
    ... left$ ("MS" + "            ", 12),
    ... left$ ("F" + "          ", 10),
    ... "p"

    @emlFormatP: emlTwoWayAnova.pA
    appendInfoLine: left$ (.displayF1$ + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssA, 4) + "            ", 12),
    ... left$ (string$ (emlTwoWayAnova.dfA) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msA, 4) + "            ", 12),
    ... left$ (fixed$ (emlTwoWayAnova.fA, 4) + "          ", 10),
    ... emlFormatP.formatted$

    @emlFormatP: emlTwoWayAnova.pB
    appendInfoLine: left$ (.displayF2$ + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssB, 4) + "            ", 12),
    ... left$ (string$ (emlTwoWayAnova.dfB) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msB, 4) + "            ", 12),
    ... left$ (fixed$ (emlTwoWayAnova.fB, 4) + "          ", 10),
    ... emlFormatP.formatted$

    @emlFormatP: emlTwoWayAnova.pAB
    .interLabel$ = .displayF1$ + " x " + .displayF2$
    .rawInterLabel$ = .factor1$ + "_x_" + .factor2$
    appendInfoLine: left$ (.interLabel$ + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssAB, 4) + "            ", 12),
    ... left$ (string$ (emlTwoWayAnova.dfAB) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msAB, 4) + "            ", 12),
    ... left$ (fixed$ (emlTwoWayAnova.fAB, 4) + "          ", 10),
    ... emlFormatP.formatted$

    appendInfoLine: left$ ("Error" + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssError, 4) + "            ", 12),
    ... left$ (string$ (emlTwoWayAnova.dfError) + "      ", 6),
    ... left$ (fixed$ (emlTwoWayAnova.msError, 4) + "            ", 12)

    appendInfoLine: left$ ("Total" + "                    ", 20),
    ... left$ (fixed$ (emlTwoWayAnova.ssTotal, 4) + "            ", 12),
    ... left$ (string$ (emlTwoWayAnova.dfTotal) + "      ", 6)

    # Effect sizes
    @emlReportBlank
    @emlReportSection: "Effect Sizes (partial eta-squared)"
    @emlReportLine: .displayF1$, emlTwoWayAnova.partialEtaSqA, 4
    @emlReportLine: .displayF2$, emlTwoWayAnova.partialEtaSqB, 4
    @emlReportLine: .interLabel$, emlTwoWayAnova.partialEtaSqAB, 4

    # CSV rows — one per effect
    @emlFormatP: emlTwoWayAnova.pA
    @emlCSVAddRow: .tableName$, .dataCol$, .factor1$,
    ... "main effect", .factor1$, "Two-way ANOVA",
    ... emlTwoWayAnova.fA, emlTwoWayAnova.dfA, emlTwoWayAnova.pA,
    ... emlTwoWayAnova.partialEtaSqA, "partial eta-squared", "",
    ... 0, 0, 0, 0, 0, 0, 0, 0

    @emlCSVAddRow: .tableName$, .dataCol$, .factor2$,
    ... "main effect", .factor2$, "Two-way ANOVA",
    ... emlTwoWayAnova.fB, emlTwoWayAnova.dfB, emlTwoWayAnova.pB,
    ... emlTwoWayAnova.partialEtaSqB, "partial eta-squared", "",
    ... 0, 0, 0, 0, 0, 0, 0, 0

    @emlCSVAddRow: .tableName$, .dataCol$, .rawInterLabel$,
    ... "interaction", .rawInterLabel$, "Two-way ANOVA",
    ... emlTwoWayAnova.fAB, emlTwoWayAnova.dfAB, emlTwoWayAnova.pAB,
    ... emlTwoWayAnova.partialEtaSqAB, "partial eta-squared", "",
    ... 0, 0, 0, 0, 0, 0, 0, 0

    @emlReportFooter
endproc


# ============================================================================
# END OF EML ANNOTATION PROCEDURES
# ============================================================================
