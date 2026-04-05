# ============================================================================
# EML VIBRATO TOOLS — ANALYSIS PROCEDURES LIBRARY
# ============================================================================
# Author: Ian Howell & Theodora Nestorova, Embodied Music Lab
#         www.embodiedmusiclab.com
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Version: 2.0
# Date: 18 March 2026
#
# Vibrato analysis procedures for rate, half-extent, smoothing (Nestorova
# et al. 2024), coefficient of variation time series, and vibrato jitter.
#
# This file lives at: vibrato/eml-vibrato-procedures.praat
# Include from wrapper scripts via: include ../vibrato/eml-vibrato-procedures.praat
#
# Dependencies:
#   ../graphs/eml-graph-procedures.praat (for drawing procedures only)
#
# Procedure index:
#   @emlVibratoScanTextGrid      — scan tier for non-empty intervals
#   @emlVibratoSelectIntervals   — checkbox dialog for interval selection
#   @emlVibratoAxisRange         — compute nice-number axis bounds
#   @emlVibratoAutoFilename      — timestamped filename generation
#   @emlVibratoPitchSetup        — pitch extraction + smoothing + PointProcess
#   @emlVibratoDetectCycles      — peak/trough detection from PointProcess
#   @emlVibratoInsertHalfCycles  — expand table with half-cycle rows
#   @emlVibratoSmooth            — pairwise averaging + rolling window
#   @emlVibratoFilter            — threshold-based include/exclude split
#   @emlVibratoJitter            — vibrato regularity from peak-time PP
#   @emlVibratoSummary           — aggregate statistics
# ============================================================================


# ----------------------------------------------------------------------------
# @emlVibratoScanTextGrid
# Scan tier 1 of a TextGrid for non-empty intervals. Trim whitespace.
#
# Arguments:
#   .textGridId  — TextGrid object ID
#   .tierNum     — tier number to scan (typically 1)
#
# Outputs:
#   .nIntervals          — count of non-empty intervals found (max 30)
#   .label$[1..N]        — trimmed label text
#   .startTime[1..N]     — interval start times
#   .endTime[1..N]       — interval end times
#   .intervalIndex[1..N] — original interval index in tier
#   .overflow            — 1 if more than 30 non-empty intervals found
# ----------------------------------------------------------------------------
procedure emlVibratoScanTextGrid: .textGridId, .tierNum
    selectObject: .textGridId
    .nTotal = Get number of intervals: .tierNum
    .nIntervals = 0
    .overflow = 0

    for .i to .nTotal
        selectObject: .textGridId
        .rawLabel$ = Get label of interval: .tierNum, .i

        # Trim leading whitespace
        .space$ = " "
        repeat
            .startsSpace = startsWith (.rawLabel$, .space$)
            if .startsSpace = 1
                .len = length (.rawLabel$)
                .rawLabel$ = right$ (.rawLabel$, .len - 1)
            endif
        until .startsSpace = 0

        # Trim trailing whitespace
        repeat
            .endsSpace = endsWith (.rawLabel$, .space$)
            if .endsSpace = 1
                .rawLabel$ = .rawLabel$ - .space$
            endif
        until .endsSpace = 0

        # Store non-empty intervals
        if .rawLabel$ <> ""
            if .nIntervals < 30
                .nIntervals += 1
                .label$[.nIntervals] = .rawLabel$
                .startTime[.nIntervals] = Get start time of interval: .tierNum, .i
                .endTime[.nIntervals] = Get end time of interval: .tierNum, .i
                .intervalIndex[.nIntervals] = .i
            else
                .overflow = 1
            endif
        endif
    endfor

    selectObject: .textGridId
endproc


# ----------------------------------------------------------------------------
# @emlVibratoSelectIntervals
# Present checkbox dialog for interval selection.
# Must be called after @emlVibratoScanTextGrid.
#
# Reads from: emlVibratoScanTextGrid.nIntervals, .label$[], .startTime[],
#             .endTime[]
#
# Outputs:
#   .nSelected              — count of selected intervals
#   .selectedLabel$[1..N]   — labels of selected intervals
#   .selectedStart[1..N]    — start times of selected intervals
#   .selectedEnd[1..N]      — end times of selected intervals
#   .quit                   — 1 if user clicked Quit
# ----------------------------------------------------------------------------
procedure emlVibratoSelectIntervals
    .nFound = emlVibratoScanTextGrid.nIntervals
    .quit = 0
    .nSelected = 0

    if .nFound = 0
        .quit = 1
    else
        beginPause: "Select intervals to analyze"
            comment: "Check the intervals you want to analyze."
            comment: ""
            if .nFound >= 1
                boolean: "Interval 1", 1
                comment: "    " + emlVibratoScanTextGrid.label$[1]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[1], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[1], 2)
                ... + " s)"
            endif
            if .nFound >= 2
                boolean: "Interval 2", 1
                comment: "    " + emlVibratoScanTextGrid.label$[2]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[2], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[2], 2)
                ... + " s)"
            endif
            if .nFound >= 3
                boolean: "Interval 3", 1
                comment: "    " + emlVibratoScanTextGrid.label$[3]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[3], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[3], 2)
                ... + " s)"
            endif
            if .nFound >= 4
                boolean: "Interval 4", 1
                comment: "    " + emlVibratoScanTextGrid.label$[4]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[4], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[4], 2)
                ... + " s)"
            endif
            if .nFound >= 5
                boolean: "Interval 5", 1
                comment: "    " + emlVibratoScanTextGrid.label$[5]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[5], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[5], 2)
                ... + " s)"
            endif
            if .nFound >= 6
                boolean: "Interval 6", 1
                comment: "    " + emlVibratoScanTextGrid.label$[6]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[6], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[6], 2)
                ... + " s)"
            endif
            if .nFound >= 7
                boolean: "Interval 7", 1
                comment: "    " + emlVibratoScanTextGrid.label$[7]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[7], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[7], 2)
                ... + " s)"
            endif
            if .nFound >= 8
                boolean: "Interval 8", 1
                comment: "    " + emlVibratoScanTextGrid.label$[8]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[8], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[8], 2)
                ... + " s)"
            endif
            if .nFound >= 9
                boolean: "Interval 9", 1
                comment: "    " + emlVibratoScanTextGrid.label$[9]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[9], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[9], 2)
                ... + " s)"
            endif
            if .nFound >= 10
                boolean: "Interval 10", 1
                comment: "    " + emlVibratoScanTextGrid.label$[10]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[10], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[10], 2)
                ... + " s)"
            endif
            if .nFound >= 11
                boolean: "Interval 11", 1
                comment: "    " + emlVibratoScanTextGrid.label$[11]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[11], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[11], 2)
                ... + " s)"
            endif
            if .nFound >= 12
                boolean: "Interval 12", 1
                comment: "    " + emlVibratoScanTextGrid.label$[12]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[12], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[12], 2)
                ... + " s)"
            endif
            if .nFound >= 13
                boolean: "Interval 13", 1
                comment: "    " + emlVibratoScanTextGrid.label$[13]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[13], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[13], 2)
                ... + " s)"
            endif
            if .nFound >= 14
                boolean: "Interval 14", 1
                comment: "    " + emlVibratoScanTextGrid.label$[14]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[14], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[14], 2)
                ... + " s)"
            endif
            if .nFound >= 15
                boolean: "Interval 15", 1
                comment: "    " + emlVibratoScanTextGrid.label$[15]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[15], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[15], 2)
                ... + " s)"
            endif
            if .nFound >= 16
                boolean: "Interval 16", 1
                comment: "    " + emlVibratoScanTextGrid.label$[16]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[16], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[16], 2)
                ... + " s)"
            endif
            if .nFound >= 17
                boolean: "Interval 17", 1
                comment: "    " + emlVibratoScanTextGrid.label$[17]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[17], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[17], 2)
                ... + " s)"
            endif
            if .nFound >= 18
                boolean: "Interval 18", 1
                comment: "    " + emlVibratoScanTextGrid.label$[18]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[18], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[18], 2)
                ... + " s)"
            endif
            if .nFound >= 19
                boolean: "Interval 19", 1
                comment: "    " + emlVibratoScanTextGrid.label$[19]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[19], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[19], 2)
                ... + " s)"
            endif
            if .nFound >= 20
                boolean: "Interval 20", 1
                comment: "    " + emlVibratoScanTextGrid.label$[20]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[20], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[20], 2)
                ... + " s)"
            endif
            if .nFound >= 21
                boolean: "Interval 21", 1
                comment: "    " + emlVibratoScanTextGrid.label$[21]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[21], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[21], 2)
                ... + " s)"
            endif
            if .nFound >= 22
                boolean: "Interval 22", 1
                comment: "    " + emlVibratoScanTextGrid.label$[22]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[22], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[22], 2)
                ... + " s)"
            endif
            if .nFound >= 23
                boolean: "Interval 23", 1
                comment: "    " + emlVibratoScanTextGrid.label$[23]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[23], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[23], 2)
                ... + " s)"
            endif
            if .nFound >= 24
                boolean: "Interval 24", 1
                comment: "    " + emlVibratoScanTextGrid.label$[24]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[24], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[24], 2)
                ... + " s)"
            endif
            if .nFound >= 25
                boolean: "Interval 25", 1
                comment: "    " + emlVibratoScanTextGrid.label$[25]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[25], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[25], 2)
                ... + " s)"
            endif
            if .nFound >= 26
                boolean: "Interval 26", 1
                comment: "    " + emlVibratoScanTextGrid.label$[26]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[26], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[26], 2)
                ... + " s)"
            endif
            if .nFound >= 27
                boolean: "Interval 27", 1
                comment: "    " + emlVibratoScanTextGrid.label$[27]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[27], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[27], 2)
                ... + " s)"
            endif
            if .nFound >= 28
                boolean: "Interval 28", 1
                comment: "    " + emlVibratoScanTextGrid.label$[28]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[28], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[28], 2)
                ... + " s)"
            endif
            if .nFound >= 29
                boolean: "Interval 29", 1
                comment: "    " + emlVibratoScanTextGrid.label$[29]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[29], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[29], 2)
                ... + " s)"
            endif
            if .nFound >= 30
                boolean: "Interval 30", 1
                comment: "    " + emlVibratoScanTextGrid.label$[30]
                ... + " (" + fixed$ (emlVibratoScanTextGrid.startTime[30], 2)
                ... + " - " + fixed$ (emlVibratoScanTextGrid.endTime[30], 2)
                ... + " s)"
            endif
            if emlVibratoScanTextGrid.overflow = 1
                comment: ""
                comment: "NOTE: More than 30 labeled intervals found. Only the first 30 are shown."
            endif
        .clicked = endPause: "Quit", "Analyze all", "Analyze selected", 3, 0

        if .clicked = 1
            .quit = 1
        elsif .clicked = 2
            # Copy all scanned intervals to selected arrays
            .nSelected = .nFound
            for .i to .nFound
                .selectedLabel$[.i] = emlVibratoScanTextGrid.label$[.i]
                .selectedStart[.i] = emlVibratoScanTextGrid.startTime[.i]
                .selectedEnd[.i] = emlVibratoScanTextGrid.endTime[.i]
            endfor
        elsif .clicked = 3
            # Read back checkbox values
            .nSelected = 0
            if .nFound >= 1 and interval_1 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[1]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[1]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[1]
            endif
            if .nFound >= 2 and interval_2 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[2]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[2]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[2]
            endif
            if .nFound >= 3 and interval_3 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[3]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[3]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[3]
            endif
            if .nFound >= 4 and interval_4 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[4]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[4]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[4]
            endif
            if .nFound >= 5 and interval_5 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[5]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[5]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[5]
            endif
            if .nFound >= 6 and interval_6 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[6]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[6]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[6]
            endif
            if .nFound >= 7 and interval_7 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[7]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[7]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[7]
            endif
            if .nFound >= 8 and interval_8 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[8]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[8]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[8]
            endif
            if .nFound >= 9 and interval_9 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[9]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[9]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[9]
            endif
            if .nFound >= 10 and interval_10 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[10]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[10]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[10]
            endif
            if .nFound >= 11 and interval_11 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[11]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[11]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[11]
            endif
            if .nFound >= 12 and interval_12 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[12]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[12]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[12]
            endif
            if .nFound >= 13 and interval_13 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[13]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[13]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[13]
            endif
            if .nFound >= 14 and interval_14 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[14]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[14]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[14]
            endif
            if .nFound >= 15 and interval_15 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[15]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[15]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[15]
            endif
            if .nFound >= 16 and interval_16 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[16]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[16]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[16]
            endif
            if .nFound >= 17 and interval_17 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[17]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[17]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[17]
            endif
            if .nFound >= 18 and interval_18 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[18]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[18]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[18]
            endif
            if .nFound >= 19 and interval_19 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[19]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[19]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[19]
            endif
            if .nFound >= 20 and interval_20 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[20]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[20]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[20]
            endif
            if .nFound >= 21 and interval_21 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[21]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[21]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[21]
            endif
            if .nFound >= 22 and interval_22 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[22]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[22]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[22]
            endif
            if .nFound >= 23 and interval_23 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[23]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[23]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[23]
            endif
            if .nFound >= 24 and interval_24 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[24]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[24]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[24]
            endif
            if .nFound >= 25 and interval_25 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[25]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[25]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[25]
            endif
            if .nFound >= 26 and interval_26 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[26]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[26]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[26]
            endif
            if .nFound >= 27 and interval_27 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[27]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[27]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[27]
            endif
            if .nFound >= 28 and interval_28 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[28]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[28]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[28]
            endif
            if .nFound >= 29 and interval_29 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[29]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[29]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[29]
            endif
            if .nFound >= 30 and interval_30 = 1
                .nSelected += 1
                .selectedLabel$[.nSelected] = emlVibratoScanTextGrid.label$[30]
                .selectedStart[.nSelected] = emlVibratoScanTextGrid.startTime[30]
                .selectedEnd[.nSelected] = emlVibratoScanTextGrid.endTime[30]
            endif
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlVibratoAxisRange
# Compute axis bounds with nice-number rounding, centered on median.
# Absorbs and replaces axisFindRange.praat / @adjustAxisBoundariesSmart.
# All outputs are procedure-local (no global variable pollution).
#
# Arguments:
#   .min            — data minimum
#   .max            — data maximum
#   .median         — data median
#   .nDivisions     — target number of axis divisions (typically 6)
#   .allowNegative  — 0 to clamp axis min at 0, 1 to allow negatives
#   .expand         — 0 for standard range, 1 for 1.25x expanded range
#
# Outputs:
#   .axisMin        — lower axis bound
#   .axisMax        — upper axis bound
#   .interval       — tick interval
# ----------------------------------------------------------------------------
procedure emlVibratoAxisRange: .min, .max, .median, .nDivisions,
    ... .allowNegative, .expand
    # Compute outlier buffer from median to farthest data point
    .buffer = max (abs (.max - .median), abs (.median - .min))
    .range = .buffer * 2

    # Target interval for nDivisions divisions
    .rawInterval = .range / .nDivisions

    # Round to nice number
    if .rawInterval > 0
        .order = floor (log10 (.rawInterval))
    else
        .order = 0
    endif
    .multiplier = 10 ^ .order
    .interval = ceiling (.rawInterval / .multiplier) * .multiplier

    # Apply expansion factor
    if .expand = 1
        .interval = .interval * 1.25
    endif

    # Compute bounds symmetrically around median
    .halfSpan = .interval * (.nDivisions / 2)
    .axisMin = .median - .halfSpan
    .axisMax = .median + .halfSpan

    # Ensure bounds include all data
    if .axisMin > .min
        .axisMin = floor (.min / .interval) * .interval
    endif
    if .axisMax < .max
        .axisMax = ceiling (.max / .interval) * .interval
    endif

    # Round to whole numbers
    .axisMin = round (.axisMin)
    .axisMax = round (.axisMax)
    .interval = round (.interval)

    # Clamp negatives if not allowed
    if .allowNegative = 0 and .axisMin < 0
        .shift = abs (.axisMin)
        .axisMin += .shift
        .axisMax += .shift
    endif
endproc


# ----------------------------------------------------------------------------
# @emlVibratoAutoFilename
# Generate a timestamped filename.
#
# Arguments:
#   .baseName$   — base name (e.g., audio file name without extension)
#   .suffix$     — descriptor (e.g., "vibrato", "detailed_data")
#   .extension$  — file extension (e.g., "png", "csv")
#
# Outputs:
#   .name$       — complete filename with timestamp
# ----------------------------------------------------------------------------
procedure emlVibratoAutoFilename: .baseName$, .suffix$, .extension$
    .d# = date# ()
    .name$ = .baseName$ + "_" + .suffix$
    ... + "_" + string$ (.d#[2])
    ... + "_" + string$ (.d#[3])
    ... + "_" + string$ (.d#[1])
    ... + "_" + string$ (.d#[4])
    ... + "_" + string$ (.d#[5])
    ... + "_" + string$ (.d#[6])
    ... + "." + .extension$
endproc


# ============================================================================
# CORE ANALYSIS PROCEDURES
# ============================================================================


# ----------------------------------------------------------------------------
# @emlVibratoPitchSetup
# From a mono Sound, create Pitch, smoothed Pitch, and PointProcesses.
#
# Arguments:
#   .soundId      — Sound object ID (must be mono)
#   .lowPitch     — pitch floor (Hz)
#   .highPitch    — pitch top (Hz) — doubled internally for LPF accommodation
#   .interpolate  — 0 or 1
#
# Outputs:
#   .pitchId        — raw Pitch (filtered autocorrelation)
#   .pitchSmoothId  — smoothed Pitch (optionally interpolated first)
#   .ppSmoothId     — PointProcess from smoothed Pitch
#   .ppAudioId      — PointProcess (periodic, peaks) from Sound
#   .lowerPitchST   — floor of minimum pitch in semitones re 440 Hz
#   .higherPitchST  — ceiling of maximum pitch in semitones re 440 Hz
# ----------------------------------------------------------------------------
procedure emlVibratoPitchSetup: .soundId, .lowPitch, .highPitch, .interpolate
    .highPitchDoubled = .highPitch * 2

    # Pitch extraction (filtered autocorrelation, 11 parameters)
    selectObject: .soundId
    To Pitch (filtered autocorrelation): 0, .lowPitch, .highPitchDoubled,
    ... 15, "yes", 0.03, 0.09, 0.5, 0.055, 0.35, 0.14
    .pitchId = selected ()

    # Measure pitch range in semitones for drawing
    .lowerPitchST = Get minimum: 0.0, 0.0, "semitones re 440 Hz", "parabolic"
    .higherPitchST = Get maximum: 0.0, 0.0, "semitones re 440 Hz", "parabolic"
    .lowerPitchST = floor (.lowerPitchST)
    .higherPitchST = ceiling (.higherPitchST)

    # Smoothed pitch (optionally interpolated first)
    selectObject: .pitchId
    if .interpolate = 1
        Interpolate
        .pitchInterp = selected ()
        Smooth: 10
        .pitchSmoothId = selected ()
        removeObject: .pitchInterp
    else
        Smooth: 10
        .pitchSmoothId = selected ()
    endif

    # PointProcess from smoothed pitch (for cycle timing)
    selectObject: .pitchSmoothId
    To PointProcess
    .ppSmoothId = selected ()

    # PointProcess from audio (for precise Hz measurement via periods)
    selectObject: .soundId
    To PointProcess (periodic, peaks): .lowPitch, .highPitchDoubled,
    ... "yes", "no"
    .ppAudioId = selected ()
endproc


# ----------------------------------------------------------------------------
# @emlVibratoDetectCycles
# Walk smoothed PointProcess intervals, detect peaks and troughs via
# 3-neighbor frequency comparison, measure Hz from audio PointProcess.
#
# Arguments:
#   .ppSmoothId     — smoothed pitch PointProcess
#   .ppAudioId      — audio PointProcess (for Hz measurement)
#   .intensityId    — Intensity object
#   .avgIntensity   — mean intensity (dB)
#   .silThreshold   — dB below mean to gate out
#
# Outputs:
#   .tableId        — Table with full column schema
#   .nCycles        — number of detected full cycles (peak-trough pairs)
# ----------------------------------------------------------------------------
procedure emlVibratoDetectCycles: .ppSmoothId, .ppAudioId, .intensityId,
    ... .avgIntensity, .silThreshold

    # Compute interval frequencies from smoothed PointProcess
    selectObject: .ppSmoothId
    .numPoints = Get number of points

    for .i to .numPoints - 1
        selectObject: .ppSmoothId
        .tStart[.i] = Get time from index: .i
        .tEnd = Get time from index: .i + 1
        .iDur[.i] = .tEnd - .tStart[.i]
        .iFreq[.i] = 1 / .iDur[.i]
    endfor

    # Create output table with full column schema
    Create Table with column names: "vibratoAnalysis", 0,
    ... "Cycle# fileName intervalLabel Intensity(dB)"
    ... + " CenterPitch(Hz) CenterPitchRe440(halfsteps)"
    ... + " Peak(Hz) PeakRe440(cents) PeakTime(s)"
    ... + " Trough(Hz) TroughRe440(cents) TroughTime(s)"
    ... + " HalfExtent(cents) Rate(Hz) MidTime(s)"
    ... + " IncludeAveragePairRate PairWiseAveragesRate(Hz) AverageRate(Hz)"
    ... + " IncludeAveragePairHalfExtent PairWiseAveragesHalfExtent(cents)"
    ... + " AverageHalfExtent(cents)"
    ... + " AverageRateForCoV(Hz) CoVTimeSeriesRate(Hz)"
    ... + " AverageHalfExtentForCoV(cents) CoVTimeSeriesHalfExtent(cents)"
    ... + " StDevRate(Hz) StDevHalfExtent(cents)"
    ... + " StDevRateForCoV(Hz) StDevHalfExtentForCoV(cents)"
    .tableId = selected ()
    .nCycles = 0

    .peakCounter = 0
    .troughCounter = 0

    # Scan for peaks and troughs using 3-neighbor comparison
    for .i to .numPoints - 3
        selectObject: .intensityId
        .intCheck = Get value at time: .tStart[.i], "cubic"

        if .intCheck > .avgIntensity - .silThreshold
            # Peak detection: freq[i+1] is local maximum
            if .iFreq[.i + 1] > .iFreq[.i] and .iFreq[.i + 1] > .iFreq[.i + 2]
                .peakCounter += 1
                .peakTime = .tStart[.i + 1]

                # Measure Hz from 3-period average of audio PointProcess
                selectObject: .ppAudioId
                .lowIdx = Get low index: .peakTime
                .highIdx = Get high index: .peakTime

                .lt1 = Get time from index: .lowIdx - 1
                .ht1 = Get time from index: .highIdx - 1
                .lt2 = Get time from index: .lowIdx
                .ht2 = Get time from index: .highIdx
                .lt3 = Get time from index: .lowIdx + 1
                .ht3 = Get time from index: .highIdx + 1

                .peakHz = 1 / (((.ht1 - .lt1) + (.ht2 - .lt2)
                ... + (.ht3 - .lt3)) / 3)

                # Get intensity at peak
                selectObject: .intensityId
                .peakInt = Get value at time: .peakTime, "cubic"

                # Write peak row to table
                selectObject: .tableId
                Append row
                .nRows = Get number of rows
                Set numeric value: .nRows, "Cycle#", .nRows
                Set numeric value: .nRows, "Intensity(dB)", .peakInt
                Set numeric value: .nRows, "Peak(Hz)", .peakHz
                Set numeric value: .nRows, "PeakRe440(cents)",
                ... 1200 * log2 (.peakHz / 440)
                Set numeric value: .nRows, "PeakTime(s)", .peakTime
            endif

            # Trough detection: freq[i+1] is local minimum
            if .iFreq[.i + 1] < .iFreq[.i] and .iFreq[.i + 1] < .iFreq[.i + 2]
                .troughCounter += 1
                .troughTime = .tStart[.i + 1]

                # Measure Hz from 3-period average of audio PointProcess
                selectObject: .ppAudioId
                .lowIdx = Get low index: .troughTime
                .highIdx = Get high index: .troughTime

                .lt1 = Get time from index: .lowIdx - 1
                .ht1 = Get time from index: .highIdx - 1
                .lt2 = Get time from index: .lowIdx
                .ht2 = Get time from index: .highIdx
                .lt3 = Get time from index: .lowIdx + 1
                .ht3 = Get time from index: .highIdx + 1

                .troughHz = 1 / (((.ht1 - .lt1) + (.ht2 - .lt2)
                ... + (.ht3 - .lt3)) / 3)

                # Attach trough to current peak row
                selectObject: .tableId
                .nRows = Get number of rows
                if .nRows > 0
                    Set numeric value: .nRows, "Trough(Hz)", .troughHz
                    Set numeric value: .nRows, "TroughRe440(cents)",
                    ... 1200 * log2 (.troughHz / 440)
                    Set numeric value: .nRows, "TroughTime(s)", .troughTime
                endif
            endif
        endif
    endfor

    selectObject: .tableId
    .nCycles = Get number of rows
endproc


# ----------------------------------------------------------------------------
# @emlVibratoInsertHalfCycles
# Expand table with interleaved 0.5 rows. Compute HalfExtent, Rate,
# CenterPitch, MidTime for all rows.
#
# Arguments:
#   .tableId    — Table from @emlVibratoDetectCycles
#
# Outputs:
#   .tableId    — replaced Table (original removed)
#   .nRows      — row count after expansion
# ----------------------------------------------------------------------------
procedure emlVibratoInsertHalfCycles: .tableId
    selectObject: .tableId
    Copy: "vibratoExpanded"
    .newTableId = selected ()
    .origRows = Get number of rows

    # Insert interleaved half-cycle rows
    for .i to .origRows - 1
        selectObject: .newTableId
        Insert row: .i * 2
        Set numeric value: .i * 2, "Cycle#", .i + 0.5
    endfor

    # Fly peak data forward and trough data backward into half-cycle rows
    selectObject: .newTableId
    .nRows = Get number of rows

    for .i to .origRows - 1
        selectObject: .newTableId
        .rowHalf = .i * 2

        # Copy next peak into this half-cycle row
        .tmpPeak = Get value: .rowHalf + 1, "Peak(Hz)"
        .tmpPeakTime = Get value: .rowHalf + 1, "PeakTime(s)"
        Set numeric value: .rowHalf, "Peak(Hz)", .tmpPeak
        Set numeric value: .rowHalf, "PeakTime(s)", .tmpPeakTime

        # Copy previous trough into this half-cycle row
        .tmpTrough = Get value: .rowHalf - 1, "Trough(Hz)"
        .tmpTroughTime = Get value: .rowHalf - 1, "TroughTime(s)"
        Set numeric value: .rowHalf, "Trough(Hz)", .tmpTrough
        Set numeric value: .rowHalf, "TroughTime(s)", .tmpTroughTime
    endfor

    # Compute cents for half-cycle rows (integer rows already have them)
    for .i to .nRows
        selectObject: .newTableId
        .cycleVal = Get value: .i, "Cycle#"
        if .cycleVal mod 1 <> 0 or .i > 1
            .tmpPeak = Get value: .i, "Peak(Hz)"
            .tmpTrough = Get value: .i, "Trough(Hz)"
            if .tmpPeak > 0 and .tmpTrough > 0
                Set numeric value: .i, "PeakRe440(cents)",
                ... 1200 * log2 (.tmpPeak / 440)
                Set numeric value: .i, "TroughRe440(cents)",
                ... 1200 * log2 (.tmpTrough / 440)
            endif
            .tmpTroughTime = Get value: .i, "TroughTime(s)"
            if .tmpTroughTime > 0
                selectObject: .newTableId
                Set numeric value: .i, "Intensity(dB)", 0
                # Intensity will be updated by caller if needed
            endif
        endif
    endfor

    # Compute HalfExtent and Rate using Formula (vectorized)
    selectObject: .newTableId
    Formula: "HalfExtent(cents)",
    ... ~(self["PeakRe440(cents)"] - self["TroughRe440(cents)"]) / 2
    Formula: "Rate(Hz)",
    ... ~(1 / (abs (self["PeakTime(s)"] - self["TroughTime(s)"]))) / 2

    # Compute MidTime
    for .i to .nRows
        selectObject: .newTableId
        .tmpPeakTime = Get value: .i, "PeakTime(s)"
        .tmpTroughTime = Get value: .i, "TroughTime(s)"
        .tmpHalfDur = abs (.tmpPeakTime - .tmpTroughTime)
        if .tmpPeakTime < .tmpTroughTime
            Set numeric value: .i, "MidTime(s)", .tmpPeakTime + .tmpHalfDur
        else
            Set numeric value: .i, "MidTime(s)", .tmpTroughTime + .tmpHalfDur
        endif
    endfor

    # Compute CenterPitch: trough + halfExtent in cents domain, then to Hz
    for .i to .nRows
        selectObject: .newTableId
        .tmpTroughCents = Get value: .i, "TroughRe440(cents)"
        .tmpHE = Get value: .i, "HalfExtent(cents)"
        .centerCents = .tmpTroughCents + .tmpHE
        Set numeric value: .i, "CenterPitch(Hz)",
        ... 2 ^ (.centerCents / 1200) * 440
        Set numeric value: .i, "CenterPitchRe440(halfsteps)",
        ... .centerCents / 100
    endfor

    # Clean up: remove original, update .tableId
    removeObject: .tableId
    .tableId = .newTableId
endproc


# ----------------------------------------------------------------------------
# @emlVibratoSmooth
# Pairwise averaging with continuity tracking, rolling window smoothing,
# and CoV time series. Implements Nestorova et al. 2024 method.
#
# Arguments:
#   .tableId     — expanded Table from @emlVibratoInsertHalfCycles
#   .avgCycles   — smoothing window in vibrato cycles
#   .lowRate     — low credible rate (Hz) for filtering before smoothing
#   .highRate    — high credible rate (Hz) for filtering before smoothing
#
# Outputs:
#   (columns modified in place on .tableId)
#   Returns .tableId of the smoothed+filtered table (rows with
#   PairWiseAveragesRate > 0 extracted)
# ----------------------------------------------------------------------------
procedure emlVibratoSmooth: .tableId, .avgCycles, .lowRate, .highRate
    selectObject: .tableId

    # Filter to credible rate range and positive half-extent
    Extract rows where:
    ... ~self["Rate(Hz)"] < .highRate and self["Rate(Hz)"] > .lowRate
    ... and self["HalfExtent(cents)"] > 0
    .smoothTable = selected ()
    Rename: "Smoothing"

    # Process both Rate and HalfExtent
    for .k to 2
        selectObject: .smoothTable
        if .k = 1
            .tag$ = "Rate(Hz)"
            .tmpTag$ = "Rate"
        elsif .k = 2
            .tag$ = "HalfExtent(cents)"
            .tmpTag$ = "HalfExtent"
        endif

        .numRows = Get number of rows

        # --- Step 1: Label continuity (S/Y/E/X) ---
        .firstCycle = Get value: 1, "Cycle#"
        .firstCyclePlus = Get value: 2, "Cycle#"
        .lastCycle = Get value: .numRows, "Cycle#"
        .lastCycleMinus = Get value: .numRows - 1, "Cycle#"

        if .firstCycle + 0.5 = .firstCyclePlus
            Set string value: 1, "IncludeAveragePair" + .tmpTag$, "S"
        endif

        if .lastCycle - 0.5 = .lastCycleMinus
            Set string value: .numRows, "IncludeAveragePair" + .tmpTag$, "E"
        endif

        for .i from 2 to .numRows - 1
            selectObject: .smoothTable
            .cM1 = Get value: .i - 1, "Cycle#"
            .c0 = Get value: .i, "Cycle#"
            .cP1 = Get value: .i + 1, "Cycle#"

            if .cM1 + 0.5 = .c0 and .c0 + 0.5 = .cP1
                Set string value: .i, "IncludeAveragePair" + .tmpTag$, "Y"
            elsif .cM1 + 0.5 <> .c0 and .c0 + 0.5 = .cP1
                Set string value: .i, "IncludeAveragePair" + .tmpTag$, "S"
            elsif .cM1 + 0.5 = .c0 and .c0 + 0.5 <> .cP1
                Set string value: .i, "IncludeAveragePair" + .tmpTag$, "E"
            elsif .cM1 + 0.5 <> .c0 and .c0 + 0.5 <> .cP1
                Set string value: .i, "IncludeAveragePair" + .tmpTag$, "X"
            endif
        endfor

        # --- Step 2: Pairwise averages ---
        for .i from 2 to .numRows
            selectObject: .smoothTable
            .val1$ = Get value: .i - 1, "IncludeAveragePair" + .tmpTag$
            .val2$ = Get value: .i, "IncludeAveragePair" + .tmpTag$
            .isPair = (.val1$ = "S" or .val1$ = "Y")
            ... and (.val2$ = "Y" or .val2$ = "E")

            if .isPair = 1
                .r1 = Get value: .i - 1, .tag$
                .r2 = Get value: .i, .tag$
                Set numeric value: .i, "PairWiseAverages" + .tag$,
                ... (.r1 + .r2) / 2
            endif
        endfor

        # --- Step 3: Rolling window average ---
        .windowSize = .avgCycles * 2
        for .i from .avgCycles + 1 to .numRows - .avgCycles
            selectObject: .smoothTable
            .pwValues# = zero# (.windowSize)
            .pwLetters$# = empty$# (.windowSize)

            for .p to .windowSize
                .pwLetters$#[.p] = Get value: .p - 1 + .i - .avgCycles,
                ... "IncludeAveragePair" + .tmpTag$
                .pwValues#[.p] = Get value: .p - 1 + .i - .avgCycles,
                ... "PairWiseAverages" + .tag$
            endfor

            # Check for X (gap) in window
            .noX = 1
            .counter = 0
            repeat
                .counter += 1
                if .pwLetters$#[.counter] = "X"
                    .noX = 0
                endif
            until .noX = 0 or .counter = size (.pwLetters$#)

            if .noX = 1
                .tmpAvg = mean (.pwValues#)
                .tmpStd = stdev (.pwValues#)
                if .tmpAvg > 0
                    Set numeric value: .i, "Average" + .tag$, .tmpAvg
                    Set numeric value: .i, "StDev" + .tag$, .tmpStd
                endif
            endif
        endfor

        # --- Step 4: CoV time series (fixed 3-cycle window) ---
        if .k = 1
            .covTag$ = "RateForCoV(Hz)"
            .covIncludeTag$ = "Rate"
            .covPairTag$ = "Rate(Hz)"
        elsif .k = 2
            .covTag$ = "HalfExtentForCoV(cents)"
            .covIncludeTag$ = "HalfExtent"
            .covPairTag$ = "HalfExtent(cents)"
        endif

        .covWindow = 3 * 2
        for .i from 4 to .numRows - 3
            selectObject: .smoothTable
            .cvValues# = zero# (.covWindow)
            .cvLetters$# = empty$# (.covWindow)

            for .p to .covWindow
                .cvLetters$#[.p] = Get value: .p - 1 + .i - 3,
                ... "IncludeAveragePair" + .covIncludeTag$
                .cvValues#[.p] = Get value: .p - 1 + .i - 3,
                ... "PairWiseAverages" + .covPairTag$
            endfor

            .noX = 1
            .counter = 0
            repeat
                .counter += 1
                if .cvLetters$#[.counter] = "X"
                    .noX = 0
                endif
            until .noX = 0 or .counter = size (.cvLetters$#)

            if .noX = 1
                .tmpAvg = mean (.cvValues#)
                .tmpStd = stdev (.cvValues#)
                if .tmpAvg > 0
                    Set numeric value: .i, "Average" + .covTag$, .tmpAvg
                    Set numeric value: .i, "StDev" + .covTag$, .tmpStd
                endif
            endif
        endfor

        # Compute CoV as percentage
        selectObject: .smoothTable
        Formula: "CoVTimeSeries" + .covPairTag$,
        ... ~(self["StDev" + .covTag$] / self["Average" + .covTag$]) * 100
    endfor

    # Extract rows with valid pairwise rate data
    selectObject: .smoothTable
    Extract rows where: ~self["PairWiseAveragesRate(Hz)"] > 0
    .resultTable = selected ()

    removeObject: .smoothTable
    .tableId = .resultTable
endproc


# ----------------------------------------------------------------------------
# @emlVibratoFilter
# Split table into included/excluded sub-tables by credibility thresholds.
#
# Arguments:
#   .tableId      — smoothed Table
#   .lowRate      — Hz
#   .highRate     — Hz
#   .lowExtent    — cents
#   .highExtent   — cents
#
# Outputs:
#   .includeId          — raw data within thresholds
#   .excludeId          — raw data outside thresholds
#   .smoothIncludeId    — smoothed data within thresholds
#   .smoothExcludeId    — smoothed data outside thresholds
#   .nIncluded          — row count of raw included
#   .nSmoothedIncluded  — row count of smoothed included
# ----------------------------------------------------------------------------
procedure emlVibratoFilter: .tableId, .lowRate, .highRate,
    ... .lowExtent, .highExtent

    # Raw include
    selectObject: .tableId
    Extract rows where:
    ... ~self["Rate(Hz)"] > .lowRate and self["Rate(Hz)"] < .highRate
    ... and self["HalfExtent(cents)"] > .lowExtent
    ... and self["HalfExtent(cents)"] < .highExtent
    .includeId = selected ()
    Rename: "Included"
    .nIncluded = Get number of rows

    # Raw exclude
    selectObject: .tableId
    Extract rows where:
    ... ~self["Rate(Hz)"] < .lowRate or self["Rate(Hz)"] > .highRate
    ... or self["HalfExtent(cents)"] < .lowExtent
    ... or self["HalfExtent(cents)"] > .highExtent
    .excludeId = selected ()
    Rename: "Excluded"

    # Smoothed include
    selectObject: .tableId
    Extract rows where:
    ... ~self["AverageRate(Hz)"] > .lowRate
    ... and self["AverageRate(Hz)"] < .highRate
    ... and self["AverageHalfExtent(cents)"] > .lowExtent
    ... and self["AverageHalfExtent(cents)"] < .highExtent
    .smoothIncludeId = selected ()
    Rename: "IncludedSmoothed"
    .nSmoothedIncluded = Get number of rows

    # Smoothed exclude
    selectObject: .tableId
    Extract rows where:
    ... ~self["AverageRate(Hz)"] < .lowRate
    ... or self["AverageRate(Hz)"] > .highRate
    ... or self["AverageHalfExtent(cents)"] < .lowExtent
    ... or self["AverageHalfExtent(cents)"] > .highExtent
    .smoothExcludeId = selected ()
    Rename: "ExcludedSmoothed"
endproc


# ----------------------------------------------------------------------------
# @emlVibratoJitter
# Compute vibrato regularity measures from peak-time PointProcess.
#
# Arguments:
#   .tableId    — the filtered include table
#   .lowRate    — Hz (max period = 1/lowRate)
#   .highRate   — Hz (min period = 1/highRate)
#   .startTime  — domain start
#   .endTime    — domain end
#
# Outputs:
#   .local      — jitter (local) proportion
#   .localAbs   — jitter (local, absolute) in seconds
#   .rap        — relative average perturbation
#   .ppq5       — five-point period perturbation quotient
#   .ddp        — average absolute difference of differences
# ----------------------------------------------------------------------------
procedure emlVibratoJitter: .tableId, .lowRate, .highRate,
    ... .startTime, .endTime

    # Create temporary PointProcess from whole-cycle peak times
    Create empty PointProcess: "vibratoJitter", .startTime, .endTime
    .tmpPP = selected ()

    selectObject: .tableId
    .nRows = Get number of rows

    for .i to .nRows
        selectObject: .tableId
        .cycleNum = Get value: .i, "Cycle#"
        if .cycleNum mod 1 = 0
            .pointTime = Get value: .i, "PeakTime(s)"
            selectObject: .tmpPP
            Add point: .pointTime
        endif
    endfor

    # Query all 5 jitter types
    .minPeriod = 1 / .highRate
    .maxPeriod = 1 / .lowRate

    selectObject: .tmpPP
    .local = Get jitter (local): 0, 0, .minPeriod, .maxPeriod, 1.3
    .localAbs = Get jitter (local, absolute): 0, 0,
    ... .minPeriod, .maxPeriod, 1.3
    .rap = Get jitter (rap): 0, 0, .minPeriod, .maxPeriod, 1.3
    .ppq5 = Get jitter (ppq5): 0, 0, .minPeriod, .maxPeriod, 1.3
    .ddp = Get jitter (ddp): 0, 0, .minPeriod, .maxPeriod, 1.3

    # Clean up temporary PointProcess
    removeObject: .tmpPP

    selectObject: .tableId
endproc


# ----------------------------------------------------------------------------
# @emlVibratoSummary
# Compute aggregate statistics across included data.
#
# Arguments:
#   .includeId          — raw included Table
#   .smoothIncludeId    — smoothed included Table
#   .pitchId            — Pitch object
#   .intensityId        — Intensity object
#
# Outputs:
#   .meanRate, .medianRate, .stDevRate
#   .meanExtent, .medianExtent, .stDevExtent
#   .meanRateSmooth, .medianRateSmooth, .stDevRateSmooth
#   .meanExtentSmooth, .medianExtentSmooth, .stDevExtentSmooth
#   .meanFo, .minFo, .maxFo
#   .meanIntensity, .minIntensity, .maxIntensity
#   .cvRate, .cvExtent, .cvRateSmooth, .cvExtentSmooth
# ----------------------------------------------------------------------------
procedure emlVibratoSummary: .includeId, .smoothIncludeId,
    ... .pitchId, .intensityId

    # Raw rate stats (extract rows with Rate > 0)
    selectObject: .includeId
    Extract rows where: ~self["Rate(Hz)"] > 0
    .tmpTable = selected ()
    .meanRate = Get mean: "Rate(Hz)"
    .stDevRate = Get standard deviation: "Rate(Hz)"
    .medianRate = Get quantile: "Rate(Hz)", 0.5
    removeObject: .tmpTable

    # Smoothed rate stats
    selectObject: .smoothIncludeId
    Extract rows where: ~self["AverageRate(Hz)"] > 0
    .tmpTable = selected ()
    .meanRateSmooth = Get mean: "AverageRate(Hz)"
    .stDevRateSmooth = Get standard deviation: "AverageRate(Hz)"
    .medianRateSmooth = Get quantile: "AverageRate(Hz)", 0.5
    removeObject: .tmpTable

    # Raw extent stats
    selectObject: .includeId
    Extract rows where: ~self["HalfExtent(cents)"] > 0
    .tmpTable = selected ()
    .meanExtent = Get mean: "HalfExtent(cents)"
    .stDevExtent = Get standard deviation: "HalfExtent(cents)"
    .medianExtent = Get quantile: "HalfExtent(cents)", 0.5
    removeObject: .tmpTable

    # Smoothed extent stats
    selectObject: .smoothIncludeId
    Extract rows where: ~self["AverageHalfExtent(cents)"] > 0
    .tmpTable = selected ()
    .meanExtentSmooth = Get mean: "AverageHalfExtent(cents)"
    .stDevExtentSmooth = Get standard deviation: "AverageHalfExtent(cents)"
    .medianExtentSmooth = Get quantile: "AverageHalfExtent(cents)", 0.5
    removeObject: .tmpTable

    # Pitch stats
    selectObject: .pitchId
    .meanFo = Get mean: 0, 0, "Hertz"
    .minFo = Get minimum: 0, 0, "Hertz", "parabolic"
    .maxFo = Get maximum: 0, 0, "Hertz", "parabolic"

    # Intensity stats
    selectObject: .intensityId
    .meanIntensity = Get mean: 0, 0, "dB"
    .minIntensity = Get minimum: 0, 0, "parabolic"
    .maxIntensity = Get maximum: 0, 0, "parabolic"

    # Coefficients of variation
    if .meanRate > 0
        .cvRate = (.stDevRate / .meanRate) * 100
    else
        .cvRate = undefined
    endif
    if .meanExtent > 0
        .cvExtent = (.stDevExtent / .meanExtent) * 100
    else
        .cvExtent = undefined
    endif
    if .meanRateSmooth > 0
        .cvRateSmooth = (.stDevRateSmooth / .meanRateSmooth) * 100
    else
        .cvRateSmooth = undefined
    endif
    if .meanExtentSmooth > 0
        .cvExtentSmooth = (.stDevExtentSmooth / .meanExtentSmooth) * 100
    else
        .cvExtentSmooth = undefined
    endif
endproc


# ============================================================================
# END OF ANALYSIS PROCEDURES
# Drawing procedures will be added in Phase 2.
# ============================================================================
