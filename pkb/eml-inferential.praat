# ============================================================================
# EML Stats : Inferential Statistics
# ============================================================================
# Module: eml-inferential.praat
# Version: 1.0 (Batch 1-7+6B+9: t-tests, effect size, correlations, MWU, Wilcoxon, nonparametric effect sizes, p-value adjustment, ANOVA+eta², Tukey HSD refactor, two-way ANOVA+partial eta², Kruskal-Wallis, Dunn's, pairwise t, pairwise Wilcoxon, Scheffe; convergence: dMatrix in Tukey/ANOVA, rMatrix in Dunn's)
# Date: 4 April 2026
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlTTest, @emlTTestPaired, @emlCohenD,
#   @emlPearsonCorrelation, @emlSpearmanCorrelation,
#   @emlMannWhitneyU, @emlWilcoxonSignedRank,
#   @emlRankBiserialR, @emlMatchedPairsR,
#   @emlBonferroni, @emlHolm, @emlBenjaminiHochberg,
#   @emlTableFromGroups, @emlOneWayAnova, @emlTwoWayAnova, @emlTukeyHSD,
#   @emlEpsilonSquared, @emlKruskalWallis, @emlDunnTest,
#   @emlPairwiseT, @emlPairwiseWilcoxon, @emlScheffe
#
# Dependencies:
#   @emlSpearmanCorrelation requires @emlRankVector from
#   eml-core-utilities.praat. The calling script must include
#   utilities before inferential:
#     include eml-core-utilities.praat
#     include eml-inferential.praat
#
#   @emlTukeyHSD (v0.9+) requires @emlExtractMultipleGroups from
#   eml-extract.praat. The calling script must include extract
#   before inferential:
#     include eml-extract.praat
#     include eml-inferential.praat
#
# All procedures use the "eml" prefix (EML Stats) to avoid
# namespace collisions with user scripts.
# ============================================================================


# ============================================================================
# @emlTTest
# ============================================================================
# Independent-samples t-test (Welch default, Student optional).
#
# Welch's t-test does not assume equal variances and is the modern
# default. Student's pooled-variance t-test is available via the
# .equalVariances parameter for cases where equal variances are
# justified and the pooled estimate is desired.
#
# Arguments:
#   .v1#             - numeric vector, group 1
#   .v2#             - numeric vector, group 2
#   .tails           - 1 (one-tailed) or 2 (two-tailed)
#   .equalVariances  - 0 = Welch (default), 1 = Student (pooled)
#
# Output:
#   .t          - t statistic (positive when mean1 > mean2)
#   .df         - degrees of freedom (fractional for Welch)
#   .p          - p-value
#   .mean1      - mean of group 1
#   .mean2      - mean of group 2
#   .sd1        - SD of group 1
#   .sd2        - SD of group 2
#   .n1         - size of group 1
#   .n2         - size of group 2
#   .meanDiff   - mean1 - mean2
#   .method$    - "Welch" or "Student"
#   .error$     - error message, or "" if valid
#
# One-tailed p: Tests significance in the direction of the observed
#   effect (i.e., p = studentQ(|t|, df)). The caller must check the
#   sign of .t to determine effect direction.
# ============================================================================

procedure emlTTest: .v1#, .v2#, .tails, .equalVariances
    # Initialize outputs
    .t = undefined
    .df = undefined
    .p = undefined
    .mean1 = undefined
    .mean2 = undefined
    .sd1 = undefined
    .sd2 = undefined
    .meanDiff = undefined
    .method$ = ""
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)

    # --- Input validation ---
    if .n1 < 2 or .n2 < 2
        .error$ = "Each group must have at least 2 observations"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute group statistics ---
        .mean1 = mean (.v1#)
        .mean2 = mean (.v2#)
        .sd1 = stdev (.v1#)
        .sd2 = stdev (.v2#)
        .meanDiff = .mean1 - .mean2
        .var1 = .sd1 * .sd1
        .var2 = .sd2 * .sd2

        # Check for zero variance in both groups
        if .var1 = 0 and .var2 = 0
            .error$ = "Both groups have zero variance"
        else
            if .equalVariances = 1
                # --- Student's t-test (pooled variance) ---
                .method$ = "Student"
                .df = .n1 + .n2 - 2
                .pooledVar = ((.n1 - 1) * .var1 + (.n2 - 1) * .var2) / .df
                .se = sqrt (.pooledVar * (1 / .n1 + 1 / .n2))
                .t = .meanDiff / .se
            else
                # --- Welch's t-test (default) ---
                .method$ = "Welch"
                .vn1 = .var1 / .n1
                .vn2 = .var2 / .n2
                .se = sqrt (.vn1 + .vn2)
                .t = .meanDiff / .se

                # Welch-Satterthwaite degrees of freedom
                .numerator = (.vn1 + .vn2) * (.vn1 + .vn2)
                .denom1 = (.vn1 * .vn1) / (.n1 - 1)
                .denom2 = (.vn2 * .vn2) / (.n2 - 1)
                .df = .numerator / (.denom1 + .denom2)
            endif

            # --- p-value ---
            .absT = abs (.t)
            if .tails = 2
                .p = 2 * studentQ (.absT, .df)
            else
                .p = studentQ (.absT, .df)
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTTestPaired
# ============================================================================
# Paired-samples t-test.
#
# Computes within-subject differences (v1 - v2) and tests whether the
# mean difference differs from zero.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .t        - t statistic
#   .df       - degrees of freedom (n - 1)
#   .p        - p-value
#   .meanDiff - mean of differences (v1 - v2)
#   .sdDiff   - SD of differences
#   .seDiff   - standard error of the mean difference
#   .n        - number of pairs
#   .error$   - error message, or "" if valid
#
# One-tailed p: Tests significance in the direction of the observed
#   effect. Check sign of .t for direction.
# ============================================================================

procedure emlTTestPaired: .v1#, .v2#, .tails
    # Initialize outputs
    .t = undefined
    .df = undefined
    .p = undefined
    .meanDiff = undefined
    .sdDiff = undefined
    .seDiff = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .n = .n1

    # --- Input validation ---
    if .n1 <> .n2
        .error$ = "Vectors must have equal length for paired test"
        .n = 0
    elsif .n < 2
        .error$ = "Need at least 2 pairs"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute differences ---
        .diffs# = zero# (.n)
        for .i from 1 to .n
            .diffs#[.i] = .v1#[.i] - .v2#[.i]
        endfor

        .meanDiff = mean (.diffs#)
        .sdDiff = stdev (.diffs#)

        if .sdDiff = 0
            .error$ = "All differences are identical (zero variance)"
        else
            .seDiff = .sdDiff / sqrt (.n)
            .df = .n - 1
            .t = .meanDiff / .seDiff

            # --- p-value ---
            .absT = abs (.t)
            if .tails = 2
                .p = 2 * studentQ (.absT, .df)
            else
                .p = studentQ (.absT, .df)
            endif
        endif
    endif
endproc


# ============================================================================
# @emlCohenD
# ============================================================================
# Cohen's d and Hedges' g for independent samples.
#
# Cohen's d uses the pooled standard deviation as the standardizer.
# Hedges' g applies a correction factor J for small-sample bias.
#
# The correction factor uses the standard approximation:
#   J = 1 - 3 / (4 * df - 1)
# where df = n1 + n2 - 2. This is accurate to 3+ decimal places
# for df >= 4 and is the formula used by most statistical software.
#
# Arguments:
#   .v1# - numeric vector, group 1
#   .v2# - numeric vector, group 2
#
# Output:
#   .d                - Cohen's d (positive when mean1 > mean2)
#   .g                - Hedges' g (bias-corrected d)
#   .pooledSD         - pooled standard deviation
#   .correctionFactor - J (Hedges' correction; multiply d by J to get g)
#   .mean1            - mean of group 1
#   .mean2            - mean of group 2
#   .n1               - size of group 1
#   .n2               - size of group 2
#   .error$           - error message, or "" if valid
# ============================================================================

procedure emlCohenD: .v1#, .v2#
    # Initialize outputs
    .d = undefined
    .g = undefined
    .pooledSD = undefined
    .correctionFactor = undefined
    .mean1 = undefined
    .mean2 = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)

    # --- Input validation ---
    if .n1 < 2 or .n2 < 2
        .error$ = "Each group must have at least 2 observations"
    else
        .mean1 = mean (.v1#)
        .mean2 = mean (.v2#)
        .sd1 = stdev (.v1#)
        .sd2 = stdev (.v2#)
        .var1 = .sd1 * .sd1
        .var2 = .sd2 * .sd2

        # Pooled standard deviation
        .df = .n1 + .n2 - 2
        .pooledVar = ((.n1 - 1) * .var1 + (.n2 - 1) * .var2) / .df
        .pooledSD = sqrt (.pooledVar)

        if .pooledSD = 0
            .error$ = "Pooled SD is zero (no variance in either group)"
        else
            # Cohen's d
            .d = (.mean1 - .mean2) / .pooledSD

            # Hedges' g correction factor (approximation)
            # J = 1 - 3 / (4 * df - 1)
            .correctionFactor = 1 - 3 / (4 * .df - 1)
            .g = .d * .correctionFactor
        endif
    endif
endproc


# ============================================================================
# @emlPearsonCorrelation
# ============================================================================
# Pearson product-moment correlation coefficient.
#
# Computes r, converts to t statistic for significance testing.
# Formula: t = r * sqrt((n-2) / (1 - r^2))
#
# For perfect correlations (|r| = 1), t is undefined (division by
# zero). In this case, p is set to 0.
#
# Arguments:
#   .x#    - numeric vector, variable 1
#   .y#    - numeric vector, variable 2 (same length as x#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .r      - Pearson correlation coefficient
#   .t      - t statistic
#   .df     - degrees of freedom (n - 2)
#   .p      - p-value
#   .n      - number of pairs
#   .error$ - error message, or "" if valid
# ============================================================================

procedure emlPearsonCorrelation: .x#, .y#, .tails
    # Initialize outputs
    .r = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .error$ = ""

    .nx = size (.x#)
    .ny = size (.y#)
    .n = .nx

    # --- Input validation ---
    if .nx <> .ny
        .error$ = "Vectors must have equal length"
        .n = 0
    elsif .n < 3
        .error$ = "Need at least 3 pairs for correlation"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute Pearson r ---
        .meanX = mean (.x#)
        .meanY = mean (.y#)
        .sumXY = 0
        .sumX2 = 0
        .sumY2 = 0

        for .i from 1 to .n
            .dx = .x#[.i] - .meanX
            .dy = .y#[.i] - .meanY
            .sumXY = .sumXY + .dx * .dy
            .sumX2 = .sumX2 + .dx * .dx
            .sumY2 = .sumY2 + .dy * .dy
        endfor

        # Check for zero variance
        if .sumX2 = 0 or .sumY2 = 0
            .error$ = "One or both variables have zero variance"
        else
            .r = .sumXY / sqrt (.sumX2 * .sumY2)
            .df = .n - 2

            # --- t statistic and p-value ---
            .rSquared = .r * .r
            if .rSquared >= 1
                # Perfect correlation — t is infinite, p is 0
                .t = undefined
                .p = 0
            else
                .t = .r * sqrt (.df / (1 - .rSquared))
                .absT = abs (.t)
                if .tails = 2
                    .p = 2 * studentQ (.absT, .df)
                else
                    .p = studentQ (.absT, .df)
                endif
            endif
        endif
    endif
endproc


# ============================================================================
# @emlSpearmanCorrelation
# ============================================================================
# Spearman rank-order correlation coefficient.
#
# Ranks both variables using @emlRankVector (with average tie handling),
# then computes Pearson r on the ranks. This is mathematically
# equivalent to the standard Spearman formula and handles ties
# correctly (unlike the simplified 1 - 6*sum(d^2)/(n*(n^2-1)) formula
# which assumes no ties).
#
# DEPENDENCY: Requires @emlRankVector from eml-core-utilities.praat.
# The calling script must include utilities before inferential.
#
# Arguments:
#   .x#    - numeric vector, variable 1
#   .y#    - numeric vector, variable 2 (same length as x#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .rho    - Spearman correlation coefficient
#   .t      - t statistic (same conversion as Pearson)
#   .df     - degrees of freedom (n - 2)
#   .p      - p-value
#   .n      - number of pairs
#   .error$ - error message, or "" if valid
# ============================================================================

procedure emlSpearmanCorrelation: .x#, .y#, .tails
    # Initialize outputs
    .rho = undefined
    .t = undefined
    .df = undefined
    .p = undefined
    .error$ = ""

    .nx = size (.x#)
    .ny = size (.y#)
    .n = .nx

    # --- Input validation ---
    if .nx <> .ny
        .error$ = "Vectors must have equal length"
        .n = 0
    elsif .n < 3
        .error$ = "Need at least 3 pairs for correlation"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Rank both variables ---
        @emlRankVector: .x#
        .ranksX# = emlRankVector.ranks#

        @emlRankVector: .y#
        .ranksY# = emlRankVector.ranks#

        # --- Compute Pearson r on ranks ---
        @emlPearsonCorrelation: .ranksX#, .ranksY#, .tails
        if emlPearsonCorrelation.error$ <> ""
            .error$ = emlPearsonCorrelation.error$
        else
            .rho = emlPearsonCorrelation.r
            .t = emlPearsonCorrelation.t
            .df = emlPearsonCorrelation.df
            .p = emlPearsonCorrelation.p
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: Exact p-value for Mann-Whitney U via DP
# ============================================================================
# Computes the exact null distribution of U1 using dynamic programming.
#
# Under the null hypothesis, all assignments of N = n1 + n2 items into
# two groups are equally likely. The distribution of U1 is computed by
# considering each rank position from highest to lowest: if the item
# belongs to group 1, it contributes the current n2 count to U1.
#
# Recurrence:
#   count(u, m, n) = count(u - n, m - 1, n) + count(u, m, n - 1)
#   where m = items remaining for group 1, n = items remaining for group 2
#
# Base case: count(0, 0, n) = 1 for all n; count(u, 0, n) = 0 for u > 0
#
# Returns cumulative probabilities (left and right tail).
# Uses the no-tie null distribution. When ties exist in the data, the
# exact p-value is slightly conservative (standard practice).
#
# Input:
#   .u1       - observed U1 statistic
#   .n1       - size of group 1
#   .n2       - size of group 2
#
# Output:
#   .pLeft    - P(U <= floor(u1)) under the null
#   .pRight   - P(U >= ceiling(u1)) under the null
# ============================================================================

procedure eml_mannWhitneyExactP: .u1, .n1, .n2
    .maxU = .n1 * .n2
    .vecSize = .maxU + 1

    # DP table: dp##[m + 1, u + 1] = count(u, m, current_n)
    # Iterate n from 0 to .n2 as outer loop
    .dp## = zero## (.n1 + 1, .vecSize)

    # Base case: n = 0 → count(0, m, 0) = 1 for all m
    for .m from 0 to .n1
        .dp##[.m + 1, 1] = 1
    endfor

    # Fill DP: iterate n from 1 to .n2
    for .n from 1 to .n2
        .new## = zero## (.n1 + 1, .vecSize)
        # m = 0: count(u, 0, n) = 1 if u = 0, else 0
        .new##[1, 1] = 1

        for .m from 1 to .n1
            for .u from 0 to .m * .n
                # count(u, m, n) = count(u - n, m - 1, n) + count(u, m, n - 1)
                .term1 = 0
                if .u >= .n
                    .term1 = .new##[.m, .u - .n + 1]
                endif
                .term2 = .dp##[.m + 1, .u + 1]
                .new##[.m + 1, .u + 1] = .term1 + .term2
            endfor
        endfor

        .dp## = .new##
    endfor

    # Total configurations = C(n1 + n2, n1)
    .total = 0
    for .u from 0 to .maxU
        .total = .total + .dp##[.n1 + 1, .u + 1]
    endfor

    # Cumulative left tail: P(U <= floor(u1))
    .uFloor = floor (.u1)
    if .uFloor < 0
        .uFloor = 0
    endif
    if .uFloor > .maxU
        .uFloor = .maxU
    endif
    .cumLeft = 0
    for .u from 0 to .uFloor
        .cumLeft = .cumLeft + .dp##[.n1 + 1, .u + 1]
    endfor
    .pLeft = .cumLeft / .total

    # Cumulative right tail: P(U >= ceiling(u1))
    .uCeil = ceiling (.u1)
    if .uCeil < 0
        .uCeil = 0
    endif
    if .uCeil > .maxU
        .uCeil = .maxU
    endif
    .cumRight = 0
    for .u from .uCeil to .maxU
        .cumRight = .cumRight + .dp##[.n1 + 1, .u + 1]
    endfor
    .pRight = .cumRight / .total
endproc


# ============================================================================
# @emlMannWhitneyU
# ============================================================================
# Mann-Whitney U test for two independent samples.
#
# Tests whether the distributions of two groups differ. Uses rank-based
# comparison (nonparametric alternative to independent-samples t-test).
#
# Algorithm selection:
#   n1 + n2 <= 20 → exact p-value via DP (no-tie null distribution)
#   n1 + n2 > 20  → normal approximation with continuity correction
#                    and tie correction factor
#
# DEPENDENCY: Requires @emlRankVector from eml-core-utilities.praat.
# The calling script must include utilities before inferential.
#
# Arguments:
#   .v1#   - numeric vector, group 1
#   .v2#   - numeric vector, group 2
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .u1       - U statistic for group 1
#   .u2       - U statistic for group 2 (= n1*n2 - u1)
#   .p        - p-value
#   .n1       - size of group 1
#   .n2       - size of group 2
#   .r1       - rank sum of group 1
#   .r2       - rank sum of group 2
#   .method$  - "exact" or "normal approximation"
#   .z        - z statistic (approximation path only; undefined for exact)
#   .error$   - error message, or "" if valid
#
# One-tailed p: Tests significance in the direction of the observed
#   effect. U1 < n1*n2/2 suggests group 1 < group 2; U1 > n1*n2/2
#   suggests group 1 > group 2.
# ============================================================================

procedure emlMannWhitneyU: .v1#, .v2#, .tails
    # Initialize outputs
    .u1 = undefined
    .u2 = undefined
    .p = undefined
    .r1 = undefined
    .r2 = undefined
    .method$ = ""
    .z = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .nTotal = .n1 + .n2

    # --- Input validation ---
    if .n1 < 1
        .error$ = "Group 1 must have at least 1 observation"
    elsif .n2 < 1
        .error$ = "Group 2 must have at least 1 observation"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Combine and rank ---
        .combined# = zero# (.nTotal)
        for .i from 1 to .n1
            .combined#[.i] = .v1#[.i]
        endfor
        for .i from 1 to .n2
            .combined#[.n1 + .i] = .v2#[.i]
        endfor

        @emlRankVector: .combined#
        .ranks# = emlRankVector.ranks#

        # Rank sums
        .r1 = 0
        for .i from 1 to .n1
            .r1 = .r1 + .ranks#[.i]
        endfor
        .r2 = 0
        for .i from 1 to .n2
            .r2 = .r2 + .ranks#[.n1 + .i]
        endfor

        # U statistics
        .u1 = .r1 - .n1 * (.n1 + 1) / 2
        .u2 = .r2 - .n2 * (.n2 + 1) / 2
        .expectedU = .n1 * .n2 / 2

        if .nTotal <= 20
            # --- Exact path (DP) ---
            .method$ = "exact"

            @eml_mannWhitneyExactP: .u1, .n1, .n2

            if .tails = 2
                .p = min (1, 2 * min (eml_mannWhitneyExactP.pLeft, eml_mannWhitneyExactP.pRight))
            else
                # One-tailed: p in direction of observed effect
                if .u1 <= .expectedU
                    .p = eml_mannWhitneyExactP.pLeft
                else
                    .p = eml_mannWhitneyExactP.pRight
                endif
            endif
        else
            # --- Normal approximation path ---
            .method$ = "normal approximation"

            # Tie correction factor
            # T = sum(t_k^3 - t_k) for each tie group of size t_k
            # Computed from the combined ranking
            .tieCorrection = 0
            if emlRankVector.hasTies = 1
                # Re-sort combined to find tie group sizes
                # Use sorted values from ranks to count consecutive equal ranks
                # More efficient: count tie groups from sorted ranks
                .sortedRanks# = zero# (.nTotal)
                for .i from 1 to .nTotal
                    .sortedRanks#[.i] = .ranks#[.i]
                endfor
                # Sort ranks (they may not be in order since they're assigned
                # to original positions)
                # Use simple insertion sort for ranks
                for .i from 2 to .nTotal
                    .key = .sortedRanks#[.i]
                    .j = .i - 1
                    while .j >= 1 and .sortedRanks#[.j] > .key
                        .sortedRanks#[.j + 1] = .sortedRanks#[.j]
                        .j = .j - 1
                    endwhile
                    .sortedRanks#[.j + 1] = .key
                endfor

                # Count consecutive equal ranks
                .i = 1
                while .i <= .nTotal
                    .tieSize = 1
                    while .i + .tieSize <= .nTotal and .sortedRanks#[.i + .tieSize] = .sortedRanks#[.i]
                        .tieSize = .tieSize + 1
                    endwhile
                    if .tieSize > 1
                        .tieCorrection = .tieCorrection + (.tieSize * .tieSize * .tieSize - .tieSize)
                    endif
                    .i = .i + .tieSize
                endwhile
            endif

            # Variance with tie correction
            .varU = .n1 * .n2 * (.nTotal + 1) / 12
            if .tieCorrection > 0
                .varU = .varU - .n1 * .n2 * .tieCorrection / (12 * .nTotal * (.nTotal - 1))
            endif

            if .varU <= 0
                # Degenerate case: all values identical
                .p = 1
                .z = 0
            else
                .sdU = sqrt (.varU)

                # Continuity correction: shift U 0.5 toward expected value
                if .u1 < .expectedU
                    .zNum = .u1 + 0.5 - .expectedU
                elsif .u1 > .expectedU
                    .zNum = .u1 - 0.5 - .expectedU
                else
                    .zNum = 0
                endif

                .z = .zNum / .sdU

                if .tails = 2
                    .p = 2 * gaussQ (abs (.z))
                else
                    # One-tailed: p in direction of observed effect
                    .p = gaussQ (abs (.z))
                endif
            endif
        endif
    endif
endproc


# ============================================================================
# INTERNAL HELPER: Exact p-value for Wilcoxon Signed-Rank via Subset-Sum DP
# ============================================================================
# Computes the exact null distribution of T+ (sum of positive ranks)
# under the no-tie assumption: ranks are integers 1, 2, ..., n.
#
# Uses dynamic programming to count subsets of {1,...,n} with each
# possible sum. Equivalent to 2^n enumeration but O(n * maxT) time
# and O(maxT) space.
#
# Input:
#   .tPlus    - observed T+ (may be non-integer when ties exist)
#   .n        - number of non-zero differences
#
# Output:
#   .pLeft    - P(T+ <= floor(tPlus)) under no-tie null
#   .pRight   - P(T+ >= ceiling(tPlus)) under no-tie null
#
# Note: The no-tie null distribution is standard (matches R wilcox.test
# and scipy wilcoxon exact). When ties exist in the absolute differences,
# the exact test is slightly conservative.
# ============================================================================

procedure eml_wilcoxonExactP: .tPlus, .n
    .maxT = .n * (.n + 1) / 2
    .total = 2 ^ .n
    .vecSize = floor (.maxT) + 1

    # DP: .dp#[s + 1] = number of subsets of {1,...,processed} with sum = s
    .dp# = zero# (.vecSize)
    .dp#[1] = 1

    for .rank from 1 to .n
        .newDp# = zero# (.vecSize)
        for .s from 0 to floor (.maxT)
            if .dp#[.s + 1] > 0
                # Exclude this rank
                .newDp#[.s + 1] = .newDp#[.s + 1] + .dp#[.s + 1]
                # Include this rank
                .sNew = .s + .rank
                if .sNew <= floor (.maxT)
                    .newDp#[.sNew + 1] = .newDp#[.sNew + 1] + .dp#[.s + 1]
                endif
            endif
        endfor
        .dp# = .newDp#
    endfor

    # Left tail: P(T+ <= floor(tPlus))
    .tFloor = floor (.tPlus)
    if .tFloor > floor (.maxT)
        .tFloor = floor (.maxT)
    endif
    if .tFloor < 0
        .tFloor = 0
    endif
    .cumLeft = 0
    for .s from 0 to .tFloor
        .cumLeft = .cumLeft + .dp#[.s + 1]
    endfor
    .pLeft = .cumLeft / .total

    # Right tail: P(T+ >= ceiling(tPlus))
    .tCeil = ceiling (.tPlus)
    if .tCeil > floor (.maxT)
        .tCeil = floor (.maxT)
    endif
    if .tCeil < 0
        .tCeil = 0
    endif
    .cumRight = 0
    for .s from .tCeil to floor (.maxT)
        .cumRight = .cumRight + .dp#[.s + 1]
    endfor
    .pRight = .cumRight / .total
endproc


# ============================================================================
# @emlWilcoxonSignedRank
# ============================================================================
# Wilcoxon signed-rank test for paired samples.
#
# Tests whether the distribution of paired differences is symmetric
# around zero. Nonparametric alternative to the paired t-test.
#
# Algorithm selection:
#   n_nonzero <= 15 -> exact p-value via subset-sum DP
#                      (no-tie null distribution, standard)
#   n_nonzero > 15  -> normal approximation with continuity correction
#                      and tie correction factor
#
# Zero differences are excluded before ranking (standard practice).
# T+ is computed from the actual (possibly tied) ranks of absolute
# differences. For the exact path, the p-value comes from the no-tie
# null distribution (matching R and scipy convention).
#
# DEPENDENCY: Requires @emlRankVector from eml-core-utilities.praat.
# The calling script must include utilities before inferential.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .tails - 1 (one-tailed) or 2 (two-tailed)
#
# Output:
#   .tPlus    - T+ (sum of ranks of positive differences)
#   .tMinus   - T- (sum of ranks of negative differences)
#   .p        - p-value
#   .n        - number of pairs (input length)
#   .nNonzero - number of non-zero differences (used for test)
#   .nZero    - number of zero differences (excluded)
#   .method$  - "exact" or "normal approximation"
#   .z        - z statistic (approximation path only; undefined for exact)
#   .error$   - error message, or "" if valid
#
# One-tailed p: Tests significance in the direction of the observed
#   effect. T+ > n*(n+1)/4 suggests v1 > v2; T+ < n*(n+1)/4
#   suggests v1 < v2.
# ============================================================================

procedure emlWilcoxonSignedRank: .v1#, .v2#, .tails
    # Initialize outputs
    .tPlus = undefined
    .tMinus = undefined
    .p = undefined
    .nNonzero = 0
    .nZero = 0
    .method$ = ""
    .z = undefined
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)
    .n = .n1

    # --- Input validation ---
    if .n1 <> .n2
        .error$ = "Vectors must have equal length for paired test"
        .n = 0
    elsif .n < 1
        .error$ = "Need at least 1 pair"
    elsif .tails < 1 or .tails > 2
        .error$ = "tails must be 1 or 2"
    else
        # --- Compute differences and separate zeros ---
        .allDiffs# = zero# (.n)
        for .i from 1 to .n
            .allDiffs#[.i] = .v1#[.i] - .v2#[.i]
        endfor

        # Count non-zero diffs
        .nNonzero = 0
        for .i from 1 to .n
            if .allDiffs#[.i] <> 0
                .nNonzero = .nNonzero + 1
            endif
        endfor
        .nZero = .n - .nNonzero

        if .nNonzero = 0
            .error$ = "All differences are zero; cannot perform test"
        else
            # Extract non-zero diffs
            .nonzeroDiffs# = zero# (.nNonzero)
            .idx = 0
            for .i from 1 to .n
                if .allDiffs#[.i] <> 0
                    .idx = .idx + 1
                    .nonzeroDiffs#[.idx] = .allDiffs#[.i]
                endif
            endfor

            # Absolute values of non-zero diffs
            .absDiffs# = zero# (.nNonzero)
            for .i from 1 to .nNonzero
                .absDiffs#[.i] = abs (.nonzeroDiffs#[.i])
            endfor

            # Rank absolute differences (with average tie handling)
            @emlRankVector: .absDiffs#
            .ranks# = emlRankVector.ranks#

            # Compute T+ and T-
            .tPlus = 0
            .tMinus = 0
            for .i from 1 to .nNonzero
                if .nonzeroDiffs#[.i] > 0
                    .tPlus = .tPlus + .ranks#[.i]
                else
                    .tMinus = .tMinus + .ranks#[.i]
                endif
            endfor

            .expectedT = .nNonzero * (.nNonzero + 1) / 4

            if .nNonzero <= 15
                # --- Exact path (subset-sum DP) ---
                .method$ = "exact"

                @eml_wilcoxonExactP: .tPlus, .nNonzero

                if .tails = 2
                    .pMin = eml_wilcoxonExactP.pLeft
                    if eml_wilcoxonExactP.pRight < .pMin
                        .pMin = eml_wilcoxonExactP.pRight
                    endif
                    .p = 2 * .pMin
                    if .p > 1
                        .p = 1
                    endif
                else
                    # One-tailed: p in direction of observed effect
                    if .tPlus >= .expectedT
                        .p = eml_wilcoxonExactP.pRight
                    else
                        .p = eml_wilcoxonExactP.pLeft
                    endif
                endif
            else
                # --- Normal approximation path ---
                .method$ = "normal approximation"

                .varT = .nNonzero * (.nNonzero + 1) * (2 * .nNonzero + 1) / 24

                # Tie correction: subtract sum(t^3 - t)/48 for each tie group
                if emlRankVector.hasTies = 1
                    # Sort ranks to find tie groups
                    .sortedRanks# = zero# (.nNonzero)
                    for .i from 1 to .nNonzero
                        .sortedRanks#[.i] = .ranks#[.i]
                    endfor
                    # Insertion sort
                    for .i from 2 to .nNonzero
                        .key = .sortedRanks#[.i]
                        .j = .i - 1
                        while .j >= 1 and .sortedRanks#[.j] > .key
                            .sortedRanks#[.j + 1] = .sortedRanks#[.j]
                            .j = .j - 1
                        endwhile
                        .sortedRanks#[.j + 1] = .key
                    endfor

                    # Count consecutive equal ranks
                    .tieCorrection = 0
                    .i = 1
                    while .i <= .nNonzero
                        .tieSize = 1
                        while .i + .tieSize <= .nNonzero and .sortedRanks#[.i + .tieSize] = .sortedRanks#[.i]
                            .tieSize = .tieSize + 1
                        endwhile
                        if .tieSize > 1
                            .tieCorrection = .tieCorrection + (.tieSize * .tieSize * .tieSize - .tieSize)
                        endif
                        .i = .i + .tieSize
                    endwhile

                    .varT = .varT - .tieCorrection / 48
                endif

                if .varT <= 0
                    # Degenerate case
                    .p = 1
                    .z = 0
                else
                    .sdT = sqrt (.varT)

                    # Continuity correction
                    if .tPlus > .expectedT
                        .zNum = .tPlus - 0.5 - .expectedT
                    elsif .tPlus < .expectedT
                        .zNum = .tPlus + 0.5 - .expectedT
                    else
                        .zNum = 0
                    endif

                    .z = .zNum / .sdT

                    if .tails = 2
                        .p = 2 * gaussQ (abs (.z))
                    else
                        .p = gaussQ (abs (.z))
                    endif
                endif
            endif
        endif
    endif
endproc


# ============================================================================
# @emlRankBiserialR
# ============================================================================
# Rank-biserial correlation: effect size for Mann-Whitney U test.
#
# Measures the degree of overlap between two independent groups.
# Computed as the directed rank-biserial correlation (Wendt 1972,
# Kerby 2014):
#
#   r = (U1 - U2) / (n1 * n2)
#
# where U1 and U2 are the Mann-Whitney U statistics for groups 1 and 2.
#
# Interpretation:
#   r = +1  — complete separation, group 1 > group 2
#   r =  0  — no difference (complete overlap)
#   r = -1  — complete separation, group 1 < group 2
#
# DEPENDENCY: Requires @emlMannWhitneyU (this file) and @emlRankVector
# from eml-core-utilities.praat.
#
# Arguments:
#   .v1#   - numeric vector, group 1
#   .v2#   - numeric vector, group 2
#   .tails - 1 (one-tailed) or 2 (two-tailed) — controls p from MWU
#
# Output:
#   .r       - rank-biserial correlation (range -1 to +1)
#   .u1      - U statistic for group 1 (passthrough from MWU)
#   .u2      - U statistic for group 2 (passthrough from MWU)
#   .p       - p-value (passthrough from MWU)
#   .n1      - size of group 1
#   .n2      - size of group 2
#   .method$ - "exact" or "normal approximation" (from MWU)
#   .error$  - error message, or "" if valid
#
# Note: r is always directed regardless of .tails. The .tails parameter
# only affects the p-value computation within the internal MWU call.
# ============================================================================

procedure emlRankBiserialR: .v1#, .v2#, .tails
    # Initialize outputs
    .r = undefined
    .u1 = undefined
    .u2 = undefined
    .p = undefined
    .method$ = ""
    .error$ = ""

    .n1 = size (.v1#)
    .n2 = size (.v2#)

    # Run Mann-Whitney U internally
    @emlMannWhitneyU: .v1#, .v2#, .tails

    if emlMannWhitneyU.error$ <> ""
        .error$ = emlMannWhitneyU.error$
    else
        # Pass through MWU outputs
        .u1 = emlMannWhitneyU.u1
        .u2 = emlMannWhitneyU.u2
        .p = emlMannWhitneyU.p
        .n1 = emlMannWhitneyU.n1
        .n2 = emlMannWhitneyU.n2
        .method$ = emlMannWhitneyU.method$

        # Rank-biserial r (directed)
        .r = (.u1 - .u2) / (.n1 * .n2)
    endif
endproc


# ============================================================================
# @emlMatchedPairsR
# ============================================================================
# Matched-pairs rank-biserial correlation: effect size for the Wilcoxon
# signed-rank test.
#
# Two effect size measures are provided:
#
# 1. T-based r (always available):
#    r = (T+ - T-) / S
#    where S = n_nonzero * (n_nonzero + 1) / 2
#    This is the "simple difference formula" (Kerby 2014): the
#    proportion of favorable ranks minus unfavorable ranks.
#
# 2. Z-based r (approximation path only, Rosenthal 1991):
#    rZ = z / sqrt(n_nonzero)
#    Only meaningful when the normal approximation is used
#    (n_nonzero > 15). Set to undefined for the exact path.
#
# Interpretation (both measures):
#   r = +1  — all differences favor v1 > v2
#   r =  0  — balanced (no directional effect)
#   r = -1  — all differences favor v2 > v1
#
# DEPENDENCY: Requires @emlWilcoxonSignedRank (this file) and
# @emlRankVector from eml-core-utilities.praat.
#
# Arguments:
#   .v1#   - numeric vector, condition 1
#   .v2#   - numeric vector, condition 2 (same length as v1#)
#   .tails - 1 (one-tailed) or 2 (two-tailed) — controls p
#
# Output:
#   .r        - T-based rank-biserial r (range -1 to +1; always available)
#   .rZ       - Z-based r (Rosenthal 1991; undefined for exact path)
#   .tPlus    - T+ (passthrough from Wilcoxon)
#   .tMinus   - T- (passthrough from Wilcoxon)
#   .p        - p-value (passthrough from Wilcoxon)
#   .n        - number of pairs (input length)
#   .nNonzero - non-zero differences (used for test)
#   .nZero    - zero differences (excluded)
#   .method$  - "exact" or "normal approximation" (from Wilcoxon)
#   .error$   - error message, or "" if valid
# ============================================================================

procedure emlMatchedPairsR: .v1#, .v2#, .tails
    # Initialize outputs
    .r = undefined
    .rZ = undefined
    .tPlus = undefined
    .tMinus = undefined
    .p = undefined
    .nNonzero = 0
    .nZero = 0
    .method$ = ""
    .error$ = ""

    .n = size (.v1#)

    # Run Wilcoxon signed-rank internally
    @emlWilcoxonSignedRank: .v1#, .v2#, .tails

    if emlWilcoxonSignedRank.error$ <> ""
        .error$ = emlWilcoxonSignedRank.error$
        .n = emlWilcoxonSignedRank.n
    else
        # Pass through Wilcoxon outputs
        .tPlus = emlWilcoxonSignedRank.tPlus
        .tMinus = emlWilcoxonSignedRank.tMinus
        .p = emlWilcoxonSignedRank.p
        .n = emlWilcoxonSignedRank.n
        .nNonzero = emlWilcoxonSignedRank.nNonzero
        .nZero = emlWilcoxonSignedRank.nZero
        .method$ = emlWilcoxonSignedRank.method$

        # T-based r (directed, Kerby 2014)
        .sMax = .nNonzero * (.nNonzero + 1) / 2
        .r = (.tPlus - .tMinus) / .sMax

        # Z-based r (Rosenthal 1991) — approximation path only
        if .method$ = "normal approximation"
            .rZ = emlWilcoxonSignedRank.z / sqrt (.nNonzero)
        else
            .rZ = undefined
        endif
    endif
endproc


# ============================================================================
# @emlBonferroni
# ============================================================================
# Bonferroni correction for multiple comparisons.
#
# Each p-value is multiplied by the number of comparisons k, capped at 1.0.
# The most conservative standard correction; controls family-wise error rate.
#
# Arguments:
#   .pValues#  - vector of raw p-values
#
# Output:
#   .adjusted# - vector of adjusted p-values (same order as input)
#   .k         - number of comparisons
#   .error$    - error message, or "" if valid
# ============================================================================

procedure emlBonferroni: .pValues#
    .error$ = ""
    .k = size (.pValues#)
    .adjusted# = zero# (.k)

    if .k = 0
        .error$ = "Empty p-value vector."
    else
        for .i from 1 to .k
            .val = .pValues# [.i] * .k
            if .val > 1
                .val = 1
            endif
            .adjusted# [.i] = .val
        endfor
    endif
endproc


# ============================================================================
# @emlHolm
# ============================================================================
# Holm step-down correction for multiple comparisons (Holm 1979).
#
# Less conservative than Bonferroni while still controlling family-wise
# error rate. Procedure:
#   1. Sort p-values ascending
#   2. Multiply p[i] by (k - i + 1) where i is the ascending rank
#   3. Enforce monotonicity via running maximum (step-down)
#   4. Cap at 1.0
#   5. Return in original input order
#
# DEPENDENCY: Requires @emlSortWithIndex from eml-core-utilities.praat.
#
# Arguments:
#   .pValues#  - vector of raw p-values
#
# Output:
#   .adjusted# - vector of adjusted p-values (same order as input)
#   .k         - number of comparisons
#   .error$    - error message, or "" if valid
# ============================================================================

procedure emlHolm: .pValues#
    .error$ = ""
    .k = size (.pValues#)
    .adjusted# = zero# (.k)

    if .k = 0
        .error$ = "Empty p-value vector."
    elif .k = 1
        .adjusted# [1] = .pValues# [1]
    else
        # Sort ascending, track original indices
        @emlSortWithIndex: .pValues#
        .sortedP# = emlSortWithIndex.sorted#
        .origIdx# = emlSortWithIndex.indices#

        # Step-down: multiply by (k - rank + 1), enforce running max
        .runningMax = 0
        for .i from 1 to .k
            .val = .sortedP# [.i] * (.k - .i + 1)
            if .val > .runningMax
                .runningMax = .val
            endif
            if .runningMax > 1
                .runningMax = 1
            endif
            # Map back to original position
            .origPos = .origIdx# [.i]
            .adjusted# [.origPos] = .runningMax
        endfor
    endif
endproc


# ============================================================================
# @emlBenjaminiHochberg
# ============================================================================
# Benjamini-Hochberg step-up correction for multiple comparisons (1995).
#
# Controls the false discovery rate (FDR) rather than family-wise error
# rate. Less conservative than Bonferroni and Holm; appropriate when
# testing many hypotheses and some false positives are tolerable.
#
# Procedure:
#   1. Sort p-values descending
#   2. For each (processing largest first): adjusted = p * k / rank
#      where rank is the position in ascending order
#   3. Enforce monotonicity via running minimum (step-up)
#   4. Cap at 1.0
#   5. Return in original input order
#
# DEPENDENCY: Requires @emlSortWithIndex from eml-core-utilities.praat.
#
# Arguments:
#   .pValues#  - vector of raw p-values
#
# Output:
#   .adjusted# - vector of adjusted p-values (same order as input)
#   .k         - number of comparisons
#   .error$    - error message, or "" if valid
# ============================================================================

procedure emlBenjaminiHochberg: .pValues#
    .error$ = ""
    .k = size (.pValues#)
    .adjusted# = zero# (.k)

    if .k = 0
        .error$ = "Empty p-value vector."
    elif .k = 1
        .adjusted# [1] = .pValues# [1]
    else
        # Sort ascending, track original indices
        @emlSortWithIndex: .pValues#
        .sortedP# = emlSortWithIndex.sorted#
        .origIdx# = emlSortWithIndex.indices#

        # Process in descending order (step-up): running minimum
        .runningMin = 1
        for .j from 1 to .k
            # Walk from largest to smallest
            .i = .k - .j + 1
            .rank = .i
            .val = .sortedP# [.i] * .k / .rank
            if .val < .runningMin
                .runningMin = .val
            endif
            if .runningMin > 1
                .runningMin = 1
            endif
            # Map back to original position
            .origPos = .origIdx# [.i]
            .adjusted# [.origPos] = .runningMin
        endfor
    endif
endproc

# ============================================================================
# @eml_parseAnovaLine (INTERNAL)
# ============================================================================
# Parses a single row from Praat's ANOVA Info window output.
#
# The built-in Report one-way anova / Report two-way anova commands write
# a whitespace-aligned table to the Info window. Each row has a label
# (e.g., "Between", "Within", "Total", factor name) followed by numeric
# fields: SS, df, MS, F, p. Not all rows have all fields — "Within" and
# "Error" rows have SS, df, MS only; "Total" rows have SS, df only.
#
# Arguments:
#   .info$     - full Info window text (captured via info$() after Report)
#   .rowLabel$ - exact text of the row label to find (e.g., "Between")
#
# Output:
#   .ss  - sum of squares (or undefined if not found)
#   .df  - degrees of freedom (or undefined if not found)
#   .ms  - mean square (or undefined if row has < 3 numeric fields)
#   .f   - F statistic (or undefined if row has < 4 numeric fields)
#   .p   - p-value (or undefined if row has < 5 numeric fields)
#   .error$ - "" on success, diagnostic message on failure
#
# Notes:
#   - Uses extractLine$ to find the row, then tokenizes by whitespace
#   - number() handles scientific notation (e.g., 8.24e-195)
#   - Caller is responsible for passing unique row labels
# ============================================================================

procedure eml_parseAnovaLine: .info$, .rowLabel$
    .ss = undefined
    .df = undefined
    .ms = undefined
    .f = undefined
    .p = undefined
    .error$ = ""

    # Extract the remainder of the line after the row label
    .remainder$ = extractLine$ (.info$, .rowLabel$)

    if .remainder$ = ""
        .error$ = "eml_parseAnovaLine: row label not found: " + .rowLabel$
    else
        # Replace tabs with spaces for consistent tokenization
        .remainder$ = replace$ (.remainder$, tab$, " ", 0)

        # Collapse multiple spaces to single space
        .prev$ = .remainder$
        .remainder$ = replace$ (.remainder$, "  ", " ", 0)
        while .remainder$ <> .prev$
            .prev$ = .remainder$
            .remainder$ = replace$ (.remainder$, "  ", " ", 0)
        endwhile

        # Trim leading spaces
        while left$ (.remainder$, 1) = " "
            .len = length (.remainder$)
            if .len > 1
                .remainder$ = mid$ (.remainder$, 2, .len - 1)
            else
                .remainder$ = ""
            endif
        endwhile

        # Trim trailing spaces
        while length (.remainder$) > 0 and right$ (.remainder$, 1) = " "
            .remainder$ = left$ (.remainder$, length (.remainder$) - 1)
        endwhile

        if .remainder$ = ""
            .error$ = "eml_parseAnovaLine: no numeric data after label: "
            ... + .rowLabel$
        else
            # Tokenize by single spaces
            .nTokens = 0
            .work$ = .remainder$

            while length (.work$) > 0
                .nTokens = .nTokens + 1
                .spacePos = index (.work$, " ")
                if .spacePos > 0
                    .token$[.nTokens] = left$ (.work$, .spacePos - 1)
                    .work$ = mid$ (.work$, .spacePos + 1,
                    ... length (.work$) - .spacePos)
                else
                    .token$[.nTokens] = .work$
                    .work$ = ""
                endif
            endwhile

            # Map positional tokens to output fields
            # Full row (source with F and p): SS df MS F p
            # Partial row (residual): SS df MS
            # Minimal row (total): SS df
            if .nTokens >= 1
                .ss = number (.token$[1])
            endif
            if .nTokens >= 2
                .df = number (.token$[2])
            endif
            if .nTokens >= 3
                .ms = number (.token$[3])
            endif
            if .nTokens >= 4
                .f = number (.token$[4])
            endif
            if .nTokens >= 5
                .p = number (.token$[5])
            endif
        endif
    endif
endproc


# ============================================================================
# @emlTableFromGroups
# ============================================================================
# Convenience constructor: builds a Praat Table from pre-populated group
# data stored in indexed variables on this procedure's namespace.
#
# Before calling, the caller MUST set:
#   emlTableFromGroups.groupLabel$[i]  - string label for group i
#   emlTableFromGroups.groupSize[i]    - number of observations in group i
#   emlTableFromGroups.data#           - flat numeric vector of ALL values
#                                        (group 1 values, then group 2, etc.)
#
# Arguments:
#   .nGroups      - number of groups (>= 1)
#   .dataColName$ - name for the numeric data column
#   .factorColName$ - name for the string factor column
#
# Output:
#   .tableId - ID of the created Table object (caller owns cleanup)
#   .nRows   - total number of rows
#   .error$  - "" on success, diagnostic message on failure
#
# Example:
#   emlTableFromGroups.data# = {10, 12, 14, 20, 22, 24}
#   emlTableFromGroups.groupSize[1] = 3
#   emlTableFromGroups.groupSize[2] = 3
#   emlTableFromGroups.groupLabel$[1] = "Control"
#   emlTableFromGroups.groupLabel$[2] = "Treatment"
#   @emlTableFromGroups: 2, "Score", "Group"
#   tableId = emlTableFromGroups.tableId
# ============================================================================

procedure emlTableFromGroups: .nGroups, .dataColName$, .factorColName$
    .tableId = 0
    .nRows = 0
    .error$ = ""

    # --- Validate inputs ---

    if .nGroups < 1
        .error$ = "emlTableFromGroups: nGroups must be >= 1, got "
        ... + string$ (.nGroups)
    endif

    if .error$ = ""
        # Sum group sizes to get total rows
        for .g from 1 to .nGroups
            .nRows = .nRows + .groupSize[.g]
        endfor

        if .nRows < 1
            .error$ = "emlTableFromGroups: total rows = 0 (all groups empty)"
        endif
    endif

    if .error$ = ""
        # Verify data vector length matches sum of group sizes
        .dataLen = size (.data#)
        if .nRows <> .dataLen
            .error$ = "emlTableFromGroups: sum of groupSize ("
            ... + string$ (.nRows)
            ... + ") does not match data# length ("
            ... + string$ (.dataLen) + ")"
        endif
    endif

    # --- Build Table ---

    if .error$ = ""
        .colSpec$ = .dataColName$ + " " + .factorColName$
        .tableId = Create Table with column names: "emlGroupTable",
        ... .nRows, .colSpec$

        # Populate rows: step through data# sequentially,
        # assigning group labels based on groupSize boundaries
        selectObject: .tableId
        .row = 0
        .dataIdx = 0
        for .g from 1 to .nGroups
            for .j from 1 to .groupSize[.g]
                .row = .row + 1
                .dataIdx = .dataIdx + 1
                Set numeric value: .row, .dataColName$, .data#[.dataIdx]
                Set string value: .row, .factorColName$, .groupLabel$[.g]
            endfor
        endfor
    endif
endproc


# ============================================================================
# @emlTukeyHSD
# ============================================================================
# Performs Tukey Honest Significant Difference post-hoc test on a Table.
#
# Computes pairwise q statistics directly from group means and pooled
# MSE, using Praat's native studentized range distribution functions
# (Get TukeyQ: / Get invTukeyQ:) for p-values and critical values.
#
# Arguments:
#   .tableId       - ID of a Table object (must be in object list)
#   .dataColumn$   - name of the numeric data column
#   .factorColumn$ - name of the string factor column
#   .alpha         - significance level for critical q (e.g., 0.05)
#
# Output:
#   .pMatrix##       - k × k symmetric matrix of pairwise p-values
#                      (diagonal = 1, off-diagonal = Tukey p)
#   .qMatrix##       - k × k symmetric matrix of q statistics
#                      (diagonal = 0)
#   .meanDiff##      - k × k antisymmetric mean differences
#                      (meanDiff[i,j] = mean_i − mean_j)
#   .qCritical       - critical q value at specified alpha
#   .dMatrix##       - k × k antisymmetric Cohen's d matrix
#                      (dMatrix[i,j] = d for group i vs group j; signed)
#   .msWithin        - pooled mean square error (MSE)
#   .dfWithin        - within-groups degrees of freedom (N − k)
#   .groupName$[i]   - group label for row/column i (1..nGroups)
#   .nGroups         - number of groups (k)
#   .nPairs          - number of unique pairwise comparisons (k*(k-1)/2)
#   .sortMap[s]      - maps sorted index s to extraction index
#   .error$          - "" on success, diagnostic message on failure
#
# Access pattern:
#   p-value for group 2 vs group 4: emlTukeyHSD.pMatrix##[2, 4]
#   q statistic for group 1 vs 3:   emlTukeyHSD.qMatrix##[1, 3]
#   mean difference (signed):        emlTukeyHSD.meanDiff##[1, 3]
#   Cohen's d for group 1 vs 3:     emlTukeyHSD.dMatrix##[1, 3]
#   group label for group 2:         emlTukeyHSD.groupName$[2]
#
# Notes:
#   - Groups are sorted alphabetically (matches R convention)
#   - Uses pairwise SE = sqrt(MSE * (1/n_i + 1/n_j) / 2) which
#     handles unbalanced designs naturally
#   - Cohen's d per pair uses two-group pooled SD (via @emlCohenD),
#     consistent with standalone effect size computation
#   - Requires >= 2 groups with enough observations for dfWithin >= 1
#   - Uses Get TukeyQ: (Goodies) for p-values and Get invTukeyQ:
#     for critical q — no Report parsing or Table side effects
#   - Dependencies: @emlExtractMultipleGroups (eml-extract.praat),
#     @eml_getGroupData (eml-inferential.praat),
#     @emlCohenD (eml-inferential.praat)
#   - Original Table selection is restored on return
# ============================================================================

procedure emlTukeyHSD: .tableId, .dataColumn$, .factorColumn$, .alpha
    .nGroups = 0
    .nPairs = 0
    .msWithin = undefined
    .dfWithin = undefined
    .qCritical = undefined
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "emlTukeyHSD: need at least 3 observations, got "
        ... + string$ (.nRows)
    endif

    if .error$ = ""
        .colIdx1 = Get column index: .dataColumn$
        if .colIdx1 = 0
            .error$ = "emlTukeyHSD: data column not found: "
            ... + .dataColumn$
        endif
    endif

    if .error$ = ""
        .colIdx2 = Get column index: .factorColumn$
        if .colIdx2 = 0
            .error$ = "emlTukeyHSD: factor column not found: "
            ... + .factorColumn$
        endif
    endif

    # --- Extract groups ---

    if .error$ = ""
        @emlExtractMultipleGroups: .tableId, .dataColumn$,
        ... .factorColumn$
        if emlExtractMultipleGroups.error$ <> ""
            .error$ = "emlTukeyHSD: "
            ... + emlExtractMultipleGroups.error$
        else
            .nGroups = emlExtractMultipleGroups.nGroups
        endif
    endif

    if .error$ = "" and .nGroups < 2
        .error$ = "emlTukeyHSD: need at least 2 groups, got "
        ... + string$ (.nGroups)
    endif

    # --- Sort groups alphabetically ---

    if .error$ = ""
        .labels$# = empty$# (.nGroups)
        for .g from 1 to .nGroups
            .labels$#[.g] = emlExtractMultipleGroups.groupLabel$[.g]
        endfor
        .sortedLabels$# = sort$# (.labels$#)

        # Map sorted index → encounter index
        for .s from 1 to .nGroups
            .sortedLabel$ = .sortedLabels$#[.s]
            for .e from 1 to .nGroups
                if emlExtractMultipleGroups.groupLabel$[.e]
                ... = .sortedLabel$
                    .sortMap[.s] = .e
                endif
            endfor
            .groupName$[.s] = .sortedLabel$
        endfor
    endif

    # --- Compute group means, sizes, and pooled MSE ---

    if .error$ = ""
        .totalN = 0
        .ssWithin = 0

        for .s from 1 to .nGroups
            @eml_getGroupData: .sortMap[.s]
            .groupN[.s] = eml_getGroupData.n
            .groupMean[.s] = mean (eml_getGroupData.data#)
            .totalN = .totalN + .groupN[.s]

            # SS within for this group (vectorized)
            .centered# = eml_getGroupData.data# - .groupMean[.s]
            .ssWithin = .ssWithin + sum (.centered# * .centered#)
        endfor

        .dfWithin = .totalN - .nGroups
        if .dfWithin < 1
            .error$ = "emlTukeyHSD: dfWithin < 1 "
            ... + "(need more observations than groups)"
        else
            .msWithin = .ssWithin / .dfWithin
        endif
    endif

    # --- Compute pairwise q statistics and p-values ---

    if .error$ = ""
        .pMatrix## = zero## (.nGroups, .nGroups)
        .qMatrix## = zero## (.nGroups, .nGroups)
        .meanDiff## = zero## (.nGroups, .nGroups)
        .dMatrix## = zero## (.nGroups, .nGroups)

        # Diagonal p = 1 (self-comparison)
        for .i from 1 to .nGroups
            .pMatrix##[.i, .i] = 1
        endfor

        .nPairs = .nGroups * (.nGroups - 1) / 2

        for .i from 1 to .nGroups
            for .j from .i + 1 to .nGroups
                .diff = .groupMean[.i] - .groupMean[.j]
                .se = sqrt (.msWithin
                ... * (1 / .groupN[.i] + 1 / .groupN[.j]) / 2)
                .q = abs (.diff) / .se
                if .q > 0
                    .p = Get TukeyQ: .q, .nGroups, .dfWithin, 1
                else
                    .p = 1
                endif

                .qMatrix##[.i, .j] = .q
                .qMatrix##[.j, .i] = .q
                .pMatrix##[.i, .j] = .p
                .pMatrix##[.j, .i] = .p
                .meanDiff##[.i, .j] = .diff
                .meanDiff##[.j, .i] = -.diff

                # Cohen's d per pair (two-group pooled SD)
                @eml_getGroupData: .sortMap[.i]
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .sortMap[.j]
                @emlCohenD: .vI#, eml_getGroupData.data#
                if emlCohenD.error$ = ""
                    .dMatrix##[.i, .j] = emlCohenD.d
                    .dMatrix##[.j, .i] = -emlCohenD.d
                else
                    .dMatrix##[.i, .j] = undefined
                    .dMatrix##[.j, .i] = undefined
                endif
            endfor
        endfor

        # Critical q value at specified alpha
        .qCritical = Get invTukeyQ: .alpha, .nGroups, .dfWithin, 1
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlOneWayAnova
# ============================================================================
# Performs one-way ANOVA on a Table with optional Tukey HSD post-hoc.
#
# Native computation (Hays 1988). Replaces the previous wrapper around
# Report one-way anova, which had a display bug (Table_extensions.cpp
# Table_printAsMeansTable: Melder_padLeft width 10 truncating means)
# and wrote to Info window as a side effect.
#
# Algorithm: Hays (1988) 12-step computational formula.
# P-value via Praat's native fisherQ(F, df1, df2).
#
# Arguments:
#   .tableId       - ID of a Table object (must be in object list)
#   .dataColumn$   - name of the numeric data column
#   .factorColumn$ - name of the string factor column
#   .tukey         - 1 to run Tukey HSD post-hoc, 0 to skip
#
# Output (always):
#   .fValue    - F statistic
#   .p         - p-value (from fisherQ)
#   .dfBetween - between-groups degrees of freedom (k - 1)
#   .dfWithin  - within-groups degrees of freedom (N - k)
#   .dfTotal   - total degrees of freedom (N - 1)
#   .ssBetween - between-groups sum of squares
#   .ssWithin  - within-groups sum of squares
#   .ssTotal   - total sum of squares
#   .msBetween - between-groups mean square
#   .msWithin  - within-groups mean square
#   .nGroups   - number of groups (k)
#   .etaSquared - eta-squared effect size (ssBetween / ssTotal)
#   .groupMean[g] - mean of group g (1..nGroups, alphabetical order)
#   .groupN[g]    - size of group g
#   .groupLabel$[g] - label of group g
#   .error$    - "" on success, diagnostic message on failure
#
# Output (when .tukey = 1):
#   .pMatrix##     - k × k symmetric matrix of Tukey pairwise p-values
#   .qMatrix##     - k × k symmetric matrix of Tukey q statistics
#   .meanDiff##    - k × k antisymmetric mean differences
#   .dMatrix##     - k × k antisymmetric Cohen's d (from @emlTukeyHSD)
#   .qCritical     - critical q at alpha = 0.05
#   .groupName$[i] - group label for row/column i (1..nGroups, alphabetical)
#   .nPairs        - number of unique pairwise comparisons
#
# Notes:
#   - Does NOT call Report one-way anova. No Info window side effect.
#   - Group labels are in alphabetical order (matching @emlCountGroups)
#   - When tukey=1, this procedure calls @emlTukeyHSD internally
#     with alpha = 0.05. For custom alpha, call @emlTukeyHSD directly.
#   - Original Table selection is restored on return
# ============================================================================

procedure emlOneWayAnova: .tableId, .dataColumn$, .factorColumn$, .tukey
    .fValue = undefined
    .p = undefined
    .dfBetween = undefined
    .dfWithin = undefined
    .dfTotal = undefined
    .ssBetween = undefined
    .ssWithin = undefined
    .ssTotal = undefined
    .msBetween = undefined
    .msWithin = undefined
    .nGroups = undefined
    .etaSquared = undefined
    .nPairs = 0
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 3
        .error$ = "emlOneWayAnova: need at least 3 observations, got "
        ... + string$ (.nRows)
    endif

    if .error$ = ""
        .colIdx1 = Get column index: .dataColumn$
        if .colIdx1 = 0
            .error$ = "emlOneWayAnova: data column not found: "
            ... + .dataColumn$
        endif
    endif

    if .error$ = ""
        .colIdx2 = Get column index: .factorColumn$
        if .colIdx2 = 0
            .error$ = "emlOneWayAnova: factor column not found: "
            ... + .factorColumn$
        endif
    endif

    # --- Count and extract groups ---

    if .error$ = ""
        @emlCountGroups: .tableId, .factorColumn$
        if emlCountGroups.error$ <> ""
            .error$ = "emlOneWayAnova: " + emlCountGroups.error$
        else
            .nGroups = emlCountGroups.nGroups
        endif
    endif

    if .error$ = "" and .nGroups < 2
        .error$ = "emlOneWayAnova: need at least 2 groups, got "
        ... + string$ (.nGroups)
    endif

    if .error$ = ""
        @emlExtractMultipleGroups: .tableId, .dataColumn$, .factorColumn$
        if emlExtractMultipleGroups.error$ <> ""
            .error$ = "emlOneWayAnova: " + emlExtractMultipleGroups.error$
        endif
    endif

    # --- Compute ANOVA (Hays 1988 computational formula) ---
    # Reference: Table_extensions.cpp lines 477-522

    if .error$ = ""
        .totalN = 0
        .sumOfSquares = 0
        .sumOfRawScores = 0
        .c = 0

        for .g from 1 to .nGroups
            @eml_getGroupData: .g
            .gN = eml_getGroupData.n
            .gData# = eml_getGroupData.data#

            if .gN < 2
                .error$ = "emlOneWayAnova: group """
                ... + emlCountGroups.groupLabel$[.g]
                ... + """ has fewer than 2 observations"
                .g = .nGroups
            else
                .gSum = sum (.gData#)
                .gSumSq = inner (.gData#, .gData#)

                .totalN = .totalN + .gN
                .sumOfSquares = .sumOfSquares + .gSumSq
                .sumOfRawScores = .sumOfRawScores + .gSum
                .c = .c + .gSum * .gSum / .gN

                .groupMean[.g] = .gSum / .gN
                .groupN[.g] = .gN
                .groupLabel$[.g] = emlCountGroups.groupLabel$[.g]
            endif
        endfor
    endif

    if .error$ = ""
        .correctionTerm = .sumOfRawScores * .sumOfRawScores / .totalN

        .ssTotal = .sumOfSquares - .correctionTerm
        .ssBetween = .c - .correctionTerm
        .ssWithin = .sumOfSquares - .c

        .dfBetween = .nGroups - 1
        .dfWithin = .totalN - .nGroups
        .dfTotal = .totalN - 1

        .msBetween = .ssBetween / .dfBetween
        .msWithin = .ssWithin / .dfWithin
        .fValue = .msBetween / .msWithin
        .p = fisherQ (.fValue, .dfBetween, .dfWithin)

        .etaSquared = .ssBetween / .ssTotal
    endif

    # --- Tukey HSD post-hoc (optional, chained) ---

    if .error$ = "" and .tukey = 1
        @emlTukeyHSD: .tableId, .dataColumn$, .factorColumn$, 0.05
        if emlTukeyHSD.error$ <> ""
            .error$ = "emlOneWayAnova (Tukey): "
            ... + emlTukeyHSD.error$
        else
            .nPairs = emlTukeyHSD.nPairs
            .pMatrix## = emlTukeyHSD.pMatrix##
            .qMatrix## = emlTukeyHSD.qMatrix##
            .meanDiff## = emlTukeyHSD.meanDiff##
            .dMatrix## = emlTukeyHSD.dMatrix##
            .qCritical = emlTukeyHSD.qCritical
            for .g from 1 to emlTukeyHSD.nGroups
                .groupName$[.g] = emlTukeyHSD.groupName$[.g]
            endfor
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc

# ============================================================================
# @emlTwoWayAnova
# ============================================================================
# Performs two-way ANOVA on a Table.
#
# Wraps Praat's built-in Report two-way anova (hidden command). Parses
# the Info window output into structured numeric variables for both
# main effects, interaction, error, and total.
#
# Arguments:
#   .tableId   - ID of a Table object (must be in object list)
#   .dataCol$  - name of the numeric data column
#   .factor1$  - name of the first factor column (string)
#   .factor2$  - name of the second factor column (string)
#
# Output:
#   Main effect A (factor1):
#     .fA, .pA, .dfA, .ssA, .msA
#   Main effect B (factor2):
#     .fB, .pB, .dfB, .ssB, .msB
#   Interaction (A × B):
#     .fAB, .pAB, .dfAB, .ssAB, .msAB
#   Error:
#     .ssError, .dfError, .msError
#   Total:
#     .ssTotal, .dfTotal
#   Effect sizes:
#     .partialEtaSqA  - partial eta-squared for factor 1
#     .partialEtaSqB  - partial eta-squared for factor 2
#     .partialEtaSqAB - partial eta-squared for interaction
#   Status:
#     .error$ - "" on success, diagnostic message on failure
#
# Notes:
#   - The built-in Report two-way anova is a hidden command (stable since ~2006)
#   - Info window output row order: factor1, factor2, interaction, Error, Total
#   - Interaction row label is "factor1 x factor2" (constructed internally)
#   - Parsing isolates the data section (after "Source" header) to avoid
#     matching factor names in the header line
#   - Original Table selection is restored on return
# ============================================================================

procedure emlTwoWayAnova: .tableId, .dataCol$, .factor1$, .factor2$
    .fA = undefined
    .pA = undefined
    .dfA = undefined
    .ssA = undefined
    .msA = undefined
    .fB = undefined
    .pB = undefined
    .dfB = undefined
    .ssB = undefined
    .msB = undefined
    .fAB = undefined
    .pAB = undefined
    .dfAB = undefined
    .ssAB = undefined
    .msAB = undefined
    .ssError = undefined
    .dfError = undefined
    .msError = undefined
    .ssTotal = undefined
    .dfTotal = undefined
    .partialEtaSqA = undefined
    .partialEtaSqB = undefined
    .partialEtaSqAB = undefined
    .error$ = ""

    # --- Validate inputs ---

    selectObject: .tableId
    .nRows = Get number of rows
    if .nRows < 4
        .error$ = "emlTwoWayAnova: need at least 4 observations, got "
        ... + string$ (.nRows)
    endif

    if .error$ = ""
        .colIdx1 = Get column index: .dataCol$
        if .colIdx1 = 0
            .error$ = "emlTwoWayAnova: data column not found: "
            ... + .dataCol$
        endif
    endif

    if .error$ = ""
        .colIdx2 = Get column index: .factor1$
        if .colIdx2 = 0
            .error$ = "emlTwoWayAnova: factor1 column not found: "
            ... + .factor1$
        endif
    endif

    if .error$ = ""
        .colIdx3 = Get column index: .factor2$
        if .colIdx3 = 0
            .error$ = "emlTwoWayAnova: factor2 column not found: "
            ... + .factor2$
        endif
    endif

    # --- Run Report two-way anova ---

    if .error$ = ""
        selectObject: .tableId
        Report two-way anova: .dataCol$, .factor1$, .factor2$, "no"
        .anovaInfo$ = info$ ()
    endif

    # --- Isolate data section (after "Source" header line) ---
    # Factor names appear both in the header sentence and in the data
    # rows. Trimming to the data section prevents false matches.

    if .error$ = ""
        .sourcePos = index (.anovaInfo$, "Source")
        if .sourcePos = 0
            .error$ = "emlTwoWayAnova: could not find Source header "
            ... + "in Info window output"
        endif
    endif

    if .error$ = ""
        # Get substring from "Source" onward
        .fromSource$ = mid$ (.anovaInfo$, .sourcePos,
        ... length (.anovaInfo$) - .sourcePos + 1)

        # Find the first newline to skip the "Source SS Df MS F P" header
        .nlPos = index (.fromSource$, newline$)
        if .nlPos = 0
            .error$ = "emlTwoWayAnova: malformed Info window output "
            ... + "(no newline after Source header)"
        else
            .dataSection$ = mid$ (.fromSource$, .nlPos + 1,
            ... length (.fromSource$) - .nlPos)
        endif
    endif

    # --- Parse factor 1 row: SS, df, MS, F, p ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, .factor1$
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "emlTwoWayAnova (factor1): "
            ... + eml_parseAnovaLine.error$
        else
            .ssA = eml_parseAnovaLine.ss
            .dfA = eml_parseAnovaLine.df
            .msA = eml_parseAnovaLine.ms
            .fA = eml_parseAnovaLine.f
            .pA = eml_parseAnovaLine.p
        endif
    endif

    # --- Parse factor 2 row: SS, df, MS, F, p ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, .factor2$
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "emlTwoWayAnova (factor2): "
            ... + eml_parseAnovaLine.error$
        else
            .ssB = eml_parseAnovaLine.ss
            .dfB = eml_parseAnovaLine.df
            .msB = eml_parseAnovaLine.ms
            .fB = eml_parseAnovaLine.f
            .pB = eml_parseAnovaLine.p
        endif
    endif

    # --- Parse interaction row: SS, df, MS, F, p ---

    if .error$ = ""
        .interactionLabel$ = .factor1$ + " x " + .factor2$
        @eml_parseAnovaLine: .dataSection$, .interactionLabel$
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "emlTwoWayAnova (interaction): "
            ... + eml_parseAnovaLine.error$
        else
            .ssAB = eml_parseAnovaLine.ss
            .dfAB = eml_parseAnovaLine.df
            .msAB = eml_parseAnovaLine.ms
            .fAB = eml_parseAnovaLine.f
            .pAB = eml_parseAnovaLine.p
        endif
    endif

    # --- Parse Error row: SS, df, MS ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, "Error"
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "emlTwoWayAnova (error): "
            ... + eml_parseAnovaLine.error$
        else
            .ssError = eml_parseAnovaLine.ss
            .dfError = eml_parseAnovaLine.df
            .msError = eml_parseAnovaLine.ms
        endif
    endif

    # --- Parse Total row: SS, df ---

    if .error$ = ""
        @eml_parseAnovaLine: .dataSection$, "Total"
        if eml_parseAnovaLine.error$ <> ""
            .error$ = "emlTwoWayAnova (total): "
            ... + eml_parseAnovaLine.error$
        else
            .ssTotal = eml_parseAnovaLine.ss
            .dfTotal = eml_parseAnovaLine.df
        endif
    endif

    # --- Compute partial eta-squared effect sizes ---

    if .error$ = ""
        .partialEtaSqA = .ssA / (.ssA + .ssError)
        .partialEtaSqB = .ssB / (.ssB + .ssError)
        .partialEtaSqAB = .ssAB / (.ssAB + .ssError)
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc



# ============================================================================
# @emlEpsilonSquared
# ============================================================================
# Epsilon-squared effect size for Kruskal-Wallis H test.
#
# Computes the Tomczak & Tomczak (2014) formula:
#   epsilon^2 = H / (N - 1)
#
# This is the formula used by R rstatix::kruskal_effsize(). It ranges
# from 0 (no effect) to 1 (complete separation). Interpretive
# guidelines (Rea & Parker 2014): < 0.01 negligible, 0.01–0.06 small,
# 0.06–0.14 medium, >= 0.14 large.
#
# This procedure is intentionally standalone. Users can call it with
# any H and N (not just from @emlKruskalWallis).
#
# Arguments:
#   .h  - H statistic (Kruskal-Wallis chi-squared approximation)
#   .n  - total number of observations (N)
#
# Output:
#   .result - epsilon-squared
#   .error$ - error message, or "" if valid
# ============================================================================

procedure emlEpsilonSquared: .h, .n
    .result = undefined
    .error$ = ""

    if .n <= 1
        .error$ = "emlEpsilonSquared: N must be > 1, got "
        ... + string$ (.n)
    elsif .h < 0
        .error$ = "emlEpsilonSquared: H must be >= 0, got "
        ... + string$ (.h)
    else
        .result = .h / (.n - 1)
    endif
endproc


# ============================================================================
# @emlKruskalWallis
# ============================================================================
# Kruskal-Wallis H test for k independent samples.
#
# Nonparametric one-way ANOVA on ranks. Tests whether k groups come
# from the same distribution. Uses the chi-squared approximation for
# the p-value.
#
# The H statistic is computed natively from global ranks (not by
# wrapping Praat's hidden Report command). This gives us mean ranks
# and tie correction as structured output — needed by Dunn's post-hoc
# and avoids Info window parsing fragility.
#
# Algorithm:
#   1. Extract all data and group labels from Table
#   2. Global ranking via @emlRankVector (average ties)
#   3. H_raw = [12 / (N(N+1))] * sum(Ri^2 / ni) - 3(N+1)
#   4. Tie correction: C = 1 - sum(tj^3 - tj) / (N^3 - N)
#   5. H = H_raw / C  (or H_raw if no ties)
#   6. p = chiSquareQ(H, k-1)
#   7. epsilon^2 = H / (N-1) via @emlEpsilonSquared
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#
# Output:
#   .h             - H statistic (tie-corrected)
#   .p             - p-value (chi-squared approximation)
#   .df            - degrees of freedom (k - 1)
#   .n             - total N
#   .nGroups       - number of groups (k)
#   .groupName$[i] - group label for group i (1..nGroups)
#   .groupN[i]     - sample size for group i
#   .meanRank[i]   - mean rank for group i
#   .epsilonSq     - epsilon-squared effect size
#   .tieCorrection - tie correction factor C (1.0 if no ties)
#   .error$        - error message, or "" if valid
#
# Limits:
#   Max 10 groups (consistent with @emlExtractMultipleGroups).
#
# Dependencies:
#   @emlExtractMultipleGroups (eml-extract.praat)
#   @emlRankVector (eml-core-utilities.praat)
#   @emlEpsilonSquared (this file)
#   chiSquareQ() (Praat built-in)
# ============================================================================

procedure emlKruskalWallis: .tableId, .dataCol$, .factorCol$
    .h = undefined
    .p = undefined
    .df = undefined
    .n = 0
    .nGroups = 0
    .epsilonSq = undefined
    .tieCorrection = undefined
    .error$ = ""

    # --- Extract groups from Table ---

    @emlExtractMultipleGroups: .tableId, .dataCol$, .factorCol$

    if emlExtractMultipleGroups.error$ <> ""
        .error$ = "emlKruskalWallis: "
        ... + emlExtractMultipleGroups.error$
    else
        .nGroups = emlExtractMultipleGroups.nGroups

        if .nGroups < 2
            .error$ = "emlKruskalWallis: need >= 2 groups, got "
            ... + string$ (.nGroups)
        endif
    endif

    if .error$ = ""
        # Copy group labels and sizes into local indexed vars
        for .g from 1 to .nGroups
            .groupName$[.g] = emlExtractMultipleGroups.groupLabel$[.g]
        endfor
        .groupN[1] = emlExtractMultipleGroups.groupSize1
        .groupN[2] = emlExtractMultipleGroups.groupSize2
        if .nGroups >= 3
            .groupN[3] = emlExtractMultipleGroups.groupSize3
        endif
        if .nGroups >= 4
            .groupN[4] = emlExtractMultipleGroups.groupSize4
        endif
        if .nGroups >= 5
            .groupN[5] = emlExtractMultipleGroups.groupSize5
        endif
        if .nGroups >= 6
            .groupN[6] = emlExtractMultipleGroups.groupSize6
        endif
        if .nGroups >= 7
            .groupN[7] = emlExtractMultipleGroups.groupSize7
        endif
        if .nGroups >= 8
            .groupN[8] = emlExtractMultipleGroups.groupSize8
        endif
        if .nGroups >= 9
            .groupN[9] = emlExtractMultipleGroups.groupSize9
        endif
        if .nGroups >= 10
            .groupN[10] = emlExtractMultipleGroups.groupSize10
        endif

        # Validate: no empty groups
        for .g from 1 to .nGroups
            if .groupN[.g] = 0
                .error$ = "emlKruskalWallis: group "
                ... + .groupName$[.g] + " has 0 observations"
            endif
        endfor
    endif

    if .error$ = ""
        # Compute total N
        .n = 0
        for .g from 1 to .nGroups
            .n = .n + .groupN[.g]
        endfor

        # --- Build flat data vector from group data vectors ---
        # Must follow the same order as @emlExtractMultipleGroups

        .allData# = zero# (.n)
        .idx = 0

        # Group 1
        for .j from 1 to .groupN[1]
            .idx = .idx + 1
            .allData#[.idx] = emlExtractMultipleGroups.groupData1#[.j]
        endfor
        # Group 2
        for .j from 1 to .groupN[2]
            .idx = .idx + 1
            .allData#[.idx] = emlExtractMultipleGroups.groupData2#[.j]
        endfor
        if .nGroups >= 3
            for .j from 1 to .groupN[3]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData3#[.j]
            endfor
        endif
        if .nGroups >= 4
            for .j from 1 to .groupN[4]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData4#[.j]
            endfor
        endif
        if .nGroups >= 5
            for .j from 1 to .groupN[5]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData5#[.j]
            endfor
        endif
        if .nGroups >= 6
            for .j from 1 to .groupN[6]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData6#[.j]
            endfor
        endif
        if .nGroups >= 7
            for .j from 1 to .groupN[7]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData7#[.j]
            endfor
        endif
        if .nGroups >= 8
            for .j from 1 to .groupN[8]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData8#[.j]
            endfor
        endif
        if .nGroups >= 9
            for .j from 1 to .groupN[9]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData9#[.j]
            endfor
        endif
        if .nGroups >= 10
            for .j from 1 to .groupN[10]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData10#[.j]
            endfor
        endif
    endif

    if .error$ = ""
        # --- Global ranking ---

        @emlRankVector: .allData#
        .ranks# = emlRankVector.ranks#

        # --- Compute rank sums and mean ranks per group ---

        .offset = 0
        for .g from 1 to .nGroups
            .rankSum[.g] = 0
            for .j from 1 to .groupN[.g]
                .rankSum[.g] = .rankSum[.g]
                ... + .ranks#[.offset + .j]
            endfor
            .meanRank[.g] = .rankSum[.g] / .groupN[.g]
            .offset = .offset + .groupN[.g]
        endfor

        # --- Compute H statistic ---
        # H_raw = [12 / (N(N+1))] * sum(Ri^2 / ni) - 3(N+1)

        .sumTerm = 0
        for .g from 1 to .nGroups
            .sumTerm = .sumTerm
            ... + (.rankSum[.g] * .rankSum[.g]) / .groupN[.g]
        endfor

        .hRaw = (12 / (.n * (.n + 1))) * .sumTerm - 3 * (.n + 1)

        # --- Tie correction ---
        # C = 1 - sum(tj^3 - tj) / (N^3 - N)

        .tieCorrSum = emlRankVector.tieCorrectionSum

        if .tieCorrSum = 0
            .tieCorrection = 1
            .h = .hRaw
        else
            .denominator = .n ^ 3 - .n
            if .denominator = 0
                # Degenerate case (N <= 1, shouldn't reach here)
                .tieCorrection = 1
                .h = .hRaw
            else
                .tieCorrection = 1 - .tieCorrSum / .denominator
                if .tieCorrection <= 0
                    # All values identical — H must be 0
                    .h = 0
                    .tieCorrection = 0
                else
                    .h = .hRaw / .tieCorrection
                endif
            endif
        endif

        # --- p-value (chi-squared approximation) ---

        .df = .nGroups - 1

        if .h = 0
            .p = 1
        else
            .p = chiSquareQ (.h, .df)
        endif

        # --- Epsilon-squared effect size ---

        @emlEpsilonSquared: .h, .n
        if emlEpsilonSquared.error$ = ""
            .epsilonSq = emlEpsilonSquared.result
        else
            .epsilonSq = undefined
        endif
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlDunnTest
# ============================================================================
# Dunn's post-hoc test for pairwise comparisons after Kruskal-Wallis.
#
# Uses global KW ranks (not re-ranked pairs) for z-statistics, which is
# the correct Dunn's test. The alternative (pairwise MWU) re-ranks
# within each pair and is a different, less standard, procedure.
#
# Algorithm:
#   1. Extract groups and compute global ranks (same as KW)
#   2. Compute tie-corrected variance:
#      sigma^2 = N(N+1)/12 - sum(tj^3 - tj) / (12(N-1))
#   3. For each pair (i,j):
#      z_ij = (mean_rank_i - mean_rank_j) / sqrt(sigma^2 * (1/ni + 1/nj))
#   4. Two-tailed raw p: 2 * gaussQ(|z|)
#   5. Adjust p-values via user-chosen method
#   6. Populate symmetric matrices
#
# Flat vector pair ordering:
#   (1,2), (1,3), ..., (1,k), (2,3), ..., (k-1,k)
#   Same as R dunn.test output.
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .method$    - p-value adjustment: "bonferroni", "holm", or "bh"
#
# Output:
#   .pMatrix##     - k x k symmetric matrix (adjusted p; diagonal = 1)
#   .zMatrix##     - k x k antisymmetric matrix (z-stats; diagonal = 0)
#   .rMatrix##     - k x k antisymmetric rank-biserial r (per-pair,
#                    independently ranked via @emlRankBiserialR)
#   .rawP#         - unadjusted p-values, C(k,2) length
#   .adjustedP#    - adjusted p-values, C(k,2) length
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .groupName$[i] - group label for group i
#   .method$       - adjustment method used (echoed back)
#   .error$        - error message, or "" if valid
#
# Dependencies:
#   @emlExtractMultipleGroups (eml-extract.praat)
#   @eml_getGroupData (eml-inferential.praat)
#   @emlRankVector (eml-core-utilities.praat)
#   @emlRankBiserialR (eml-inferential.praat)
#   @emlBonferroni / @emlHolm / @emlBenjaminiHochberg (this file)
#   gaussQ() (Praat built-in)
# ============================================================================

procedure emlDunnTest: .tableId, .dataCol$, .factorCol$, .method$
    .nGroups = 0
    .nPairs = 0
    .error$ = ""

    # --- Validate method ---

    if .method$ <> "bonferroni" and .method$ <> "holm"
    ... and .method$ <> "bh"
        .error$ = "emlDunnTest: method must be bonferroni, holm, "
        ... + "or bh, got: " + .method$
    endif

    # --- Extract groups from Table ---

    if .error$ = ""
        @emlExtractMultipleGroups: .tableId, .dataCol$, .factorCol$

        if emlExtractMultipleGroups.error$ <> ""
            .error$ = "emlDunnTest: "
            ... + emlExtractMultipleGroups.error$
        else
            .nGroups = emlExtractMultipleGroups.nGroups

            if .nGroups < 2
                .error$ = "emlDunnTest: need >= 2 groups, got "
                ... + string$ (.nGroups)
            endif
        endif
    endif

    if .error$ = ""
        # Copy group labels and sizes
        for .g from 1 to .nGroups
            .groupName$[.g] = emlExtractMultipleGroups.groupLabel$[.g]
        endfor
        .groupN[1] = emlExtractMultipleGroups.groupSize1
        .groupN[2] = emlExtractMultipleGroups.groupSize2
        if .nGroups >= 3
            .groupN[3] = emlExtractMultipleGroups.groupSize3
        endif
        if .nGroups >= 4
            .groupN[4] = emlExtractMultipleGroups.groupSize4
        endif
        if .nGroups >= 5
            .groupN[5] = emlExtractMultipleGroups.groupSize5
        endif
        if .nGroups >= 6
            .groupN[6] = emlExtractMultipleGroups.groupSize6
        endif
        if .nGroups >= 7
            .groupN[7] = emlExtractMultipleGroups.groupSize7
        endif
        if .nGroups >= 8
            .groupN[8] = emlExtractMultipleGroups.groupSize8
        endif
        if .nGroups >= 9
            .groupN[9] = emlExtractMultipleGroups.groupSize9
        endif
        if .nGroups >= 10
            .groupN[10] = emlExtractMultipleGroups.groupSize10
        endif

        # Validate: no empty groups
        for .g from 1 to .nGroups
            if .groupN[.g] = 0
                .error$ = "emlDunnTest: group "
                ... + .groupName$[.g] + " has 0 observations"
            endif
        endfor
    endif

    if .error$ = ""
        # Compute total N
        .n = 0
        for .g from 1 to .nGroups
            .n = .n + .groupN[.g]
        endfor

        # --- Build flat data vector ---

        .allData# = zero# (.n)
        .idx = 0

        for .j from 1 to .groupN[1]
            .idx = .idx + 1
            .allData#[.idx] = emlExtractMultipleGroups.groupData1#[.j]
        endfor
        for .j from 1 to .groupN[2]
            .idx = .idx + 1
            .allData#[.idx] = emlExtractMultipleGroups.groupData2#[.j]
        endfor
        if .nGroups >= 3
            for .j from 1 to .groupN[3]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData3#[.j]
            endfor
        endif
        if .nGroups >= 4
            for .j from 1 to .groupN[4]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData4#[.j]
            endfor
        endif
        if .nGroups >= 5
            for .j from 1 to .groupN[5]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData5#[.j]
            endfor
        endif
        if .nGroups >= 6
            for .j from 1 to .groupN[6]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData6#[.j]
            endfor
        endif
        if .nGroups >= 7
            for .j from 1 to .groupN[7]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData7#[.j]
            endfor
        endif
        if .nGroups >= 8
            for .j from 1 to .groupN[8]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData8#[.j]
            endfor
        endif
        if .nGroups >= 9
            for .j from 1 to .groupN[9]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData9#[.j]
            endfor
        endif
        if .nGroups >= 10
            for .j from 1 to .groupN[10]
                .idx = .idx + 1
                .allData#[.idx] = emlExtractMultipleGroups.groupData10#[.j]
            endfor
        endif
    endif

    if .error$ = ""
        # --- Global ranking ---

        @emlRankVector: .allData#
        .ranks# = emlRankVector.ranks#

        # --- Compute mean ranks per group ---

        .offset = 0
        for .g from 1 to .nGroups
            .rankSum = 0
            for .j from 1 to .groupN[.g]
                .rankSum = .rankSum + .ranks#[.offset + .j]
            endfor
            .meanRank[.g] = .rankSum / .groupN[.g]
            .offset = .offset + .groupN[.g]
        endfor

        # --- Compute tie-corrected variance ---
        # sigma^2 = N(N+1)/12 - sum(tj^3 - tj) / (12(N-1))

        .sigmaSq = .n * (.n + 1) / 12
        .tieCorrSum = emlRankVector.tieCorrectionSum
        if .tieCorrSum > 0 and .n > 1
            .sigmaSq = .sigmaSq
            ... - .tieCorrSum / (12 * (.n - 1))
        endif

        # --- Pairwise z-statistics and raw p-values ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .rawP# = zero# (.nPairs)
        .zFlat# = zero# (.nPairs)

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1

                .diff = .meanRank[.i] - .meanRank[.j]

                if .sigmaSq <= 0
                    # Degenerate: all values identical
                    .z = 0
                    .rawPVal = 1
                else
                    .se = sqrt (.sigmaSq
                    ... * (1 / .groupN[.i] + 1 / .groupN[.j]))

                    if .se = 0
                        .z = 0
                        .rawPVal = 1
                    else
                        .z = .diff / .se
                        .rawPVal = 2 * gaussQ (abs (.z))
                    endif
                endif

                .zFlat#[.pairIdx] = .z
                .rawP#[.pairIdx] = .rawPVal
            endfor
        endfor

        # --- Adjust p-values ---

        if .method$ = "bonferroni"
            @emlBonferroni: .rawP#
            .adjustedP# = emlBonferroni.adjusted#
        elsif .method$ = "holm"
            @emlHolm: .rawP#
            .adjustedP# = emlHolm.adjusted#
        elsif .method$ = "bh"
            @emlBenjaminiHochberg: .rawP#
            .adjustedP# = emlBenjaminiHochberg.adjusted#
        endif

        # --- Populate matrices ---

        .pMatrix## = zero## (.nGroups, .nGroups)
        .zMatrix## = zero## (.nGroups, .nGroups)

        # Diagonal = 1 for p, 0 for z (already zero from zero##)
        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        # Fill upper and lower triangles
        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1
                .pMatrix##[.i, .j] = .adjustedP#[.pairIdx]
                .pMatrix##[.j, .i] = .adjustedP#[.pairIdx]
                .zMatrix##[.i, .j] = .zFlat#[.pairIdx]
                .zMatrix##[.j, .i] = -.zFlat#[.pairIdx]
            endfor
        endfor

        # --- Pairwise rank-biserial r (independently ranked per pair) ---

        .rMatrix## = zero## (.nGroups, .nGroups)
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .i
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .j
                @emlRankBiserialR: .vI#, eml_getGroupData.data#, 2
                if emlRankBiserialR.error$ = ""
                    .rMatrix##[.i, .j] = emlRankBiserialR.r
                    .rMatrix##[.j, .i] = -emlRankBiserialR.r
                else
                    .rMatrix##[.i, .j] = undefined
                    .rMatrix##[.j, .i] = undefined
                endif
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# INTERNAL HELPER: @eml_getGroupData
# ============================================================================
# Copies group data from @emlExtractMultipleGroups numbered variables
# into a single output vector, dispatched by group index.
#
# Must be called AFTER @emlExtractMultipleGroups. Reads from that
# procedure's namespace directly.
#
# Arguments:
#   .groupIdx  - group number (1..10)
#
# Output:
#   .data#     - copy of the group's data vector
#   .n         - size of the group
# ============================================================================

procedure eml_getGroupData: .groupIdx
    .n = 0
    .data# = zero# (0)

    if .groupIdx = 1
        .n = emlExtractMultipleGroups.groupSize1
        .data# = emlExtractMultipleGroups.groupData1#
    elsif .groupIdx = 2
        .n = emlExtractMultipleGroups.groupSize2
        .data# = emlExtractMultipleGroups.groupData2#
    elsif .groupIdx = 3
        .n = emlExtractMultipleGroups.groupSize3
        .data# = emlExtractMultipleGroups.groupData3#
    elsif .groupIdx = 4
        .n = emlExtractMultipleGroups.groupSize4
        .data# = emlExtractMultipleGroups.groupData4#
    elsif .groupIdx = 5
        .n = emlExtractMultipleGroups.groupSize5
        .data# = emlExtractMultipleGroups.groupData5#
    elsif .groupIdx = 6
        .n = emlExtractMultipleGroups.groupSize6
        .data# = emlExtractMultipleGroups.groupData6#
    elsif .groupIdx = 7
        .n = emlExtractMultipleGroups.groupSize7
        .data# = emlExtractMultipleGroups.groupData7#
    elsif .groupIdx = 8
        .n = emlExtractMultipleGroups.groupSize8
        .data# = emlExtractMultipleGroups.groupData8#
    elsif .groupIdx = 9
        .n = emlExtractMultipleGroups.groupSize9
        .data# = emlExtractMultipleGroups.groupData9#
    elsif .groupIdx = 10
        .n = emlExtractMultipleGroups.groupSize10
        .data# = emlExtractMultipleGroups.groupData10#
    endif
endproc


# ============================================================================
# @emlPairwiseT
# ============================================================================
# All-pairs independent t-tests with p-value adjustment and Cohen's d.
#
# Runs @emlTTest and @emlCohenD for each of the C(k,2) pairs, collects
# the raw two-tailed p-values, adjusts them via the chosen method, and
# populates symmetric p-value and antisymmetric t/d matrices.
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .method$    - p-value adjustment: "bonferroni", "holm", or "bh"
#   .type$      - "welch" (default) or "student"
#
# Output:
#   .pMatrix##     - k x k adjusted p-values (symmetric, diagonal = 1)
#   .tMatrix##     - k x k t-statistics (antisymmetric, diagonal = 0)
#   .dMatrix##     - k x k Cohen's d (antisymmetric, diagonal = 0)
#   .rawP#         - unadjusted p-values, C(k,2) length
#   .adjustedP#    - adjusted p-values, C(k,2) length
#   .groupName$[i] - group label for group i
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .method$       - adjustment method used (echoed back)
#   .error$        - error message or ""
#
# Dependencies:
#   @emlExtractMultipleGroups (eml-extract.praat)
#   @eml_getGroupData (this file)
#   @emlTTest (Batch 1)
#   @emlCohenD (Batch 1)
#   @emlBonferroni / @emlHolm / @emlBenjaminiHochberg (Batch 5)
# ============================================================================

procedure emlPairwiseT: .tableId, .dataCol$, .factorCol$, .method$, .type$
    .nGroups = 0
    .nPairs = 0
    .error$ = ""

    # --- Validate method ---

    if .method$ <> "bonferroni" and .method$ <> "holm"
    ... and .method$ <> "bh"
        .error$ = "emlPairwiseT: method must be bonferroni, holm, "
        ... + "or bh, got: " + .method$
    endif

    # --- Validate type ---

    if .error$ = ""
        if .type$ <> "welch" and .type$ <> "student"
            .error$ = "emlPairwiseT: type must be welch or student, "
            ... + "got: " + .type$
        endif
    endif

    # --- Extract groups ---

    if .error$ = ""
        @emlExtractMultipleGroups: .tableId, .dataCol$, .factorCol$

        if emlExtractMultipleGroups.error$ <> ""
            .error$ = "emlPairwiseT: "
            ... + emlExtractMultipleGroups.error$
        else
            .nGroups = emlExtractMultipleGroups.nGroups
            if .nGroups < 2
                .error$ = "emlPairwiseT: need >= 2 groups, got "
                ... + string$ (.nGroups)
            endif
        endif
    endif

    if .error$ = ""
        # Copy group labels
        for .g from 1 to .nGroups
            .groupName$[.g] = emlExtractMultipleGroups.groupLabel$[.g]
        endfor

        # --- Determine equalVariances flag ---
        .eqVar = 0
        if .type$ = "student"
            .eqVar = 1
        endif

        # --- Pairwise tests ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .rawP# = zero# (.nPairs)
        .tFlat# = zero# (.nPairs)
        .dFlat# = zero# (.nPairs)

        .pairIdx = 0
        .pairError$ = ""
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1

                # Get group vectors
                @eml_getGroupData: .i
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .j
                .vJ# = eml_getGroupData.data#

                # t-test
                @emlTTest: .vI#, .vJ#, 2, .eqVar
                if emlTTest.error$ <> ""
                    # Record but continue — some pairs may have
                    # zero variance while others are valid
                    .tFlat#[.pairIdx] = undefined
                    .rawP#[.pairIdx] = 1
                    if .pairError$ = ""
                        .pairError$ = emlTTest.error$
                    endif
                else
                    .tFlat#[.pairIdx] = emlTTest.t
                    .rawP#[.pairIdx] = emlTTest.p
                endif

                # Cohen's d
                @emlCohenD: .vI#, .vJ#
                if emlCohenD.error$ <> ""
                    .dFlat#[.pairIdx] = undefined
                else
                    .dFlat#[.pairIdx] = emlCohenD.d
                endif
            endfor
        endfor

        # --- Adjust p-values ---

        if .method$ = "bonferroni"
            @emlBonferroni: .rawP#
            .adjustedP# = emlBonferroni.adjusted#
        elsif .method$ = "holm"
            @emlHolm: .rawP#
            .adjustedP# = emlHolm.adjusted#
        elsif .method$ = "bh"
            @emlBenjaminiHochberg: .rawP#
            .adjustedP# = emlBenjaminiHochberg.adjusted#
        endif

        # --- Populate matrices ---

        .pMatrix## = zero## (.nGroups, .nGroups)
        .tMatrix## = zero## (.nGroups, .nGroups)
        .dMatrix## = zero## (.nGroups, .nGroups)

        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1
                .pMatrix##[.i, .j] = .adjustedP#[.pairIdx]
                .pMatrix##[.j, .i] = .adjustedP#[.pairIdx]
                .tMatrix##[.i, .j] = .tFlat#[.pairIdx]
                .tMatrix##[.j, .i] = -.tFlat#[.pairIdx]
                .dMatrix##[.i, .j] = .dFlat#[.pairIdx]
                .dMatrix##[.j, .i] = -.dFlat#[.pairIdx]
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlPairwiseWilcoxon
# ============================================================================
# All-pairs Mann-Whitney U tests with p-value adjustment and
# rank-biserial r effect size.
#
# Each pair is re-ranked independently (contrast with Dunn's test,
# which preserves the global KW ranking). Use Dunn's for KW follow-up;
# use PairwiseWilcoxon for general independent-group comparisons.
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#   .method$    - p-value adjustment: "bonferroni", "holm", or "bh"
#
# Output:
#   .pMatrix##     - k x k adjusted p-values (symmetric, diagonal = 1)
#   .uMatrix##     - k x k U1 statistics (diagonal = 0)
#   .rMatrix##     - k x k rank-biserial r (antisymmetric, diagonal = 0)
#   .rawP#         - unadjusted p-values, C(k,2) length
#   .adjustedP#    - adjusted p-values, C(k,2) length
#   .groupName$[i] - group label for group i
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .method$       - adjustment method used (echoed back)
#   .error$        - error message or ""
#
# Dependencies:
#   @emlExtractMultipleGroups (eml-extract.praat)
#   @eml_getGroupData (this file)
#   @emlRankBiserialR (Batch 4, which calls @emlMannWhitneyU internally)
#   @emlBonferroni / @emlHolm / @emlBenjaminiHochberg (Batch 5)
# ============================================================================

procedure emlPairwiseWilcoxon: .tableId, .dataCol$, .factorCol$, .method$
    .nGroups = 0
    .nPairs = 0
    .error$ = ""

    # --- Validate method ---

    if .method$ <> "bonferroni" and .method$ <> "holm"
    ... and .method$ <> "bh"
        .error$ = "emlPairwiseWilcoxon: method must be bonferroni, "
        ... + "holm, or bh, got: " + .method$
    endif

    # --- Extract groups ---

    if .error$ = ""
        @emlExtractMultipleGroups: .tableId, .dataCol$, .factorCol$

        if emlExtractMultipleGroups.error$ <> ""
            .error$ = "emlPairwiseWilcoxon: "
            ... + emlExtractMultipleGroups.error$
        else
            .nGroups = emlExtractMultipleGroups.nGroups
            if .nGroups < 2
                .error$ = "emlPairwiseWilcoxon: need >= 2 groups, "
                ... + "got " + string$ (.nGroups)
            endif
        endif
    endif

    if .error$ = ""
        # Copy group labels
        for .g from 1 to .nGroups
            .groupName$[.g] = emlExtractMultipleGroups.groupLabel$[.g]
        endfor

        # --- Pairwise tests ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .rawP# = zero# (.nPairs)
        .uFlat# = zero# (.nPairs)
        .rFlat# = zero# (.nPairs)

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1

                @eml_getGroupData: .i
                .vI# = eml_getGroupData.data#
                @eml_getGroupData: .j
                .vJ# = eml_getGroupData.data#

                # MWU + rank-biserial r
                @emlRankBiserialR: .vI#, .vJ#, 2
                if emlRankBiserialR.error$ <> ""
                    .uFlat#[.pairIdx] = undefined
                    .rFlat#[.pairIdx] = undefined
                    .rawP#[.pairIdx] = 1
                else
                    .uFlat#[.pairIdx] = emlRankBiserialR.u1
                    .rFlat#[.pairIdx] = emlRankBiserialR.r
                    .rawP#[.pairIdx] = emlRankBiserialR.p
                endif
            endfor
        endfor

        # --- Adjust p-values ---

        if .method$ = "bonferroni"
            @emlBonferroni: .rawP#
            .adjustedP# = emlBonferroni.adjusted#
        elsif .method$ = "holm"
            @emlHolm: .rawP#
            .adjustedP# = emlHolm.adjusted#
        elsif .method$ = "bh"
            @emlBenjaminiHochberg: .rawP#
            .adjustedP# = emlBenjaminiHochberg.adjusted#
        endif

        # --- Populate matrices ---

        .pMatrix## = zero## (.nGroups, .nGroups)
        .uMatrix## = zero## (.nGroups, .nGroups)
        .rMatrix## = zero## (.nGroups, .nGroups)

        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        .pairIdx = 0
        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .pairIdx = .pairIdx + 1
                .pMatrix##[.i, .j] = .adjustedP#[.pairIdx]
                .pMatrix##[.j, .i] = .adjustedP#[.pairIdx]
                .uMatrix##[.i, .j] = .uFlat#[.pairIdx]
                # U2 = n1*n2 - U1; store in lower triangle
                @eml_getGroupData: .i
                .nI = eml_getGroupData.n
                @eml_getGroupData: .j
                .nJ = eml_getGroupData.n
                .uMatrix##[.j, .i] = .nI * .nJ
                ... - .uFlat#[.pairIdx]
                .rMatrix##[.i, .j] = .rFlat#[.pairIdx]
                .rMatrix##[.j, .i] = -.rFlat#[.pairIdx]
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# @emlScheffe
# ============================================================================
# Scheffé post-hoc test for pairwise (and all-contrast) comparisons.
#
# Computes the Scheffé F statistic for each pair of group means and
# tests against the F distribution with df1 = k-1, df2 = N-k. The
# critical value inherently controls FWER for all possible contrasts
# (not just pairwise), making it the most conservative standard
# post-hoc for pairwise-only comparisons.
#
# For pairwise-only comparisons, Tukey HSD or Bonferroni-adjusted
# t-tests are preferred (tighter). Use Scheffé when you may also test
# non-pairwise contrasts (e.g., group1+group2 vs group3).
#
# Algorithm:
#   1. Extract groups, compute group means and sizes
#   2. SSwithin = sum of within-group SS; MSE = SSwithin / (N - k)
#   3. For each pair (i,j):
#      diff = mean_i - mean_j
#      SE = sqrt(MSE * (1/n_i + 1/n_j))
#      F_scheffe = (diff / SE)^2 / (k - 1)
#      p = fisherQ(F_scheffe, k - 1, N - k)
#   4. Populate matrices
#
# Arguments:
#   .tableId    - ID of a Table object
#   .dataCol$   - name of the numeric data column
#   .factorCol$ - name of the string factor column
#
# Output:
#   .pMatrix##     - k x k Scheffe p-values (symmetric, diagonal = 1)
#   .fMatrix##     - k x k F-Scheffe statistics (symmetric, diagonal = 0)
#   .diffMatrix##  - k x k mean differences (antisymmetric, diagonal = 0)
#   .groupName$[i] - group label for group i
#   .nGroups       - k
#   .nPairs        - C(k,2)
#   .mse           - within-group mean square error
#   .dfWithin      - degrees of freedom for error term (N - k)
#   .error$        - error message or ""
#
# Dependencies:
#   @emlExtractMultipleGroups (eml-extract.praat)
#   @eml_getGroupData (this file)
#   fisherQ() (Praat built-in)
# ============================================================================

procedure emlScheffe: .tableId, .dataCol$, .factorCol$
    .nGroups = 0
    .nPairs = 0
    .mse = undefined
    .dfWithin = undefined
    .error$ = ""

    # --- Extract groups ---

    @emlExtractMultipleGroups: .tableId, .dataCol$, .factorCol$

    if emlExtractMultipleGroups.error$ <> ""
        .error$ = "emlScheffe: "
        ... + emlExtractMultipleGroups.error$
    else
        .nGroups = emlExtractMultipleGroups.nGroups
        if .nGroups < 2
            .error$ = "emlScheffe: need >= 2 groups, got "
            ... + string$ (.nGroups)
        endif
    endif

    if .error$ = ""
        # Copy group labels
        for .g from 1 to .nGroups
            .groupName$[.g] = emlExtractMultipleGroups.groupLabel$[.g]
        endfor

        # --- Compute group means, sizes, and SSwithin ---

        .totalN = 0
        .ssWithin = 0

        for .g from 1 to .nGroups
            @eml_getGroupData: .g
            .gN[.g] = eml_getGroupData.n
            .gData# = eml_getGroupData.data#
            .totalN = .totalN + .gN[.g]

            if .gN[.g] > 0
                .gMean[.g] = mean (.gData#)
            else
                .gMean[.g] = undefined
            endif

            # Within-group SS: sum of (x - group_mean)^2
            for .idx from 1 to .gN[.g]
                .dev = .gData#[.idx] - .gMean[.g]
                .ssWithin = .ssWithin + .dev * .dev
            endfor
        endfor

        # MSE
        .dfWithin = .totalN - .nGroups
        if .dfWithin <= 0
            .error$ = "emlScheffe: dfWithin <= 0 (N="
            ... + string$ (.totalN) + ", k="
            ... + string$ (.nGroups) + ")"
        else
            .mse = .ssWithin / .dfWithin
        endif
    endif

    if .error$ = ""
        # --- Pairwise Scheffe F and p ---

        .nPairs = .nGroups * (.nGroups - 1) / 2
        .pMatrix## = zero## (.nGroups, .nGroups)
        .fMatrix## = zero## (.nGroups, .nGroups)
        .diffMatrix## = zero## (.nGroups, .nGroups)

        for .g from 1 to .nGroups
            .pMatrix##[.g, .g] = 1
        endfor

        for .i from 1 to .nGroups - 1
            for .j from .i + 1 to .nGroups
                .diff = .gMean[.i] - .gMean[.j]
                .se = sqrt (.mse * (1 / .gN[.i] + 1 / .gN[.j]))

                if .se = 0
                    .fScheffe = 0
                    .pVal = 1
                else
                    .fScheffe = (.diff / .se) ^ 2
                    ... / (.nGroups - 1)
                    .pVal = fisherQ (.fScheffe,
                    ... .nGroups - 1, .dfWithin)
                endif

                .pMatrix##[.i, .j] = .pVal
                .pMatrix##[.j, .i] = .pVal
                .fMatrix##[.i, .j] = .fScheffe
                .fMatrix##[.j, .i] = .fScheffe
                .diffMatrix##[.i, .j] = .diff
                .diffMatrix##[.j, .i] = -.diff
            endfor
        endfor
    endif

    # --- Restore selection ---

    selectObject: .tableId
endproc


# ============================================================================
# END OF MODULE
# ============================================================================
