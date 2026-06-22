# ============================================================================
# EML Stats : Data Extraction Layer
# ============================================================================
# Module: eml-extract.praat
# Version: 1.2
# Date: 6 April 2026
#
# v1.2: Group sort order — @emlCountGroups optionally sorts labels
#        alphabetically when emlGroupSortAlphabetical = 1. Default 0
#        (table/discovery order). Global initialized in this file.
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# v1.1: Deleted @emlExtractMultipleGroups (10-group limit, vector
#        index overflow bug). Replaced with on-demand extraction:
#        @emlCountGroups rewritten (no group limit, no .groupSize
#        outputs), @eml_getGroupData added (4-arg, self-contained,
#        filters undefined values, auto-sized vector via C-level
#        Table extraction). Moved @eml_getGroupData here from
#        eml-inferential.praat (extraction, not inference).
#
# Provides: @emlExtractColumn, @emlExtractColumnAsStrings,
#   @emlExtractGroupVectors, @eml_getGroupData,
#   @emlExtractPairedColumns, @emlExtractPitchValues,
#   @emlExtractFormantValues, @emlExtractIntensityFrames,
#   @emlExtractHarmonicityFrames, @emlValidateTable,
#   @emlValidateNumericColumn, @emlTableColumnNames,
#   @emlCountGroups
#
# These procedures extract data from Praat objects into numeric
# vectors suitable for passing to EML Stats statistical procedures.
# ============================================================================


# ============================================================================
# @emlExtractColumn
# Extract a numeric column from a Table into a vector.
#
# Arguments:
#   tableId     - ID of the Table object
#   columnName$ - name of the column to extract
#
# Output:
#   .data#      - vector of values (length = number of rows)
#   .n          - number of values extracted
#   .nUndefined - count of undefined/non-numeric values
#   .error$     - error message if column doesn't exist, else ""
# ============================================================================
procedure emlExtractColumn: .tableId, .columnName$
    # Initialize outputs
    .n = 0
    .nUndefined = 0
    .error$ = ""
    .data# = zero#(0)
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns
    
    # Check if column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor
    
    if .colExists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .columnName$
    elsif .nRows = 0
        # Empty table - valid but no data
        .data# = zero#(0)
        .n = 0
    else
        # Allocate vector
        .data# = zero#(.nRows)
        .n = 0
        .nUndefined = 0
        
        # Extract values
        for .row from 1 to .nRows
            selectObject: .tableId
            .val = Get value: .row, .columnName$
            if .val <> undefined
                .n = .n + 1
                .data#[.n] = .val
            else
                .nUndefined = .nUndefined + 1
            endif
        endfor
        
        # Resize to actual count if there were undefined values
        if .n < .nRows and .n > 0
            .temp# = zero#(.n)
            for .i from 1 to .n
                .temp#[.i] = .data#[.i]
            endfor
            .data# = .temp#
        elsif .n = 0
            .data# = zero#(0)
        endif
    endif
endproc


# ============================================================================
# @emlExtractColumnAsStrings
# Extract a string column from a Table.
#
# Arguments:
#   tableId     - ID of the Table object
#   columnName$ - name of the column to extract
#
# Output:
#   .n          - number of strings
#   .str$[1..n] - the string values (bracket notation)
#   .error$     - error message if column doesn't exist
# ============================================================================
procedure emlExtractColumnAsStrings: .tableId, .columnName$
    # Initialize outputs
    .n = 0
    .error$ = ""
    
    # Pre-allocate string array (max 1000)
    for .init from 1 to 1000
        .str$[.init] = ""
    endfor
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns
    
    # Check if column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor
    
    if .colExists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .columnName$
    elsif .nRows = 0
        .n = 0
    else
        # Extract string values
        for .row from 1 to .nRows
            selectObject: .tableId
            .val$ = Get value: .row, .columnName$
            .n = .n + 1
            .str$[.n] = .val$
        endfor
    endif
endproc


# ============================================================================
# @emlExtractGroupVectors
# Extract two vectors split by a grouping variable with exactly two levels.
#
# Arguments:
#   tableId     - ID of the Table object
#   measureCol$ - column containing numeric values
#   groupCol$   - column containing group labels
#   label1$     - first group label
#   label2$     - second group label
#
# Output:
#   .group1#    - data vector for label1$
#   .group2#    - data vector for label2$
#   .n1         - size of group 1
#   .n2         - size of group 2
#   .nExcluded  - rows matching neither label
#   .error$     - error message if any
# ============================================================================
procedure emlExtractGroupVectors: .tableId, .measureCol$, .groupCol$, .label1$, .label2$
    # Initialize outputs
    .n1 = 0
    .n2 = 0
    .nExcluded = 0
    .error$ = ""
    .group1# = zero#(0)
    .group2# = zero#(0)
    
    # Select table and get row count
    selectObject: .tableId
    .nRows = Get number of rows
    
    if .nRows = 0
        .error$ = "Table is empty"
    else
        # First pass: count members of each group
        .count1 = 0
        .count2 = 0
        .countExcluded = 0
        
        for .row from 1 to .nRows
            selectObject: .tableId
            .grp$ = Get value: .row, .groupCol$
            .val = Get value: .row, .measureCol$
            
            if .val <> undefined
                if .grp$ = .label1$
                    .count1 = .count1 + 1
                elsif .grp$ = .label2$
                    .count2 = .count2 + 1
                else
                    .countExcluded = .countExcluded + 1
                endif
            else
                .countExcluded = .countExcluded + 1
            endif
        endfor
        
        # Allocate vectors
        if .count1 > 0
            .group1# = zero#(.count1)
        endif
        if .count2 > 0
            .group2# = zero#(.count2)
        endif
        
        # Second pass: populate vectors
        .idx1 = 0
        .idx2 = 0
        
        for .row from 1 to .nRows
            selectObject: .tableId
            .grp$ = Get value: .row, .groupCol$
            .val = Get value: .row, .measureCol$
            
            if .val <> undefined
                if .grp$ = .label1$
                    .idx1 = .idx1 + 1
                    .group1#[.idx1] = .val
                elsif .grp$ = .label2$
                    .idx2 = .idx2 + 1
                    .group2#[.idx2] = .val
                endif
            endif
        endfor
        
        .n1 = .count1
        .n2 = .count2
        .nExcluded = .countExcluded
    endif
endproc



# ============================================================================
# @emlExtractPairedColumns
# Extract two columns for paired analysis, excluding rows where either is undefined.
#
# Arguments:
#   tableId - ID of the Table object
#   col1$   - name of first column
#   col2$   - name of second column
#
# Output:
#   .data1#       - first column values (complete pairs only)
#   .data2#       - second column values (complete pairs only)
#   .n            - number of complete pairs
#   .nExcludedRows - rows with missing values
#   .error$       - error message if columns don't exist
# ============================================================================
procedure emlExtractPairedColumns: .tableId, .col1$, .col2$
    # Initialize outputs
    .n = 0
    .nExcludedRows = 0
    .error$ = ""
    .data1# = zero#(0)
    .data2# = zero#(0)
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns
    
    # Check if both columns exist
    .col1Exists = 0
    .col2Exists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .col1$
            .col1Exists = 1
        endif
        if .checkName$ = .col2$
            .col2Exists = 1
        endif
    endfor
    
    if .col1Exists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .col1$
    elsif .col2Exists = 0
        .error$ = "Column not found: "
        .error$ = .error$ + .col2$
    elsif .nRows = 0
        .n = 0
    else
        # First pass: count complete pairs
        .countComplete = 0
        .countExcluded = 0
        
        for .row from 1 to .nRows
            selectObject: .tableId
            .val1 = Get value: .row, .col1$
            selectObject: .tableId
            .val2 = Get value: .row, .col2$
            
            if .val1 <> undefined and .val2 <> undefined
                .countComplete = .countComplete + 1
            else
                .countExcluded = .countExcluded + 1
            endif
        endfor
        
        # Allocate vectors
        if .countComplete > 0
            .data1# = zero#(.countComplete)
            .data2# = zero#(.countComplete)
            
            # Second pass: populate
            .idx = 0
            for .row from 1 to .nRows
                selectObject: .tableId
                .val1 = Get value: .row, .col1$
                selectObject: .tableId
                .val2 = Get value: .row, .col2$
                
                if .val1 <> undefined and .val2 <> undefined
                    .idx = .idx + 1
                    .data1#[.idx] = .val1
                    .data2#[.idx] = .val2
                endif
            endfor
        endif
        
        .n = .countComplete
        .nExcludedRows = .countExcluded
    endif
endproc


# ============================================================================
# @emlExtractPitchValues
# Extract all voiced F0 values from a Pitch object.
#
# Arguments:
#   pitchId - ID of the Pitch object
#   unit$   - unit for extraction ("Hertz", "semitones re 100 Hz", etc.)
#
# Output:
#   .data#         - voiced values only
#   .times#        - corresponding timestamps
#   .n             - number of voiced frames
#   .nTotal        - total number of frames
#   .nUnvoiced     - number of unvoiced frames
#   .percentVoiced - percentage of voiced frames
# ============================================================================
procedure emlExtractPitchValues: .pitchId, .unit$
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .nUnvoiced = 0
    .percentVoiced = 0
    .data# = zero#(0)
    .times# = zero#(0)
    
    # Select pitch and get frame count
    selectObject: .pitchId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        # Empty Pitch object
        .n = 0
    else
        # First pass: count voiced frames
        .countVoiced = 0
        
        for .frame from 1 to .nTotal
            selectObject: .pitchId
            .t = Get time from frame number: .frame
            selectObject: .pitchId
            .val = Get value at time: .t, .unit$, "linear"
            
            if .val <> undefined
                .countVoiced = .countVoiced + 1
            endif
        endfor
        
        .nUnvoiced = .nTotal - .countVoiced
        
        # Allocate vectors
        if .countVoiced > 0
            .data# = zero#(.countVoiced)
            .times# = zero#(.countVoiced)
            
            # Second pass: populate
            .idx = 0
            for .frame from 1 to .nTotal
                selectObject: .pitchId
                .t = Get time from frame number: .frame
                selectObject: .pitchId
                .val = Get value at time: .t, .unit$, "linear"
                
                if .val <> undefined
                    .idx = .idx + 1
                    .data#[.idx] = .val
                    .times#[.idx] = .t
                endif
            endfor
        endif
        
        .n = .countVoiced
        if .nTotal > 0
            .percentVoiced = (.countVoiced / .nTotal) * 100
        endif
    endif
endproc


# ============================================================================
# @emlExtractFormantValues
# Extract formant frequency values from a Formant object.
#
# Arguments:
#   formantId     - ID of the Formant object
#   formantNumber - which formant (1, 2, 3, etc.)
#   unit$         - unit for extraction ("hertz")
#
# Output:
#   .data#       - frequency values (defined frames only)
#   .times#      - corresponding timestamps
#   .bandwidths# - corresponding bandwidths
#   .n           - number of defined frames
#   .nTotal      - total number of frames
# ============================================================================
procedure emlExtractFormantValues: .formantId, .formantNumber, .unit$
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .data# = zero#(0)
    .times# = zero#(0)
    .bandwidths# = zero#(0)
    
    # Select formant and get frame count
    selectObject: .formantId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        .n = 0
    else
        # First pass: count defined frames
        .countDefined = 0
        
        for .frame from 1 to .nTotal
            selectObject: .formantId
            .t = Get time from frame number: .frame
            selectObject: .formantId
            .val = Get value at time: .formantNumber, .t, .unit$, "linear"
            
            if .val <> undefined
                .countDefined = .countDefined + 1
            endif
        endfor
        
        # Allocate vectors
        if .countDefined > 0
            .data# = zero#(.countDefined)
            .times# = zero#(.countDefined)
            .bandwidths# = zero#(.countDefined)
            
            # Second pass: populate
            .idx = 0
            for .frame from 1 to .nTotal
                selectObject: .formantId
                .t = Get time from frame number: .frame
                selectObject: .formantId
                .val = Get value at time: .formantNumber, .t, .unit$, "linear"
                
                if .val <> undefined
                    .idx = .idx + 1
                    .data#[.idx] = .val
                    .times#[.idx] = .t
                    selectObject: .formantId
                    .bw = Get bandwidth at time: .formantNumber, .t, .unit$, "linear"
                    .bandwidths#[.idx] = .bw
                endif
            endfor
        endif
        
        .n = .countDefined
    endif
endproc


# ============================================================================
# @emlExtractIntensityFrames
# Extract intensity values frame by frame.
#
# Arguments:
#   intensityId - ID of the Intensity object
#
# Output:
#   .data#  - intensity values (dB)
#   .times# - timestamps (from Get time from frame number)
#   .n      - number of frames
#   .nTotal - total number of frames (same as .n; included for interface parity)
# ============================================================================
procedure emlExtractIntensityFrames: .intensityId
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .data# = zero#(0)
    .times# = zero#(0)
    
    # Get frame count directly from Intensity object
    selectObject: .intensityId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        .n = 0
    else
        # Allocate vectors
        .data# = zero#(.nTotal)
        .times# = zero#(.nTotal)
        
        # Extract values using frame queries on the Intensity object
        for .frame from 1 to .nTotal
            selectObject: .intensityId
            .t = Get time from frame number: .frame
            selectObject: .intensityId
            .val = Get value at time: .t, "cubic"
            .data#[.frame] = .val
            .times#[.frame] = .t
        endfor
        
        .n = .nTotal
    endif
endproc


# ============================================================================
# @emlExtractHarmonicityFrames
# Extract HNR values (defined frames only).
#
# Arguments:
#   harmonicityId - ID of the Harmonicity object
#
# Output:
#   .data#      - HNR values (dB)
#   .times#     - timestamps
#   .n          - number of defined frames
#   .nTotal     - total number of frames
#   .nUndefined - number of undefined frames
# ============================================================================
procedure emlExtractHarmonicityFrames: .harmonicityId
    # Initialize outputs
    .n = 0
    .nTotal = 0
    .nUndefined = 0
    .data# = zero#(0)
    .times# = zero#(0)
    
    # Select harmonicity and get frame count
    selectObject: .harmonicityId
    .nTotal = Get number of frames
    
    if .nTotal = 0
        .n = 0
    else
        # First pass: count defined frames
        .countDefined = 0
        
        for .frame from 1 to .nTotal
            selectObject: .harmonicityId
            .t = Get time from frame number: .frame
            selectObject: .harmonicityId
            .val = Get value at time: .t, "cubic"
            
            if .val <> undefined
                .countDefined = .countDefined + 1
            endif
        endfor
        
        .nUndefined = .nTotal - .countDefined
        
        # Allocate vectors
        if .countDefined > 0
            .data# = zero#(.countDefined)
            .times# = zero#(.countDefined)
            
            # Second pass: populate
            .idx = 0
            for .frame from 1 to .nTotal
                selectObject: .harmonicityId
                .t = Get time from frame number: .frame
                selectObject: .harmonicityId
                .val = Get value at time: .t, "cubic"
                
                if .val <> undefined
                    .idx = .idx + 1
                    .data#[.idx] = .val
                    .times#[.idx] = .t
                endif
            endfor
        endif
        
        .n = .countDefined
    endif
endproc


# ============================================================================
# @emlValidateTable
# Validate Table has required columns (space-separated string).
#
# Arguments:
#   tableId          - ID of the Table object
#   requiredColumns$ - space-separated list of required column names
#
# Output:
#   .valid    - 1 if all columns present, 0 otherwise
#   .message$ - lists missing columns if invalid, else ""
#   .nRows    - number of rows in table
#   .nCols    - number of columns in table
# ============================================================================
procedure emlValidateTable: .tableId, .requiredColumns$
    # Initialize outputs
    .valid = 1
    .message$ = ""
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    selectObject: .tableId
    .nCols = Get number of columns
    
    # Get all column names into an array
    for .c from 1 to .nCols
        selectObject: .tableId
        .existingCol$[.c] = Get column label: .c
    endfor
    
    # Parse required columns and check each
    .missingCols$ = ""
    .searchStr$ = .requiredColumns$
    
    # Process space-separated required columns
    while .searchStr$ <> ""
        # Find next space or end of string
        .spacePos = index(.searchStr$, " ")
        
        if .spacePos > 0
            .reqCol$ = left$(.searchStr$, .spacePos - 1)
            .searchStr$ = right$(.searchStr$, length(.searchStr$) - .spacePos)
        else
            .reqCol$ = .searchStr$
            .searchStr$ = ""
        endif
        
        # Skip empty tokens (from multiple spaces)
        if .reqCol$ <> ""
            # Check if this column exists
            .colFound = 0
            for .c from 1 to .nCols
                if .existingCol$[.c] = .reqCol$
                    .colFound = 1
                endif
            endfor
            
            if .colFound = 0
                .valid = 0
                if .missingCols$ = ""
                    .missingCols$ = .reqCol$
                else
                    .missingCols$ = .missingCols$ + ", "
                    .missingCols$ = .missingCols$ + .reqCol$
                endif
            endif
        endif
    endwhile
    
    if .valid = 0
        .message$ = "Missing columns: "
        .message$ = .message$ + .missingCols$
    endif
endproc


# ============================================================================
# @emlValidateNumericColumn
# Validate column exists and contains numeric data.
#
# Arguments:
#   tableId     - ID of the Table object
#   columnName$ - name of the column to validate
#
# Output:
#   .valid    - 1 if column exists and has numeric data, 0 otherwise
#   .nTotal   - total number of rows
#   .nNumeric - number of numeric values
#   .nMissing - number of missing/non-numeric values
#   .message$ - descriptive message about validation result
# ============================================================================
procedure emlValidateNumericColumn: .tableId, .columnName$
    # Initialize outputs
    .valid = 0
    .nTotal = 0
    .nNumeric = 0
    .nMissing = 0
    .message$ = ""
    
    # Select table and get dimensions
    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns
    
    .nTotal = .nRows
    
    # Check if column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .columnName$
            .colExists = 1
        endif
    endfor
    
    if .colExists = 0
        .valid = 0
        .message$ = "Column not found: "
        .message$ = .message$ + .columnName$
    elsif .nRows = 0
        .valid = 0
        .message$ = "Table is empty"
    else
        # Count numeric vs non-numeric values
        for .row from 1 to .nRows
            selectObject: .tableId
            .val = Get value: .row, .columnName$
            
            if .val <> undefined
                .nNumeric = .nNumeric + 1
            else
                .nMissing = .nMissing + 1
            endif
        endfor
        
        if .nNumeric > 0
            .valid = 1
            if .nMissing > 0
                .message$ = "Column valid with some missing values"
            else
                .message$ = "Column valid, all values numeric"
            endif
        else
            .valid = 0
            .message$ = "Column contains no numeric values"
        endif
    endif
endproc


# ============================================================================
# @emlTableColumnNames
# Get all column names from a Table.
#
# Arguments:
#   tableId - ID of the Table object
#
# Output:
#   .nCols       - number of columns
#   .name$[1..n] - column names (bracket notation)
# ============================================================================
procedure emlTableColumnNames: .tableId
    # Initialize
    .nCols = 0
    
    # Pre-initialize name array
    for .init from 1 to 100
        .name$[.init] = ""
    endfor
    
    # Select table and get column count
    selectObject: .tableId
    .nCols = Get number of columns
    
    # Get each column name
    for .c from 1 to .nCols
        selectObject: .tableId
        .name$[.c] = Get column label: .c
    endfor
endproc


# Global: group sort order (0 = table/discovery order, 1 = alphabetical).
# Set by graphs UI (eml-graphs-form.praat) or manually before calling.
# Stats wrappers without UI default to 0 (table order).
emlGroupSortAlphabetical = 0

# ============================================================================
# @emlCountGroups
# Discover distinct groups in a column. No group limit.
#
# Arguments:
#   tableId   - ID of the Table object
#   groupCol$ - name of the grouping column
#
# Output:
#   .nGroups           - number of distinct groups
#   .groupLabel$[1..n] - labels (order controlled by
#                        emlGroupSortAlphabetical: 0 = discovery, 1 = alpha)
#   .error$            - error message if column not found
# ============================================================================
procedure emlCountGroups: .tableId, .groupCol$
    .nGroups = 0
    .error$ = ""

    selectObject: .tableId
    .nRows = Get number of rows
    .nCols = Get number of columns

    # Verify column exists
    .colExists = 0
    for .c from 1 to .nCols
        selectObject: .tableId
        .checkName$ = Get column label: .c
        if .checkName$ = .groupCol$
            .colExists = 1
        endif
    endfor

    if .colExists = 0
        .error$ = "Column not found: " + .groupCol$
    elsif .nRows > 0
        for .row from 1 to .nRows
            selectObject: .tableId
            .grp$ = Get value: .row, .groupCol$

            .found = 0
            for .g from 1 to .nGroups
                if .groupLabel$[.g] = .grp$
                    .found = 1
                endif
            endfor

            if .found = 0
                .nGroups = .nGroups + 1
                .groupLabel$[.nGroups] = .grp$
            endif
        endfor

        # Optional alphabetical sort
        if emlGroupSortAlphabetical = 1 and .nGroups > 1
            .tempVec$# = empty$# (.nGroups)
            for .g from 1 to .nGroups
                .tempVec$#[.g] = .groupLabel$[.g]
            endfor
            .tempVec$# = sort$# (.tempVec$#)
            for .g from 1 to .nGroups
                .groupLabel$[.g] = .tempVec$#[.g]
            endfor
        endif
    endif
endproc


# ============================================================================
# @eml_getGroupData
# Extract one group's numeric data from a Table. Self-contained:
# filters rows by group label, removes undefined values, returns
# auto-sized vector. No group limit, no shared state.
#
# Arguments:
#   tableId    - ID of the Table object
#   dataCol$   - name of the numeric data column
#   groupCol$  - name of the grouping column
#   groupLabel$ - label value to match
#
# Output:
#   .n     - number of valid (non-undefined) observations
#   .data# - vector of values
# ============================================================================
procedure eml_getGroupData: .tableId, .dataCol$, .groupCol$, .groupLabel$
    selectObject: .tableId
    .tempGroup = Extract rows where column (text): .groupCol$, "is equal to", .groupLabel$
    selectObject: .tempGroup
    .tempClean = Extract rows where: ~self [.dataCol$] <> undefined
    removeObject: .tempGroup
    selectObject: .tempClean
    .n = Get number of rows
    if .n > 0
        .data# = Get all numbers in column: .dataCol$
    else
        .data# = zero# (0)
    endif
    removeObject: .tempClean
endproc
