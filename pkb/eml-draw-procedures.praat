# ============================================================================
# EML GRAPHS — DRAWING PROCEDURES
# ============================================================================
# Author: Ian Howell, Embodied Music Lab, www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Version: 1.12
# Date: 4 April 2026
#
# v1.12: @emlDrawTimeSeriesCI: CI critical value changed from hardcoded
#         1.96 (normal approximation) to invStudentQ(annotAlpha/2, n-1)
#         for correct t-distribution intervals at any sample size and
#         confidence level. Reads global annotAlpha (default 0.05 = 95%
#         CI). At n=5 and α=0.05, gives t=2.776 vs the old z=1.96.
# v1.11: Faceted histogram group labels moved from right margin to left
#         margin (Text left:, rotated 90°). Truncation with binary search
#         when label physical width exceeds 85% of panel height. Right
#         margin reverted to standard (no longer widened for labels).
# v1.10: @emlDrawBarChart refactored to pure renderer — all data extraction
#         (unique groups, aggregation, SE/SD/custom error computation) removed.
#         Now reads pre-computed emlBarData_* globals from @emlMeasureBarData
#         (eml-graph-procedures.praat). Signature unchanged for dispatch
#         uniformity.
# v1.9: @emlDrawBarChart signature change — .errorCol$ replaced by
#         .errorMode (0=none, 1=SE, 2=SD, 3=custom) + .errorCol$ (for
#         custom only). SE and SD computed internally from value column
#         per group using single-pass variance (sum of squares). Error
#         bar drawing condition uses .errorMode > 0 instead of .hasError.
# v1.8: Per-axis visibility — all 8 direct axis label draws (Text left/
#        Text bottom) gated by emlShowAxisNameY/emlShowAxisNameX globals.
#        Axis label sanitization removed from all 6 draw procedures —
#        auto-generated labels sanitized at source (@emlCapitalizeLabel),
#        user-typed labels pass through raw to support Praat formatting
#        codes. Title sanitization preserved. Group label sanitization
#        preserved. Scatter alpha sprites always on when available —
#        removed group-column condition gate so ungrouped scatters show
#        density transparency.
# v1.6: Faceted histogram x-axis ticks — replaced Marks bottom: with
#        @emlDrawAlignedMarksBottom for nice-number alignment consistent
#        with gridlines and all other axis tick drawing.
# v1.5: All 12 hardcoded "Helvetica" in Text special: calls replaced
#        with emlFont$ global variable (set by main script font dropdown).
# v1.4: Debug lines removed. All 7 legend callers updated to
#        @emlPlaceElements (adaptive corner selection). Font state
#        fixes: bodySize before all Select inner viewport calls.
#        Faceted histogram restructured: symmetric right margin,
#        gridlines inside branch, group labels outside box.
# v1.3: All Draw inner box calls replaced with @emlDrawInnerBoxIf (font
#        state assertion + boolean toggle). Gridline dispatch updated:
#        continuous types now 4-way (Both/Horizontal/Vertical/Off),
#        categorical types now 2-way (Horizontal/Off).
#
# v1.1: All 6 categorical label sections now use @emlFitCategoricalLabels
#        for space-aware rotation + truncation. Faceted histogram uses
#        per-facet tick count from panel height instead of full canvas.
# v1.0: Extracted from eml-graphs.praat v2.28 to enable shared use by
#        both the graph UI (eml-graphs.praat) and stats wrapper scripts.
#        Contains all 14 drawing procedures. No standalone executable code.
#
# Dependencies:
#   eml-graph-procedures.praat   — theme, palette, axes, violin/box primitives
#   eml-annotation-procedures.praat — bridge, annotation rendering
#   eml-core-utilities.praat     — table utilities
#   eml-core-descriptive.praat   — descriptive stats
#   eml-extract.praat            — group extraction
#   eml-inferential.praat        — statistical tests
#
# Procedures:
#   @emlDrawF0Contour       — F0 contour from Pitch object
#   @emlDrawWaveform        — waveform from Sound object
#   @emlDrawSpectrum        — spectrum from Spectrum object
#   @emlDrawLTAS            — long-term average spectrum
#   @emlDrawTimeSeries      — time series (modes A + D)
#   @emlDrawTimeSeriesCI    — time series with confidence interval
#   @emlDrawSpaghettiPlot   — individual subject traces (categorical x)
#   @emlDrawBarChart        — grouped bar chart with error bars
#   @emlDrawViolinPlot      — violin plot
#   @emlDrawScatterPlot     — scatter plot with regression
#   @emlDrawBoxPlot         — box plot (Tukey whiskers)
#   @emlDrawHistogram       — histogram (overlap or faceted)
#   @emlDrawGroupedViolin   — two-factor violin (category × sub-group)
#   @emlDrawGroupedBoxPlot  — two-factor box plot
# ============================================================================

# ============================================================================
# DRAWING PROCEDURES
# ============================================================================
# Real implementations for all 7 graph types. Each procedure's signature
# matches the dispatch calls in the MAIN EXECUTION section below.
# ============================================================================

# ----------------------------------------------------------------------------
# @emlDrawF0Contour
# Draws a publication-quality F0 contour from a Pitch object.
# Source: v1.0 (17 Feb 2026), adapted for plugin dispatch signature.
# v1.1: Y-axis unit option (Hz or semitones re 440 Hz). Unit-branched
#        queries, auto-range, and draw command.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawF0Contour: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .fMin, .fMax, .yUnit

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Determine unit string for queries
    if .yUnit = 2
        .unitStr$ = "semitones re 440 Hz"
    else
        .unitStr$ = "Hertz"
    endif

    # Step 2: Compute time range (both 0 = auto)
    selectObject: .objectId
    .startTime = Get start time
    .endTime = Get end time
    if .tMin = 0 and .tMax = 0
        .timeMin = .startTime
        .timeMax = .endTime
    else
        .timeMin = .tMin
        .timeMax = .tMax
        # Clamp to object domain
        if .timeMin >= .endTime or .timeMax <= .startTime
            appendInfoLine: "WARNING: Time range (",
            ... fixed$ (.timeMin, 3), " – ", fixed$ (.timeMax, 3),
            ... " s) outside Pitch domain (",
            ... fixed$ (.startTime, 3), " – ", fixed$ (.endTime, 3),
            ... " s). Using full domain."
            .timeMin = .startTime
            .timeMax = .endTime
        else
            if .timeMin < .startTime
                .timeMin = .startTime
            endif
            if .timeMax > .endTime
                .timeMax = .endTime
            endif
        endif
    endif

    # Step 3: Compute frequency/semitone range (both 0 = auto)
    selectObject: .objectId
    .pitchMin = Get minimum: 0, 0, .unitStr$, "parabolic"
    .pitchMax = Get maximum: 0, 0, .unitStr$, "parabolic"

    if .pitchMin = undefined or .pitchMax = undefined
        if .yUnit = 2
            .autoFreqMin = -36
            .autoFreqMax = 6
        else
            .autoFreqMin = 75
            .autoFreqMax = 500
        endif
    else
        @emlComputeAxisRange: .pitchMin, .pitchMax, 10, 0
        .autoFreqMin = emlComputeAxisRange.axisMin
        .autoFreqMax = emlComputeAxisRange.axisMax
        # Enforce minimum visible span
        if .yUnit = 2
            # Semitones: minimum 12 st span
            if .autoFreqMax - .autoFreqMin < 12
                .midVal = (.pitchMin + .pitchMax) / 2
                @emlComputeAxisRange: .midVal - 6, .midVal + 6, 10, 0
                .autoFreqMin = emlComputeAxisRange.axisMin
                .autoFreqMax = emlComputeAxisRange.axisMax
            endif
        else
            # Hertz: minimum 50 Hz span
            if .autoFreqMax - .autoFreqMin < 50
                .midF0 = (.pitchMin + .pitchMax) / 2
                @emlComputeAxisRange: .midF0 - 25, .midF0 + 25, 10, 0
                .autoFreqMin = emlComputeAxisRange.axisMin
                .autoFreqMax = emlComputeAxisRange.axisMax
            endif
        endif
    endif

    if .fMin = 0 and .fMax = 0
        .freqMin = .autoFreqMin
        .freqMax = .autoFreqMax
    else
        .freqMin = .fMin
        .freqMax = .fMax
    endif

    # Step 4: Set viewport and axes
    @emlSetPanelViewport
    Axes: .timeMin, .timeMax, .freqMin, .freqMax

    # Step 5: Draw gridlines (if requested)
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .timeMin, .timeMax, .freqMin, .freqMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .timeMin, .timeMax, .freqMin, .freqMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .timeMin, .timeMax, .freqMin, .freqMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 6: Draw the F0 contour
    selectObject: .objectId
    Colour: emlSetColorPalette.line$[1]
    Line width: emlSetAdaptiveTheme.dataLineWidth
    if .yUnit = 2
        Draw semitones (re 440 Hz): .timeMin, .timeMax, .freqMin, .freqMax, "no"
    else
        Draw: .timeMin, .timeMax, .freqMin, .freqMax, "no"
    endif

    # Step 7: Draw axes on top
    @emlDrawAxes: .timeMin, .timeMax, .freqMin, .freqMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Step 8: Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawWaveform
# Draws a publication-quality waveform from a Sound object.
# Uses stepped symmetric amplitude bounds and zero-line reference.
# Source: task spec (17 Feb 2026), adapted for plugin dispatch signature.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawWaveform: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .aMin, .aMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Step 2: Compute time range (both 0 = auto)
    selectObject: .objectId
    .startTime = Get start time
    .endTime = Get end time
    if .tMin = 0 and .tMax = 0
        .timeMin = .startTime
        .timeMax = .endTime
    else
        .timeMin = .tMin
        .timeMax = .tMax
        # Clamp to object domain
        if .timeMin >= .endTime or .timeMax <= .startTime
            appendInfoLine: "WARNING: Time range (",
            ... fixed$ (.timeMin, 3), " – ", fixed$ (.timeMax, 3),
            ... " s) outside Sound domain (",
            ... fixed$ (.startTime, 3), " – ", fixed$ (.endTime, 3),
            ... " s). Using full domain."
            .timeMin = .startTime
            .timeMax = .endTime
        else
            if .timeMin < .startTime
                .timeMin = .startTime
            endif
            if .timeMax > .endTime
                .timeMax = .endTime
            endif
        endif
    endif

    # Step 3: Compute amplitude range
    selectObject: .objectId
    .maxAmp = Get maximum: .timeMin, .timeMax, "Sinc70"
    .minAmp = Get minimum: .timeMin, .timeMax, "Sinc70"

    if .aMin = 0 and .aMax = 0
        # Auto: symmetric range with buffer via emlComputeAxisRange
        .absMax = max (abs (.maxAmp), abs (.minAmp))
        @emlComputeAxisRange: 0, .absMax, 0.05, 0
        .ampBound = emlComputeAxisRange.axisMax
        .ampTop = .ampBound
        .ampBottom = -.ampBound
    else
        # Custom: user values taken literally
        .ampBottom = .aMin
        .ampTop = .aMax
    endif

    # Step 4: Set viewport and axes
    @emlSetPanelViewport
    Axes: .timeMin, .timeMax, .ampBottom, .ampTop

    # Step 5: Draw gridlines (if requested)
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .timeMin, .timeMax, .ampBottom, .ampTop, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .timeMin, .timeMax, .ampBottom, .ampTop, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .timeMin, .timeMax, .ampBottom, .ampTop, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 6: Draw zero line (faint reference)
    Colour: "{0.85, 0.85, 0.85}"
    Line width: 0.5
    Draw line: .timeMin, 0, .timeMax, 0

    # Step 7: Draw the waveform
    selectObject: .objectId
    Colour: emlSetColorPalette.line$[1]
    Line width: emlSetAdaptiveTheme.dataLineWidth
    Draw: .timeMin, .timeMax, .ampBottom, .ampTop, "no", "Curve"

    # Step 8: Draw axes on top
    @emlDrawAxes: .timeMin, .timeMax, .ampBottom, .ampTop, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Step 9: Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawSpectrum
# Draws a publication-quality Spectrum plot.
# Source: v1.1 (17 Feb 2026), adapted for plugin dispatch signature.
# v1.1: Fixed frequency auto-detection (uses sensible defaults, not time queries).
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawSpectrum: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax

    # Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Compute frequency range (both 0 = auto)
    if .fMin = 0 and .fMax = 0
        .freqMin = 0
        .freqMax = 5000
    else
        .freqMin = .fMin
        .freqMax = .fMax
    endif

    # Compute power range (both 0 = auto)
    if .pMin = 0 and .pMax = 0
        .powerMin = 0
        .powerMax = 80
    else
        .powerMin = .pMin
        .powerMax = .pMax
    endif

    # Set viewport and axes
    @emlSetPanelViewport
    Axes: .freqMin, .freqMax, .powerMin, .powerMax

    # Draw gridlines if requested
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Draw the spectrum
    selectObject: .objectId
    Colour: emlSetColorPalette.line$[1]
    Line width: emlSetAdaptiveTheme.dataLineWidth
    Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no"

    # Draw axes
    @emlDrawAxes: .freqMin, .freqMax, .powerMin, .powerMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawLTAS
# Draws a publication-quality LTAS plot with optional multi-method overlay.
# Source: v1.2 (26 Mar 2026).
# v1.1: Fixed frequency auto-detection (uses sensible defaults, not time queries).
# v1.2: Multi-method overlay (Curve, Bars, Poles, Speckles) with sequential
#        Okabe-Ito color assignment. Draw order back-to-front:
#        Bars → Speckles → Poles → Curve. Fallback if all disabled: Curve.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawLTAS: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax, .showCurve, .showBars, .showPoles, .showSpeckles

    # Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Fallback: if nothing enabled, draw Curve
    if .showCurve = 0 and .showBars = 0 and .showPoles = 0 and .showSpeckles = 0
        .showCurve = 1
    endif

    # Compute frequency range (both 0 = auto)
    if .fMin = 0 and .fMax = 0
        .freqMin = 0
        .freqMax = 5000
    else
        .freqMin = .fMin
        .freqMax = .fMax
    endif

    # Compute power range (both 0 = auto)
    if .pMin = 0 and .pMax = 0
        .powerMin = -20
        .powerMax = 80
    else
        .powerMin = .pMin
        .powerMax = .pMax
    endif

    # Set viewport and axes
    @emlSetPanelViewport
    Axes: .freqMin, .freqMax, .powerMin, .powerMax

    # Draw gridlines if requested
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .freqMin, .freqMax, .powerMin, .powerMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Build draw queue: back-to-front order (Bars, Poles, Curve, Speckles)
    # Speckles drawn last to cap poles visually.
    # Each enabled method gets the next sequential palette color.
    .colorIdx = 0

    # --- Bars (back layer — native, respects viewport) ---
    if .showBars
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Bars"
    endif

    # --- Poles (custom — thin lines from 0 to value, clamped) ---
    if .showPoles
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        .nBins = Get number of bins
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        # Origin at 0, clamped to axis bounds
        .poleOrigin = 0
        if .poleOrigin < .powerMin
            .poleOrigin = .powerMin
        endif
        if .poleOrigin > .powerMax
            .poleOrigin = .powerMax
        endif
        for .iBin from 1 to .nBins
            selectObject: .objectId
            .binFreq = Get frequency from bin number: .iBin
            .binVal = Get value in bin: .iBin
            if .binVal <> undefined
                if .binFreq >= .freqMin and .binFreq <= .freqMax
                    # Clamp value to axis bounds (don't skip — draw visible portion)
                    .clampedVal = .binVal
                    if .clampedVal < .powerMin
                        .clampedVal = .powerMin
                    endif
                    if .clampedVal > .powerMax
                        .clampedVal = .powerMax
                    endif
                    Draw line: .binFreq, .poleOrigin, .binFreq, .clampedVal
                endif
            endif
        endfor
    endif

    # --- Curve (native) ---
    if .showCurve
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Curve"
    endif

    # --- Speckles (custom — dots at data values, drawn last to cap poles) ---
    if .showSpeckles
        .colorIdx = .colorIdx + 1
        selectObject: .objectId
        .nBins = Get number of bins
        Colour: emlSetColorPalette.line$[.colorIdx]
        # Dot radius in world x-coordinates (frequency)
        .dotRadius = (.freqMax - .freqMin) * 0.006
        for .iBin from 1 to .nBins
            selectObject: .objectId
            .binFreq = Get frequency from bin number: .iBin
            .binVal = Get value in bin: .iBin
            if .binVal <> undefined
                if .binFreq >= .freqMin and .binFreq <= .freqMax
                    if .binVal >= .powerMin and .binVal <= .powerMax
                        Paint circle: emlSetColorPalette.line$[.colorIdx], .binFreq, .binVal, .dotRadius
                    endif
                endif
            endif
        endfor
    endif

    # Draw axes
    @emlDrawAxes: .freqMin, .freqMax, .powerMin, .powerMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Reset state
    Colour: "Black"
    Line width: 1.0
endproc

# ----------------------------------------------------------------------------
# @emlDrawTimeSeries
# Draws a publication-quality time series plot with optional spaghetti
# strands (individual traces), grouped lines, and mean overlays.
#
# Drawing modes (determined by column configuration):
#   A — No ID, no group: single line + optional band (original behavior)
#   B — ID, no group: spaghetti strands (muted), optional mean overlay
#   C — ID + group: spaghetti colored by group, per-group mean overlay
#   D — No ID + group: one line per group (grouped time series)
#
# Band columns apply to mode A only (CI around a single series).
# Mean overlay is optional (boolean) and applies to modes B and C.
# Group count capped at 10 (palette limit). ID count is uncapped.
# ----------------------------------------------------------------------------
# ============================================================================
# @emlDrawTimeSeries (reverted — modes A + D only)
# ============================================================================
# Simple time series: one line, or one line per group. No individuals.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawTimeSeries: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax

    # Step 1: Setup
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    .hasGroup = 0
    .nGroups = 0
    if .groupCol$ <> ""
        @emlCountGroups: .objectId, .groupCol$
        if emlCountGroups.error$ = "" and emlCountGroups.nGroups > 1
            .hasGroup = 1
            .nGroups = emlCountGroups.nGroups
            if .nGroups > 10
                appendInfoLine: "NOTE: Group column has ", .nGroups,
                ... " groups — capping at 10."
                .nGroups = 10
            endif
            @emlOptimizePaletteContrast: .nGroups
            for .g from 1 to .nGroups
                .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endfor
        endif
    endif

    # Step 2: Copy and sort table
    selectObject: .objectId
    .tempTable = Copy: "eml_ts_temp"
    if .hasGroup = 1
        Sort rows: .groupCol$ + " " + .timeCol$
    else
        Sort rows: .timeCol$
    endif

    # Step 3: Read data
    selectObject: .tempTable
    .nRows = Get number of rows
    for .i from 1 to .nRows
        selectObject: .tempTable
        .val$ = Get value: .i, .timeCol$
        .rowT'.i' = number (.val$)
        .val$ = Get value: .i, .valueCol$
        .rowY'.i' = number (.val$)
        if .hasGroup = 1
            .rowGrp'.i'$ = Get value: .i, .groupCol$
        endif
    endfor
    removeObject: .tempTable

    # Step 4: Axis ranges
    .xDataMin = .rowT1
    .xDataMax = .rowT1
    .yDataMin = .rowY1
    .yDataMax = .rowY1
    for .i from 2 to .nRows
        if .rowT'.i' < .xDataMin
            .xDataMin = .rowT'.i'
        endif
        if .rowT'.i' > .xDataMax
            .xDataMax = .rowT'.i'
        endif
        if .rowY'.i' < .yDataMin
            .yDataMin = .rowY'.i'
        endif
        if .rowY'.i' > .yDataMax
            .yDataMax = .rowY'.i'
        endif
    endfor

    # X-axis: exact data range (no nice-number rounding for time axes)
    if .tMin = 0 and .tMax = 0
        .xMin = .xDataMin
        .xMax = .xDataMax
    else
        .xMin = .tMin
        .xMax = .tMax
    endif

    @emlComputeAxisRange: .yDataMin, .yDataMax, 10, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 5: Viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 6: Gridlines
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 7: Draw data
    if .hasGroup = 0
        # Single line
        Colour: emlSetColorPalette.line$[1]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        for .i from 1 to .nRows - 1
            .iN = .i + 1
            if .rowT'.iN' >= .xMin and .rowT'.i' <= .xMax
                .cx1 = max (.xMin, min (.xMax, .rowT'.i'))
                .cy1 = max (.yMin, min (.yMax, .rowY'.i'))
                .cx2 = max (.xMin, min (.xMax, .rowT'.iN'))
                .cy2 = max (.yMin, min (.yMax, .rowY'.iN'))
                Draw line: .cx1, .cy1, .cx2, .cy2
            endif
        endfor
    else
        # One line per group
        for .g from 1 to .nGroups
            Colour: emlSetColorPalette.line$[.g]
            Line width: emlSetAdaptiveTheme.dataLineWidth
            .prevT = 0
            .prevY = 0
            .started = 0
            for .i from 1 to .nRows
                .thisGrp$ = .rowGrp'.i'$
                if .thisGrp$ = .grpLabel$[.g]
                    .thisT = .rowT'.i'
                    .thisY = .rowY'.i'
                    if .started = 1
                        .cx1 = max (.xMin, min (.xMax, .prevT))
                        .cy1 = max (.yMin, min (.yMax, .prevY))
                        .cx2 = max (.xMin, min (.xMax, .thisT))
                        .cy2 = max (.yMin, min (.yMax, .thisY))
                        Draw line: .cx1, .cy1, .cx2, .cy2
                    endif
                    .prevT = .thisT
                    .prevY = .thisY
                    .started = 1
                endif
            endfor
        endfor

        # Quadrant scoring for adaptive legend placement
        selectObject: .objectId
        .nScanRows = Get number of rows
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nScanRows
            selectObject: .objectId
            .rx = Get value: .qi, .timeCol$
            .ry = Get value: .qi, .valueCol$
            if .rx <> undefined and .ry <> undefined
                if .ry >= .yMidQ
                    if .rx < .xMidQ
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .rx < .xMidQ
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endif
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        # Legend
        legendN = .nGroups
        for .g from 1 to .nGroups
            legendColor$[.g] = emlSetColorPalette.line$[.g]
            legendLabel$[.g] = .grpLabel$[.g]
        endfor
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, emlPlaceElements.corner1$,
        ... emlSetAdaptiveTheme.annotSize
    endif

    # Step 8: Axes
    @emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$,
    ... .title$, .vpW, .vpH

    # Step 9: Reset
    Line width: 1.0
    Colour: "Black"
endproc


# ============================================================================
# @emlDrawTimeSeriesCI
# ============================================================================
# Time series with auto-computed confidence interval bands.
# Detects repeated measures per time point and computes mean ± CI using
# the t-distribution. CI level is (1 - annotAlpha) — default 95%.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme),
#                annotAlpha (confidence level; default 0.05 = 95% CI).
procedure emlDrawTimeSeriesCI: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    .hasGroup = 0
    .nGroups = 1
    if .groupCol$ <> ""
        @emlCountGroups: .objectId, .groupCol$
        if emlCountGroups.error$ = "" and emlCountGroups.nGroups > 1
            .hasGroup = 1
            .nGroups = emlCountGroups.nGroups
            if .nGroups > 10
                .nGroups = 10
            endif
            @emlOptimizePaletteContrast: .nGroups
            for .g from 1 to .nGroups
                .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endfor
        endif
    endif

    # Read all rows
    selectObject: .objectId
    .nRows = Get number of rows
    for .i from 1 to .nRows
        selectObject: .objectId
        .val$ = Get value: .i, .timeCol$
        .rowT'.i' = number (.val$)
        .val$ = Get value: .i, .valueCol$
        .rowY'.i' = number (.val$)
        if .hasGroup = 1
            .rowGrp'.i'$ = Get value: .i, .groupCol$
        else
            .rowGrp'.i'$ = "all"
        endif
    endfor

    # Per group: accumulate unique time points, compute mean ± CI
    # Global y range tracking
    .yDataMin = undefined
    .yDataMax = undefined
    .xDataMin = undefined
    .xDataMax = undefined

    for .g from 1 to .nGroups
        if .hasGroup = 1
            .gLabel$ = .grpLabel$[.g]
        else
            .gLabel$ = "all"
        endif
        .nUT = 0
        for .i from 1 to .nRows
            if .rowGrp'.i'$ = .gLabel$
                .t = .rowT'.i'
                .y = .rowY'.i'
                if .y = undefined
                    # skip
                else
                    .isNew = 1
                    for .k from 1 to .nUT
                        if abs (.t - .gUT'.g'_'.k') < 0.0001
                            .isNew = 0
                            .gUS'.g'_'.k' = .gUS'.g'_'.k' + .y
                            .gUSS'.g'_'.k' = .gUSS'.g'_'.k' + .y * .y
                            .gUC'.g'_'.k' = .gUC'.g'_'.k' + 1
                        endif
                    endfor
                    if .isNew = 1
                        .nUT = .nUT + 1
                        .k = .nUT
                        .gUT'.g'_'.k' = .t
                        .gUS'.g'_'.k' = .y
                        .gUSS'.g'_'.k' = .y * .y
                        .gUC'.g'_'.k' = 1
                    endif
                endif
            endif
        endfor
        .gNUT'.g' = .nUT

        # Sort unique times (insertion sort)
        for .i from 2 to .nUT
            .keyT = .gUT'.g'_'.i'
            .keyS = .gUS'.g'_'.i'
            .keySS = .gUSS'.g'_'.i'
            .keyC = .gUC'.g'_'.i'
            .j = .i - 1
            .done = 0
            while .j >= 1 and .done = 0
                if .gUT'.g'_'.j' > .keyT
                    .jn = .j + 1
                    .gUT'.g'_'.jn' = .gUT'.g'_'.j'
                    .gUS'.g'_'.jn' = .gUS'.g'_'.j'
                    .gUSS'.g'_'.jn' = .gUSS'.g'_'.j'
                    .gUC'.g'_'.jn' = .gUC'.g'_'.j'
                    .j = .j - 1
                else
                    .done = 1
                endif
            endwhile
            .jn = .j + 1
            .gUT'.g'_'.jn' = .keyT
            .gUS'.g'_'.jn' = .keyS
            .gUSS'.g'_'.jn' = .keySS
            .gUC'.g'_'.jn' = .keyC
        endfor

        # Compute mean, CI for each unique time point
        for .k from 1 to .nUT
            .n = .gUC'.g'_'.k'
            .mean = .gUS'.g'_'.k' / .n
            .gMean'.g'_'.k' = .mean
            if .n >= 2
                .var = (.gUSS'.g'_'.k' - .n * .mean * .mean) / (.n - 1)
                if .var < 0
                    .var = 0
                endif
                .se = sqrt (.var / .n)
                .tCrit = invStudentQ (annotAlpha / 2, .n - 1)
                .gLo'.g'_'.k' = .mean - .tCrit * .se
                .gHi'.g'_'.k' = .mean + .tCrit * .se
            else
                .gLo'.g'_'.k' = .mean
                .gHi'.g'_'.k' = .mean
            endif
            # Track global ranges
            .t = .gUT'.g'_'.k'
            if .xDataMin = undefined
                .xDataMin = .t
                .xDataMax = .t
                .yDataMin = .gLo'.g'_'.k'
                .yDataMax = .gHi'.g'_'.k'
            else
                if .t < .xDataMin
                    .xDataMin = .t
                endif
                if .t > .xDataMax
                    .xDataMax = .t
                endif
                if .gLo'.g'_'.k' < .yDataMin
                    .yDataMin = .gLo'.g'_'.k'
                endif
                if .gHi'.g'_'.k' > .yDataMax
                    .yDataMax = .gHi'.g'_'.k'
                endif
            endif
        endfor
    endfor

    if .xDataMin = undefined
        .xDataMin = 0
        .xDataMax = 1
        .yDataMin = 0
        .yDataMax = 1
    endif

    # Axis ranges
    # X-axis: exact data range (no nice-number rounding for time axes)
    if .tMin = 0 and .tMax = 0
        .xMin = .xDataMin
        .xMax = .xDataMax
    else
        .xMin = .tMin
        .xMax = .tMax
    endif
    @emlComputeAxisRange: .yDataMin, .yDataMax, 10, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Viewport
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Gridlines
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksX,
        ... emlSetAdaptiveTheme.useMinorTicks
    endif

    # Draw CI bands and mean lines per group
    for .g from 1 to .nGroups
        .nUT = .gNUT'.g'
        .colorIdx = (((.g - 1) mod 10) + 1)

        # CI band (alpha-composited)
        for .k from 1 to .nUT - 1
            .kN = .k + 1
            .x1 = .gUT'.g'_'.k'
            .x2 = .gUT'.g'_'.kN'
            if .x2 >= .xMin and .x1 <= .xMax
                .lo = min (.gLo'.g'_'.k', .gLo'.g'_'.kN')
                .hi = max (.gHi'.g'_'.k', .gHi'.g'_'.kN')
                .dx1 = max (.x1, .xMin)
                .dx2 = min (.x2, .xMax)
                .dLo = max (.lo, .yMin)
                .dHi = min (.hi, .yMax)
                if .dLo < .dHi
                    @emlDrawAlphaRect: .dx1, .dx2, .dLo, .dHi, .colorIdx, .colorMode$, "a30", emlSetColorPalette.fill$[.colorIdx]
                endif
            endif
        endfor

        # Mean line
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.dataLineWidth
        for .k from 2 to .nUT
            .kp = .k - 1
            .mt1 = .gUT'.g'_'.kp'
            .mt2 = .gUT'.g'_'.k'
            .my1 = .gMean'.g'_'.kp'
            .my2 = .gMean'.g'_'.k'
            if .mt2 >= .xMin and .mt1 <= .xMax
                .my1 = max (.yMin, min (.yMax, .my1))
                .my2 = max (.yMin, min (.yMax, .my2))
                Draw line: max (.mt1, .xMin), .my1,
                ... min (.mt2, .xMax), .my2
            endif
        endfor
    endfor

    # Legend
    if .hasGroup = 1
        selectObject: .objectId
        .nScanRows = Get number of rows
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nScanRows
            selectObject: .objectId
            .rx = Get value: .qi, .timeCol$
            .ry = Get value: .qi, .valueCol$
            if .rx <> undefined and .ry <> undefined
                if .ry >= .yMidQ
                    if .rx < .xMidQ
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .rx < .xMidQ
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endif
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        legendN = .nGroups
        for .g from 1 to .nGroups
            legendColor$[.g] = emlSetColorPalette.line$[.g]
            legendLabel$[.g] = .grpLabel$[.g]
        endfor
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, emlPlaceElements.corner1$,
        ... emlSetAdaptiveTheme.annotSize
    endif

    # Info window
    appendInfoLine: "Time Series (with CI): ", .nGroups, " group(s)"
    for .g from 1 to .nGroups
        .nUT = .gNUT'.g'
        if .hasGroup = 1
            appendInfoLine: "  Group: ", .grpLabel$[.g],
            ... " — ", .nUT, " time points"
        else
            appendInfoLine: "  ", .nUT, " time points"
        endif
        .maxN = 0
        for .k from 1 to .nUT
            if .gUC'.g'_'.k' > .maxN
                .maxN = .gUC'.g'_'.k'
            endif
        endfor
        if .maxN <= 1
            appendInfoLine: "  NOTE: No repeated measures detected. CI not computed."
        else
            appendInfoLine: "  Observations per time point: up to ", .maxN
        endif
    endfor

    # Axes
    @emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$,
    ... .title$, .vpW, .vpH

    Line width: 1.0
    Colour: "Black"
endproc


# ============================================================================
# @emlDrawSpaghettiPlot
# ============================================================================
# Individual subject traces across ordinal conditions with optional mean
# overlay. X-axis is categorical (equal-spaced positions in encounter
# order from the Table). Strands drawn muted; mean overlay bold.
# Endpoint dots at every subject × condition intersection.
#
# Arguments:
#   .condCol$  — categorical condition column (encounter order = x order)
#   .valueCol$ — numeric dependent variable
#   .idCol$    — subject/participant identifier column
#   .groupCol$ — optional grouping column ("" = no groups)
#   .showMean  — boolean: draw bold mean overlay
#   .vMin/.vMax — y-axis range (both 0 = auto)
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawSpaghettiPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .condCol$, .valueCol$, .idCol$, .groupCol$, .showMean, .vMin, .vMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # ----------------------------------------------------------------
    # Extract unique conditions in encounter order
    # ----------------------------------------------------------------
    selectObject: .objectId
    .nRows = Get number of rows
    .nCond = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCond$ = Get value: .i, .condCol$
        .found = 0
        for .c from 1 to .nCond
            if .thisCond$ = .condLabel$[.c]
                .found = 1
            endif
        endfor
        if .found = 0
            .nCond = .nCond + 1
            .condLabel$[.nCond] = .thisCond$
        endif
    endfor
    if .nCond < 2
        appendInfoLine: "WARNING: Spaghetti plot requires at least 2 conditions. Found ", .nCond, "."
    endif

    # ----------------------------------------------------------------
    # Groups (optional)
    # ----------------------------------------------------------------
    .hasGroup = 0
    .nGroups = 0
    if .groupCol$ <> ""
        @emlCountGroups: .objectId, .groupCol$
        if emlCountGroups.error$ = "" and emlCountGroups.nGroups > 1
            .hasGroup = 1
            .nGroups = emlCountGroups.nGroups
            if .nGroups > 10
                .nGroups = 10
            endif
            @emlOptimizePaletteContrast: .nGroups
            for .g from 1 to .nGroups
                .grpLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endfor
        endif
    endif

    # ----------------------------------------------------------------
    # Read all rows: map condition label → integer x-position,
    # read value, subject ID, and optional group
    # ----------------------------------------------------------------
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCond$ = Get value: .i, .condCol$
        # Map to integer position (encounter order)
        .rowX[.i] = 0
        for .c from 1 to .nCond
            if .thisCond$ = .condLabel$[.c]
                .rowX[.i] = .c
            endif
        endfor
        .val$ = Get value: .i, .valueCol$
        .rowY[.i] = number (.val$)
        .rowId$[.i] = Get value: .i, .idCol$
        if .hasGroup = 1
            .rowGrp$[.i] = Get value: .i, .groupCol$
        endif
    endfor

    # ----------------------------------------------------------------
    # Y-axis range
    # ----------------------------------------------------------------
    .yDataMin = .rowY[1]
    .yDataMax = .rowY[1]
    for .i from 2 to .nRows
        if .rowY[.i] < .yDataMin
            .yDataMin = .rowY[.i]
        endif
        if .rowY[.i] > .yDataMax
            .yDataMax = .rowY[.i]
        endif
    endfor
    @emlComputeAxisRange: .yDataMin, .yDataMax, 10, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif
    .xMin = 0.5
    .xMax = .nCond + 0.5

    # ----------------------------------------------------------------
    # Viewport
    # ----------------------------------------------------------------
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Gridlines (horizontal only — categorical x-axis)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax,
        ... emlSetAdaptiveTheme.targetTicksY,
        ... emlSetAdaptiveTheme.useMinorTicks
    endif

    # ----------------------------------------------------------------
    # Collect unique subject IDs (encounter order)
    # ----------------------------------------------------------------
    .nSubjects = 0
    for .i from 1 to .nRows
        .found = 0
        for .s from 1 to .nSubjects
            if .rowId$[.i] = .subjId$[.s]
                .found = 1
            endif
        endfor
        if .found = 0
            .nSubjects = .nSubjects + 1
            .subjId$[.nSubjects] = .rowId$[.i]
        endif
    endfor

    # ----------------------------------------------------------------
    # Strand + dot drawing parameters
    # ----------------------------------------------------------------
    .strandWidth = 1.0
    .dotSize = emlSetAdaptiveTheme.markerSize * 1.5
    if .dotSize < 1.0
        .dotSize = 1.0
    endif
    .meanDotSize = emlSetAdaptiveTheme.markerSize * 2.5
    if .meanDotSize < 1.5
        .meanDotSize = 1.5
    endif

    # ----------------------------------------------------------------
    # Draw strands + endpoint dots
    # ----------------------------------------------------------------
    if .hasGroup = 0
        # --- Ungrouped: single muted color ---
        @emlLightenColor: emlSetColorPalette.line$[1], 0.6
        .strandColor$ = emlLightenColor.result$

        for .s from 1 to .nSubjects
            Colour: .strandColor$
            Line width: .strandWidth
            .prevX = 0
            .prevY = 0
            .hasPrev = 0
            for .c from 1 to .nCond
                # Find this subject's value at this condition
                .foundVal = 0
                for .i from 1 to .nRows
                    if .foundVal = 0
                        if .rowId$[.i] = .subjId$[.s] and .rowX[.i] = .c
                            .thisY = .rowY[.i]
                            .foundVal = 1
                        endif
                    endif
                endfor
                if .foundVal = 1
                    .thisX = .c
                    # Draw connecting line from previous condition
                    if .hasPrev = 1
                        Draw line: .prevX, .prevY, .thisX, .thisY
                    endif
                    # Endpoint dot
                    Paint circle (mm): .strandColor$, .thisX, .thisY, .dotSize
                    .prevX = .thisX
                    .prevY = .thisY
                    .hasPrev = 1
                endif
            endfor
        endfor

        # Mean overlay
        if .showMean = 1
            Colour: emlSetColorPalette.line$[1]
            Line width: emlSetAdaptiveTheme.dataLineWidth
            .prevMeanX = 0
            .prevMeanY = 0
            .hasPrevMean = 0
            for .c from 1 to .nCond
                .sum = 0
                .cnt = 0
                for .i from 1 to .nRows
                    if .rowX[.i] = .c
                        .sum = .sum + .rowY[.i]
                        .cnt = .cnt + 1
                    endif
                endfor
                if .cnt > 0
                    .meanY = .sum / .cnt
                    if .hasPrevMean = 1
                        Draw line: .prevMeanX, .prevMeanY, .c, .meanY
                    endif
                    Paint circle (mm): emlSetColorPalette.line$[1], .c, .meanY, .meanDotSize
                    .prevMeanX = .c
                    .prevMeanY = .meanY
                    .hasPrevMean = 1
                endif
            endfor
        endif

    else
        # --- Grouped: muted strands per group ---
        for .g from 1 to .nGroups
            @emlLightenColor: emlSetColorPalette.line$[.g], 0.6
            .strandCol$[.g] = emlLightenColor.result$
        endfor

        for .s from 1 to .nSubjects
            # Determine this subject's group from first row match
            .sGrp = 1
            for .i from 1 to .nRows
                if .rowId$[.i] = .subjId$[.s]
                    for .g from 1 to .nGroups
                        if .rowGrp$[.i] = .grpLabel$[.g]
                            .sGrp = .g
                        endif
                    endfor
                endif
            endfor

            Colour: .strandCol$[.sGrp]
            Line width: .strandWidth
            .prevX = 0
            .prevY = 0
            .hasPrev = 0
            for .c from 1 to .nCond
                .foundVal = 0
                for .i from 1 to .nRows
                    if .foundVal = 0
                        if .rowId$[.i] = .subjId$[.s] and .rowX[.i] = .c
                            .thisY = .rowY[.i]
                            .foundVal = 1
                        endif
                    endif
                endfor
                if .foundVal = 1
                    .thisX = .c
                    if .hasPrev = 1
                        Draw line: .prevX, .prevY, .thisX, .thisY
                    endif
                    Paint circle (mm): .strandCol$[.sGrp], .thisX, .thisY, .dotSize
                    .prevX = .thisX
                    .prevY = .thisY
                    .hasPrev = 1
                endif
            endfor
        endfor

        # Per-group mean overlay
        if .showMean = 1
            for .g from 1 to .nGroups
                Colour: emlSetColorPalette.line$[.g]
                Line width: emlSetAdaptiveTheme.dataLineWidth
                .prevMeanX = 0
                .prevMeanY = 0
                .hasPrevMean = 0
                for .c from 1 to .nCond
                    .sum = 0
                    .cnt = 0
                    for .i from 1 to .nRows
                        if .rowX[.i] = .c and .rowGrp$[.i] = .grpLabel$[.g]
                            .sum = .sum + .rowY[.i]
                            .cnt = .cnt + 1
                        endif
                    endfor
                    if .cnt > 0
                        .meanY = .sum / .cnt
                        if .hasPrevMean = 1
                            Draw line: .prevMeanX, .prevMeanY, .c, .meanY
                        endif
                        Paint circle (mm): emlSetColorPalette.line$[.g], .c, .meanY, .meanDotSize
                        .prevMeanX = .c
                        .prevMeanY = .meanY
                        .hasPrevMean = 1
                    endif
                endfor
            endfor
        endif

        # Quadrant scoring for adaptive legend placement
        selectObject: .objectId
        .nScanRows = Get number of rows
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nScanRows
            selectObject: .objectId
            .ry = Get value: .qi, .valueCol$
            .rc$ = Get value: .qi, .condCol$
            if .ry <> undefined
                # Map condition to x position
                .rcIdx = 0
                for .ci from 1 to .nCond
                    if .rc$ = .condLabel$[.ci]
                        .rcIdx = .ci
                    endif
                endfor
                if .rcIdx > 0
                    if .ry >= .yMidQ
                        if .rcIdx < .xMidQ
                            .qTL = .qTL + 1
                        else
                            .qTR = .qTR + 1
                        endif
                    else
                        if .rcIdx < .xMidQ
                            .qBL = .qBL + 1
                        else
                            .qBR = .qBR + 1
                        endif
                    endif
                endif
            endif
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        # Legend
        legendN = .nGroups
        for .g from 1 to .nGroups
            legendColor$[.g] = emlSetColorPalette.line$[.g]
            legendLabel$[.g] = .grpLabel$[.g]
        endfor
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, emlPlaceElements.corner1$,
        ... emlSetAdaptiveTheme.annotSize
    endif

    # ----------------------------------------------------------------
    # Axes — categorical x with condition labels (pre-measured)
    # ----------------------------------------------------------------
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Condition labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nCond, .xMin, .xMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ----------------------------------------------------------------------------
# @emlDrawBarChart
# Draws a publication-quality grouped bar chart with optional error bars.
# Error mode: 0=none, 1=SE (auto), 2=SD (auto), 3=custom column.
# Source: task spec (17 Feb 2026), adapted for plugin dispatch signature.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawBarChart: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .errorMode, .errorCol$, .vMin, .vMax

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Sanitize title (axis labels handled at generation)
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Read pre-computed data from @emlMeasureBarData globals
    .nGroups = emlBarData_nGroups
    @emlOptimizePaletteContrast: .nGroups

    # Step 3: Compute y-axis range (both 0 = auto)
    if .vMin = 0 and .vMax = 0
        @emlComputeAxisRange: 0, emlBarData_visibleMax, 10, 0
        .yMin = 0
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 4: Set x-axis range (categorical — one position per group)
    .xMin = 0.5
    .xMax = .nGroups + 0.5

    # Step 5: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 6: Draw horizontal gridlines (if requested)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 7: Draw bars with error bars (one bar per group, colored by palette)
    .barWidth = 0.6
    .halfBar = .barWidth / 2
    .capWidth = .barWidth * 0.17

    for .g from 1 to .nGroups
        .xCenter = .g
        .colorIdx = (((.g - 1) mod 6) + 1)

        # Clamp bar top to axis maximum (TODO-055 fix)
        .barTop = min (emlBarData_mean[.g], .yMax)

        # Filled bar
        Paint rectangle: emlSetColorPalette.fill$[.colorIdx], .xCenter - .halfBar, .xCenter + .halfBar, .yMin, .barTop

        # Bar outline
        Colour: emlSetColorPalette.line$[.colorIdx]
        Line width: emlSetAdaptiveTheme.axisLineWidth
        Draw rectangle: .xCenter - .halfBar, .xCenter + .halfBar, .yMin, .barTop

        # Error bar (if enabled and nonzero)
        if .errorMode > 0 and emlBarData_error[.g] > 0
            Line width: emlSetAdaptiveTheme.dataLineWidth * 0.7
            .errLow = emlBarData_mean[.g] - emlBarData_error[.g]
            .errHigh = emlBarData_mean[.g] + emlBarData_error[.g]

            # Clamp error bar bottom to yMin
            if .errLow < .yMin
                .errLow = .yMin
            endif

            # Clamp error bar top to yMax (TODO-055 fix)
            if .errHigh > .yMax
                .errHigh = .yMax
            endif

            Draw line: .xCenter, .errLow, .xCenter, .errHigh
            Draw line: .xCenter - .capWidth, .errLow, .xCenter + .capWidth, .errLow
            Draw line: .xCenter - .capWidth, .errHigh, .xCenter + .capWidth, .errHigh
        endif
    endfor

    # Expose axis ranges for annotation bridge
    .axisXMin = 0.5
    .axisXMax = .nGroups + 0.5
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 8: Draw axes with group labels (manual — no @emlDrawAxes)
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Group labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nGroups, .axisXMin, .axisXMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    # Title
    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Step 9: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc

# ----------------------------------------------------------------------------
# @emlDrawViolinPlot
# Draws a publication-quality violin plot with kernel density estimation.
# Source: v1.1 (17 Feb 2026), adapted for plugin dispatch signature.
# v1.1 fixes: bracket notation for string arrays, pre-computed indices.
# Calls @emlDrawViolin from eml-graph-procedures.praat for each group.
# ----------------------------------------------------------------------------
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawViolinPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Sanitize title (Rule 28J)
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Extract unique group names from the Table
    selectObject: .objectId
    .nRows = Get number of rows

    .nGroups = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisGroup$ = Get value: .i, .groupCol$

        # Check if this group already seen
        .found = 0
        for .g from 1 to .nGroups
            if .thisGroup$ = .uniqueGroup$[.g]
                .found = 1
            endif
        endfor

        if .found = 0
            .nGroups = .nGroups + 1
            .uniqueGroup$[.nGroups] = .thisGroup$
        endif
    endfor

    if .nGroups > 10
        appendInfoLine: "NOTE: Group column has ", .nGroups,
        ... " groups — capping at 10."
        .nGroups = 10
    endif
    @emlOptimizePaletteContrast: .nGroups

    # Step 3: Count observations per group and extract values
    for .g from 1 to .nGroups
        .groupCount'.g' = 0
    endfor

    for .i from 1 to .nRows
        selectObject: .objectId
        .thisGroup$ = Get value: .i, .groupCol$
        .val$ = Get value: .i, .valueCol$
        .thisVal = number (.val$)

        # Find which group this belongs to
        for .g from 1 to .nGroups
            if .thisGroup$ = .uniqueGroup$[.g]
                .groupCount'.g' = .groupCount'.g' + 1
                .c = .groupCount'.g'
                .groupData'.g'_'.c' = .thisVal
            endif
        endfor
    endfor

    # Step 4: Compute y-axis range (both 0 = auto)
    .globalMin = undefined
    .globalMax = undefined
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        for .k from 1 to .n
            .val = .groupData'.g'_'.k'
            if .globalMin = undefined
                .globalMin = .val
                .globalMax = .val
            else
                if .val < .globalMin
                    .globalMin = .val
                endif
                if .val > .globalMax
                    .globalMax = .val
                endif
            endif
        endfor
    endfor
    @emlComputeAxisRange: .globalMin, .globalMax, 10, 0
    .autoYMin = emlComputeAxisRange.axisMin
    .autoYMax = emlComputeAxisRange.axisMax

    if .vMin = 0 and .vMax = 0
        .yMin = .autoYMin
        .yMax = .autoYMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 5: Set x-axis range
    .xMin = 0.5
    .xMax = .nGroups + 0.5

    # Step 6: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 7: Draw horizontal gridlines (if requested)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 8: Draw each violin
    for .g from 1 to .nGroups
        # Build data vector for this group
        .n = .groupCount'.g'
        .data# = zero# (.n)
        for .k from 1 to .n
            .data# [.k] = .groupData'.g'_'.k'
        endfor

        # Determine color index (cycle through palette)
        .colorIdx = (((.g - 1) mod 6) + 1)

        @emlDrawViolin: .g, .data#, emlSetColorPalette.fill$[.colorIdx], emlSetColorPalette.line$[.colorIdx], .yMin, .yMax, 0.35
    endfor

    # Jittered points overlay (controlled by global)
    if variableExists ("prev_violinShowJitter")
        if prev_violinShowJitter = 1
            for .g from 1 to .nGroups
                .n = .groupCount'.g'
                jitterData# = zero# (.n)
                for .k from 1 to .n
                    jitterData#[.k] = .groupData'.g'_'.k'
                endfor
                .colorIdx = (((.g - 1) mod 6) + 1)
                @emlDrawJitteredPoints: .g, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.5, 0.12
            endfor
        endif
    endif

    # Expose axis ranges for annotation bridge
    .axisXMin = 0.5
    .axisXMax = .nGroups + 0.5
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 9: Draw axes with group labels (manual — no @emlDrawAxes)
    Colour: emlSetAdaptiveTheme.axisColor$
    Line width: emlSetAdaptiveTheme.axisLineWidth

    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Group labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nGroups, .axisXMin, .axisXMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Step 10: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# @emlDrawScatterPlot
# ============================================================================
# Draws a scatter plot from Table with X and Y columns.
# Optional group column for color-coded points.
# Handles all annotation internally: correlation stats, regression lines,
# formula display, and per-group regression.
#
# Reads globals: scatterDotSize, scatterRegressionLine, scatterShowFormula,
#   scatterShowDots, annotate, annotCorrType$, annotStyle$, annotShowNS,
#   annotCorrType$, annotStyle$, annotAlpha
#
# Arguments:
#   .objectId    — Table object ID
#   .title$      — figure title
#   .xLabel$     — x-axis label
#   .yLabel$     — y-axis label
#   .vpW, .vpH   — viewport dimensions
#   .colorMode$  — "color" or "bw"
#   .gridMode    — 1 = both, 2 = horizontal only, 3 = vertical only, 4 = off
#   .colX$       — x column name
#   .colY$       — y column name
#   .groupCol$   — group column name ("" for no grouping)
#   .xMin, .xMax — axis x range (both 0 = auto)
#   .yMin, .yMax — axis y range (both 0 = auto)
#   .annotate    — 1 = draw annotations, 0 = skip
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawScatterPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .colX$, .colY$, .groupCol$, .xMin, .xMax, .yMin, .yMax, .annotate
    # Step 1: Theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    # Step 2: Extract all data (for axis computation and ungrouped stats)
    selectObject: .objectId
    .nRows = Get number of rows
    .xData# = zero# (.nRows)
    .yData# = zero# (.nRows)
    .nValid = 0

    for .i from 1 to .nRows
        selectObject: .objectId
        .xVal = Get value: .i, .colX$
        .yVal = Get value: .i, .colY$
        if .xVal <> undefined and .yVal <> undefined
            .nValid = .nValid + 1
            .xData#[.nValid] = .xVal
            .yData#[.nValid] = .yVal
        endif
    endfor

    if .nValid < 2
        appendInfoLine: "WARNING: Fewer than 2 valid data points for scatter plot."
    endif

    # Trim to valid length (avoids trailing zeros biasing corner selection)
    if .nValid > 0 and .nValid < .nRows
        .xTmp# = zero# (.nValid)
        .yTmp# = zero# (.nValid)
        for .i from 1 to .nValid
            .xTmp#[.i] = .xData#[.i]
            .yTmp#[.i] = .yData#[.i]
        endfor
        .xData# = .xTmp#
        .yData# = .yTmp#
    endif

    # Step 3: Compute data extent and axis ranges
    if .nValid > 0
        .dataXMin = .xData#[1]
        .dataXMax = .xData#[1]
        .dataYMin = .yData#[1]
        .dataYMax = .yData#[1]
        for .i from 2 to .nValid
            if .xData#[.i] < .dataXMin
                .dataXMin = .xData#[.i]
            endif
            if .xData#[.i] > .dataXMax
                .dataXMax = .xData#[.i]
            endif
            if .yData#[.i] < .dataYMin
                .dataYMin = .yData#[.i]
            endif
            if .yData#[.i] > .dataYMax
                .dataYMax = .yData#[.i]
            endif
        endfor
    else
        .dataXMin = 0
        .dataXMax = 1
        .dataYMin = 0
        .dataYMax = 1
    endif

    if .xMin = 0 and .xMax = 0
        @emlComputeAxisRange: .dataXMin, .dataXMax, 1, 0
        .axisXMin = emlComputeAxisRange.axisMin
        .axisXMax = emlComputeAxisRange.axisMax
    else
        .axisXMin = .xMin
        .axisXMax = .xMax
    endif

    if .yMin = 0 and .yMax = 0
        @emlComputeAxisRange: .dataYMin, .dataYMax, 1, 0
        .axisYMin = emlComputeAxisRange.axisMin
        .axisYMax = emlComputeAxisRange.axisMax
    else
        .axisYMin = .yMin
        .axisYMax = .yMax
    endif

    # Step 4: Set viewport and axes
    @emlSetPanelViewport
    Axes: .axisXMin, .axisXMax, .axisYMin, .axisYMax

    # Step 5: Gridlines
    # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
    if .gridMode = 1
        @emlDrawGridlines: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 2
        @emlDrawHorizontalGridlines: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    elsif .gridMode = 3
        @emlDrawVerticalGridlines: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 6: Dot size from global
    if scatterDotSize = 1
        .sizeScale = 0.008
    elsif scatterDotSize = 3
        .sizeScale = 0.025
    else
        .sizeScale = 0.015
    endif
    .markerRadius = emlSetAdaptiveTheme.markerSize * .sizeScale
    .xRange = .axisXMax - .axisXMin
    .radiusWorld = .markerRadius * .xRange

    # Step 6B: Alpha dot geometry (aspect-corrected for circular dots)
    @emlSetAlphaDotGeometry: .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.innerLeft, emlSetAdaptiveTheme.innerRight, emlSetAdaptiveTheme.innerTop, emlSetAdaptiveTheme.innerBottom, .radiusWorld

    # Step 6C: Auto-transparency decision
    # Alpha always on when sprites available — density benefits from transparency
    .useAlpha = emlInitAlphaSprites.available
    .alphaLevel$ = "a50"
    if scatterRegressionLine = 1
        # More transparent when regression lines present so lines read clearly
        .alphaLevel$ = "a30"
    endif

    # Regression line color (mode-aware)
    if .colorMode$ = "bw"
        .regColor$ = "{0.4, 0.4, 0.4}"
    else
        .regColor$ = "{0.5, 0.3, 0.3}"
    endif

    # Step 7: Initialize annotation block
    annotBlockN = 0

    # Point color: in B/W mode use lighter fill so regression lines are visible
    if .colorMode$ = "bw"
        for .c from 1 to 10
            .pointColor$[.c] = emlSetColorPalette.fill$[.c]
        endfor
    else
        for .c from 1 to 10
            .pointColor$[.c] = emlSetColorPalette.line$[.c]
        endfor
    endif

    if .groupCol$ = ""
        # ==============================================================
        # UNGROUPED PATH
        # ==============================================================

        # Plot points
        if scatterShowDots = 1
            for .i from 1 to .nValid
                if .useAlpha = 1 and emlInitAlphaSprites.available = 1
                    @emlDrawAlphaDot: .xData#[.i], .yData#[.i], 1, .colorMode$, .alphaLevel$, .pointColor$[1]
                else
                    Paint circle: .pointColor$[1], .xData#[.i], .yData#[.i], .radiusWorld
                endif
            endfor
        endif

        # Compute correlations and build annotation block
        .havePearson = 0
        .pearsonR = 0

        # Correlation annotations (gated by annotate)
        if .annotate = 1 and .nValid >= 3

            # --- Pearson ---
            .pearsonP = 0
            if annotCorrType$ = "pearson" or annotCorrType$ = "both"
                @emlPearsonCorrelation: .xData#, .yData#, 2
                if emlPearsonCorrelation.error$ = ""
                    .havePearson = 1
                    .pearsonR = emlPearsonCorrelation.r
                    .pearsonP = emlPearsonCorrelation.p

                    # Format p-value per annotation style setting
                    @emlFormatAnnotLabel: .pearsonP, 0, annotStyle$, 0, ""
                    .pText$ = emlFormatAnnotLabel.result$
                    appendInfoLine: "r = " + fixed$ (.pearsonR, 3) + ", " + .pText$

                    # Annotation block line (Picture)
                    annotBlockN = annotBlockN + 1
                    annotBlockLabel$[annotBlockN] = "r = " + fixed$ (.pearsonR, 3) + ", " + .pText$
                    annotBlockDraw$[annotBlockN] = "%r = " + fixed$ (.pearsonR, 3) + ", " + .pText$
                endif
            endif

            # --- Spearman ---
            .haveSpearman = 0
            .spearmanR = 0
            .spearmanP = 0
            if annotCorrType$ = "spearman" or annotCorrType$ = "both"
                @emlSpearmanCorrelation: .xData#, .yData#, 2
                if emlSpearmanCorrelation.error$ = ""
                    .haveSpearman = 1
                    .spearmanR = emlSpearmanCorrelation.rho
                    .spearmanP = emlSpearmanCorrelation.p

                    @emlFormatAnnotLabel: .spearmanP, 0, annotStyle$, 0, ""
                    .pText$ = emlFormatAnnotLabel.result$
                    appendInfoLine: "rs = " + fixed$ (.spearmanR, 3) + ", " + .pText$

                    annotBlockN = annotBlockN + 1
                    annotBlockLabel$[annotBlockN] = "rs = " + fixed$ (.spearmanR, 3) + ", " + .pText$
                    annotBlockDraw$[annotBlockN] = "%%r%_s = " + fixed$ (.spearmanR, 3) + ", " + .pText$
                endif
            endif
        endif

        # --- Regression line (independent of annotate) ---
        if scatterRegressionLine = 1 and .nValid >= 3
            # Ensure Pearson r is available for regression slope
            if .havePearson = 0
                @emlPearsonCorrelation: .xData#, .yData#, 2
                if emlPearsonCorrelation.error$ = ""
                    .pearsonR = emlPearsonCorrelation.r
                endif
            endif

            .meanX = mean (.xData#)
            .meanY = mean (.yData#)
            .sdX = stdev (.xData#)
            .sdY = stdev (.yData#)

            if .sdX > 0
                .slope = .pearsonR * (.sdY / .sdX)
                .intercept = .meanY - .slope * .meanX

                @emlDrawRegressionLine: .dataXMin, .dataXMax, .slope, .intercept, .axisYMin, .axisYMax, .regColor$

                # Formula to Info window always
                appendInfoLine: "y = " + fixed$ (.slope, 4) + "x + " + fixed$ (.intercept, 4)

                # Formula on graph if requested (independent of annotate)
                if scatterShowFormula = 1
                    annotBlockN = annotBlockN + 1
                    .formulaStr$ = "y = " + fixed$ (.slope, 4) + "x + " + fixed$ (.intercept, 4)
                    annotBlockLabel$[annotBlockN] = .formulaStr$
                    annotBlockDraw$[annotBlockN] = "%y = " + fixed$ (.slope, 4) + "%x + " + fixed$ (.intercept, 4)
                endif
            endif
        endif

        # Draw annotation block
        if annotBlockN > 0
            .xMidQ = (.axisXMin + .axisXMax) / 2
            .yMidQ = (.axisYMin + .axisYMax) / 2
            .qTL = 0
            .qTR = 0
            .qBL = 0
            .qBR = 0
            for .qi from 1 to .nValid
                if .yData#[.qi] >= .yMidQ
                    if .xData#[.qi] < .xMidQ
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .xData#[.qi] < .xMidQ
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endfor
            @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1
            @emlDrawAnnotationBlock: emlPlaceElements.corner1$, .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.annotSize
        endif

    else
        # ==============================================================
        # GROUPED PATH
        # ==============================================================

        @emlCountGroups: .objectId, .groupCol$
        .nGroups = emlCountGroups.nGroups

        if .nGroups > 10
            appendInfoLine: "WARNING: " + string$ (.nGroups) + " groups detected. Only first 10 will be plotted."
            appendInfoLine: "  (Scatter plot supports a maximum of 10 groups.)"
            .nGroups = 10
        endif
        @emlOptimizePaletteContrast: .nGroups

        # Set up legend (use line$ for visual weight match with dots)
        legendN = .nGroups
        for .g from 1 to .nGroups
            .colorIdx = (((.g - 1) mod 10) + 1)
            legendColor$[.g] = emlSetColorPalette.line$[.colorIdx]
            @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor

        # Plot all points (color by group)
        if scatterShowDots = 1
            for .i from 1 to .nRows
                selectObject: .objectId
                .xVal = Get value: .i, .colX$
                .yVal = Get value: .i, .colY$
                if .xVal <> undefined and .yVal <> undefined
                    .grp$ = Get value: .i, .groupCol$
                    .gIdx = 1
                    for .g from 1 to .nGroups
                        if emlCountGroups.groupLabel$[.g] = .grp$
                            .gIdx = .g
                        endif
                    endfor
                    .colorIdx = (((.gIdx - 1) mod 10) + 1)
                    if .useAlpha = 1 and emlInitAlphaSprites.available = 1
                        @emlDrawAlphaDot: .xVal, .yVal, .gIdx, .colorMode$, .alphaLevel$, .pointColor$[.colorIdx]
                    else
                        Paint circle: .pointColor$[.colorIdx], .xVal, .yVal, .radiusWorld
                    endif
                endif
            endfor
        endif

        # Per-group correlations and regression lines
        # Per-group statistics and regression lines
        if .annotate = 1 or scatterRegressionLine = 1
            if annotCorrType$ <> "" or scatterRegressionLine = 1
                appendInfoLine: ""
                appendInfoLine: "Per-group results:"
            endif

            for .g from 1 to .nGroups
                # Extract this group's x/y data
                .gN = 0
                .gXData# = zero# (.nRows)
                .gYData# = zero# (.nRows)
                for .i from 1 to .nRows
                    selectObject: .objectId
                    .grp$ = Get value: .i, .groupCol$
                    if .grp$ = emlCountGroups.groupLabel$[.g]
                        .xVal = Get value: .i, .colX$
                        .yVal = Get value: .i, .colY$
                        if .xVal <> undefined and .yVal <> undefined
                            .gN = .gN + 1
                            .gXData#[.gN] = .xVal
                            .gYData#[.gN] = .yVal
                        endif
                    endif
                endfor

                @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
                .groupDispLabel$ = emlSanitizeLabel.result$

                if .gN >= 3
                    # Trim vectors
                    .gXTrim# = zero# (.gN)
                    .gYTrim# = zero# (.gN)
                    for .j from 1 to .gN
                        .gXTrim#[.j] = .gXData#[.j]
                        .gYTrim#[.j] = .gYData#[.j]
                    endfor

                    .gHavePearson = 0
                    .gPearsonR = 0

                    # --- Per-group Pearson (annotation) ---
                    if .annotate = 1
                        .gPearsonP = 0
                        if annotCorrType$ = "pearson" or annotCorrType$ = "both"
                            @emlPearsonCorrelation: .gXTrim#, .gYTrim#, 2
                            if emlPearsonCorrelation.error$ = ""
                                .gHavePearson = 1
                                .gPearsonR = emlPearsonCorrelation.r
                                .gPearsonP = emlPearsonCorrelation.p

                                @emlFormatAnnotLabel: .gPearsonP, 0, annotStyle$, 0, ""
                                .pText$ = emlFormatAnnotLabel.result$
                                appendInfoLine: "  " + .groupDispLabel$ + ": r = " + fixed$ (.gPearsonR, 3) + ", " + .pText$ + " (n = " + string$ (.gN) + ")"

                                annotBlockN = annotBlockN + 1
                                annotBlockLabel$[annotBlockN] = .groupDispLabel$ + ": r = " + fixed$ (.gPearsonR, 3) + ", " + .pText$
                                annotBlockDraw$[annotBlockN] = .groupDispLabel$ + ": %r = " + fixed$ (.gPearsonR, 3) + ", " + .pText$
                            endif
                        endif

                        # --- Per-group Spearman (annotation) ---
                        if annotCorrType$ = "spearman" or annotCorrType$ = "both"
                            @emlSpearmanCorrelation: .gXTrim#, .gYTrim#, 2
                            if emlSpearmanCorrelation.error$ = ""
                                .gSpearmanR = emlSpearmanCorrelation.rho
                                .gSpearmanP = emlSpearmanCorrelation.p

                                @emlFormatAnnotLabel: .gSpearmanP, 0, annotStyle$, 0, ""
                                .pText$ = emlFormatAnnotLabel.result$
                                appendInfoLine: "  " + .groupDispLabel$ + ": rs = " + fixed$ (.gSpearmanR, 3) + ", " + .pText$ + " (n = " + string$ (.gN) + ")"

                                annotBlockN = annotBlockN + 1
                                annotBlockLabel$[annotBlockN] = .groupDispLabel$ + ": rs = " + fixed$ (.gSpearmanR, 3) + ", " + .pText$
                                annotBlockDraw$[annotBlockN] = .groupDispLabel$ + ": %%r%_s = " + fixed$ (.gSpearmanR, 3) + ", " + .pText$
                            endif
                        endif
                    endif

                    # --- Per-group regression line (independent of annotate) ---
                    if scatterRegressionLine = 1
                        # Ensure Pearson r for line
                        if .gHavePearson = 0
                            @emlPearsonCorrelation: .gXTrim#, .gYTrim#, 2
                            if emlPearsonCorrelation.error$ = ""
                                .gPearsonR = emlPearsonCorrelation.r
                            endif
                        endif

                        .gMeanX = mean (.gXTrim#)
                        .gMeanY = mean (.gYTrim#)
                        .gSdX = stdev (.gXTrim#)
                        .gSdY = stdev (.gYTrim#)

                        if .gSdX > 0
                            .gSlope = .gPearsonR * (.gSdY / .gSdX)
                            .gIntercept = .gMeanY - .gSlope * .gMeanX

                            # Data extent for this group
                            .gXMin = .gXTrim#[1]
                            .gXMax = .gXTrim#[1]
                            for .j from 2 to .gN
                                if .gXTrim#[.j] < .gXMin
                                    .gXMin = .gXTrim#[.j]
                                endif
                                if .gXTrim#[.j] > .gXMax
                                    .gXMax = .gXTrim#[.j]
                                endif
                            endfor

                            # Draw in group's palette color
                            .colorIdx = (((.g - 1) mod 10) + 1)
                            @emlDrawRegressionLine: .gXMin, .gXMax, .gSlope, .gIntercept, .axisYMin, .axisYMax, emlSetColorPalette.line$[.colorIdx]

                            # Formula to Info window always
                            appendInfoLine: "  " + .groupDispLabel$ + ": y = " + fixed$ (.gSlope, 4) + "x + " + fixed$ (.gIntercept, 4)

                            # Formula on graph if requested (independent of annotate)
                            if scatterShowFormula = 1
                                annotBlockN = annotBlockN + 1
                                annotBlockLabel$[annotBlockN] = .groupDispLabel$ + ": y = " + fixed$ (.gSlope, 4) + "x + " + fixed$ (.gIntercept, 4)
                                annotBlockDraw$[annotBlockN] = .groupDispLabel$ + ": %y = " + fixed$ (.gSlope, 4) + "%x + " + fixed$ (.gIntercept, 4)
                            endif
                        endif
                    endif
                else
                    if annotCorrType$ <> "" or scatterRegressionLine = 1
                        appendInfoLine: "  " + .groupDispLabel$ + ": too few points (n = " + string$ (.gN) + ")"
                    endif
                endif
            endfor
        endif

        # Place annotation block and legend — adaptive corner selection
        .xMidQ = (.axisXMin + .axisXMax) / 2
        .yMidQ = (.axisYMin + .axisYMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .qi from 1 to .nValid
            if .yData#[.qi] >= .yMidQ
                if .xData#[.qi] < .xMidQ
                    .qTL = .qTL + 1
                else
                    .qTR = .qTR + 1
                endif
            else
                if .xData#[.qi] < .xMidQ
                    .qBL = .qBL + 1
                else
                    .qBR = .qBR + 1
                endif
            endif
        endfor

        if annotBlockN > 0
            @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 2
            @emlDrawAnnotationBlock: emlPlaceElements.corner1$, .axisXMin, .axisXMax, .axisYMin, .axisYMax, emlSetAdaptiveTheme.annotSize
            .legendCorner$ = emlPlaceElements.corner2$
        else
            @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1
            .legendCorner$ = emlPlaceElements.corner1$
        endif
        @emlDrawLegend: .axisXMin, .axisXMax, .axisYMin, .axisYMax, .legendCorner$, emlSetAdaptiveTheme.annotSize
    endif

    # Step 8: Axes
    @emlDrawAxes: .axisXMin, .axisXMax, .axisYMin, .axisYMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH

    # Step 9: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# @emlDrawBoxPlot
# ============================================================================
# Draws a grouped box-and-whisker plot with Tukey whiskers and outlier dots.
# Follows the same data extraction pattern as @emlDrawViolinPlot.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawBoxPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax

    # Step 1: Set up theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Extract groups and data
    selectObject: .objectId
    .nRows = Get number of rows

    .nGroups = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisGroup$ = Get value: .i, .groupCol$

        .found = 0
        for .g from 1 to .nGroups
            if .thisGroup$ = .uniqueGroup$[.g]
                .found = 1
            endif
        endfor

        if .found = 0
            .nGroups = .nGroups + 1
            .uniqueGroup$[.nGroups] = .thisGroup$
        endif
    endfor

    @emlOptimizePaletteContrast: .nGroups

    # Step 3: Extract per-group values
    for .g from 1 to .nGroups
        .groupCount'.g' = 0
    endfor

    for .i from 1 to .nRows
        selectObject: .objectId
        .thisGroup$ = Get value: .i, .groupCol$
        .val$ = Get value: .i, .valueCol$
        .thisVal = number (.val$)

        for .g from 1 to .nGroups
            if .thisGroup$ = .uniqueGroup$[.g]
                .groupCount'.g' = .groupCount'.g' + 1
                .c = .groupCount'.g'
                .groupData'.g'_'.c' = .thisVal
            endif
        endfor
    endfor

    # Step 4: Compute y-axis range (both 0 = auto)
    .globalMin = undefined
    .globalMax = undefined
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        for .k from 1 to .n
            .val = .groupData'.g'_'.k'
            if .globalMin = undefined
                .globalMin = .val
                .globalMax = .val
            else
                if .val < .globalMin
                    .globalMin = .val
                endif
                if .val > .globalMax
                    .globalMax = .val
                endif
            endif
        endfor
    endfor
    @emlComputeAxisRange: .globalMin, .globalMax, 10, 0
    .autoYMin = emlComputeAxisRange.axisMin
    .autoYMax = emlComputeAxisRange.axisMax

    if .vMin = 0 and .vMax = 0
        .yMin = .autoYMin
        .yMax = .autoYMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 5: Set x-axis range
    .xMin = 0.5
    .xMax = .nGroups + 0.5

    # Step 6: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 7: Draw horizontal gridlines (if requested)
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 8: Draw each box
    for .g from 1 to .nGroups
        .n = .groupCount'.g'
        .data# = zero# (.n)
        for .k from 1 to .n
            .data#[.k] = .groupData'.g'_'.k'
        endfor

        .colorIdx = (((.g - 1) mod 10) + 1)

        @emlDrawBox: .g, .data#, emlSetColorPalette.fill$[.colorIdx], emlSetColorPalette.line$[.colorIdx], .yMin, .yMax, 0.25
    endfor

    # Step 8B: Jittered points overlay
    if variableExists ("prev_boxShowJitter")
        if prev_boxShowJitter = 1
            for .g from 1 to .nGroups
                .n = .groupCount'.g'
                jitterData# = zero# (.n)
                for .k from 1 to .n
                    jitterData#[.k] = .groupData'.g'_'.k'
                endfor
                .colorIdx = (((.g - 1) mod 10) + 1)
                @emlDrawJitteredPoints: .g, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.5, 0.12
            endfor
        endif
    endif

    # Expose axis ranges for annotation bridge
    .axisXMin = 0.5
    .axisXMax = .nGroups + 0.5
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 9: Draw axes with group labels
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Group labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nGroups, .axisXMin, .axisXMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Step 10: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc


# ============================================================================
# @emlDrawHistogram
# ============================================================================
# Draws a histogram from Table data with optional grouped display.
# Grouped modes: overlap (alpha-composited bars) or side-by-side.
# Auto-bins via Sturges formula when binCount = 0.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawHistogram: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .valueCol$, .groupCol$, .binCount, .displayMode, .vMin, .vMax, .freqMax

    # Step 1: Theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Read all data
    selectObject: .objectId
    .nRows = Get number of rows
    .allData# = zero# (.nRows)
    .nValid = 0

    for .i from 1 to .nRows
        selectObject: .objectId
        .val = Get value: .i, .valueCol$
        if .val <> undefined
            .nValid = .nValid + 1
            .allData#[.nValid] = .val
        endif
    endfor

    if .nValid < 1
        appendInfoLine: "WARNING: No valid data for histogram."
        goto HIST_END
    endif

    # Trim to valid
    .trimData# = zero# (.nValid)
    for .i from 1 to .nValid
        .trimData#[.i] = .allData#[.i]
    endfor

    # Step 3: Compute data range
    .dataMin = .trimData#[1]
    .dataMax = .trimData#[1]
    for .i from 2 to .nValid
        if .trimData#[.i] < .dataMin
            .dataMin = .trimData#[.i]
        endif
        if .trimData#[.i] > .dataMax
            .dataMax = .trimData#[.i]
        endif
    endfor

    # Value axis range
    if .vMin = 0 and .vMax = 0
        .xMin = .dataMin
        .xMax = .dataMax
    else
        .xMin = .vMin
        .xMax = .vMax
    endif

    # Step 4: Compute bins
    if .binCount <= 0
        # Sturges formula
        .nBins = ceiling (1 + 3.322 * log10 (.nValid))
        if .nBins < 3
            .nBins = 3
        endif
    else
        .nBins = .binCount
    endif

    .binWidth = (.xMax - .xMin) / .nBins

    # Guard: zero range
    if .binWidth <= 0
        .binWidth = 1
        .nBins = 1
        .xMax = .xMin + 1
    endif

    # Step 5: Determine grouping
    .hasGroups = 0
    .nGroups = 1
    if .groupCol$ <> ""
        .hasGroups = 1
        @emlCountGroups: .objectId, .groupCol$
        .nGroups = emlCountGroups.nGroups
        if .nGroups > 10
            appendInfoLine: "WARNING: " + string$ (.nGroups) + " groups. Only first 10 plotted."
            .nGroups = 10
        endif
    endif

    if .hasGroups = 1
        @emlOptimizePaletteContrast: .nGroups
    endif

    # Step 6: Count per bin (per group if grouped)
    .maxFreq = 0

    for .g from 1 to .nGroups
        for .b from 1 to .nBins
            .count'.g'_'.b' = 0
        endfor
    endfor

    for .i from 1 to .nRows
        selectObject: .objectId
        .val = Get value: .i, .valueCol$
        if .val <> undefined and .val >= .xMin and .val <= .xMax
            .b = floor ((.val - .xMin) / .binWidth) + 1
            if .b > .nBins
                .b = .nBins
            endif
            if .b < 1
                .b = 1
            endif

            if .hasGroups
                .grp$ = Get value: .i, .groupCol$
                .gIdx = 1
                for .g from 1 to .nGroups
                    if emlCountGroups.groupLabel$[.g] = .grp$
                        .gIdx = .g
                    endif
                endfor
            else
                .gIdx = 1
            endif

            .count'.gIdx'_'.b' = .count'.gIdx'_'.b' + 1
        endif
    endfor

    # Find max frequency
    for .g from 1 to .nGroups
        for .b from 1 to .nBins
            if .count'.g'_'.b' > .maxFreq
                .maxFreq = .count'.g'_'.b'
            endif
        endfor
    endfor

    # Step 7: Y-axis range
    if .freqMax = 0
        @emlComputeAxisRange: 0, .maxFreq, 5, 0
        .yMin = 0
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = 0
        .yMax = .freqMax
    endif

    # Step 8: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 9–10: Gridlines and data drawing (branched by display mode)
    if .hasGroups and .displayMode = 2
        # === FACETED (vertically stacked panels, shared x + y axes) ===
        .innerL = emlSetAdaptiveTheme.innerLeft
        .innerR = emlSetAdaptiveTheme.innerRight
        .innerT = emlSetAdaptiveTheme.innerTop
        .innerB = emlSetAdaptiveTheme.innerBottom
        .totalInnerH = .innerB - .innerT
        .panelGap = 0.15
        .panelH = (.totalInnerH - (.nGroups - 1) * .panelGap) / .nGroups

        # Shared y-axis: global max across all groups
        .sharedYMax = 0
        for .g from 1 to .nGroups
            for .b from 1 to .nBins
                if .count'.g'_'.b' > .sharedYMax
                    .sharedYMax = .count'.g'_'.b'
                endif
            endfor
        endfor
        if .freqMax > 0
            .sharedYMax = .freqMax
        elsif .sharedYMax = 0
            .sharedYMax = 1
        else
            @emlComputeAxisRange: 0, .sharedYMax, 5, 0
            .sharedYMax = emlComputeAxisRange.axisMax
        endif

        # Per-facet tick count (based on panel height, not full canvas)
        .facetTicksY = max (2, min (7, round (.panelH / 0.5)))

        for .g from 1 to .nGroups
            .panelTop = .innerT + (.g - 1) * (.panelH + .panelGap)
            .panelBot = .panelTop + .panelH

            # Panel viewport and content at annotSize (one tier below body)
            .facetBodySize = emlSetAdaptiveTheme.annotSize
            Font size: .facetBodySize
            Select inner viewport: .innerL, .innerR, .panelTop, .panelBot
            Axes: .xMin, .xMax, 0, .sharedYMax

            # Gridlines (horizontal only — categorical per panel)
            # gridMode: 1=Horizontal, 2=Off
            if .gridMode = 1
                @emlDrawHorizontalGridlines: .xMin, .xMax, 0, .sharedYMax, .facetTicksY, emlSetAdaptiveTheme.useMinorTicks
            endif

            # Bars
            .colorIdx = (((.g - 1) mod 10) + 1)
            for .b from 1 to .nBins
                .barLeft = .xMin + (.b - 1) * .binWidth
                .barRight = .barLeft + .binWidth
                .barTop = .count'.g'_'.b'
                if .barTop > 0
                    .clamped = min (.barTop, .sharedYMax)
                    Paint rectangle: emlSetColorPalette.fill$[.colorIdx], .barLeft, .barRight, 0, .clamped
                    Colour: emlSetColorPalette.line$[.colorIdx]
                    Line width: 0.6
                    Draw rectangle: .barLeft, .barRight, 0, .clamped
                endif
            endfor

            # Panel frame and y-axis (facetBodySize — matches panel viewport)
            Colour: emlSetAdaptiveTheme.axisColor$
            Line width: emlSetAdaptiveTheme.axisLineWidth
            if emlShowInnerBox = 1
                Draw inner box
            endif
            @emlDrawAlignedMarksLeft: 0, .sharedYMax, .facetTicksY, emlSetAdaptiveTheme.useMinorTicks

            # X-axis ticks only on bottom panel (facetBodySize)
            if .g = .nGroups
                @emlDrawAlignedMarksBottom: .xMin, .xMax,
                ... emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
            endif

            # Group label — left margin, rotated 90° (reading bottom-to-top)
            # Truncate if label exceeds panel height
            Font size: emlSetAdaptiveTheme.bodySize
            Colour: emlSetAdaptiveTheme.textColor$
            @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
            .panelLabel$ = emlSanitizeLabel.result$

            # Measure text width in inches (becomes vertical extent at 90°)
            # Text width is in x-world-coords; convert to inches via panel width
            .xRange = .xMax - .xMin
            .panelWInches = .innerR - .innerL
            .labelWC = Text width (world coordinates): .panelLabel$
            .labelInches = .labelWC * (.panelWInches / .xRange)
            # Available vertical = panel height × 85%
            .maxLabelInches = .panelH * 0.85
            if .labelInches > .maxLabelInches and .maxLabelInches > 0
                # Convert inch limit back to world coordinates for measurement
                .maxLabelWC = .maxLabelInches * (.xRange / .panelWInches)
                # Truncate with binary search
                .lo = 1
                .hi = length (.panelLabel$)
                .origLabel$ = .panelLabel$
                while .lo < .hi - 1
                    .mid = round ((.lo + .hi) / 2)
                    .tryLabel$ = left$ (.origLabel$, .mid) + "…"
                    .tryW = Text width (world coordinates): .tryLabel$
                    if .tryW <= .maxLabelWC
                        .lo = .mid
                    else
                        .hi = .mid
                    endif
                endwhile
                .panelLabel$ = left$ (.origLabel$, .lo) + "…"
            endif

            Text left: "yes", .panelLabel$
        endfor

        # Full viewport for shared axis labels at bodySize
        Font size: emlSetAdaptiveTheme.bodySize
        Select inner viewport: .innerL, .innerR, .innerT, .innerB
        Axes: .xMin, .xMax, .yMin, .yMax

    else
        # === NON-FACETED (ungrouped or overlap) ===

        # Gridlines
        # gridMode: 1=Both, 2=Horizontal only, 3=Vertical only, 4=Off
        if .gridMode = 1
            @emlDrawGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
        elsif .gridMode = 2
            @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
        elsif .gridMode = 3
            @emlDrawVerticalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks
        endif

        # Bars
        if .hasGroups = 0
            # === UNGROUPED ===
            for .b from 1 to .nBins
                .barLeft = .xMin + (.b - 1) * .binWidth
                .barRight = .barLeft + .binWidth
                .barTop = .count1_'.b'

                if .barTop > 0
                    .clamped = min (.barTop, .yMax)
                    Paint rectangle: emlSetColorPalette.fill$[1], .barLeft, .barRight, 0, .clamped
                    Colour: emlSetColorPalette.line$[1]
                    Line width: 0.6
                    Draw rectangle: .barLeft, .barRight, 0, .clamped
                endif
            endfor
        else
            # === OVERLAP (alpha) ===
            for .b from 1 to .nBins
                .barLeft = .xMin + (.b - 1) * .binWidth
                .barRight = .barLeft + .binWidth

                for .g from 1 to .nGroups
                    .barTop = .count'.g'_'.b'
                    .colorIdx = (((.g - 1) mod 10) + 1)

                    if .barTop > 0
                        .clamped = min (.barTop, .yMax)
                        @emlDrawAlphaRect: .barLeft, .barRight, 0, .clamped, .g, .colorMode$, "a50", emlSetColorPalette.fill$[.colorIdx]
                        Colour: emlSetColorPalette.line$[.colorIdx]
                        Line width: 0.5
                        Draw rectangle: .barLeft, .barRight, 0, .clamped
                    endif
                endfor
            endfor
        endif
    endif

    # Step 11: Legend (if grouped — overlap mode only; faceted uses panel labels)
    if .hasGroups and .displayMode <> 2
        # Quadrant scoring from bin counts
        .xMidQ = (.xMin + .xMax) / 2
        .yMidQ = (.yMin + .yMax) / 2
        .qTL = 0
        .qTR = 0
        .qBL = 0
        .qBR = 0
        for .g from 1 to .nGroups
            for .b from 1 to .nBins
                .binCenter = .xMin + (.b - 0.5) * .binWidth
                .binVal = .count'.g'_'.b'
                if .binVal > 0
                    if .binVal >= .yMidQ
                        if .binCenter < .xMidQ
                            .qTL = .qTL + 1
                        else
                            .qTR = .qTR + 1
                        endif
                    else
                        if .binCenter < .xMidQ
                            .qBL = .qBL + 1
                        else
                            .qBR = .qBR + 1
                        endif
                    endif
                endif
            endfor
        endfor
        @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMidQ, 1

        legendN = .nGroups
        for .g from 1 to .nGroups
            .colorIdx = (((.g - 1) mod 10) + 1)
            legendColor$[.g] = emlSetColorPalette.line$[.colorIdx]
            @emlSanitizeLabel: emlCountGroups.groupLabel$[.g]
            legendLabel$[.g] = emlSanitizeLabel.result$
        endfor
        @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, emlPlaceElements.corner1$, emlSetAdaptiveTheme.annotSize
    endif

    # Step 12: Axes
    if .displayMode <> 2
        @emlDrawAxes: .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpW, .vpH
    else
        # Faceted: draw title and shared axis labels in full viewport
        Font size: emlSetAdaptiveTheme.bodySize
        @emlSetPanelViewport
        Axes: 0, 1, 0, 1
        @emlSanitizeLabel: .title$
        .title$ = emlSanitizeLabel.result$
        @emlDrawTitle: .title$, .vpW, .vpH, 0, 1, 0, 1
        Colour: emlSetAdaptiveTheme.textColor$
        if .yLabel$ <> ""
            if emlShowAxisNameY
                Text left: "yes", .yLabel$
            endif
        endif
        if .xLabel$ <> ""
            if emlShowAxisNameX
                Text bottom: "yes", .xLabel$
            endif
        endif
    endif

    # Expose axis ranges for annotation bridge
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 13: Info
    appendInfoLine: "Histogram: " + string$ (.nBins) + " bins, bin width = " + fixed$ (.binWidth, 4)
    if .hasGroups
        appendInfoLine: "Groups: " + string$ (.nGroups)
    endif

    # Reset
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize

    label HIST_END
endproc


# ============================================================================
# @emlDrawGroupedViolin
# ============================================================================
# Draws a grouped violin plot: categories on x-axis, sub-groups as
# side-by-side violins within each category.
# Example: 5 songs (categories) x 3 platforms (sub-groups) = 15 violins
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawGroupedViolin: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax

    # Step 1: Theme and palette
    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$

    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    # Step 2: Extract unique categories
    selectObject: .objectId
    .nRows = Get number of rows

    .nCats = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCat$ = Get value: .i, .catCol$
        .found = 0
        for .c from 1 to .nCats
            if .thisCat$ = .cat$[.c]
                .found = 1
            endif
        endfor
        if .found = 0
            .nCats = .nCats + 1
            .cat$[.nCats] = .thisCat$
        endif
    endfor

    # Step 3: Extract unique sub-groups
    .nSubs = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisSub$ = Get value: .i, .subCol$
        .found = 0
        for .s from 1 to .nSubs
            if .thisSub$ = .sub$[.s]
                .found = 1
            endif
        endfor
        if .found = 0
            .nSubs = .nSubs + 1
            .sub$[.nSubs] = .thisSub$
        endif
    endfor

    if .nSubs > 10
        appendInfoLine: "WARNING: " + string$ (.nSubs) + " sub-groups. Only first 10 plotted."
        .nSubs = 10
    endif

    @emlOptimizePaletteContrast: .nSubs

    # Step 4: Extract data per category x sub-group
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .cellCount'.c'_'.s' = 0
        endfor
    endfor

    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCat$ = Get value: .i, .catCol$
        .thisSub$ = Get value: .i, .subCol$
        .val$ = Get value: .i, .valueCol$
        .thisVal = number (.val$)

        if .thisVal <> undefined
            .cIdx = 0
            for .c from 1 to .nCats
                if .thisCat$ = .cat$[.c]
                    .cIdx = .c
                endif
            endfor
            .sIdx = 0
            for .s from 1 to .nSubs
                if .thisSub$ = .sub$[.s]
                    .sIdx = .s
                endif
            endfor

            if .cIdx > 0 and .sIdx > 0 and .sIdx <= 10
                .cellCount'.cIdx'_'.sIdx' = .cellCount'.cIdx'_'.sIdx' + 1
                .k = .cellCount'.cIdx'_'.sIdx'
                .cellData'.cIdx'_'.sIdx'_'.k' = .thisVal
            endif
        endif
    endfor

    # Step 5: Compute global y-axis range
    .globalMin = undefined
    .globalMax = undefined
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .globalMin = undefined
                    .globalMin = .val
                    .globalMax = .val
                else
                    if .val < .globalMin
                        .globalMin = .val
                    endif
                    if .val > .globalMax
                        .globalMax = .val
                    endif
                endif
            endfor
        endfor
    endfor

    if .globalMin = undefined
        .globalMin = 0
        .globalMax = 1
    endif

    @emlComputeAxisRange: .globalMin, .globalMax, 10, 0
    .autoYMin = emlComputeAxisRange.axisMin
    .autoYMax = emlComputeAxisRange.axisMax

    if .vMin = 0 and .vMax = 0
        .yMin = .autoYMin
        .yMax = .autoYMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif

    # Step 6: X-axis layout
    .xMin = 0.5
    .xMax = .nCats + 0.5

    # Step 7: Set viewport and axes
    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax

    # Step 8: Gridlines
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    # Step 9: Draw grouped violins
    .slotWidth = 0.82
    .spacing = .slotWidth / .nSubs
    .subViolinWidth = .spacing * 0.4

    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .n = .cellCount'.c'_'.s'
            if .n >= 1
                .data# = zero# (.n)
                for .k from 1 to .n
                    .data#[.k] = .cellData'.c'_'.s'_'.k'
                endfor

                # Sub-violin x-center
                .totalGroupWidth = (.nSubs - 1) * .spacing
                .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing

                .colorIdx = (((.s - 1) mod 10) + 1)
                @emlDrawViolin: .subCenter, .data#, emlSetColorPalette.fill$[.colorIdx], emlSetColorPalette.line$[.colorIdx], .yMin, .yMax, .subViolinWidth
            endif
        endfor
    endfor

    # Step 9B: Jittered points overlay
    if variableExists ("prev_gvShowJitter")
        if prev_gvShowJitter = 1
            for .c from 1 to .nCats
                for .s from 1 to .nSubs
                    .n = .cellCount'.c'_'.s'
                    if .n >= 1
                        jitterData# = zero# (.n)
                        for .k from 1 to .n
                            jitterData#[.k] = .cellData'.c'_'.s'_'.k'
                        endfor
                        .totalGroupWidth = (.nSubs - 1) * .spacing
                        .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing
                        .colorIdx = (((.s - 1) mod 10) + 1)
                        .jitterW = .subViolinWidth * 0.3
                        @emlDrawJitteredPoints: .subCenter, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.4, .jitterW
                    endif
                endfor
            endfor
        endif
    endif

    # Step 10: Legend (by sub-group) — adaptive placement
    .xMid = (.xMin + .xMax) / 2
    .yMid = (.yMin + .yMax) / 2
    .qTL = 0
    .qTR = 0
    .qBL = 0
    .qBR = 0
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .val >= .yMid
                    if .c < .xMid
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .c < .xMid
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endfor
        endfor
    endfor
    @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, 1
    legendN = .nSubs
    for .s from 1 to .nSubs
        .colorIdx = (((.s - 1) mod 10) + 1)
        legendColor$[.s] = emlSetColorPalette.line$[.colorIdx]
        @emlSanitizeLabel: .sub$[.s]
        legendLabel$[.s] = emlSanitizeLabel.result$
    endfor
    @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, emlPlaceElements.corner1$, emlSetAdaptiveTheme.annotSize

    # Step 11: Axes with category labels
    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Category labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nCats, .xMin, .xMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    # Expose axis ranges
    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax

    # Step 12: Reset state
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc



# ============================================================================
# @emlDrawGroupedBoxPlot
# ============================================================================
# Categories on x-axis, sub-groups as side-by-side boxes per category.
# ============================================================================
# Requires: @emlInitDrawingDefaults (or manual global initialization).
# Reads globals: emlPanelOriginX, emlPanelOriginY (via @emlSetAdaptiveTheme).
procedure emlDrawGroupedBoxPlot: .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax

    @emlSetAdaptiveTheme: .vpW, .vpH
    @emlSetColorPalette: .colorMode$
    @emlSanitizeLabel: .title$
    .title$ = emlSanitizeLabel.result$

    selectObject: .objectId
    .nRows = Get number of rows
    .nCats = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCat$ = Get value: .i, .catCol$
        .found = 0
        for .c from 1 to .nCats
            if .thisCat$ = .cat$[.c]
                .found = 1
            endif
        endfor
        if .found = 0
            .nCats = .nCats + 1
            .cat$[.nCats] = .thisCat$
        endif
    endfor

    .nSubs = 0
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisSub$ = Get value: .i, .subCol$
        .found = 0
        for .s from 1 to .nSubs
            if .thisSub$ = .sub$[.s]
                .found = 1
            endif
        endfor
        if .found = 0
            .nSubs = .nSubs + 1
            .sub$[.nSubs] = .thisSub$
        endif
    endfor
    if .nSubs > 10
        appendInfoLine: "WARNING: " + string$ (.nSubs) + " sub-groups. Capping at 10."
        .nSubs = 10
    endif
    @emlOptimizePaletteContrast: .nSubs

    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .cellCount'.c'_'.s' = 0
        endfor
    endfor
    for .i from 1 to .nRows
        selectObject: .objectId
        .thisCat$ = Get value: .i, .catCol$
        .thisSub$ = Get value: .i, .subCol$
        .val$ = Get value: .i, .valueCol$
        .thisVal = number (.val$)
        if .thisVal <> undefined
            .cIdx = 0
            for .c from 1 to .nCats
                if .thisCat$ = .cat$[.c]
                    .cIdx = .c
                endif
            endfor
            .sIdx = 0
            for .s from 1 to .nSubs
                if .thisSub$ = .sub$[.s]
                    .sIdx = .s
                endif
            endfor
            if .cIdx > 0 and .sIdx > 0 and .sIdx <= 10
                .cellCount'.cIdx'_'.sIdx' = .cellCount'.cIdx'_'.sIdx' + 1
                .k = .cellCount'.cIdx'_'.sIdx'
                .cellData'.cIdx'_'.sIdx'_'.k' = .thisVal
            endif
        endif
    endfor

    .globalMin = undefined
    .globalMax = undefined
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .globalMin = undefined
                    .globalMin = .val
                    .globalMax = .val
                else
                    if .val < .globalMin
                        .globalMin = .val
                    endif
                    if .val > .globalMax
                        .globalMax = .val
                    endif
                endif
            endfor
        endfor
    endfor
    if .globalMin = undefined
        .globalMin = 0
        .globalMax = 1
    endif
    @emlComputeAxisRange: .globalMin, .globalMax, 10, 0
    if .vMin = 0 and .vMax = 0
        .yMin = emlComputeAxisRange.axisMin
        .yMax = emlComputeAxisRange.axisMax
    else
        .yMin = .vMin
        .yMax = .vMax
    endif
    .xMin = 0.5
    .xMax = .nCats + 0.5

    @emlSetPanelViewport
    Axes: .xMin, .xMax, .yMin, .yMax
    # gridMode: 1=Horizontal, 2=Off
    if .gridMode = 1
        @emlDrawHorizontalGridlines: .xMin, .xMax, .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks
    endif

    .slotWidth = 0.82
    .spacing = .slotWidth / .nSubs
    .subBoxWidth = .spacing * 0.35
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .n = .cellCount'.c'_'.s'
            if .n >= 1
                .data# = zero# (.n)
                for .k from 1 to .n
                    .data#[.k] = .cellData'.c'_'.s'_'.k'
                endfor
                .totalGroupWidth = (.nSubs - 1) * .spacing
                .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing
                .colorIdx = (((.s - 1) mod 10) + 1)
                @emlDrawBox: .subCenter, .data#, emlSetColorPalette.fill$[.colorIdx], emlSetColorPalette.line$[.colorIdx], .yMin, .yMax, .subBoxWidth
            endif
        endfor
    endfor

    if variableExists ("prev_gbShowJitter")
        if prev_gbShowJitter = 1
            for .c from 1 to .nCats
                for .s from 1 to .nSubs
                    .n = .cellCount'.c'_'.s'
                    if .n >= 1
                        jitterData# = zero# (.n)
                        for .k from 1 to .n
                            jitterData#[.k] = .cellData'.c'_'.s'_'.k'
                        endfor
                        .totalGroupWidth = (.nSubs - 1) * .spacing
                        .subCenter = .c - .totalGroupWidth / 2 + (.s - 1) * .spacing
                        .colorIdx = (((.s - 1) mod 10) + 1)
                        @emlDrawJitteredPoints: .subCenter, emlSetColorPalette.line$[.colorIdx], emlSetAdaptiveTheme.markerSize * 0.4, .subBoxWidth * 0.3
                    endif
                endfor
            endfor
        endif
    endif

    # Quadrant scoring for adaptive legend placement
    .xMid = (.xMin + .xMax) / 2
    .yMid = (.yMin + .yMax) / 2
    .qTL = 0
    .qTR = 0
    .qBL = 0
    .qBR = 0
    for .c from 1 to .nCats
        for .s from 1 to .nSubs
            .n = .cellCount'.c'_'.s'
            for .k from 1 to .n
                .val = .cellData'.c'_'.s'_'.k'
                if .val >= .yMid
                    if .c < .xMid
                        .qTL = .qTL + 1
                    else
                        .qTR = .qTR + 1
                    endif
                else
                    if .c < .xMid
                        .qBL = .qBL + 1
                    else
                        .qBR = .qBR + 1
                    endif
                endif
            endfor
        endfor
    endfor
    @emlPlaceElements: .qTL, .qTR, .qBL, .qBR, .xMid, 1

    legendN = .nSubs
    for .s from 1 to .nSubs
        .colorIdx = (((.s - 1) mod 10) + 1)
        legendColor$[.s] = emlSetColorPalette.line$[.colorIdx]
        @emlSanitizeLabel: .sub$[.s]
        legendLabel$[.s] = emlSanitizeLabel.result$
    endfor
    @emlDrawLegend: .xMin, .xMax, .yMin, .yMax, emlPlaceElements.corner1$, emlSetAdaptiveTheme.annotSize

    @emlDrawInnerBoxIf
    @emlDrawAlignedMarksLeft: .yMin, .yMax, emlSetAdaptiveTheme.targetTicksY, emlSetAdaptiveTheme.useMinorTicks

    # Category labels and x-axis label (pre-measured)
    @emlDrawCategoricalXAxis: .nCats, .xMin, .xMax, .yMin, .yMax, .xLabel$
    if emlShowAxisNameY
        Text left: "yes", .yLabel$
    endif

    @emlDrawTitle: .title$, .vpW, .vpH, .xMin, .xMax, .yMin, .yMax

    .axisXMin = .xMin
    .axisXMax = .xMax
    .axisYMin = .yMin
    .axisYMax = .yMax
    Colour: "Black"
    Line width: 1.0
    Font size: emlSetAdaptiveTheme.bodySize
endproc
