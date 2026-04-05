# ============================================================================
# EML Stats : Output Formatting
# ============================================================================
# Module: eml-output.praat
# Version: 1.1
# Date: 3 April 2026
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlReportHeader, @emlReportFooter, @emlReportSection,
#   @emlReportLine, @emlReportLineString, @emlReportBlank,
#   @emlFormatP, @emlFormatCI, @emlFormatTestResult,
#   @emlReportDescriptiveRow, @emlReportDescriptiveHeader,
#   @emlReportAPA, @emlReportToFile, @emlFormatEffectLabel,
#   @emlPadRight, @emlUnderscoreToSpace, @emlSaveInfoToFile,
#   @emlCSVInit, @emlCSVAddRow, @emlExportStatsCSV
#
# All procedures use the "eml" prefix (EML Stats).
# ============================================================================


# ============================================================================
# UTILITY PROCEDURES
# ============================================================================

procedure emlPadRight: .text$, .targetLength
    # Pad string with trailing spaces to reach targetLength
    # If string is already >= targetLength, return unchanged
    .currentLength = length(.text$)
    if .currentLength >= .targetLength
        .result$ = .text$
    else
        .paddingNeeded = .targetLength - .currentLength
        .padding$ = ""
        .i = 1
        while .i <= .paddingNeeded
            .space$ = " "
            .padding$ = .padding$ + .space$
            .i = .i + 1
        endwhile
        .result$ = .text$ + .padding$
    endif
endproc


procedure emlUnderscoreToSpace: .text$
    # Convert all underscores to spaces
    .underscore$ = "_"
    .space$ = " "
    .result$ = replace$(.text$, .underscore$, .space$, 0)
endproc


# ============================================================================
# REPORT STRUCTURE PROCEDURES (write to Info window)
# ============================================================================

procedure emlReportHeader: .title$
    # Print report header with double-line borders
    # This is the ONLY procedure that clears the Info window
    .border$ = "══════════════════════════════════════════════"
    .indent$ = "  "
    .prefix$ = "EML Stats : "
    .titleLine$ = .indent$ + .prefix$ + .title$
    writeInfoLine: .border$
    appendInfoLine: .titleLine$
    appendInfoLine: .border$
    .empty$ = ""
    appendInfoLine: .empty$
endproc


procedure emlReportFooter
    # Print closing double-line border
    .empty$ = ""
    .border$ = "══════════════════════════════════════════════"
    appendInfoLine: .empty$
    appendInfoLine: .border$
endproc


procedure emlReportSection: .title$
    # Print section divider with title
    # Format: ── [title] ──────────────────────────────
    .empty$ = ""
    appendInfoLine: .empty$
    .indent$ = "  "
    .prefix$ = "── "
    .spacer$ = " "
    # Calculate remaining dashes to fill line (target ~46 chars total)
    .usedLength = 2 + 3 + length(.title$) + 1
    .remainingDashes = 46 - .usedLength
    if .remainingDashes < 3
        .remainingDashes = 3
    endif
    .dashes$ = ""
    .i = 1
    while .i <= .remainingDashes
        .dash$ = "─"
        .dashes$ = .dashes$ + .dash$
        .i = .i + 1
    endwhile
    .line$ = .indent$ + .prefix$ + .title$ + .spacer$ + .dashes$
    appendInfoLine: .line$
endproc


procedure emlReportLine: .label$, .value, .decimals
    # Print labeled numeric value with 2-space indent
    # Label padded to 20 characters
    .indent$ = "  "
    @emlPadRight: .label$, 20
    .paddedLabel$ = emlPadRight.result$
    .formattedValue$ = fixed$(.value, .decimals)
    .line$ = .indent$ + .paddedLabel$ + .formattedValue$
    appendInfoLine: .line$
endproc


procedure emlReportLineString: .label$, .value$
    # Print labeled string value with 2-space indent
    # Label padded to 20 characters
    .indent$ = "  "
    @emlPadRight: .label$, 20
    .paddedLabel$ = emlPadRight.result$
    .line$ = .indent$ + .paddedLabel$ + .value$
    appendInfoLine: .line$
endproc


procedure emlReportBlank
    # Print empty line
    .empty$ = ""
    appendInfoLine: .empty$
endproc


# ============================================================================
# FORMATTING PROCEDURES (produce strings, do NOT write to Info window)
# ============================================================================

procedure emlFormatP: .pValue
    # Format p-value according to APA guidelines
    # Output: .formatted$
    # p < 0.001 -> "p < .001"
    # p >= 0.001 -> "p = .XXX" (3 decimals, no leading zero)
    # p undefined -> "p = undefined"
    
    if .pValue = undefined
        .formatted$ = "p = undefined"
    elsif .pValue < 0.001
        .formatted$ = "p < .001"
    else
        # Format with 3 decimals, remove leading zero
        .rawFormatted$ = fixed$(.pValue, 3)
        # Check if starts with "0." and remove leading zero
        .firstChar$ = left$(.rawFormatted$, 1)
        .zeroChar$ = "0"
        if .firstChar$ = .zeroChar$
            .noLeadingZero$ = right$(.rawFormatted$, length(.rawFormatted$) - 1)
        else
            .noLeadingZero$ = .rawFormatted$
        endif
        .prefix$ = "p = "
        .formatted$ = .prefix$ + .noLeadingZero$
    endif
endproc


procedure emlFormatCI: .lower, .upper, .level
    # Format confidence interval string
    # Output: .formatted$
    # level as proportion (0.95 -> "95%"), values to 2 decimals
    # Example: "95% CI [0.22, 1.40]"
    
    .levelPercent = .level * 100
    .levelInt = floor(.levelPercent)
    .levelStr$ = string$(.levelInt)
    .percent$ = "%"
    .ciLabel$ = " CI ["
    .comma$ = ", "
    .bracket$ = "]"
    .lowerStr$ = fixed$(.lower, 2)
    .upperStr$ = fixed$(.upper, 2)
    .formatted$ = .levelStr$ + .percent$ + .ciLabel$ + .lowerStr$ + .comma$ + .upperStr$ + .bracket$
endproc


procedure emlFormatTestResult: .testName$, .statSymbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper
    # Format complete test result line
    # Output: .summary$
    # If df2 = 0: single df, e.g., "t(23) = 2.45, p = .021, d = 0.89 [0.32, 1.45]"
    # If df2 > 0: dual df, e.g., "F(2, 27) = 4.85, p = .016, η² = .26"
    # Fractional df: 1 decimal place
    # effectName$ empty: omit effect size
    # ciLower undefined: omit CI brackets
    
    # Format degrees of freedom
    .openParen$ = "("
    .closeParen$ = ")"
    .comma$ = ", "
    .equals$ = " = "
    
    # Check if df1 is fractional (has decimal component)
    .df1Floor = floor(.df1)
    .df1Diff = .df1 - .df1Floor
    if .df1Diff > 0.001
        .df1Str$ = fixed$(.df1, 1)
    else
        .df1Str$ = string$(.df1Floor)
    endif
    
    # Build df string
    if .df2 = 0 or .df2 = undefined
        # Single df
        .dfStr$ = .openParen$ + .df1Str$ + .closeParen$
    else
        # Dual df - check if df2 is fractional
        .df2Floor = floor(.df2)
        .df2Diff = .df2 - .df2Floor
        if .df2Diff > 0.001
            .df2Str$ = fixed$(.df2, 1)
        else
            .df2Str$ = string$(.df2Floor)
        endif
        .dfStr$ = .openParen$ + .df1Str$ + .comma$ + .df2Str$ + .closeParen$
    endif
    
    # Format test statistic (2 decimals)
    .statStr$ = fixed$(.statValue, 2)
    
    # Format p-value
    @emlFormatP: .pValue
    .pStr$ = emlFormatP.formatted$
    
    # Build base result
    .summary$ = .statSymbol$ + .dfStr$ + .equals$ + .statStr$ + .comma$ + .pStr$
    
    # Add effect size if provided
    if .effectName$ <> ""
        .effectStr$ = fixed$(.effectValue, 2)
        .effectPart$ = .comma$ + .effectName$ + .equals$ + .effectStr$
        .summary$ = .summary$ + .effectPart$
        
        # Add CI if provided
        if .ciLower <> undefined and .ciUpper <> undefined
            .ciLowerStr$ = fixed$(.ciLower, 2)
            .ciUpperStr$ = fixed$(.ciUpper, 2)
            .openBracket$ = " ["
            .closeBracket$ = "]"
            .ciPart$ = .openBracket$ + .ciLowerStr$ + .comma$ + .ciUpperStr$ + .closeBracket$
            .summary$ = .summary$ + .ciPart$
        endif
    endif
endproc


procedure emlFormatEffectLabel: .effectValue, .effectType$
    # Return plain-language effect size interpretation
    # Output: .label$
    # Cohen's conventions by effect type
    
    .absValue = abs(.effectValue)
    
    # Set thresholds based on effect type (Cohen's conventions)
    # d: negligible < 0.2, small 0.2–0.5, medium 0.5–0.8, large >= 0.8
    # r, w, V: negligible < 0.1, small 0.1–0.3, medium 0.3–0.5, large >= 0.5
    # eta_squared, omega_squared: negligible < 0.01, small 0.01–0.06, medium 0.06–0.14, large >= 0.14
    
    .d$ = "d"
    .r$ = "r"
    .w$ = "w"
    .vUpper$ = "V"
    .eta$ = "eta_squared"
    .omega$ = "omega_squared"
    .eps$ = "epsilon2"
    .epsAlt$ = "epsilon_squared"
    
    if .effectType$ = .d$
        .negligibleThresh = 0.2
        .mediumThresh = 0.5
        .largeThresh = 0.8
    elsif .effectType$ = .r$ or .effectType$ = .w$ or .effectType$ = .vUpper$
        .negligibleThresh = 0.1
        .mediumThresh = 0.3
        .largeThresh = 0.5
    elsif .effectType$ = .eta$ or .effectType$ = .omega$ or .effectType$ = .eps$ or .effectType$ = .epsAlt$
        .negligibleThresh = 0.01
        .mediumThresh = 0.06
        .largeThresh = 0.14
    else
        # Default to d thresholds
        .negligibleThresh = 0.2
        .mediumThresh = 0.5
        .largeThresh = 0.8
    endif
    
    # Determine label (Cohen's conventions)
    if .absValue >= .largeThresh
        .label$ = "large effect"
    elsif .absValue >= .mediumThresh
        .label$ = "medium effect"
    elsif .absValue >= .negligibleThresh
        .label$ = "small effect"
    else
        .label$ = "negligible effect"
    endif
endproc


# ============================================================================
# DESCRIPTIVE TABLE PROCEDURES
# ============================================================================

procedure emlReportDescriptiveHeader
    # Print column header row for descriptive statistics table
    # Columns: Group (14), N (6), Mean (10), SD (10), Median (10)
    .indent$ = "  "
    @emlPadRight: "Group", 14
    .groupCol$ = emlPadRight.result$
    @emlPadRight: "N", 6
    .nCol$ = emlPadRight.result$
    @emlPadRight: "Mean", 10
    .meanCol$ = emlPadRight.result$
    @emlPadRight: "SD", 10
    .sdCol$ = emlPadRight.result$
    @emlPadRight: "Median", 10
    .medianCol$ = emlPadRight.result$
    .headerLine$ = .indent$ + .groupCol$ + .nCol$ + .meanCol$ + .sdCol$ + .medianCol$
    appendInfoLine: .headerLine$
endproc


procedure emlReportDescriptiveRow: .label$, .n, .mean, .sd, .median
    # Print one data row for descriptive statistics table
    # Same column widths as header, 2 decimal places for values
    .indent$ = "  "
    @emlPadRight: .label$, 14
    .groupCol$ = emlPadRight.result$
    
    .nStr$ = string$(.n)
    @emlPadRight: .nStr$, 6
    .nCol$ = emlPadRight.result$
    
    .meanStr$ = fixed$(.mean, 2)
    @emlPadRight: .meanStr$, 10
    .meanCol$ = emlPadRight.result$
    
    .sdStr$ = fixed$(.sd, 2)
    @emlPadRight: .sdStr$, 10
    .sdCol$ = emlPadRight.result$
    
    .medianStr$ = fixed$(.median, 2)
    @emlPadRight: .medianStr$, 10
    .medianCol$ = emlPadRight.result$
    
    .rowLine$ = .indent$ + .groupCol$ + .nCol$ + .meanCol$ + .sdCol$ + .medianCol$
    appendInfoLine: .rowLine$
endproc


# ============================================================================
# APA FORMATTING
# ============================================================================

procedure emlReportAPA: .testType$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper
    # Format complete APA 7th edition result string
    # Output: .formatted$
    # testType$ -> symbol mapping: t->t, F->F, r->r, chi2->χ², U->U, W->W, H->H, z->z
    
    # Map test type to symbol
    .t$ = "t"
    .f$ = "F"
    .rType$ = "r"
    .chi2$ = "chi2"
    .u$ = "U"
    .w$ = "W"
    .h$ = "H"
    .z$ = "z"
    
    if .testType$ = .t$
        .symbol$ = "t"
    elsif .testType$ = .f$
        .symbol$ = "F"
    elsif .testType$ = .rType$
        .symbol$ = "r"
    elsif .testType$ = .chi2$
        .symbol$ = "χ²"
    elsif .testType$ = .u$
        .symbol$ = "U"
    elsif .testType$ = .w$
        .symbol$ = "W"
    elsif .testType$ = .h$
        .symbol$ = "H"
    elsif .testType$ = .z$
        .symbol$ = "z"
    else
        .symbol$ = .testType$
    endif
    
    # Use the test result formatter
    @emlFormatTestResult: .testType$, .symbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper
    .formatted$ = emlFormatTestResult.summary$
endproc


# ============================================================================
# FILE OUTPUT PROCEDURES
# ============================================================================

procedure emlReportToFile: .filePath$, .content$
    # Write content to file with overwrite protection
    # Output: .success (1/0), .actualPath$
    # If file exists, append ascending integer: results.txt -> results_1.txt
    
    .success = 0
    .actualPath$ = .filePath$
    
    # Check if file exists
    if fileReadable(.filePath$)
        # File exists, need to find available name
        # Extract base name and extension
        .dot$ = "."
        .dotPos = rindex(.filePath$, .dot$)
        
        if .dotPos > 0
            .baseName$ = left$(.filePath$, .dotPos - 1)
            .extension$ = right$(.filePath$, length(.filePath$) - .dotPos + 1)
        else
            .baseName$ = .filePath$
            .extension$ = ""
        endif
        
        # Try incrementing numbers
        .counter = 1
        .found = 0
        while .found = 0 and .counter <= 999
            .underscore$ = "_"
            .counterStr$ = string$(.counter)
            .tryPath$ = .baseName$ + .underscore$ + .counterStr$ + .extension$
            if not fileReadable(.tryPath$)
                .actualPath$ = .tryPath$
                .found = 1
            else
                .counter = .counter + 1
            endif
        endwhile
        
        if .found = 0
            # Could not find available name
            .success = 0
        else
            writeFileLine: .actualPath$, .content$
            .success = 1
        endif
    else
        # File does not exist, write directly
        writeFileLine: .actualPath$, .content$
        .success = 1
    endif
endproc


procedure emlSaveInfoToFile: .filePath$
    # Save current Info window contents to file
    # Output: .success (1/0), .actualPath$
    
    # Capture Info window contents using Praat's special variable
    .content$ = info$
    
    # Use the file writer with overwrite protection
    @emlReportToFile: .filePath$, .content$
    .success = emlReportToFile.success
    .actualPath$ = emlReportToFile.actualPath$
endproc


# ============================================================================
# CSV RESULT ACCUMULATION
# ============================================================================
# Shared infrastructure for building CSV export from any entry point.
# Reporters append rows; @emlExportStatsCSV writes the file.

emlCSV_n = 0
emlCSV_header$ = "table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2"

procedure emlCSVInit
    emlCSV_n = 0
endproc

procedure emlCSVAddRow: .table$, .dataCol$, .groupCol$, .g1$, .g2$, .test$, .stat, .df, .p, .es, .esType$, .esLabel$, .n1, .n2, .mean1, .sd1, .median1, .mean2, .sd2, .median2
    emlCSV_n = emlCSV_n + 1
    .sep$ = ","
    emlCSV_row$[emlCSV_n] = .table$ + .sep$
    ... + .dataCol$ + .sep$
    ... + .groupCol$ + .sep$
    ... + .g1$ + .sep$
    ... + .g2$ + .sep$
    ... + .test$ + .sep$
    ... + fixed$ (.stat, 6) + .sep$
    ... + fixed$ (.df, 2) + .sep$
    ... + fixed$ (.p, 6) + .sep$
    ... + fixed$ (.es, 4) + .sep$
    ... + .esType$ + .sep$
    ... + .esLabel$ + .sep$
    ... + string$ (.n1) + .sep$
    ... + string$ (.n2) + .sep$
    ... + fixed$ (.mean1, 4) + .sep$
    ... + fixed$ (.sd1, 4) + .sep$
    ... + fixed$ (.median1, 4) + .sep$
    ... + fixed$ (.mean2, 4) + .sep$
    ... + fixed$ (.sd2, 4) + .sep$
    ... + fixed$ (.median2, 4)
endproc

procedure emlExportStatsCSV: .filePath$
    # Write accumulated CSV rows with overwrite protection.
    # Output: .success (1/0), .actualPath$
    if emlCSV_n = 0
        .success = 0
        .actualPath$ = .filePath$
    else
        # Build full content
        .content$ = emlCSV_header$
        for .i from 1 to emlCSV_n
            .content$ = .content$ + newline$ + emlCSV_row$[.i]
        endfor
        @emlReportToFile: .filePath$, .content$
        .success = emlReportToFile.success
        .actualPath$ = emlReportToFile.actualPath$
    endif
endproc


# ============================================================================
# END OF MODULE
# ============================================================================
