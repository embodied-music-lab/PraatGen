# ============================================================================
# EML Stats : Core Utility Procedures
# ============================================================================
# Module: eml-core-utilities.praat
# Version: 1.0
# Date: 20 February 2026
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlRankVector, @emlCountIf, @emlSubset, @emlUniqueValues,
#   @emlFrequency, @emlCumulativeSum, @emlDiff, @emlLag, @emlBinData,
#   @emlZScore, @emlRemoveUndefined, @emlSortWithIndex,
#   @emlConcatenateVectors, @emlRepeatVector
#
# Internal helpers: @eml_sortPairsByValue
#
# All procedures use the "eml" prefix (EML Stats) to avoid
# namespace collisions with user scripts.
# ============================================================================


# ============================================================================
# INTERNAL HELPER: Shell Sort with Index Tracking
# ============================================================================
# Sorts values in ascending order while tracking original indices.
# Uses Shell sort with Knuth gap sequence for O(n^1.5) performance.
# Efficient for n up to 10,000+.
#
# Input:
#   .inputValues# — vector of values to sort
#   .inputIndices# — vector of corresponding indices
#
# Output:
#   .sortedValues# — sorted values (ascending)
#   .sortedIndices# — indices permuted to match sorted order
# ============================================================================

procedure eml_sortPairsByValue: .inputValues#, .inputIndices#
    .n = size (.inputValues#)
    
    # Handle trivial cases
    if .n <= 1
        .sortedValues# = .inputValues#
        .sortedIndices# = .inputIndices#
    else
        # Copy input to working arrays
        .sortedValues# = .inputValues#
        .sortedIndices# = .inputIndices#
        
        # Compute Knuth gap sequence starting point
        # Gap sequence: 1, 4, 13, 40, 121, 364, 1093, 3280, ...
        .gap = 1
        while .gap < .n / 3
            .gap = .gap * 3 + 1
        endwhile
        
        # Shell sort with decreasing gaps
        while .gap >= 1
            # Insertion sort with gap
            for .i from .gap + 1 to .n
                .tempVal = .sortedValues#[.i]
                .tempIdx = .sortedIndices#[.i]
                .j = .i
                
                # Shift elements that are greater than tempVal
                .done = 0
                while .j > .gap and .done = 0
                    .jMinusGap = .j - .gap
                    if .sortedValues#[.jMinusGap] > .tempVal
                        .sortedValues#[.j] = .sortedValues#[.jMinusGap]
                        .sortedIndices#[.j] = .sortedIndices#[.jMinusGap]
                        .j = .jMinusGap
                    else
                        .done = 1
                    endif
                endwhile
                
                # Place the element at final position
                .sortedValues#[.j] = .tempVal
                .sortedIndices#[.j] = .tempIdx
            endfor
            
            # Reduce gap
            .gap = floor (.gap / 3)
        endwhile
    endif
endproc


# ============================================================================
# @emlRankVector
# ============================================================================
# Assigns statistical ranks to data values with average tie handling.
# Foundation for nonparametric tests (Spearman, Mann-Whitney, Wilcoxon, etc.)
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .ranks# — vector of ranks (same length as input)
#             tied values receive the average of their ranks
#   .hasTies — 1 if any ties exist, 0 otherwise
#   .nTieGroups — number of distinct groups of tied values
#   .tieCorrectionSum — sum of (t^3 - t) for each tie group of size t
#                       Used by KW tie correction and Dunn's variance.
#                       Zero when no ties.
# ============================================================================

procedure emlRankVector: .data#
    .n = size (.data#)
    
    # Handle trivial cases
    if .n = 0
        .ranks# = zero# (0)
        .hasTies = 0
        .nTieGroups = 0
        .tieCorrectionSum = 0
    elsif .n = 1
        .ranks# = {1}
        .hasTies = 0
        .nTieGroups = 0
        .tieCorrectionSum = 0
    else
        # Create parallel arrays: values and original indices
        .values# = .data#
        .indices# = from_to# (1, .n)
        
        # Sort by value, tracking original positions
        @eml_sortPairsByValue: .values#, .indices#
        .sortedValues# = eml_sortPairsByValue.sortedValues#
        .sortedIndices# = eml_sortPairsByValue.sortedIndices#
        
        # Assign ranks with tie averaging
        # First pass: assign sequential ranks and identify tie groups
        .assignedRanks# = zero# (.n)
        .hasTies = 0
        .nTieGroups = 0
        .tieCorrectionSum = 0
        
        .i = 1
        while .i <= .n
            # Find the extent of this tie group
            .tieStart = .i
            .tieEnd = .i
            .currentValue = .sortedValues#[.i]
            
            # Scan forward for equal values
            .j = .i + 1
            while .j <= .n
                if .sortedValues#[.j] = .currentValue
                    .tieEnd = .j
                    .j = .j + 1
                else
                    .j = .n + 1
                endif
            endwhile
            
            # Calculate average rank for this group
            # Ranks would be tieStart, tieStart+1, ..., tieEnd
            # Average = (tieStart + tieEnd) / 2
            .avgRank = (.tieStart + .tieEnd) / 2
            
            # Check if this is actually a tie group
            if .tieEnd > .tieStart
                .hasTies = 1
                .nTieGroups = .nTieGroups + 1
                .tieSize = .tieEnd - .tieStart + 1
                .tieCorrectionSum = .tieCorrectionSum
                ... + (.tieSize ^ 3 - .tieSize)
            endif
            
            # Assign average rank to all elements in this group
            for .k from .tieStart to .tieEnd
                .assignedRanks#[.k] = .avgRank
            endfor
            
            # Move to next group
            .i = .tieEnd + 1
        endwhile
        
        # Map ranks back to original positions
        .ranks# = zero# (.n)
        for .i from 1 to .n
            .origPos = .sortedIndices#[.i]
            .ranks#[.origPos] = .assignedRanks#[.i]
        endfor
    endif
endproc


# ============================================================================
# @emlCountIf
# ============================================================================
# Counts elements satisfying a comparison condition.
#
# Input:
#   .data# — vector of numeric values
#   .operator$ — comparison operator: "=", "<>", "<", ">", "<=", ">="
#   .value — comparison threshold
#
# Output:
#   .count — number of elements satisfying the condition
#   .error$ — empty if valid, error message if invalid operator
# ============================================================================

procedure emlCountIf: .data#, .operator$, .value
    .n = size (.data#)
    .count = 0
    .error$ = ""
    
    # Validate operator
    .validOp = 0
    if .operator$ = "="
        .validOp = 1
    elsif .operator$ = "<>"
        .validOp = 1
    elsif .operator$ = "<"
        .validOp = 1
    elsif .operator$ = ">"
        .validOp = 1
    elsif .operator$ = "<="
        .validOp = 1
    elsif .operator$ = ">="
        .validOp = 1
    endif
    
    if .validOp = 0
        .error$ = "Invalid operator: " + .operator$
    else
        # Count matching elements
        for .i from 1 to .n
            .x = .data#[.i]
            .match = 0
            
            if .operator$ = "="
                if .x = .value
                    .match = 1
                endif
            elsif .operator$ = "<>"
                if .x <> .value
                    .match = 1
                endif
            elsif .operator$ = "<"
                if .x < .value
                    .match = 1
                endif
            elsif .operator$ = ">"
                if .x > .value
                    .match = 1
                endif
            elsif .operator$ = "<="
                if .x <= .value
                    .match = 1
                endif
            elsif .operator$ = ">="
                if .x >= .value
                    .match = 1
                endif
            endif
            
            .count = .count + .match
        endfor
    endif
endproc


# ============================================================================
# @emlSubset
# ============================================================================
# Extracts elements at specified indices.
#
# Input:
#   .data# — source vector
#   .indices# — vector of 1-based positions to extract
#
# Output:
#   .result# — extracted elements (in order of indices#)
#   .nSkipped — count of out-of-range indices skipped
# ============================================================================

procedure emlSubset: .data#, .indices#
    .nData = size (.data#)
    .nIndices = size (.indices#)
    .nSkipped = 0
    
    if .nIndices = 0 or .nData = 0
        .result# = zero# (0)
    else
        # First pass: count valid indices
        .nValid = 0
        for .i from 1 to .nIndices
            .idx = .indices#[.i]
            if .idx >= 1 and .idx <= .nData
                .nValid = .nValid + 1
            else
                .nSkipped = .nSkipped + 1
            endif
        endfor
        
        # Second pass: extract valid elements
        if .nValid = 0
            .result# = zero# (0)
        else
            .result# = zero# (.nValid)
            .outIdx = 0
            for .i from 1 to .nIndices
                .idx = .indices#[.i]
                if .idx >= 1 and .idx <= .nData
                    .outIdx = .outIdx + 1
                    .result#[.outIdx] = .data#[.idx]
                endif
            endfor
        endif
    endif
endproc


# ============================================================================
# @emlUniqueValues
# ============================================================================
# Finds sorted unique values in a vector.
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .values# — sorted vector of unique values
#   .nUnique — count of unique values
# ============================================================================

procedure emlUniqueValues: .data#
    .n = size (.data#)
    
    if .n = 0
        .values# = zero# (0)
        .nUnique = 0
    elsif .n = 1
        .values# = .data#
        .nUnique = 1
    else
        # Sort the data
        .sorted# = sort# (.data#)
        
        # Count unique values (scan for changes)
        .nUnique = 1
        for .i from 2 to .n
            .iPrev = .i - 1
            if .sorted#[.i] <> .sorted#[.iPrev]
                .nUnique = .nUnique + 1
            endif
        endfor
        
        # Collect unique values
        .values# = zero# (.nUnique)
        .values#[1] = .sorted#[1]
        .uniqueIdx = 1
        
        for .i from 2 to .n
            .iPrev = .i - 1
            if .sorted#[.i] <> .sorted#[.iPrev]
                .uniqueIdx = .uniqueIdx + 1
                .values#[.uniqueIdx] = .sorted#[.i]
            endif
        endfor
    endif
endproc


# ============================================================================
# @emlFrequency
# ============================================================================
# Computes frequency distribution of values.
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .values# — sorted unique values
#   .counts# — frequency of each unique value (parallel to .values#)
#   .nUnique — number of unique categories
# ============================================================================

procedure emlFrequency: .data#
    .n = size (.data#)
    
    if .n = 0
        .values# = zero# (0)
        .counts# = zero# (0)
        .nUnique = 0
    else
        # Sort the data
        .sorted# = sort# (.data#)
        
        # Count unique values
        .nUnique = 1
        for .i from 2 to .n
            .iPrev = .i - 1
            if .sorted#[.i] <> .sorted#[.iPrev]
                .nUnique = .nUnique + 1
            endif
        endfor
        
        # Collect unique values and their counts
        .values# = zero# (.nUnique)
        .counts# = zero# (.nUnique)
        
        .values#[1] = .sorted#[1]
        .currentCount = 1
        .uniqueIdx = 1
        
        for .i from 2 to .n
            .iPrev = .i - 1
            if .sorted#[.i] = .sorted#[.iPrev]
                .currentCount = .currentCount + 1
            else
                # Store count for previous value
                .counts#[.uniqueIdx] = .currentCount
                # Start new value
                .uniqueIdx = .uniqueIdx + 1
                .values#[.uniqueIdx] = .sorted#[.i]
                .currentCount = 1
            endif
        endfor
        
        # Store final count
        .counts#[.uniqueIdx] = .currentCount
    endif
endproc


# ============================================================================
# @emlCumulativeSum
# ============================================================================
# Computes running cumulative sum.
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .result# — cumulative sum (same length as input)
# ============================================================================

procedure emlCumulativeSum: .data#
    .n = size (.data#)
    
    if .n = 0
        .result# = zero# (0)
    else
        .result# = zero# (.n)
        .result#[1] = .data#[1]
        
        for .i from 2 to .n
            .iPrev = .i - 1
            .result#[.i] = .result#[.iPrev] + .data#[.i]
        endfor
    endif
endproc


# ============================================================================
# @emlDiff
# ============================================================================
# Computes first differences.
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .result# — first differences (length n-1)
#   .error$ — empty if valid, error message if n < 2
# ============================================================================

procedure emlDiff: .data#
    .n = size (.data#)
    .error$ = ""
    
    if .n < 2
        .result# = zero# (0)
        .error$ = "Input must have at least 2 elements for differencing"
    else
        .nOut = .n - 1
        .result# = zero# (.nOut)
        
        for .i from 1 to .nOut
            .iNext = .i + 1
            .result#[.i] = .data#[.iNext] - .data#[.i]
        endfor
    endif
endproc


# ============================================================================
# @emlLag
# ============================================================================
# Creates lagged version of data.
#
# Input:
#   .data# — vector of numeric values
#   .k — lag order (positive integer)
#
# Output:
#   .result# — lagged data (same length, first k elements = undefined)
# ============================================================================

procedure emlLag: .data#, .k
    .n = size (.data#)
    
    if .n = 0
        .result# = zero# (0)
    elsif .k = 0
        # No lag - return copy
        .result# = .data#
    elsif .k >= .n
        # All undefined
        .result# = zero# (.n)
        for .i from 1 to .n
            .result#[.i] = undefined
        endfor
    else
        .result# = zero# (.n)
        
        # First k elements are undefined
        for .i from 1 to .k
            .result#[.i] = undefined
        endfor
        
        # Remaining elements are lagged values
        for .i from .k + 1 to .n
            .lagIdx = .i - .k
            .result#[.i] = .data#[.lagIdx]
        endfor
    endif
endproc


# ============================================================================
# @emlBinData
# ============================================================================
# Bins data into histogram.
#
# Input:
#   .data# — vector of numeric values
#   .nBins — desired number of bins
#
# Output:
#   .binEdges# — vector of bin edge values (length nBins + 1)
#   .counts# — vector of counts per bin (length nBins)
#   .nBins — actual number of bins used
# ============================================================================

procedure emlBinData: .data#, .nBins
    .n = size (.data#)
    
    if .n = 0
        .binEdges# = zero# (0)
        .counts# = zero# (0)
        .nBins = 0
    else
        .dataMin = min (.data#)
        .dataMax = max (.data#)
        .range = .dataMax - .dataMin
        
        if .range = 0
            # All values identical - single bin
            .nBins = 1
            .binEdges# = {.dataMin, .dataMax}
            .counts# = {.n}
        else
            # Create equal-width bins
            .binWidth = .range / .nBins
            
            # Create bin edges
            .nEdges = .nBins + 1
            .binEdges# = zero# (.nEdges)
            for .i from 1 to .nEdges
                .binEdges#[.i] = .dataMin + (.i - 1) * .binWidth
            endfor
            
            # Ensure last edge exactly equals max (avoid floating-point issues)
            .binEdges#[.nEdges] = .dataMax
            
            # Count elements in each bin
            .counts# = zero# (.nBins)
            
            for .i from 1 to .n
                .x = .data#[.i]
                
                # Find which bin this value belongs to
                .binFound = 0
                for .b from 1 to .nBins
                    if .binFound = 0
                        .leftEdge = .binEdges#[.b]
                        .bNext = .b + 1
                        .rightEdge = .binEdges#[.bNext]
                        
                        # Last bin includes right endpoint
                        if .b = .nBins
                            if .x >= .leftEdge and .x <= .rightEdge
                                .counts#[.b] = .counts#[.b] + 1
                                .binFound = 1
                            endif
                        else
                            if .x >= .leftEdge and .x < .rightEdge
                                .counts#[.b] = .counts#[.b] + 1
                                .binFound = 1
                            endif
                        endif
                    endif
                endfor
            endfor
        endif
    endif
endproc


# ============================================================================
# @emlZScore
# ============================================================================
# Standardizes values to z-scores.
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .result# — z-scores: (xi - mean) / sd
#   .mean — the mean used
#   .sd — the standard deviation used
#   .warning$ — empty if valid, warning message if sd = 0 or n < 2
# ============================================================================

procedure emlZScore: .data#
    .n = size (.data#)
    .warning$ = ""
    
    if .n < 2
        .result# = zero# (.n)
        .mean = undefined
        .sd = undefined
        .warning$ = "Need at least 2 values for z-score computation"
        
        if .n = 1
            .result#[1] = undefined
        endif
    else
        .mean = mean (.data#)
        .sd = stdev (.data#)
        
        if .sd = 0
            # All values identical
            .result# = zero# (.n)
            .warning$ = "Standard deviation is zero; all z-scores set to 0"
        else
            .result# = zero# (.n)
            for .i from 1 to .n
                .result#[.i] = (.data#[.i] - .mean) / .sd
            endfor
        endif
    endif
endproc


# ============================================================================
# @emlRemoveUndefined
# ============================================================================
# Removes undefined values from a vector.
#
# Input:
#   .data# — vector that may contain undefined values
#
# Output:
#   .result# — vector with undefined values removed
#   .nRemoved — count of undefined values removed
#   .nKept — count of valid values retained
#   .keptIndices# — original indices of kept values
# ============================================================================

procedure emlRemoveUndefined: .data#
    .n = size (.data#)
    
    if .n = 0
        .result# = zero# (0)
        .nRemoved = 0
        .nKept = 0
        .keptIndices# = zero# (0)
    else
        # First pass: count defined values
        .nKept = 0
        for .i from 1 to .n
            if .data#[.i] <> undefined
                .nKept = .nKept + 1
            endif
        endfor
        
        .nRemoved = .n - .nKept
        
        # Second pass: collect defined values and their indices
        if .nKept = 0
            .result# = zero# (0)
            .keptIndices# = zero# (0)
        else
            .result# = zero# (.nKept)
            .keptIndices# = zero# (.nKept)
            .outIdx = 0
            
            for .i from 1 to .n
                if .data#[.i] <> undefined
                    .outIdx = .outIdx + 1
                    .result#[.outIdx] = .data#[.i]
                    .keptIndices#[.outIdx] = .i
                endif
            endfor
        endif
    endif
endproc


# ============================================================================
# @emlSortWithIndex
# ============================================================================
# Sorts values ascending while tracking original positions.
#
# Input:
#   .data# — vector of numeric values
#
# Output:
#   .sorted# — sorted values (ascending)
#   .indices# — original positions: .sorted#[i] was at .indices#[i]
# ============================================================================

procedure emlSortWithIndex: .data#
    .n = size (.data#)
    
    if .n = 0
        .sorted# = zero# (0)
        .indices# = zero# (0)
    else
        # Create index array
        .origIndices# = from_to# (1, .n)
        
        # Use shared sorting helper
        @eml_sortPairsByValue: .data#, .origIndices#
        .sorted# = eml_sortPairsByValue.sortedValues#
        .indices# = eml_sortPairsByValue.sortedIndices#
    endif
endproc


# ============================================================================
# @emlConcatenateVectors
# ============================================================================
# Concatenates two vectors.
#
# Input:
#   .v1# — first vector
#   .v2# — second vector
#
# Output:
#   .result# — concatenation of v1# followed by v2#
# ============================================================================

procedure emlConcatenateVectors: .v1#, .v2#
    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .nTotal = .n1 + .n2
    
    if .nTotal = 0
        .result# = zero# (0)
    elsif .n1 = 0
        .result# = .v2#
    elsif .n2 = 0
        .result# = .v1#
    else
        .result# = zero# (.nTotal)
        
        # Copy first vector
        for .i from 1 to .n1
            .result#[.i] = .v1#[.i]
        endfor
        
        # Copy second vector
        for .i from 1 to .n2
            .outIdx = .n1 + .i
            .result#[.outIdx] = .v2#[.i]
        endfor
    endif
endproc


# ============================================================================
# @emlRepeatVector
# ============================================================================
# Repeats a vector n times.
#
# Input:
#   .v# — vector to repeat
#   .nReps — number of repetitions
#
# Output:
#   .result# — v# repeated nReps times
# ============================================================================

procedure emlRepeatVector: .v#, .nReps
    .nV = size (.v#)
    
    if .nReps <= 0 or .nV = 0
        .result# = zero# (0)
    elsif .nReps = 1
        .result# = .v#
    else
        .nTotal = .nV * .nReps
        .result# = zero# (.nTotal)
        
        for .rep from 1 to .nReps
            .offset = (.rep - 1) * .nV
            for .i from 1 to .nV
                .outIdx = .offset + .i
                .result#[.outIdx] = .v#[.i]
            endfor
        endfor
    endif
endproc


# ============================================================================
# END OF CORE UTILITY PROCEDURES
# ============================================================================
