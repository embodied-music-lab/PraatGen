# ============================================================================
# EML Stats : Test Helpers
# ============================================================================
# Module: eml-test-helpers.praat
# Version: 1.0
# Date: 26 February 2026
#
# Part of the EML Stats library (EML Praat Tools).
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides: @emlTestInit, @emlTestSection, @emlTestAssertTrue,
#   @emlTestAssertEqualNum, @emlTestAssertEqualStr,
#   @emlTestAssertUndefined, @emlTestAssertVectorsEqual,
#   @emlTestAssertContains, @emlTestSummary
#
# Unified test assertion library for all EML Stats test suites.
# Replaces the ad-hoc test helpers in Phase 1 test files.
#
# Usage:
#   include eml-test-helpers.praat
#   @emlTestInit
#   @emlTestSection: "My tests"
#   @emlTestAssertTrue: "something is true", 1
#   @emlTestAssertEqualNum: "values match", 3.14, 3.14, 0.001
#   @emlTestSummary
#
# State management:
#   All assertion procedures increment counters stored as persistent
#   local variables in @emlTestInit (.passed, .failed, .count).
#   These are accessed cross-procedure as emlTestInit.passed, etc.
# ============================================================================


# ============================================================================
# @emlTestInit
# ============================================================================
# Initialize test counters and print suite header.
# Call once at the start of each test suite.
#
# Output (persistent, read by all other emlTest procedures):
#   .passed       - number of passed assertions
#   .failed       - number of failed assertions
#   .count        - total assertions run
#   .sectionCount - number of sections started
# ============================================================================

procedure emlTestInit
    .passed = 0
    .failed = 0
    .count = 0
    .sectionCount = 0
    .border$ = "═══════════════════════════════════════════════════════"
    .title$ = "  EML Stats Test Suite"
    writeInfoLine: .border$
    appendInfoLine: .title$
    appendInfoLine: .border$
    .empty$ = ""
    appendInfoLine: .empty$
endproc


# ============================================================================
# @emlTestSection
# ============================================================================
# Print a section header to visually group related tests.
#
# Arguments:
#   .title$ - section name
# ============================================================================

procedure emlTestSection: .title$
    emlTestInit.sectionCount = emlTestInit.sectionCount + 1
    .prefix$ = "── "
    .suffix$ = " ──────────────────────────────────"
    .line$ = .prefix$ + .title$ + .suffix$
    .empty$ = ""
    appendInfoLine: .empty$
    appendInfoLine: .line$
endproc


# ============================================================================
# @emlTestAssertTrue
# ============================================================================
# Assert that a condition is true (nonzero).
#
# Arguments:
#   .name$     - test description
#   .condition - numeric value (nonzero = pass, 0 = fail)
# ============================================================================

procedure emlTestAssertTrue: .name$, .condition
    emlTestInit.count = emlTestInit.count + 1
    if .condition
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    endif
endproc


# ============================================================================
# @emlTestAssertEqualNum
# ============================================================================
# Assert that two numeric values are equal within tolerance.
# Handles undefined: both undefined = pass, one undefined = fail.
#
# Arguments:
#   .name$     - test description
#   .expected  - expected value
#   .actual    - actual value
#   .tolerance - maximum allowed difference
# ============================================================================

procedure emlTestAssertEqualNum: .name$, .expected, .actual, .tolerance
    emlTestInit.count = emlTestInit.count + 1

    # Determine pass/fail with undefined handling
    if .expected = undefined and .actual = undefined
        .pass = 1
    elsif .expected = undefined or .actual = undefined
        .pass = 0
    else
        .diff = abs (.actual - .expected)
        if .diff <= .tolerance
            .pass = 1
        else
            .pass = 0
        endif
    endif

    if .pass
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        # Detail lines
        if .expected = undefined
            .expectedStr$ = "undefined"
        else
            .expectedStr$ = fixed$ (.expected, 6)
        endif
        if .actual = undefined
            .actualStr$ = "undefined"
        else
            .actualStr$ = fixed$ (.actual, 6)
        endif
        .expectedLabel$ = "    Expected: "
        .actualLabel$ = "    Got:      "
        .expectedLine$ = .expectedLabel$ + .expectedStr$
        .actualLine$ = .actualLabel$ + .actualStr$
        appendInfoLine: .expectedLine$
        appendInfoLine: .actualLine$
    endif
endproc


# ============================================================================
# @emlTestAssertEqualStr
# ============================================================================
# Assert that two strings are identical.
#
# Arguments:
#   .name$     - test description
#   .expected$ - expected string
#   .actual$   - actual string
# ============================================================================

procedure emlTestAssertEqualStr: .name$, .expected$, .actual$
    emlTestInit.count = emlTestInit.count + 1
    if .expected$ = .actual$
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        .expectedLabel$ = "    Expected: "
        .actualLabel$ = "    Got:      "
        .expectedLine$ = .expectedLabel$ + .expected$
        .actualLine$ = .actualLabel$ + .actual$
        appendInfoLine: .expectedLine$
        appendInfoLine: .actualLine$
    endif
endproc


# ============================================================================
# @emlTestAssertUndefined
# ============================================================================
# Assert that a value is undefined.
#
# Arguments:
#   .name$  - test description
#   .value  - value to check
# ============================================================================

procedure emlTestAssertUndefined: .name$, .value
    emlTestInit.count = emlTestInit.count + 1
    if .value = undefined
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        .actualStr$ = fixed$ (.value, 6)
        .detailLabel$ = "    Expected undefined, got: "
        .detailLine$ = .detailLabel$ + .actualStr$
        appendInfoLine: .detailLine$
    endif
endproc


# ============================================================================
# @emlTestAssertVectorsEqual
# ============================================================================
# Assert that two numeric vectors are element-wise equal within tolerance.
# Fails if sizes differ or any element pair exceeds tolerance.
#
# Arguments:
#   .name$     - test description
#   .v1#       - expected vector
#   .v2#       - actual vector
#   .tolerance - maximum allowed per-element difference
#
# Note: undefined elements are compared via subtraction — if both are
#   undefined, the difference is undefined (not zero), which will exceed
#   tolerance. Use @emlTestAssertTrue with explicit undefined checks if
#   vectors may contain undefined values.
# ============================================================================

procedure emlTestAssertVectorsEqual: .name$, .v1#, .v2#, .tolerance
    emlTestInit.count = emlTestInit.count + 1
    .n1 = size (.v1#)
    .n2 = size (.v2#)

    if .n1 <> .n2
        .pass = 0
        .failIdx = 0
        .reason$ = "size mismatch"
    else
        .pass = 1
        .failIdx = 0
        .reason$ = ""
        for .i from 1 to .n1
            if .pass = 1
                .diff = abs (.v1#[.i] - .v2#[.i])
                if .diff > .tolerance
                    .pass = 0
                    .failIdx = .i
                endif
            endif
        endfor
    endif

    if .pass
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        if .reason$ = "size mismatch"
            .n1Str$ = string$ (.n1)
            .n2Str$ = string$ (.n2)
            .detailLine$ = "    Size mismatch: expected " + .n1Str$ + ", got " + .n2Str$
            appendInfoLine: .detailLine$
        else
            .idxStr$ = string$ (.failIdx)
            .expectedStr$ = fixed$ (.v1#[.failIdx], 6)
            .actualStr$ = fixed$ (.v2#[.failIdx], 6)
            .detailLine$ = "    Element [" + .idxStr$ + "]: expected " + .expectedStr$ + ", got " + .actualStr$
            appendInfoLine: .detailLine$
        endif
    endif
endproc


# ============================================================================
# @emlTestAssertContains
# ============================================================================
# Assert that a string contains a substring.
#
# Arguments:
#   .name$     - test description
#   .haystack$ - string to search in
#   .needle$   - substring to find
# ============================================================================

procedure emlTestAssertContains: .name$, .haystack$, .needle$
    emlTestInit.count = emlTestInit.count + 1
    .pos = index (.haystack$, .needle$)
    if .pos > 0
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        .searchLabel$ = "    Searching for: "
        .inLabel$ = "    In string:     "
        .searchLine$ = .searchLabel$ + .needle$
        .inLine$ = .inLabel$ + .haystack$
        appendInfoLine: .searchLine$
        appendInfoLine: .inLine$
    endif
endproc


# ============================================================================
# @emlTestSummary
# ============================================================================
# Print final test results. Call once at the end of each test suite.
# ============================================================================

procedure emlTestSummary
    .empty$ = ""
    .border$ = "═══════════════════════════════════════════════════════"
    .heading$ = "  TEST SUMMARY"
    appendInfoLine: .empty$
    appendInfoLine: .border$
    appendInfoLine: .heading$
    appendInfoLine: .border$

    .passedStr$ = string$ (emlTestInit.passed)
    .failedStr$ = string$ (emlTestInit.failed)
    .countStr$ = string$ (emlTestInit.count)

    .passLine$ = "  Passed:  " + .passedStr$
    .failLine$ = "  Failed:  " + .failedStr$
    .totalLine$ = "  Total:   " + .countStr$
    appendInfoLine: .passLine$
    appendInfoLine: .failLine$
    appendInfoLine: .totalLine$

    appendInfoLine: .empty$
    if emlTestInit.failed = 0
        .resultLine$ = "  ALL TESTS PASSED"
        appendInfoLine: .resultLine$
    else
        .resultLine$ = "  SOME TESTS FAILED"
        appendInfoLine: .resultLine$
    endif
    appendInfoLine: .border$
endproc


# ============================================================================
# END OF MODULE
# ============================================================================
