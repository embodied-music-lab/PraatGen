# EML Procedure Guide
# Version: 1.1
# Date: 4 April 2026
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
#
# PURPOSE
# Condensed methodology and routing reference for the EML procedure
# library. Used by PraatGen (and any Claude project with the EML master
# prompt) to select and apply procedures correctly.
#
# This file contains RULES and ROUTING only — no procedure source code.
# For procedure signatures and parameters, see EML_PROCEDURE_REGISTRY.md.
# For complete procedure implementations, see the source .praat files
# in Project Knowledge.
#
# VERSIONING
# This guide reflects the following source file versions:
#   eml-graph-procedures.praat      v3.18
#   eml-draw-procedures.praat       v1.12
#   eml-annotation-procedures.praat v3.8
#   eml-core-utilities.praat        v1.0
#   eml-core-descriptive.praat      v1.0
#   eml-extract.praat               v1.0
#   eml-output.praat                v1.1
#   eml-inferential.praat           v0.9
#   eml-vibrato-procedures.praat    v2.0
#   eml-demo-procedures.praat       v1.2
#   eml-batch-process.praat         v1.1
#   eml-test-helpers.praat          v1.0
#   eml-wizard.praat                v1.4
#   eml-graphs.praat                v2.44
#
# When a source file is updated, bump its version here. A mismatch
# between this table and the source file header signals the guide
# needs review.

# ====================================================================
# 1. DRAWING METHODOLOGY
# ====================================================================
#
# These rules govern all Picture window output. They supplement the
# master prompt's Rule 28 (which defines correctness requirements)
# with methodology guidance for procedure selection.
#
# 1.1 GRAPH TYPE SELECTION
#
# The graph type follows from the data structure, not user preference.
# When the task is ambiguous, use this mapping:
#
#   Data structure              → Primary graph      → Alternatives
#   ─────────────────────────── ──────────────────── ──────────────
#   One continuous variable     → Histogram           → Violin (if grouped)
#   Two groups, continuous DV   → Violin              → Box, Bar
#   k groups, continuous DV     → Violin              → Box, Bar
#   Two continuous variables    → Scatter              → (none)
#   Time series, one group      → Time Series          → Spaghetti (if subjects)
#   Time series, CI needed      → Time Series CI       → (none)
#   Repeated measures           → Spaghetti            → (none)
#   Pitch object                → F0 Contour           → (none)
#   Sound object                → Waveform              → (none)
#   Spectrum object             → Spectrum              → LTAS
#   Ltas object                 → LTAS                  → (none)
#   Two factors, continuous DV  → Grouped Violin        → Grouped Box
#
# Bar charts are appropriate when the user has pre-computed summary
# statistics or when the audience expects bars (e.g., grant reports).
# For raw data, violin or box plots are preferred because they show
# distribution shape.
#
# 1.2 ADAPTIVE THEMING
#
# All visual parameters (font sizes, margins, line widths, marker
# sizes, tick density) are computed from viewport dimensions by
# @emlSetAdaptiveTheme. Never hardcode these values. Key outputs:
#   .bodySize, .titleSize, .subtitleSize, .annotSize, .matrixSize
#   .marginLeft, .marginRight, .marginTop, .marginBottom
#   .lineWidth, .thinLine, .markerSize
#   .worldPerInchX, .worldPerInchY (coordinate conversion)
#
# 1.3 COLOR PALETTE
#
# @emlSetColorPalette provides Okabe-Ito (colorblind-safe) or B/W
# palettes for up to 10 groups. Access via .line$[n], .fill$[n],
# .lightLine$[n]. When groups > 3, call @emlOptimizePaletteContrast
# to reorder for maximum perceptual separation.
#
# 1.4 AXIS CONVENTIONS
#
# Always suppress garnish (set garnish parameter to "no") and use
# manual axis commands via @emlDrawAxes or @emlDrawAxesSelective.
# Axis ranges: @emlComputeAxisRange with buffer.
# Tick intervals: @emlComputeNiceStep.
# Categorical axes: @emlDrawCategoricalXAxis with
# @emlFitCategoricalLabels for font-size-aware truncation.
#
# 1.5 FONT STATE INVARIANT (Picture window)
#
# `Font size: bodySize` must be the ambient state before all
# coordinate-dependent drawing commands (Select inner viewport:,
# One mark:, Draw inner box, etc.). `Text special:` is self-
# contained and does not alter global font state. This invariant
# ensures text-width measurements match the rendering state.
#
# 1.6 SPECIAL CHARACTER ESCAPING
#
# %, #, ^, _ are style toggles in Praat's text renderer. Any display
# text from variables (column headers, object names, user input) must
# pass through @emlSanitizeLabel before rendering. Static string
# literals need only visual inspection.
#
# 1.7 VIEWPORT AND SAVE
#
# Before any Save as ... file: command, select the full outer viewport
# with @emlAssertFullViewport. This procedure reads from drawn extent
# globals (emlDrawnMinX/MaxX/MinY/MaxY) and takes no parameters.
# Failure to reset after panel drawing saves only the last panel.
#
# 1.8 MEASURE-THEN-DRAW
#
# All data extraction and measurement must occur before drawing
# dispatch. Draw procedures are pure renderers — they read from
# measurement globals only. This applies universally:
#   @emlMeasureCategoricalLabels — label widths for categorical axis
#   @emlMeasureBarData — means, errors, ranges for bar charts
#   @emlMeasureGraphLayout — viewport, margins, label placement
#   @emlMeasureMatrixLayout — cell dimensions for comparison matrix
#
# 1.9 LEGEND AND ANNOTATION
#
# Include @emlDrawLegend when multiple groups, series, or colors
# appear in the same figure. Corner placement uses @emlPlaceElements
# to avoid collisions with annotation blocks.
#
# For statistical annotations on graphs, use the annotation bridge
# (Section 4). The annotation system uses an array-based queue:
# @emlClearAnnotations → populate brackets/text → @emlStackBrackets
# → @emlDrawAnnotations. Annotations render after data but before
# the axis frame.

# 1.10 PANEL CONTEXT
#
# All drawing orchestrators render relative to a panel origin defined
# by globals emlPanelOriginX and emlPanelOriginY. The origin is
# absorbed by @emlSetAdaptiveTheme — all viewport bounds it computes
# include the offset.
#
# Initialization: @emlInitDrawingDefaults sets panel origin to (0,0)
# and initializes all drawing globals. Call once at script start.
#
# Extent tracking: @emlResetDrawnExtent zeroes the bounding box.
# @emlExpandDrawnExtent updates it. Both draw procedures and
# @emlDrawMatrixPanel call @emlExpandDrawnExtent to register their
# viewport with the tracker. @emlAssertFullViewport reads the
# accumulated extent.
#
# Single-panel figures (default): Call @emlInitDrawingDefaults,
# @emlResetDrawnExtent, then the draw procedure. No panel origin
# manipulation needed.
#
# Multi-panel figures: Call @emlSetPanelOrigin: x, y before each
# panel's draw procedure. The orchestrator draws within its assigned
# region. The extent tracker accumulates across all panels —
# @emlResetDrawnExtent is NOT needed between panels.
# Call @emlAssertFullViewport before saving to capture everything.
#
# Example (two panels side by side):
#
#   @emlInitDrawingDefaults
#   @emlResetDrawnExtent
#   Erase all
#
#   # Left panel
#   @emlSetPanelOrigin: 0, 0
#   @emlDrawViolinPlot: tableId, "F0 Distribution", "",
#   ... "F0 (Hz)", 3.5, 5, "Color", 1, "group", "F0", 0, 0
#
#   # Right panel
#   @emlSetPanelOrigin: 3.5, 0
#   @emlDrawHistogram: tableId, "F0 Distribution", "F0 (Hz)",
#   ... "Count", 3.5, 5, "Color", 1, "F0", "", 0, 1, 0, 0, 0
#
#   # Save
#   @emlAssertFullViewport
#   Save as 300-dpi PNG file: outputPath$

# ====================================================================
# 2. STATISTICS METHODOLOGY
# ====================================================================
#
# 2.1 TEST SELECTION DECISION TREE
#
#   Research question
#   │
#   ├── Describe one variable
#   │   → @emlDescribe (full summary)
#   │   → Individual procedures for specific measures
#   │
#   ├── Compare groups
#   │   ├── 2 groups
#   │   │   ├── Independent
#   │   │   │   ├── Parametric → @emlTTest (Welch default)
#   │   │   │   └── Nonparametric → @emlMannWhitneyU
#   │   │   └── Paired
#   │   │       ├── Parametric → @emlTTestPaired
#   │   │       └── Nonparametric → @emlWilcoxonSignedRank
#   │   └── 3+ groups
#   │       ├── One factor
#   │       │   ├── Parametric → @emlOneWayAnova (+@emlTukeyHSD)
#   │       │   └── Nonparametric → @emlKruskalWallis (+@emlDunnTest)
#   │       └── Two factors → @emlTwoWayAnova
#   │
#   └── Examine relationship
#       ├── Both continuous
#       │   ├── Linear, normal → @emlPearsonCorrelation
#       │   └── Monotonic or non-normal → @emlSpearmanCorrelation
#       └── (Regression: not yet implemented)
#
# 2.2 PARAMETRIC VS. NONPARAMETRIC
#
# Default to parametric when:
#   - Sample size >= 30 per group (CLT applies)
#   - Distribution approximately symmetric (|skewness| < 1)
#   - No extreme outliers
#
# Use nonparametric when:
#   - Small samples with unknown distribution shape
#   - Ordinal data
#   - |skewness| >= 1 or kurtosis >> 3
#   - Outliers that cannot be justified for removal
#
# When uncertain, run both and report both.
#
# 2.3 EFFECT SIZE PAIRING
#
# Every test has a paired effect size. Always report both.
#
#   Test                    → Effect size             → Measure
#   ─────────────────────── ──────────────────────── ─────────
#   @emlTTest               → @emlCohenD              → d, g
#   @emlTTestPaired         → @emlCohenD              → d, g
#   @emlMannWhitneyU        → @emlRankBiserialR       → r
#   @emlWilcoxonSignedRank  → @emlMatchedPairsR        → r
#   @emlOneWayAnova         → (eta-sq from output)     → eta-sq
#   @emlKruskalWallis       → @emlEpsilonSquared       → eps-sq
#   @emlPearsonCorrelation  → (r IS the effect size)   → r
#   @emlSpearmanCorrelation → (rho IS the effect size)  → rho
#
# Pairwise effect sizes for k-group tests:
#   @emlOneWayAnova + @emlTukeyHSD → .dMatrix## (Cohen's d)
#   @emlKruskalWallis + @emlDunnTest → .rMatrix## (rank-biserial r)
#
# Effect size interpretation (Cohen's conventions):
#   d:     small 0.2,  medium 0.5,  large 0.8
#   r:     small 0.1,  medium 0.3,  large 0.5
#   eta-sq: small 0.01, medium 0.06, large 0.14
#   eps-sq: small 0.01, medium 0.06, large 0.14
#
# Use @emlFormatEffectLabel for automatic interpretation labels.
#
# 2.4 P-VALUE ADJUSTMENT
#
# When performing multiple comparisons, adjust p-values:
#
#   Holm (default)     → @emlHolm     → General purpose, more
#                                        powerful than Bonferroni
#   Bonferroni         → @emlBonferroni → Conservative, simple
#   Benjamini-Hochberg → @emlBenjaminiHochberg → Exploratory,
#                                        many comparisons
#
# Holm is the default for all post-hoc procedures.
#
# 2.5 DATA EXTRACTION PIPELINE
#
# Standard flow from Praat object to statistical test:
#
#   Praat object → @emlExtract* → vector(s) → @eml[Test] → outputs
#
# For Table data:
#   Table → @emlValidateTable → @emlExtractColumn (or
#           @emlExtractGroupVectors) → test procedure
#
# For k-group tests (ANOVA, KW), pass the Table ID directly —
# they handle extraction internally via @emlExtractMultipleGroups.
#
# For acoustic objects:
#   Pitch → @emlExtractPitchValues → vector → test
#   Formant → @emlExtractFormantValues → vector → test
#   Intensity → @emlExtractIntensityFrames → vector → test
#   Harmonicity → @emlExtractHarmonicityFrames → vector → test
#
# 2.6 OUTPUT CONVENTIONS
#
# All public procedures set .error$ = "" at entry, populate on
# failure. Check .error$ before reading output variables.
#
# Numeric outputs use `undefined` for failed computations.
# This is Praat-idiomatic: `if x <> undefined` guards work.
#
# Formatted output: @emlReportAPA for APA-style result strings,
# @emlFormatP for "< .001" / "= .023" convention, @emlFormatCI
# for confidence intervals.
#
# 2.7 VERIFIED CONVENTIONS AND KNOWN DIFFERENCES
#
# Dunn's test: Two-tailed raw p with Holm adjustment. R `dunn.test`
# uses one-sided p with alpha/2 rejection. Equivalent for Bonferroni,
# may differ slightly for Holm.
#
# MWU exact path: DP uses no-tie null distribution. Slightly
# conservative when ties produce half-integer U.
#
# Tukey HSD: Groups sorted alphabetically (matching R). Display order
# uses encounter order. The anovaMap[] lookup bridges these.
#
# All implementations cross-verified against R and scipy.
#
# 2.8 WRAPPER VERIFICATION RULE
#
# Wrappers must be written against actual source output variable names,
# never the bible or documentation. Five confirmed failures from this
# pattern. Always verify against the source .praat file before writing
# a caller that reads procedure output variables.
#
# 2.9 CSV EXPORT INFRASTRUCTURE
#
# Three procedures in eml-output.praat manage structured CSV export:
#   @emlCSVInit — initialize accumulator arrays (called once)
#   @emlCSVAddRow — append one comparison row to accumulators
#   @emlExportStatsCSV — write accumulated rows to file
#
# Shared reporters (@emlReport*) call @emlCSVAddRow internally.
# CSV rows contain structured data only — "Why:" pedagogical
# commentary and section headers are naturally excluded. The
# caller is responsible for calling @emlCSVInit before the first
# reporter and @emlExportStatsCSV after reporting is complete.

# ====================================================================
# 3. DEMO WINDOW METHODOLOGY
# ====================================================================
#
# 3.1 TEXT ALIGNMENT (CRITICAL)
#
# Set `demo Font size:` ONCE at script startup. NEVER change it.
# Use `demo Text special:` for ALL text, passing the desired size
# in Text special's own parameter:
#
#   demo Font size: 14
#   demo Text special: x, "left", y, "half", "Helvetica", 28, "0", "Title"
#   demo Text special: x, "left", y2, "half", "Helvetica", 14, "0", "Body"
#
# ROOT CAUSE: The `demo` prefix uses the ambient font size in its
# coordinate transformation. Changing ambient size shifts pixel
# positions, causing cross-size misalignment. Constant ambient size
# keeps the transformation identical for all text.
#
# Never use `demo Text:` — it inherits the ambient size and provides
# no size parameter. Use `demo Text special:` exclusively.
#
# 3.2 VIEWPORT COORDINATES
#
# `demo Select inner viewport:` takes 0-100 Demo window units
# (NOT inches). Parameter order: left, right, BOTTOM, TOP.
# Y-UP (matching demo coordinates), opposite of Picture window.
#
# Restore full viewport: `demo Select inner viewport: 0, 100, 0, 100`
#
# 3.3 ASPECT RATIO
#
# Demo window: ~1.726:1 (2686 x 1556 px on Retina).
# 1 vertical unit ~ 58% the physical size of 1 horizontal unit.
# Vertical spacing values must account for this. A "square" from
# (0,0) to (20,20) renders as a wide rectangle.
#
# 3.4 FULL-BLEED
#
# Use -10/110 for both axes to eliminate OS margins:
#   demo Paint rectangle: color$, -10, 110, -10, 110
#
# 3.5 TEMPLATE ARCHITECTURE
#
# Content/layout separation pattern:
#
# Content registry: globals named pg[N]_[field]$
#   pg3_template$ = "textPage"
#   pg3_heading$ = "The Scenario"
#   pg3_body$ = "Imagine you are a voice therapist..."
#
# Templates: procedures reading content via interpolation
#   pg'.n'_heading$ expands .n to produce the global name
#
# Placement procedures: each encodes one typographic role (hero,
# title, heading, body, bullet, code) with font/size/color/alignment.
# Returns .nextY for vertical flow.
#
# 3.6 ROTATION PARAMETER
#
# `demo Text special:` rotation parameter is string "0" (not
# numeric 0). Same as Picture window `Text special:`.

# ====================================================================
# 4. STATS-TO-GRAPH BRIDGE AND SHARED REPORTERS
# ====================================================================
#
# 4.1 ARCHITECTURE
#
# The bridge connects statistical test output to two consumers:
#   1. Graph annotations (brackets, text blocks, matrix panels)
#   2. Info window reporting (descriptive stats, test results, "Why:")
#
# Single-source-of-truth pattern: six shared reporter procedures in
# eml-annotation-procedures.praat handle ALL Info window output and
# CSV row population. They are called identically by:
#   - Stats wrapper scripts (eml-compare-groups.praat, etc.)
#   - The graphs tool (via @emlReportBridgeStats dispatcher)
#   - The wizard (via @wizardRun* procedures)
#
# 4.2 SHARED REPORTERS
#
#   Reporter                        → Test families served
#   ─────────────────────────────── ──────────────────────────────
#   @emlReportTwoGroupComparison    → Welch t, Student t, MWU
#   @emlReportAnovaComparison       → One-way ANOVA ± Tukey HSD
#   @emlReportKWComparison          → Kruskal-Wallis ± Dunn's
#   @emlReportPairedComparison      → Paired t, Wilcoxon SR
#   @emlReportCorrelationAnalysis   → Pearson, Spearman
#   @emlReportTwoWayAnova           → Two-way factorial ANOVA
#
# Each reporter produces:
#   - Descriptive statistics section (n, mean, SD, median per group)
#   - Test results (stat, df, p, effect size, CI)
#   - "Why:" pedagogical commentary (always in Info, excluded from CSV)
#   - Pairwise post-hoc results if applicable (Tukey/Dunn's)
#   - Pairwise effect sizes from matrix outputs (.dMatrix##, .rMatrix##)
#   - CSV rows via @emlCSVAddRow
#
# 4.3 BRIDGE ENTRY POINTS
#
#   @emlBridgeGroupComparison — for bar/violin/box with annotations
#   @emlBridgeCorrelation — for scatter with regression line
#   @emlReportBridgeStats — thin dispatcher (reads bridge globals,
#     routes to the appropriate shared reporter)
#
# 4.4 ANNOTATION FLOW
#
#   Test context      → Graph types    → Annotation style
#   ───────────────── ──────────────── ─────────────────────
#   2 groups          → Violin, Box,   → Single bracket
#                       Bar
#   k groups (ANOVA)  → Violin, Box,   → Omnibus text +
#                       Bar               pairwise brackets
#   k groups (KW)     → Violin, Box,   → Omnibus text +
#                       Bar               pairwise brackets
#   Correlation       → Scatter         → Regression line +
#                                         r/p text block
#
# Annotation layout modes:
#   2 groups → brackets (always)
#   3+ groups, layoutMode 0 → auto (brackets if k<=4, matrix if k>=3)
#   3+ groups, layoutMode 1 → brackets only
#   3+ groups, layoutMode 2 → matrix only
#   Matrix: split-triangle with p-values upper, effect sizes lower
#
# 4.5 ANNOTATION QUEUE PATTERN
#
#   @emlClearAnnotations              — reset arrays + globals
#   @emlBridgeGroupComparison         — run stats, populate arrays
#   @emlStackBrackets                 — compute vertical positions
#   ... draw procedure renders data ...
#   @emlDrawAnnotations               — render brackets/text
#   @emlDrawMatrixPanel (if matrix)   — render comparison matrix
#   @emlDrawAxes                      — axis frame on top
#
# 4.6 EFFECT SIZE MATRIX READS (v3.8+)
#
# Bridge and reporter procedures read pairwise effect sizes from
# matrices stored by the stats procedures, rather than recomputing:
#   - @emlOneWayAnova.dMatrix## — Cohen's d for all pairs (via Tukey)
#   - @emlDunnTest.rMatrix## — rank-biserial r for all pairs
#
# Matrix indices follow the stats procedure's alphabetical sort
# order. @emlTukeyHSD.sortMap maps display indices to matrix indices.
#
# 4.7 DISPATCHER PATTERN
#
# @emlReportBridgeStats reads bridge globals set by
# @emlBridgeGroupComparison / @emlBridgeCorrelation:
#   annotBridgeNGroups, annotBridgeTestType$, annotBridgeGroup1$,
#   annotBridgeGroup2$, annotBridgeCorrType$, etc.
#
# It routes to the appropriate shared reporter with a single
# if/elsif chain. Same 3-arg signature as the original pre-
# convergence version, so call sites in eml-graphs.praat are
# unchanged.

# ====================================================================
# 5. PROCEDURE ROUTING
# ====================================================================
#
# This section maps task descriptions to procedure families. When
# Claude receives a task, search here first for relevant procedures,
# then consult EML_PROCEDURE_REGISTRY.md for signatures, then read
# the source file for implementation.
#
# 5.1 DRAWING TASKS
#
# "Draw a bar chart / violin / box plot / histogram"
#   → Graphs: Draw family (@emlDraw*)
#   → Requires: Graphs: Core (@emlSetAdaptiveTheme, @emlSetColorPalette,
#     @emlComputeAxisRange, @emlDrawAxes)
#   → If annotation: Graphs: Annotation family
#
# "Draw a pitch contour / waveform / spectrum / LTAS"
#   → Graphs: Draw family (acoustic-specific procedures)
#   → Requires: Graphs: Core (theming, axes)
#
# "Draw a scatter plot with regression line"
#   → @emlDrawScatterPlot + @emlBridgeCorrelation
#   → @emlDrawRegressionLine for the line itself
#
# "Multi-panel figure"
#   → @emlInitDrawingDefaults + @emlResetDrawnExtent
#   → @emlSetPanelOrigin before each panel
#   → Multiple @emlDraw* calls
#   → @emlAssertFullViewport before save
#
# "Publication-quality figure"
#   → All drawing tasks use @emlSetAdaptiveTheme (always publication
#     quality by default)
#
# 5.2 STATISTICS TASKS
#
# "Compare two groups"
#   → @emlExtractGroupVectors + @emlTTest (or @emlMannWhitneyU)
#   → + @emlCohenD (or @emlRankBiserialR) for effect size
#   → Report via @emlReportTwoGroupComparison
#
# "Compare three or more groups"
#   → @emlOneWayAnova with tukey=1 (or @emlKruskalWallis + @emlDunnTest)
#   → Report via @emlReportAnovaComparison / @emlReportKWComparison
#
# "Compare paired samples"
#   → @emlTTestPaired (or @emlWilcoxonSignedRank)
#   → Report via @emlReportPairedComparison
#
# "Correlate two variables"
#   → @emlExtractPairedColumns + @emlPearsonCorrelation
#     (or @emlSpearmanCorrelation)
#   → Report via @emlReportCorrelationAnalysis
#
# "Two-way ANOVA"
#   → @emlTwoWayAnova
#   → Report via @emlReportTwoWayAnova
#
# "Descriptive statistics"
#   → @emlExtractColumn + @emlDescribe (comprehensive)
#   → Or individual: @emlMean, @emlSD, @emlMedian, etc.
#
# "Pairwise comparisons"
#   → @emlPairwiseT or @emlPairwiseWilcoxon (all pairs with adjustment)
#   → @emlScheffe (conservative alternative to Tukey)
#
# "Adjust p-values"
#   → @emlHolm (default), @emlBonferroni, @emlBenjaminiHochberg
#
# 5.3 DATA PREPARATION TASKS
#
# "Extract data from a Praat object"
#   → Stats: Extraction family (@emlExtract*)
#   → Match object type: Pitch → @emlExtractPitchValues,
#     Formant → @emlExtractFormantValues, etc.
#
# "Extract column from Table"
#   → @emlExtractColumn (numeric) or @emlExtractColumnAsStrings
#
# "Validate a Table before analysis"
#   → @emlValidateTable + @emlValidateNumericColumn
#
# "Count groups in a column"
#   → @emlCountGroups
#
# 5.4 OUTPUT AND FORMATTING TASKS
#
# "Format results for Info window"
#   → Stats: Output family (@emlReport*, @emlFormat*)
#   → @emlReportHeader to clear and start, @emlReportLine for rows,
#     @emlReportFooter to close
#   → Shared reporters (@emlReportTwoGroupComparison, etc.) for
#     complete test reporting
#
# "APA-style result string"
#   → @emlReportAPA
#
# "Save Info window to file"
#   → @emlSaveInfoToFile (with overwrite protection)
#
# "Export stats results to CSV"
#   → @emlCSVInit + shared reporters (populate rows) + @emlExportStatsCSV
#
# 5.5 BATCH PROCESSING TASKS
#
# "Process a folder of files"
#   → Batch: Infrastructure (@emlBuildDateStamp, @emlInitSentinel,
#     @emlCheckStopSentinel)
#   → Pattern: file list → batch range dialog → sentinel init →
#     per-file loop with sentinel check → CSV export → summary
#
# 5.6 VIBRATO ANALYSIS TASKS
#
# "Analyze vibrato"
#   → Vibrato family — full pipeline from @emlVibratoPitchSetup
#     through @emlVibratoSummary
#   → Drawing: @emlVibratoDrawFigure for complete 8-panel output
#   → See vibrato-procedures-manual.md for step-by-step guide
#
# 5.7 TESTING TASKS
#
# "Write tests for a procedure"
#   → Dev: Test Harness family
#   → @emlTestInit to start, @emlTestAssert* for assertions,
#     @emlTestSummary to close
#   → Pattern: init → section → assertions → section → ... → summary
#
# 5.8 DEMO WINDOW TASKS
#
# "Build a tutorial / interactive Demo window display"
#   → Demo Window family
#   → @emlResetSans + @emlClearPage to initialize
#   → @emlPlace* procedures for typographic layout
#   → @emlDrawNav for navigation bar
#   → @emlWrapText for paragraph text
#   → @emlPlaceCodeLine for monospace code examples

# ====================================================================
# 6. SCRIPT GENERATION MODEL
# ====================================================================
#
# PraatGen generates flat, self-contained scripts. Every script runs
# as-is with zero dependencies — no `include` directives, no
# companion files, no plugin requirement.
#
# 6.1 EML PROCEDURES AS ALGORITHMIC TEMPLATES
#
# The EML procedure source files in Project Knowledge are verified
# implementations of complex operations: KDE for violin plots,
# adaptive theming from viewport dimensions, Tukey HSD with
# alphabetical sort mapping, Dunn's test with Holm adjustment,
# split-triangle comparison matrices, axis range computation,
# special character escaping, and so on.
#
# PraatGen reads these procedures to understand the algorithm, then
# writes equivalent flat code directly into the script. The procedure
# is the reference — the output is inline Praat script with no
# @-calls.
#
# 6.2 FLATTENING RULES
#
# When translating a procedure's algorithm into flat script:
#
# a) Replace all .localVar with script-scoped variables using
#    descriptive names (no dot prefix in main script body).
#
# b) Resolve transitive procedure calls. If procedure A calls
#    procedure B, the flat script contains the logic of both
#    in execution order — not as procedure definitions.
#
# c) Remove procedure entry/exit scaffolding (.error$ checks,
#    output variable assignments). The flat script uses the
#    computed values directly.
#
# d) Preserve the algorithm exactly. The procedures are tested
#    against R and scipy with hundreds of assertions. Do not
#    simplify, optimize, or rewrite the mathematical logic.
#    Structural changes (variable scoping, flow integration)
#    are expected; algorithmic changes are not.
#
# e) Preserve guard clauses and edge-case handling. If the
#    procedure checks for division by zero, equal group means,
#    or empty vectors, the flat script includes the same guards.
#
# 6.3 WHEN FLATTENING IS IMPRACTICAL
#
# Some algorithms are too large to flatten into a readable script
# (full violin plot orchestrator, vibrato pipeline, comparison
# matrix renderer). In these cases, PraatGen defines the procedures
# within the script body — procedure definitions above, executable
# code below. The script is still a single file with no external
# dependencies.
#
# The threshold is judgment-based: if flattening would produce
# unreadable code or exceed ~200 lines of interleaved logic,
# use in-script procedure definitions instead.
#
# When using in-script procedure definitions:
# - Copy the procedure code exactly from the source .praat file
# - Do not rewrite, condense, or improvise
# - Include only the procedures the script actually calls
# - Order definitions so callees appear before callers
# - Place all definitions after the script header and before
#   the first executable code
#
# 6.4 NO EXTERNAL DEPENDENCIES
#
# PraatGen scripts never use `include`. Every script is a single
# file that works anywhere, with no files to keep together and no
# paths to manage.

# ====================================================================
# 7. VERSIONING PROTOCOL
# ====================================================================
#
# Three versioned artifacts must stay synchronized:
#
#   Source .praat files → EML_PROCEDURE_REGISTRY.md → this guide
#
# 7.1 SOURCE FILES (leader)
#
# Each .praat file carries a version in its header comment block.
# When a procedure is added, modified, or removed, the file version
# bumps. This is the single source of truth for procedure code.
#
# 7.2 REGISTRY (follower)
#
# EML_PROCEDURE_REGISTRY.md lists all procedures with signatures.
# Its header records the date and total count. When a source file
# changes, regenerate the affected section of the registry.
#
# 7.3 THIS GUIDE (follower)
#
# The version table at the top of this file records which source
# file versions it reflects. When a source file version bumps:
#   1. Check whether the change affects methodology or routing
#   2. If yes, update the relevant section
#   3. Bump the source version in the table
#   4. If no methodology impact, just bump the version number
#
# 7.4 STALENESS DETECTION
#
# If a source file header shows v3.18 but this guide lists v3.17,
# the guide may be stale. Check the changelog in the source file
# to determine whether an update is needed.
#
# 7.5 REGISTRY GENERATION
#
# The registry can be regenerated mechanically by scanning procedure
# definitions (lines matching `^procedure `) across all source files.
# The guide cannot be regenerated mechanically — it encodes design
# decisions and methodology that require human judgment.

# ====================================================================
# END OF GUIDE
# ====================================================================
