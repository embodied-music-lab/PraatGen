# ============================================================================
# EML Stats : Core Descriptive Statistics
# ============================================================================
# Module: eml-core-descriptive.praat
# Version: 1.0
# Date: 20 February 2026
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlMean, @emlMedian, @emlMode, @emlPercentile, @emlQuartiles,
#   @emlVariance, @emlSD, @emlSEM, @emlSkewness, @emlKurtosis,
#   @emlGeometricMean, @emlHarmonicMean, @emlTrimmedMean,
#   @emlWinsorizedMean, @emlMAD, @emlRange, @emlCI, @emlDescribe
#
# All procedures use the "eml" prefix (EML Stats) to avoid
# namespace collisions with user scripts.
#
# Usage:
#   include eml-core-descriptive.praat
#   myData# = {1, 2, 3, 4, 5}
#   @emlDescribe: myData#
#   appendInfoLine: emlDescribe.summary$
# ============================================================================


# ----------------------------------------------------------------------------
# @emlMean
# Arithmetic mean of a numeric vector.
# Input:  data# — numeric vector
# Output: .result — arithmetic mean (undefined if empty)
# ----------------------------------------------------------------------------
procedure emlMean: .data#
    .n = size (.data#)
    if .n = 0
        .result = undefined
    else
        .result = mean (.data#)
    endif
endproc


# ----------------------------------------------------------------------------
# @emlMedian
# Median of a numeric vector.
# Input:  data# — numeric vector
# Output: .result — median value (undefined if empty)
# For even n, returns average of the two middle values.
# ----------------------------------------------------------------------------
procedure emlMedian: .data#
    .n = size (.data#)
    if .n = 0
        .result = undefined
    else
        .sorted# = sort# (.data#)
        if .n mod 2 = 1
            # Odd: middle element
            .mid = floor (.n / 2) + 1
            .result = .sorted#[.mid]
        else
            # Even: average of two middle elements
            .midLow = .n / 2
            .midHigh = .midLow + 1
            .result = (.sorted#[.midLow] + .sorted#[.midHigh]) / 2
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlMode
# Mode (most frequent value) of a numeric vector.
# Input:  data# — numeric vector
# Output: .result   — modal value (first encountered if tied)
#         .count    — frequency of the mode
#         .isUnique — 1 if unique mode, 0 if tied
# Uses exact equality comparison. For continuous data with no repeats,
# returns first sorted element with count=1 and isUnique=0.
# ----------------------------------------------------------------------------
procedure emlMode: .data#
    .n = size (.data#)
    if .n = 0
        .result = undefined
        .count = 0
        .isUnique = 0
    else
        .sorted# = sort# (.data#)
        .bestVal = .sorted#[1]
        .bestCount = 1
        .isUnique = 1
        .currentVal = .sorted#[1]
        .currentCount = 1
        for .i from 2 to .n
            if .sorted#[.i] = .currentVal
                .currentCount = .currentCount + 1
            else
                # End of a run — compare with best
                if .currentCount > .bestCount
                    .bestVal = .currentVal
                    .bestCount = .currentCount
                    .isUnique = 1
                elsif .currentCount = .bestCount
                    .isUnique = 0
                endif
                .currentVal = .sorted#[.i]
                .currentCount = 1
            endif
        endfor
        # Check the final run
        if .currentCount > .bestCount
            .bestVal = .currentVal
            .bestCount = .currentCount
            .isUnique = 1
        elsif .currentCount = .bestCount
            if .currentVal <> .bestVal
                .isUnique = 0
            endif
        endif
        .result = .bestVal
        .count = .bestCount
    endif
endproc


# ----------------------------------------------------------------------------
# @emlPercentile
# Compute the p-th percentile using linear interpolation (R type=7).
# Input:  data# — numeric vector
#         p     — percentile (0–100)
# Output: .result — interpolated percentile value
# Algorithm: h = (n-1)*p/100 + 1; linear interpolation between order stats.
# ----------------------------------------------------------------------------
procedure emlPercentile: .data#, .p
    .n = size (.data#)
    if .n = 0
        .result = undefined
    elsif .p < 0 or .p > 100
        .result = undefined
    elsif .n = 1
        .result = .data#[1]
    else
        .sorted# = sort# (.data#)
        .h = (.n - 1) * .p / 100 + 1
        .lo = floor (.h)
        .hi = ceiling (.h)
        if .lo = .hi
            .result = .sorted#[.lo]
        else
            .result = .sorted#[.lo] + (.h - .lo) * (.sorted#[.hi] - .sorted#[.lo])
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlQuartiles
# Quartiles and interquartile range.
# Input:  data# — numeric vector
# Output: .q1  — 25th percentile
#         .q2  — 50th percentile (median)
#         .q3  — 75th percentile
#         .iqr — interquartile range (Q3 - Q1)
# Uses @emlPercentile (R type=7 interpolation).
# ----------------------------------------------------------------------------
procedure emlQuartiles: .data#
    .n = size (.data#)
    if .n = 0
        .q1 = undefined
        .q2 = undefined
        .q3 = undefined
        .iqr = undefined
    else
        @emlPercentile: .data#, 25
        .q1 = emlPercentile.result
        @emlPercentile: .data#, 50
        .q2 = emlPercentile.result
        @emlPercentile: .data#, 75
        .q3 = emlPercentile.result
        if .q1 <> undefined and .q3 <> undefined
            .iqr = .q3 - .q1
        else
            .iqr = undefined
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlVariance
# Sample variance (n-1 denominator).
# Input:  data# — numeric vector
# Output: .result — sample variance (undefined if n < 2)
# ----------------------------------------------------------------------------
procedure emlVariance: .data#
    .n = size (.data#)
    if .n < 2
        .result = undefined
    else
        .sd = stdev (.data#)
        .result = .sd * .sd
    endif
endproc


# ----------------------------------------------------------------------------
# @emlSD
# Sample standard deviation (n-1 denominator).
# Input:  data# — numeric vector
# Output: .result — sample SD (undefined if n < 2)
# ----------------------------------------------------------------------------
procedure emlSD: .data#
    .n = size (.data#)
    if .n < 2
        .result = undefined
    else
        .result = stdev (.data#)
    endif
endproc


# ----------------------------------------------------------------------------
# @emlSEM
# Standard error of the mean.
# Input:  data# — numeric vector
# Output: .result — SEM = SD / sqrt(n) (undefined if n < 2)
# ----------------------------------------------------------------------------
procedure emlSEM: .data#
    .n = size (.data#)
    if .n < 2
        .result = undefined
    else
        .result = stdev (.data#) / sqrt (.n)
    endif
endproc


# ----------------------------------------------------------------------------
# @emlSkewness
# Sample skewness (Fisher's definition).
# Input:  data# — numeric vector
# Output: .result — skewness (undefined if n < 3)
# Formula: (n / ((n-1)(n-2))) * sum((xi - mean) / sd)^3
# ----------------------------------------------------------------------------
procedure emlSkewness: .data#
    .n = size (.data#)
    if .n < 3
        .result = undefined
    else
        .m = mean (.data#)
        .s = stdev (.data#)
        if .s = 0
            .result = 0
        else
            .sumCubed = 0
            for .i from 1 to .n
                .z = (.data#[.i] - .m) / .s
                .sumCubed = .sumCubed + .z * .z * .z
            endfor
            .result = (.n / ((.n - 1) * (.n - 2))) * .sumCubed
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlKurtosis
# Excess kurtosis (Fisher's definition, normal = 0).
# Input:  data# — numeric vector
# Output: .result — excess kurtosis (undefined if n < 4)
# Formula: ((n(n+1)) / ((n-1)(n-2)(n-3))) * sum((xi-mean)/sd)^4
#          - (3(n-1)^2) / ((n-2)(n-3))
# ----------------------------------------------------------------------------
procedure emlKurtosis: .data#
    .n = size (.data#)
    if .n < 4
        .result = undefined
    else
        .m = mean (.data#)
        .s = stdev (.data#)
        if .s = 0
            # All values identical: platykurtic extreme
            .result = -3 * (.n - 1) * (.n - 1) / ((.n - 2) * (.n - 3))
        else
            .sumFourth = 0
            for .i from 1 to .n
                .z = (.data#[.i] - .m) / .s
                .z2 = .z * .z
                .sumFourth = .sumFourth + .z2 * .z2
            endfor
            .term1 = (.n * (.n + 1)) / ((.n - 1) * (.n - 2) * (.n - 3))
            .term2 = (3 * (.n - 1) * (.n - 1)) / ((.n - 2) * (.n - 3))
            .result = .term1 * .sumFourth - .term2
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlGeometricMean
# Geometric mean of a numeric vector.
# Input:  data# — numeric vector (all values must be > 0)
# Output: .result  — geometric mean (undefined if any value <= 0 or empty)
#         .error$  — error message if invalid input, else empty
# Formula: exp(mean(ln(data)))
# ----------------------------------------------------------------------------
procedure emlGeometricMean: .data#
    .n = size (.data#)
    .error$ = ""
    if .n = 0
        .result = undefined
    elsif min (.data#) <= 0
        .result = undefined
        .error$ = "Geometric mean requires all positive values"
    else
        .result = exp (mean (ln# (.data#)))
    endif
endproc


# ----------------------------------------------------------------------------
# @emlHarmonicMean
# Harmonic mean of a numeric vector.
# Input:  data# — numeric vector (all values must be > 0)
# Output: .result — harmonic mean (undefined if any value <= 0 or empty)
# Formula: n / sum(1/xi)
# ----------------------------------------------------------------------------
procedure emlHarmonicMean: .data#
    .n = size (.data#)
    if .n = 0
        .result = undefined
    elsif min (.data#) <= 0
        .result = undefined
    else
        .recipSum = 0
        for .i from 1 to .n
            .recipSum = .recipSum + 1 / .data#[.i]
        endfor
        .result = .n / .recipSum
    endif
endproc


# ----------------------------------------------------------------------------
# @emlTrimmedMean
# Trimmed mean: remove a proportion from each tail before averaging.
# Input:  data#      — numeric vector
#         proportion — fraction to trim from each tail (e.g., 0.1 = 10%)
# Output: .result — trimmed mean (undefined if proportion >= 0.5 or empty)
# When proportion = 0, returns ordinary mean.
# ----------------------------------------------------------------------------
procedure emlTrimmedMean: .data#, .proportion
    .n = size (.data#)
    if .n = 0
        .result = undefined
    elsif .proportion < 0 or .proportion >= 0.5
        .result = undefined
    elsif .proportion = 0
        .result = mean (.data#)
    else
        .sorted# = sort# (.data#)
        .k = floor (.n * .proportion)
        .nTrimmed = .n - 2 * .k
        if .nTrimmed <= 0
            .result = undefined
        else
            .sum = 0
            for .i from .k + 1 to .n - .k
                .sum = .sum + .sorted#[.i]
            endfor
            .result = .sum / .nTrimmed
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlWinsorizedMean
# Winsorized mean: replace tail values instead of removing them.
# Input:  data#      — numeric vector
#         proportion — fraction to replace from each tail (e.g., 0.1 = 10%)
# Output: .result — Winsorized mean (undefined if proportion >= 0.5 or empty)
# Replaces bottom k values with value at position k+1 and top k with n-k.
# ----------------------------------------------------------------------------
procedure emlWinsorizedMean: .data#, .proportion
    .n = size (.data#)
    if .n = 0
        .result = undefined
    elsif .proportion < 0 or .proportion >= 0.5
        .result = undefined
    elsif .proportion = 0
        .result = mean (.data#)
    else
        .sorted# = sort# (.data#)
        .k = floor (.n * .proportion)
        if .k = 0
            .result = mean (.data#)
        else
            .lowerVal = .sorted#[.k + 1]
            .upperIdx = .n - .k
            .upperVal = .sorted#[.upperIdx]
            # Sum: k copies of lowerVal + middle values + k copies of upperVal
            .sum = .k * .lowerVal + .k * .upperVal
            for .i from .k + 1 to .upperIdx
                .sum = .sum + .sorted#[.i]
            endfor
            .result = .sum / .n
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlMAD
# Median absolute deviation with consistency constant.
# Input:  data# — numeric vector
# Output: .result — MAD * 1.4826 (scaled for normal consistency)
#         .rawMAD — unscaled MAD (median of absolute deviations)
# Formula: median(|xi - median(x)|) * 1.4826
# ----------------------------------------------------------------------------
procedure emlMAD: .data#
    .n = size (.data#)
    if .n = 0
        .result = undefined
        .rawMAD = undefined
    else
        # Get median of data
        @emlMedian: .data#
        .med = emlMedian.result
        # Compute absolute deviations
        .deviations# = zero# (.n)
        for .i from 1 to .n
            .deviations#[.i] = abs (.data#[.i] - .med)
        endfor
        # Get median of deviations
        @emlMedian: .deviations#
        .rawMAD = emlMedian.result
        .result = .rawMAD * 1.4826
    endif
endproc


# ----------------------------------------------------------------------------
# @emlRange
# Range statistics.
# Input:  data# — numeric vector
# Output: .min   — minimum value
#         .max   — maximum value
#         .range — max - min
# ----------------------------------------------------------------------------
procedure emlRange: .data#
    .n = size (.data#)
    if .n = 0
        .min = undefined
        .max = undefined
        .range = undefined
    else
        .min = min (.data#)
        .max = max (.data#)
        .range = .max - .min
    endif
endproc


# ----------------------------------------------------------------------------
# @emlCI
# Confidence interval for the mean (t-based).
# Input:  data#           — numeric vector
#         confidenceLevel — as proportion (e.g., 0.95 for 95%)
# Output: .lower         — lower bound
#         .upper         — upper bound
#         .mean          — sample mean
#         .marginOfError — half-width of CI
# Formula: mean +/- invStudentQ((1 - conf) / 2, n-1) * SEM
# ----------------------------------------------------------------------------
procedure emlCI: .data#, .confidenceLevel
    .n = size (.data#)
    if .n < 2
        .lower = undefined
        .upper = undefined
        .mean = undefined
        .marginOfError = undefined
    else
        .mean = mean (.data#)
        .sem = stdev (.data#) / sqrt (.n)
        .alpha = 1 - .confidenceLevel
        .tCrit = invStudentQ (.alpha / 2, .n - 1)
        .marginOfError = .tCrit * .sem
        .lower = .mean - .marginOfError
        .upper = .mean + .marginOfError
    endif
endproc


# ----------------------------------------------------------------------------
# @emlDescribe
# Comprehensive descriptive statistics summary.
# Input:  data# — numeric vector
# Output: .n, .mean, .sd, .variance, .sem
#         .median, .q1, .q3, .iqr
#         .min, .max, .range
#         .skewness, .kurtosis
#         .ci95Lower, .ci95Upper
#         .summary$ — multi-line formatted string
# Calls all other pp procedures and assembles results.
# ----------------------------------------------------------------------------
procedure emlDescribe: .data#
    .n = size (.data#)
    if .n = 0
        .mean = undefined
        .sd = undefined
        .variance = undefined
        .sem = undefined
        .median = undefined
        .q1 = undefined
        .q3 = undefined
        .iqr = undefined
        .min = undefined
        .max = undefined
        .range = undefined
        .skewness = undefined
        .kurtosis = undefined
        .ci95Lower = undefined
        .ci95Upper = undefined
        .summary$ = "Descriptive Statistics (n = 0): no data"
    else
        @emlMean: .data#
        .mean = emlMean.result
        @emlSD: .data#
        .sd = emlSD.result
        @emlVariance: .data#
        .variance = emlVariance.result
        @emlSEM: .data#
        .sem = emlSEM.result
        @emlMedian: .data#
        .median = emlMedian.result
        @emlQuartiles: .data#
        .q1 = emlQuartiles.q1
        .q3 = emlQuartiles.q3
        .iqr = emlQuartiles.iqr
        @emlRange: .data#
        .min = emlRange.min
        .max = emlRange.max
        .range = emlRange.range
        @emlSkewness: .data#
        .skewness = emlSkewness.result
        @emlKurtosis: .data#
        .kurtosis = emlKurtosis.result
        @emlCI: .data#, 0.95
        .ci95Lower = emlCI.lower
        .ci95Upper = emlCI.upper
        # Build summary string
        .summary$ = "Descriptive Statistics (n = " + string$ (.n) + ")" + newline$
        .summary$ = .summary$ + "  Mean:       " + fixed$ (.mean, 4) + newline$
        .summary$ = .summary$ + "  Median:     " + fixed$ (.median, 4) + newline$
        .summary$ = .summary$ + "  SD:         " + fixed$ (.sd, 4) + newline$
        .summary$ = .summary$ + "  Variance:   " + fixed$ (.variance, 4) + newline$
        .summary$ = .summary$ + "  SEM:        " + fixed$ (.sem, 4) + newline$
        .summary$ = .summary$ + "  Min:        " + fixed$ (.min, 4) + newline$
        .summary$ = .summary$ + "  Max:        " + fixed$ (.max, 4) + newline$
        .summary$ = .summary$ + "  Range:      " + fixed$ (.range, 4) + newline$
        .summary$ = .summary$ + "  Q1:         " + fixed$ (.q1, 4) + newline$
        .summary$ = .summary$ + "  Q3:         " + fixed$ (.q3, 4) + newline$
        .summary$ = .summary$ + "  IQR:        " + fixed$ (.iqr, 4) + newline$
        .summary$ = .summary$ + "  Skewness:   " + fixed$ (.skewness, 4) + newline$
        .summary$ = .summary$ + "  Kurtosis:   " + fixed$ (.kurtosis, 4) + newline$
        .summary$ = .summary$ + "  95% CI:     [" + fixed$ (.ci95Lower, 4) + ", " + fixed$ (.ci95Upper, 4) + "]"
    endif
endproc
