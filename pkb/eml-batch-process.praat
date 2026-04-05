# ============================================================================
# Batch Voice Analysis
# ============================================================================
# Purpose: Batch process a folder of Sound files to extract user-selected
#          acoustic measures (mean F0, mean intensity, jitter, shimmer, HNR,
#          CPPS), optionally constrained to labeled TextGrid intervals.
#          Results are exported to a CSV file with one row per analysis
#          segment.
# Date: 3 April 2026
# Version: 1.1
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# ATTRIBUTION
# Framework: EML Praat Assistant by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Acoustic analysis scripts were developed using the EML Praat
#    Assistant (Howell, Embodied Music Lab) with code generation
#    by Claude 4.6 Extended Thinking (Anthropic). All scripts were
#    reviewed, tested, and validated by [your name]."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

# ============================================================================
# Procedures
# ============================================================================

procedure emlBuildDateStamp
    .vec# = date# ()
    .year$ = string$ (.vec#[1])
    .month$ = right$ ("0" + string$ (.vec#[2]), 2)
    .day$ = right$ ("0" + string$ (.vec#[3]), 2)
    .result$ = .year$ + "-" + .month$ + "-" + .day$
endproc

procedure emlCheckStopSentinel: .sentinelPath$
    .shouldStop = 0
    if fileReadable (.sentinelPath$)
        .content$ = readFile$ (.sentinelPath$)
        .firstLine$ = extractWord$ (.content$, "")
        if index_caseInsensitive (.firstLine$, "stop") > 0
            .shouldStop = 1
        endif
    endif
endproc

procedure emlInitSentinel: .sentinelPath$
    writeFileLine: .sentinelPath$, "RUN"
    appendFileLine: .sentinelPath$, "---"
    appendFileLine: .sentinelPath$, "To stop processing after the current file,"
    appendFileLine: .sentinelPath$, "change the first line from RUN to STOP and save."
    appendFileLine: .sentinelPath$, "The script checks this file after each file completes."
endproc

# ============================================================================
# Initialize defaults
# ============================================================================

sound_folder$ = ""
file_extension$ = "wav"
channel_handling = 1
mean_F0 = 1
mean_intensity = 1
jitter = 0
shimmer = 0
hNR = 0
cPPS = 0
highest_expected_F0 = 500
use_TextGrids = 0
textGrid_folder$ = ""
tier_number = 1
target_label$ = "V"

# ============================================================================
# Configuration dialog (with Standard button for analysis parameters)
# ============================================================================

repeat
    beginPause: "Batch Voice Analysis"
        comment: "--- Input ---"
        folder: "Sound folder", sound_folder$
        word: "File extension", file_extension$
        optionmenu: "Channel handling", channel_handling
            option: "Mix to mono"
            option: "Left channel only"
            option: "Right channel only"
        comment: "--- Measures ---"
        boolean: "Mean F0", mean_F0
        boolean: "Mean intensity", mean_intensity
        boolean: "Jitter (local)", jitter
        boolean: "Shimmer (local)", shimmer
        boolean: "HNR", hNR
        boolean: "CPPS", cPPS
        comment: "--- Pitch range ---"
        positive: "Highest expected F0 (Hz)", string$ (highest_expected_F0)
        comment: "--- TextGrid options ---"
        boolean: "Use TextGrids", use_TextGrids
        folder: "TextGrid folder", textGrid_folder$
        natural: "Tier number", string$ (tier_number)
        word: "Target label", target_label$
    clicked = endPause: "Quit", "Standard", "Run", 3, 0
    if clicked = 1
        exitScript: "User quit."
    elsif clicked = 2
        # Reset analysis parameters to canonical defaults
        mean_F0 = 1
        mean_intensity = 1
        jitter = 0
        shimmer = 0
        hNR = 0
        cPPS = 0
        highest_expected_F0 = 500
    endif
until clicked <> 2

# ============================================================================
# Validate inputs
# ============================================================================

if sound_folder$ = ""
    exitScript: "No sound folder selected. Please re-run and select a folder."
endif

if not mean_F0 and not mean_intensity and not jitter and not shimmer and not hNR and not cPPS
    exitScript: "No measures selected. Please re-run and select at least one measure."
endif

if use_TextGrids and textGrid_folder$ = ""
    exitScript: "TextGrid folder is required when Use TextGrids is selected."
endif

# Strip leading dot from extension if present
if left$ (file_extension$, 1) = "."
    file_extension$ = right$ (file_extension$, length (file_extension$) - 1)
endif

# ============================================================================
# Pre-compute derived analysis parameters
# ============================================================================

needsRccPitch = jitter or shimmer
needsPointProcess = jitter or shimmer

# FAC pitch top: canonical 800 (APPENDIX_D S1A), raise only if needed
facPitchTop = max (2 * highest_expected_F0, 800)

# RCC pitch ceiling: canonical 600 (APPENDIX_D S1B), raise only if needed
rccPitchCeiling = max (highest_expected_F0 * 1.1, 600)

# ============================================================================
# Create file list and validate
# ============================================================================

fileListId = Create Strings as file list: "files",
    ... sound_folder$ + "/*." + file_extension$
nFiles = Get number of strings

if nFiles = 0
    removeObject: fileListId
    exitScript: "No ." + file_extension$ + " files found in selected folder."
endif

# ============================================================================
# Batch range dialog (S10B)
# ============================================================================

beginPause: "Batch range"
    comment: "Found " + string$ (nFiles) + " ." + file_extension$ + " files."
    natural: "Start from file", "1"
    natural: "End at file", string$ (nFiles)
clicked = endPause: "Quit", "Run", 2, 0
if clicked = 1
    removeObject: fileListId
    exitScript: "User quit."
endif

# ============================================================================
# Build table columns (dynamic based on selected measures)
# ============================================================================

colNames$ = "file"
if use_TextGrids
    colNames$ = colNames$ + " interval_label interval_start interval_end"
endif
if mean_F0
    colNames$ = colNames$ + " mean_F0_Hz"
endif
if mean_intensity
    colNames$ = colNames$ + " mean_intensity_dB"
endif
if jitter
    colNames$ = colNames$ + " jitter_local"
endif
if shimmer
    colNames$ = colNames$ + " shimmer_local"
endif
if hNR
    colNames$ = colNames$ + " HNR_dB"
endif
if cPPS
    colNames$ = colNames$ + " CPPS_dB"
endif

resultsId = Create Table with column names: "results", 0, colNames$
currentRow = 0

# ============================================================================
# Auto-generate output filename (S9)
# ============================================================================

slashPos = rindex (sound_folder$, "/")
if slashPos > 0
    folderName$ = right$ (sound_folder$, length (sound_folder$) - slashPos)
else
    folderName$ = sound_folder$
endif

@emlBuildDateStamp
proposedCsv$ = folderName$ + "_results_" + emlBuildDateStamp.result$ + ".csv"
csvPath$ = sound_folder$ + "/" + proposedCsv$

# Non-colliding path (Rule 27)
if fileReadable (csvPath$)
    baseCsv$ = folderName$ + "_results_" + emlBuildDateStamp.result$
    suffix = 2
    repeat
        csvPath$ = sound_folder$ + "/" + baseCsv$ + "_"
            ... + string$ (suffix) + ".csv"
        suffix = suffix + 1
    until not fileReadable (csvPath$)
endif

# ============================================================================
# Initialize STOP sentinel (S5)
# ============================================================================

sentinelPath$ = sound_folder$ + "/STOP.txt"
@emlInitSentinel: sentinelPath$

# ============================================================================
# Info window header
# ============================================================================

writeInfoLine: "Batch Voice Analysis"
line$ = "Sound folder: " + sound_folder$
appendInfoLine: line$
if use_TextGrids
    line$ = "TextGrid folder: " + textGrid_folder$
    appendInfoLine: line$
    line$ = "Tier: " + string$ (tier_number) + ", Label: " + target_label$
    appendInfoLine: line$
endif
line$ = "Output: " + csvPath$
appendInfoLine: line$
appendInfoLine: ""
line$ = "Sentinel file: " + sentinelPath$
appendInfoLine: line$
appendInfoLine: "To stop: open that file, change first line to STOP, save."
appendInfoLine: ""

# ============================================================================
# Tracking variables
# ============================================================================

nProcessed = 0
nSkipped = 0
nWarnings = 0

# ============================================================================
# Main processing loop
# ============================================================================

for iFile from start_from_file to end_at_file

    # --- Check STOP sentinel ---
    @emlCheckStopSentinel: sentinelPath$
    if emlCheckStopSentinel.shouldStop
        line$ = "=== STOPPED BY USER after " + string$ (nProcessed)
            ... + " of " + string$ (nFiles) + " files ==="
        appendInfoLine: newline$, line$
        @emlInitSentinel: sentinelPath$
        goto BATCH_END
    endif

    # --- Read file ---
    selectObject: fileListId
    fileName$ = Get string: iFile
    filePath$ = sound_folder$ + "/" + fileName$
    soundId = Read from file: filePath$

    # Extract base name for display and TextGrid pairing
    dotPos = rindex (fileName$, ".")
    if dotPos > 1
        baseName$ = left$ (fileName$, dotPos - 1)
    else
        baseName$ = fileName$
    endif

    # --- Progress (S7A) ---
    line$ = "[" + string$ (iFile) + "/" + string$ (end_at_file) + "] "
        ... + baseName$
    appendInfoLine: line$

    # --- Channel handling ---
    selectObject: soundId
    nChannels = Get number of channels
    if nChannels > 1
        if channel_handling = 1
            derivedId = Convert to mono
        elsif channel_handling = 2
            derivedId = Extract one channel: 1
        else
            derivedId = Extract one channel: 2
        endif
        removeObject: soundId
        soundId = derivedId
        line$ = "  Converted: " + channel_handling$
        appendInfoLine: line$
    endif

    # --- Determine segments to analyze ---
    if use_TextGrids
        gridPath$ = textGrid_folder$ + "/" + baseName$ + ".TextGrid"
        if not fileReadable (gridPath$)
            line$ = "  WARNING: No TextGrid for " + baseName$ + " — skipping."
            appendInfoLine: line$
            nSkipped = nSkipped + 1
            nWarnings = nWarnings + 1
            removeObject: soundId
            goto NEXT_FILE
        endif
        gridId = Read from file: gridPath$

        # Find matching intervals
        selectObject: gridId
        nIntervals = Get number of intervals: tier_number
        nSegments = 0
        for iInt from 1 to nIntervals
            selectObject: gridId
            lab$ = Get label of interval: tier_number, iInt
            if lab$ = target_label$
                nSegments = nSegments + 1
                segStart[nSegments] = Get start time of interval: tier_number, iInt
                segEnd[nSegments] = Get end time of interval: tier_number, iInt
                segLabel$[nSegments] = lab$
            endif
        endfor

        if nSegments = 0
            line$ = "  WARNING: No intervals labeled """
                ... + target_label$ + """ — skipping."
            appendInfoLine: line$
            nSkipped = nSkipped + 1
            nWarnings = nWarnings + 1
            removeObject: gridId, soundId
            goto NEXT_FILE
        endif
    else
        nSegments = 1
    endif

    # --- Segment loop ---
    for iSeg from 1 to nSegments

        # Get analysis sound
        if use_TextGrids
            selectObject: soundId
            segId = Extract part: segStart[iSeg], segEnd[iSeg],
                ... "rectangular", 1, "no"
        else
            segId = soundId
        endif

        # Check segment duration
        selectObject: segId
        segDuration = Get total duration
        if segDuration < 0.064
            line$ = "  WARNING: Segment duration "
                ... + fixed$ (segDuration, 3)
                ... + " s — measures may be undefined."
            appendInfoLine: line$
            nWarnings = nWarnings + 1
        endif

        # ========================================================
        # Create analysis objects and query measures
        # ========================================================

        # --- Mean F0 (filtered autocorrelation, APPENDIX_D S1A) ---
        if mean_F0
            selectObject: segId
            facPitchId = noprogress To Pitch (filtered autocorrelation):
                ... 0.0, 50, facPitchTop, 15, "no", 0.03, 0.09,
                ... 0.5, 0.055, 0.35, 0.14
            selectObject: facPitchId
            meanF0Val = Get mean: 0, 0, "Hertz"
        endif

        # --- Pitch for voice quality (raw cross-correlation, APPENDIX_D S1B) ---
        if needsRccPitch
            selectObject: segId
            rccPitchId = noprogress To Pitch (raw cross-correlation):
                ... 0.0, 75, rccPitchCeiling, 15, "no", 0.03,
                ... 0.45, 0.01, 0.35, 0.14
        endif

        # --- PointProcess for jitter/shimmer (APPENDIX_D S3A) ---
        if needsPointProcess
            selectObject: segId
            plusObject: rccPitchId
            ppId = To PointProcess (cc)
        endif

        # --- Jitter (APPENDIX_D S3B) ---
        if jitter
            selectObject: ppId
            jitterVal = Get jitter (local): 0, 0, 0.0001, 0.02, 1.3
        endif

        # --- Shimmer (APPENDIX_D S3C, requires PointProcess + Sound) ---
        if shimmer
            selectObject: ppId
            plusObject: segId
            shimmerVal = Get shimmer (local): 0, 0, 0.0001, 0.02,
                ... 1.3, 1.6
        endif

        # --- Mean intensity (APPENDIX_D S6) ---
        if mean_intensity
            selectObject: segId
            intId = To Intensity: 100, 0.0, "yes"
            selectObject: intId
            intVal = Get mean: 0, 0, "dB"
        endif

        # --- HNR (APPENDIX_D S2A) ---
        if hNR
            selectObject: segId
            harmId = noprogress To Harmonicity (cc): 0.01, 75,
                ... 0.1, 1.0
            selectObject: harmId
            hnrVal = Get mean: 0, 0
        endif

        # --- CPPS (APPENDIX_D S5, Maryn et al. parameters) ---
        if cPPS
            selectObject: segId
            cepId = noprogress To PowerCepstrogram: 60, 0.002,
                ... 5000, 50
            selectObject: cepId
            cppsVal = Get CPPS: "yes", 0.01, 0.001, 60, 330, 0.05,
                ... "parabolic", 0.001, 0.05, "Straight",
                ... "Robust slow"
        endif

        # ========================================================
        # Plausibility warnings (APPENDIX_D S7)
        # ========================================================

        if mean_F0
            if meanF0Val <> undefined
                if meanF0Val < 50 or meanF0Val > 1000
                    line$ = "  WARNING: Mean F0 = "
                        ... + fixed$ (meanF0Val, 1)
                        ... + " Hz — outside range (50-1000)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if jitter
            if jitterVal <> undefined
                if jitterVal > 0.05
                    line$ = "  WARNING: Jitter = "
                        ... + fixed$ (jitterVal, 4)
                        ... + " — unusually high (> 5%)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if shimmer
            if shimmerVal <> undefined
                if shimmerVal > 0.15
                    line$ = "  WARNING: Shimmer = "
                        ... + fixed$ (shimmerVal, 4)
                        ... + " — unusually high (> 15%)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if hNR
            if hnrVal <> undefined
                if hnrVal < -20 or hnrVal > 40
                    line$ = "  WARNING: HNR = "
                        ... + fixed$ (hnrVal, 2)
                        ... + " dB — outside range (-20 to 40)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if cPPS
            if cppsVal <> undefined
                if cppsVal < 0 or cppsVal > 25
                    line$ = "  WARNING: CPPS = "
                        ... + fixed$ (cppsVal, 2)
                        ... + " dB — outside range (0 to 25)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        # ========================================================
        # Write row to results table
        # ========================================================

        selectObject: resultsId
        Append row
        currentRow = currentRow + 1

        Set string value: currentRow, "file", baseName$

        if use_TextGrids
            Set string value: currentRow, "interval_label",
                ... segLabel$[iSeg]
            Set numeric value: currentRow, "interval_start",
                ... segStart[iSeg]
            Set numeric value: currentRow, "interval_end",
                ... segEnd[iSeg]
        endif

        if mean_F0
            Set numeric value: currentRow, "mean_F0_Hz", meanF0Val
        endif
        if mean_intensity
            Set numeric value: currentRow, "mean_intensity_dB", intVal
        endif
        if jitter
            Set numeric value: currentRow, "jitter_local", jitterVal
        endif
        if shimmer
            Set numeric value: currentRow, "shimmer_local", shimmerVal
        endif
        if hNR
            Set numeric value: currentRow, "HNR_dB", hnrVal
        endif
        if cPPS
            Set numeric value: currentRow, "CPPS_dB", cppsVal
        endif

        # ========================================================
        # Clean up analysis objects for this segment
        # ========================================================

        if mean_F0
            removeObject: facPitchId
        endif
        if needsPointProcess
            removeObject: ppId
        endif
        if needsRccPitch
            removeObject: rccPitchId
        endif
        if mean_intensity
            removeObject: intId
        endif
        if hNR
            removeObject: harmId
        endif
        if cPPS
            removeObject: cepId
        endif
        if use_TextGrids
            removeObject: segId
        endif

    endfor

    # --- Clean up file-level objects ---
    if use_TextGrids
        removeObject: gridId
    endif
    removeObject: soundId
    nProcessed = nProcessed + 1

    label NEXT_FILE
endfor

label BATCH_END

# ============================================================================
# Export results
# ============================================================================

selectObject: resultsId
Save as comma-separated file: csvPath$

# ============================================================================
# Post-completion summary (S8)
# ============================================================================

sep$ = "============================================"
appendInfoLine: ""
appendInfoLine: sep$
appendInfoLine: "COMPLETE"
appendInfoLine: sep$
line$ = "Files processed: " + string$ (nProcessed)
appendInfoLine: line$
line$ = "Files skipped:   " + string$ (nSkipped)
appendInfoLine: line$
line$ = "Warnings:        " + string$ (nWarnings)
appendInfoLine: line$
line$ = "Data rows:       " + string$ (currentRow)
appendInfoLine: line$
line$ = "Output:          " + csvPath$
appendInfoLine: line$
appendInfoLine: sep$
appendInfoLine: ""
appendInfoLine: "Results Table retained in Objects window."

# Reset sentinel for next run
@emlInitSentinel: sentinelPath$

# Clean up file list, keep results table
removeObject: fileListId
selectObject: resultsId
