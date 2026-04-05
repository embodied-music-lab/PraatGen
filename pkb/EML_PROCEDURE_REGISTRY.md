# EML Praat Tools — Procedure Registry

Generated: 4 April 2026 | Source: plugin_EMLTools v1.0 pre-release | 255 procedures (250 public, 5 internal)

# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab


---

## Stats: Descriptive
**File:** `stats/eml-core-descriptive.praat` (v1.0) — 18 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlMean` | Arithmetic mean of a numeric vector | .data# | public |
| `@emlMedian` | Median (middle value) of a numeric vector | .data# | public |
| `@emlMode` | Most frequent value in a numeric vector | .data# | public |
| `@emlPercentile` | Value at the p-th percentile | .data#, .p | public |
| `@emlQuartiles` | Q1, Q2 (median), Q3 quartile values | .data# | public |
| `@emlVariance` | Population and sample variance | .data# | public |
| `@emlSD` | Population and sample standard deviation | .data# | public |
| `@emlSEM` | Standard error of the mean | .data# | public |
| `@emlSkewness` | Skewness (asymmetry of distribution) | .data# | public |
| `@emlKurtosis` | Kurtosis (tail weight of distribution) | .data# | public |
| `@emlGeometricMean` | Geometric mean (multiplicative central tendency) | .data# | public |
| `@emlHarmonicMean` | Harmonic mean (rate-appropriate central tendency) | .data# | public |
| `@emlTrimmedMean` | Mean after trimming proportion from both tails | .data#, .proportion | public |
| `@emlWinsorizedMean` | Mean with extreme values clamped to percentile bounds | .data#, .proportion | public |
| `@emlMAD` | Median absolute deviation (robust spread measure) | .data# | public |
| `@emlRange` | Minimum, maximum, and range of a vector | .data# | public |
| `@emlCI` | Confidence interval for the mean | .data#, .confidenceLevel | public |
| `@emlDescribe` | Full descriptive summary (all stats in one call) | .data# | public |

## Stats: Utilities
**File:** `stats/eml-core-utilities.praat` (v1.0) — 15 procedures (14 public, 1 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_sortPairsByValue` | Shell sort with index tracking (internal helper) | .inputValues#, .inputIndices# | internal |
| `@emlRankVector` | Rank values with tie correction; outputs .tieCorrectionSum | .data# | public |
| `@emlCountIf` | Count elements matching a condition (>, <, =, etc.) | .data#, .operator$, .value | public |
| `@emlSubset` | Extract elements at specified indices | .data#, .indices# | public |
| `@emlUniqueValues` | Sorted unique values from a vector | .data# | public |
| `@emlFrequency` | Frequency count for each unique value | .data# | public |
| `@emlCumulativeSum` | Running cumulative sum of a vector | .data# | public |
| `@emlDiff` | First differences (element[i+1] - element[i]) | .data# | public |
| `@emlLag` | Lag a vector by k positions (shift + pad with undefined) | .data#, .k | public |
| `@emlBinData` | Bin data into nBins equal-width bins | .data#, .nBins | public |
| `@emlZScore` | Standardize vector to z-scores (mean=0, SD=1) | .data# | public |
| `@emlRemoveUndefined` | Remove undefined values from a vector | .data# | public |
| `@emlSortWithIndex` | Sort ascending; preserve original index mapping | .data# | public |
| `@emlConcatenateVectors` | Concatenate two vectors into one | .v1#, .v2# | public |
| `@emlRepeatVector` | Repeat a vector nReps times | .v#, .nReps | public |

## Stats: Extraction
**File:** `stats/eml-extract.praat` (v1.0) — 13 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlExtractColumn` | Extract numeric column from Table as vector | .tableId, .columnName$ | public |
| `@emlExtractColumnAsStrings` | Extract string column from Table as string array | .tableId, .columnName$ | public |
| `@emlExtractGroupVectors` | Split column into two vectors by group labels | .tableId, .measureCol$, .groupCol$, .label1$, .label2$ | public |
| `@emlExtractMultipleGroups` | Split column into k vectors by group (auto-detect groups) | .tableId, .measureCol$, .groupCol$ | public |
| `@emlExtractPairedColumns` | Extract two paired numeric columns as vectors | .tableId, .col1$, .col2$ | public |
| `@emlExtractPitchValues` | Extract defined F0 frames from Pitch object as vector | .pitchId, .unit$ | public |
| `@emlExtractFormantValues` | Extract formant values from Formant object as vector | .formantId, .formantNumber, .unit$ | public |
| `@emlExtractIntensityFrames` | Extract all frames from Intensity object as vector | .intensityId | public |
| `@emlExtractHarmonicityFrames` | Extract defined frames from Harmonicity object as vector | .harmonicityId | public |
| `@emlValidateTable` | Check Table has required columns; exitScript if not | .tableId, .requiredColumns$ | public |
| `@emlValidateNumericColumn` | Check column contains numeric data | .tableId, .columnName$ | public |
| `@emlTableColumnNames` | List all column names in a Table | .tableId | public |
| `@emlCountGroups` | Count distinct group labels in a column | .tableId, .groupCol$ | public |

## Stats: Output
**File:** `stats/eml-output.praat` (v1.1) — 20 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlPadRight` | Pad string with trailing spaces to target length | .text$, .targetLength | public |
| `@emlUnderscoreToSpace` | Replace all underscores with spaces | .text$ | public |
| `@emlReportHeader` | Print report header with borders (clears Info window) | .title$ | public |
| `@emlReportFooter` | Print report footer with borders | — | public |
| `@emlReportSection` | Print section divider with title | .title$ | public |
| `@emlReportLine` | Print label + numeric value row | .label$, .value, .decimals | public |
| `@emlReportLineString` | Print label + string value row | .label$, .value$ | public |
| `@emlReportBlank` | Print blank line in report | — | public |
| `@emlFormatP` | Format p-value (< .001, = .023, etc.) | .pValue | public |
| `@emlFormatCI` | Format confidence interval as [lower, upper] | .lower, .upper, .level | public |
| `@emlFormatTestResult` | Format complete test result line (stat, df, p, effect) | .testName$, .statSymbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper | public |
| `@emlFormatEffectLabel` | Format effect size with interpretive label (small/medium/large) | .effectValue, .effectType$ | public |
| `@emlReportDescriptiveHeader` | Print column headers for descriptive stats table | — | public |
| `@emlReportDescriptiveRow` | Print one row of descriptive stats | .label$, .n, .mean, .sd, .median | public |
| `@emlReportAPA` | Format result in APA style (e.g., t(28) = 2.31, p = .028) | .testType$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper | public |
| `@emlReportToFile` | Write current Info window contents to a file | .filePath$, .content$ | public |
| `@emlSaveInfoToFile` | Save Info window to file with overwrite protection | .filePath$ | public |
| `@emlCSVInit` | Initialize CSV export accumulator arrays | — | public |
| `@emlCSVAddRow` | Add one row to CSV accumulator | .table$, .dataCol$, .groupCol$, .g1$, .g2$, .test$, .stat, .df, .p, .es, .esType$, .esLabel$, .n1, .n2, .mean1, .sd1, .median1, .mean2, .sd2, .median2 | public |
| `@emlExportStatsCSV` | Export accumulated CSV data to file | .filePath$ | public |

## Stats: Inferential
**File:** `stats/eml-inferential.praat` (v0.9) — 26 procedures (22 public, 4 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlTTest` | Independent samples t-test (Welch or Student) | .v1#, .v2#, .tails, .equalVariances | public |
| `@emlTTestPaired` | Paired samples t-test | .v1#, .v2#, .tails | public |
| `@emlCohenD` | Cohen's d and Hedges' g effect sizes | .v1#, .v2# | public |
| `@emlPearsonCorrelation` | Pearson product-moment correlation with p-value | .x#, .y#, .tails | public |
| `@emlSpearmanCorrelation` | Spearman rank correlation with p-value | .x#, .y#, .tails | public |
| `@eml_mannWhitneyExactP` | Exact p-value for Mann-Whitney U (internal, n <= 20) | .u1, .n1, .n2 | internal |
| `@emlMannWhitneyU` | Mann-Whitney U test (nonparametric two-group comparison) | .v1#, .v2#, .tails | public |
| `@eml_wilcoxonExactP` | Exact p-value for Wilcoxon signed-rank (internal, n <= 20) | .tPlus, .n | internal |
| `@emlWilcoxonSignedRank` | Wilcoxon signed-rank test (nonparametric paired comparison) | .v1#, .v2#, .tails | public |
| `@emlRankBiserialR` | Rank-biserial r effect size for Mann-Whitney U | .v1#, .v2#, .tails | public |
| `@emlMatchedPairsR` | Matched-pairs rank-biserial r for Wilcoxon signed-rank | .v1#, .v2#, .tails | public |
| `@emlBonferroni` | Bonferroni p-value adjustment for multiple comparisons | .pValues# | public |
| `@emlHolm` | Holm step-down p-value adjustment | .pValues# | public |
| `@emlBenjaminiHochberg` | Benjamini-Hochberg FDR p-value adjustment | .pValues# | public |
| `@eml_parseAnovaLine` | Parse one line from Praat ANOVA report (internal) | .info$, .rowLabel$ | internal |
| `@emlTableFromGroups` | Prepare group data arrays for ANOVA from pre-extracted vectors | .nGroups, .dataColName$, .factorColName$ | public |
| `@emlTukeyHSD` | Tukey HSD post-hoc pairwise comparisons after ANOVA | .tableId, .dataColumn$, .factorColumn$, .alpha | public |
| `@emlOneWayAnova` | One-way ANOVA (native implementation, no Report parsing) | .tableId, .dataColumn$, .factorColumn$, .tukey | public |
| `@emlTwoWayAnova` | Two-way factorial ANOVA via Praat Report | .tableId, .dataCol$, .factor1$, .factor2$ | public |
| `@emlEpsilonSquared` | Epsilon-squared effect size for Kruskal-Wallis | .h, .n | public |
| `@emlKruskalWallis` | Kruskal-Wallis H test (nonparametric k-group comparison) | .tableId, .dataCol$, .factorCol$ | public |
| `@emlDunnTest` | Dunn's test with Holm adjustment after Kruskal-Wallis | .tableId, .dataCol$, .factorCol$, .method$ | public |
| `@eml_getGroupData` | Extract group data by index from emlTableFromGroups (internal) | .groupIdx | internal |
| `@emlPairwiseT` | All pairwise t-tests with p-value adjustment | .tableId, .dataCol$, .factorCol$, .method$, .type$ | public |
| `@emlPairwiseWilcoxon` | All pairwise Wilcoxon tests with p-value adjustment | .tableId, .dataCol$, .factorCol$, .method$ | public |
| `@emlScheffe` | Scheffe post-hoc test after ANOVA | .tableId, .dataCol$, .factorCol$ | public |

## Graphs: Core
**File:** `graphs/eml-graph-procedures.praat` (v3.18) — 45 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlInitDrawingDefaults` | Initialize panel origin globals and drawing defaults | — | public |
| `@emlResetDrawnExtent` | Reset drawn extent tracker to zero | — | public |
| `@emlExpandDrawnExtent` | Expand drawn extent bounding box (single SOT for extent tracking) | .left, .right, .top, .bottom | public |
| `@emlSetPanelOrigin` | Set panel origin for multi-panel figures | .x, .y | public |
| `@emlSetPanelViewport` | Select outer viewport from theme-computed bounds | — | public |
| `@emlSetAdaptiveTheme` | Set font sizes, margins, and spacing from viewport dimensions | .vpWidth, .vpHeight | public |
| `@emlSetColorPalette` | Populate Okabe-Ito or B/W color arrays for up to 10 groups | .mode$ | public |
| `@emlOptimizePaletteContrast` | Reorder palette entries for maximum perceptual contrast | .nGroups | public |
| `@emlComputeAxisRange` | Compute nice axis min/max with buffer from data range | .dataMin, .dataMax, .roundTo, .isPercentage | public |
| `@emlComputeNiceStep` | Round tick interval to a human-friendly value (1, 2, 5 multiples) | .range, .targetTicks | public |
| `@emlDrawGridlines` | Draw both horizontal and vertical gridlines | .xMin, .xMax, .yMin, .yMax, .targetTicksX, .targetTicksY, .useMinor | public |
| `@emlDrawHorizontalGridlines` | Draw horizontal gridlines at tick positions | .xMin, .xMax, .yMin, .yMax, .targetTicksY, .useMinor | public |
| `@emlDrawVerticalGridlines` | Draw vertical gridlines at tick positions | .xMin, .xMax, .yMin, .yMax, .targetTicksX, .useMinor | public |
| `@emlDrawInnerBoxIf` | Draw inner box if config flag is set | — | public |
| `@emlExpandAxisControls` | Parse per-axis tick/value/label visibility flags | — | public |
| `@emlDrawAlignedMarksLeft` | Draw left axis ticks and labels with font-size-aware alignment | .yMin, .yMax, .targetTicks, .useMinor | public |
| `@emlDrawAlignedMarksRight` | Draw right axis ticks and labels (dual-axis panels) | .yMin, .yMax, .targetTicks, .useMinor | public |
| `@emlDrawAlignedMarksBottom` | Draw bottom axis ticks and labels | .xMin, .xMax, .targetTicks, .useMinor | public |
| `@emlDrawTitle` | Draw title and optional subtitle with content-driven marginTop | .title$, .vpWidth, .vpHeight, .xMin, .xMax, .yMin, .yMax | public |
| `@emlDrawAxes` | Full axis frame: title, labels, ticks, box, gridlines | .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpWidth, .vpHeight | public |
| `@emlDrawAxesSelective` | Axis frame with per-side tick/value/label control | .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpWidth, .vpHeight, .showXLabel, .showYLabel, .showXTicks, .showYTicks | public |
| `@emlCapitalizeLabel` | Capitalize first character of a label string | .raw$ | public |
| `@emlPaintSmoothBand` | Draw a filled smooth band (e.g., CI ribbon) via scanline | .fillColor$, .subsamples | public |
| `@emlDrawViolin` | Draw one violin shape from KDE data | .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width | public |
| `@emlDrawBox` | Draw one box plot element (box, whiskers, median line) | .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width | public |
| `@emlSanitizeLabel` | Escape Praat special characters (%, #, ^, _) in display text | .raw$ | public |
| `@emlDrawJitteredPoints` | Draw data points with horizontal jitter at categorical positions | .xCenter, .lineColor$, .markerSize, .jitterWidth | public |
| `@emlAssertFullViewport` | Select full outer viewport from drawn extent globals | — | public |
| `@emlCheckChannels` | Check Sound channel count; present dialog if stereo (wraps @emlHandleStereo) | .soundId | public |
| `@emlHandleStereo` | Single-file stereo handler with beginPause dialog for channel choice | .soundId, .fileName$ | public |
| `@emlApplyChannelChoice` | Batch-mode stereo handler — applies pre-selected channel handling without dialog | .soundId, .channelHandling | public |
| `@emlCheckPlausibility` | Warn if acoustic measure falls outside expected range | .value, .lowerBound, .upperBound, .measureName$, .unit$ | public |
| `@emlDrawLegend` | Draw legend box with colored swatches and labels | .xMin, .xMax, .yMin, .yMax, .position$, .fontSize | public |
| `@emlCheckNumericColumn` | Validate Table column contains numeric data by sampling | .tableId, .colName$ | public |
| `@emlInitAlphaSprites` | Locate sprites/ directory; set .available and .dir$ | — | public |
| `@emlSetAlphaDotGeometry` | Compute aspect-corrected stamp dimensions for alpha dots | .axisXMin, .axisXMax, .axisYMin, .axisYMax, .innerLeft, .innerRight, .innerTop, .innerBottom, .dotHalf | public |
| `@emlDrawAlphaDot` | Stamp alpha-composited PNG dot or fall back to Paint circle | .x, .y, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$ | public |
| `@emlDrawAlphaRect` | Stamp alpha-composited PNG rectangle (bar fills) | .x1, .x2, .y1, .y2, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$ | public |
| `@emlLightenColor` | Blend an RGB color toward white by a given fraction | .rgb$, .amount | public |
| `@emlFitCategoricalLabels` | Binary search for font size that fits all category labels | .nLabels, .xMin, .xMax | public |
| `@emlExtractUniqueValues` | Extract unique group labels from Table column (sorted) | .tableId, .colName$ | public |
| `@emlMeasureCategoricalLabels` | Measure label widths for categorical axis layout | .tableId, .colName$, .vpW, .vpH | public |
| `@emlMeasureGraphLayout` | Compute viewport, margins, and label placement for a graph | .vpW, .vpH, .title$, .xLabel$, .yLabel$ | public |
| `@emlDrawCategoricalXAxis` | Draw category labels on x-axis (truncated if needed) | .nLabels, .xMin, .xMax, .yMin, .yMax, .xLabel$ | public |
| `@emlMeasureBarData` | Extract means, errors, and ranges for bar chart groups | .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$ | public |

## Graphs: Draw
**File:** `graphs/eml-draw-procedures.praat` (v1.12) — 14 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlDrawF0Contour` | Draw F0 pitch contour from Pitch object | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawWaveform` | Draw Sound waveform | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawSpectrum` | Draw Spectrum (frequency domain) | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawLTAS` | Draw Long-Term Average Spectrum (multi-method support) | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawTimeSeries` | Draw time series line plot from Table columns | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawTimeSeriesCI` | Draw time series with confidence interval band | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawSpaghettiPlot` | Draw individual subject lines overlaid (spaghetti plot) | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawBarChart` | Draw grouped bar chart with error bars | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawViolinPlot` | Draw violin plot with embedded box plot and data points | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawScatterPlot` | Draw scatter plot with optional regression line | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawBoxPlot` | Draw box-and-whisker plot | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawHistogram` | Draw frequency histogram with optional faceting | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawGroupedViolin` | Draw side-by-side violin plots for grouped data | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |
| `@emlDrawGroupedBoxPlot` | Draw side-by-side box plots for grouped data | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .nGroups | public |

## Graphs: Annotation & Shared Reporters
**File:** `graphs/eml-annotation-procedures.praat` (v3.8) — 23 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlClearAnnotations` | Reset all annotation arrays to empty | — | public |
| `@emlFormatStars` | Convert p-value to significance stars (*, **, ***, ns) | .p | public |
| `@emlFormatAnnotLabel` | Format annotation label (p-value, stars, or both) | .p, .d, .style$, .showEffect, .effectLabel$ | public |
| `@emlStackBrackets` | Compute non-overlapping vertical positions for brackets | — | public |
| `@emlDrawBracket` | Draw one comparison bracket between two groups | .xI, .xJ, .yBase, .tierHeight, .tier, .label$, .fontSize, .lineColor$ | public |
| `@emlDrawAnnotation` | Draw one text annotation at specified position | .x, .y, .anchor$, .label$, .fontSize, .hasBg, .xRange, .yRange | public |
| `@emlDrawAnnotations` | Draw all queued annotations | .xMin, .xMax, .yDataMax, .yRange, .bracketColor$, .fontSize | public |
| `@emlDrawRegressionLine` | Draw regression line with equation and R-squared | .xMin, .xMax, .slope, .intercept, .yAxisMin, .yAxisMax, .lineColor$ | public |
| `@emlPlaceElements` | Position corner elements (stat box, legend) without collision | .qTL, .qTR, .qBL, .qBR, .xMid, .nElements | public |
| `@emlComputeAnnotationHeadroom` | Calculate extra top margin needed for brackets | .yDataRange, .fontSize | public |
| `@emlOppositeCorner` | Return the diagonally opposite corner position | .corner$ | public |
| `@emlDrawAnnotationBlock` | Draw multi-line stats text block in a corner | .corner$, .xMin, .xMax, .yMin, .yMax, .fontSize | public |
| `@emlMeasureMatrixLayout` | Compute cell dimensions for comparison matrix panel | .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize | public |
| `@emlDrawMatrixPanel` | Draw split-triangle comparison matrix (p-values + effect sizes) | .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize, .colorMode$ | public |
| `@emlBridgeGroupComparison` | Run stats and populate annotations for group comparisons | .tableId, .dataCol$, .factorCol$, .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode | public |
| `@emlBridgeCorrelation` | Run correlation and populate annotations for scatter plots | .tableId, .colX$, .colY$, .alpha, .style$, .corrType$ | public |
| `@emlReportBridgeStats` | Thin dispatcher — routes to shared reporters by test type | .tableId, .dataCol$, .groupCol$ | public |
| `@emlReportTwoGroupComparison` | Shared reporter for 2-group tests (Info window + CSV) | .tableName$, .dataCol$, .groupCol$, .group1$, .group2$, .n1, .mean1, .sd1, .median1, .n2, .mean2, .sd2, .median2, .testType$ | public |
| `@emlReportAnovaComparison` | Shared reporter for ANOVA with optional Tukey HSD (Info + CSV) | .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doTukey | public |
| `@emlReportKWComparison` | Shared reporter for Kruskal-Wallis with optional Dunn's (Info + CSV) | .tableName$, .dataCol$, .groupCol$, .nGroups, .doDunn | public |
| `@emlReportPairedComparison` | Shared reporter for paired t-test / Wilcoxon SR (Info + CSV) | .tableName$, .col1$, .col2$, .n, .mean1, .sd1, .median1, .mean2, .sd2, .median2, .testType$ | public |
| `@emlReportCorrelationAnalysis` | Shared reporter for Pearson / Spearman correlation (Info + CSV) | .tableName$, .colX$, .colY$, .n, .testType$ | public |
| `@emlReportTwoWayAnova` | Shared reporter for two-way ANOVA (Info + CSV) | .tableName$, .dataCol$, .factor1$, .factor2$ | public |

## Scripts: Graphs Main
**File:** `scripts/eml-graphs.praat` (v2.44) — 7 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlGenerateUniquePath` | Generate non-colliding output filename with ascending integer | .path$ | public |
| `@emlPickFromMultiple` | Let user pick one object when multiple are selected | .type$ | public |
| `@emlCleanConvertedTable` | Clean auto-converted Table (from TableOfReal/Matrix) | .tableId | public |
| `@emlLoadConfig` | Load saved graph settings from preferences file | — | public |
| `@emlSaveConfig` | Save current graph settings to preferences file | — | public |
| `@emlDetectContext` | Detect selected object type and configure graph options | — | public |
| `@emlBuildFilteredMenu` | Build graph type menu filtered by selected object type | — | public |

## Scripts: Wizard
**File:** `scripts/eml-wizard.praat` (v1.4) — 15 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@wizardNormDiag` | Run normality diagnostics (skewness, kurtosis) for wizard | .data#, .label$ | public |
| `@wizardRunIndepT` | Execute independent t-test from wizard selections | .g1#, .g2#, .label1$, .label2$ | public |
| `@wizardRunMWU` | Execute Mann-Whitney U test from wizard selections | .g1#, .g2#, .label1$, .label2$ | public |
| `@wizardRunPairedT` | Execute paired t-test from wizard selections | .v1#, .v2#, .col1$, .col2$ | public |
| `@wizardRunWilcoxonSR` | Execute Wilcoxon signed-rank test from wizard selections | .v1#, .v2#, .col1$, .col2$ | public |
| `@wizardRunAnova` | Execute one-way ANOVA from wizard selections | .tableId, .dataCol$, .groupCol$ | public |
| `@wizardRunKW` | Execute Kruskal-Wallis test from wizard selections | .tableId, .dataCol$, .groupCol$ | public |
| `@wizardRunTwoWay` | Execute two-way ANOVA from wizard selections | .tableId, .dataCol$, .factor1$, .factor2$ | public |
| `@wizardRunPearson` | Execute Pearson correlation from wizard selections | .x#, .y#, .col1$, .col2$ | public |
| `@wizardRunSpearman` | Execute Spearman correlation from wizard selections | .x#, .y#, .col1$, .col2$ | public |
| `@wizardRunDescribe` | Execute descriptive stats from wizard selections | .data#, .col$ | public |
| `@wizardRunDescribeByGroup` | Execute grouped descriptive stats from wizard selections | .tableId, .dataCol$, .groupCol$ | public |
| `@wizardReportPairwise` | Report pairwise post-hoc results from wizard | .nGroups, .method$ | public |
| `@wizardCreateExample` | Create example Table for wizard demo | .hint$ | public |
| `@wizardStub` | Placeholder for unimplemented wizard branches | .analysis$, .batch$ | public |

## Scripts: Batch Processing
**File:** `scripts/eml-batch-process.praat` (v1.1) — 3 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlBuildDateStamp` | Generate YYYY-MM-DD date string from Praat date info | — | public |
| `@emlInitSentinel` | Create stop-sentinel file for graceful batch interrupt | .sentinelPath$ | public |
| `@emlCheckStopSentinel` | Check if user requested batch stop via sentinel file | .sentinelPath$ | public |

## Vibrato
**File:** `vibrato/eml-vibrato-procedures.praat` (v2.0) — 16 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlVibratoScanTextGrid` | Find labeled intervals in TextGrid for vibrato analysis | .textGridId, .tierNum | public |
| `@emlVibratoSelectIntervals` | Let user select which intervals to analyze | — | public |
| `@emlVibratoAxisRange` | Compute axis ranges for vibrato scatter/summary plots | .min, .max, .median, .nDivisions | public |
| `@emlVibratoAutoFilename` | Generate output filename from source Sound name | .baseName$, .suffix$, .extension$ | public |
| `@emlVibratoPitchSetup` | Create and configure Pitch object for vibrato detection | .soundId, .lowPitch, .highPitch, .interpolate | public |
| `@emlVibratoDetectCycles` | Detect vibrato cycles via peak/valley detection in PitchTier | .pitchSmoothId, .ppAudioId, .intensityId | public |
| `@emlVibratoInsertHalfCycles` | Insert half-cycle boundaries into TextGrid | .tableId | public |
| `@emlVibratoSmooth` | Apply smoothing to PitchTier for cycle detection | .tableId, .avgCycles, .lowRate, .highRate | public |
| `@emlVibratoFilter` | Filter vibrato cycles by rate and extent thresholds | .tableId, .lowRate, .highRate | public |
| `@emlVibratoJitter` | Compute cycle-to-cycle jitter for vibrato regularity | .tableId, .lowRate, .highRate | public |
| `@emlVibratoSummary` | Compute summary statistics for detected vibrato | .includeId, .smoothIncludeId | public |
| `@emlVibratoDrawDualScatter` | Draw rate vs. extent scatter plot | .includeId, .excludeId | public |
| `@emlVibratoDrawCoV` | Draw coefficient of variation bar chart | .tableId, .startTime, .endTime | public |
| `@emlVibratoDrawPitchIntensity` | Draw pitch + intensity contour overlay | .pitchSmoothId, .intensityId | public |
| `@emlVibratoDrawSummaryTable` | Draw formatted summary statistics table in figure | .vpLeft, .vpRight, .vpTop, .vpBottom | public |
| `@emlVibratoDrawFigure` | Draw complete multi-panel vibrato analysis figure | .smoothedTableId, .includeId, .excludeId | public |

## Demo Window
**File:** `tutorial/eml-demo-procedures.praat` (v1.2) — 31 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlResetSans` | Reset Demo window to Helvetica, ambient size, 0-100 axes | — | public |
| `@emlClearPage` | Clear Demo window with background color | — | public |
| `@emlAccentLine` | Draw decorative accent line at position | .x, .y | public |
| `@emlGuideTick` | Draw development guide tick mark (only if showGrid = 1) | .y | public |
| `@emlDrawGuides` | Draw full development grid overlay (only if showGrid = 1) | — | public |
| `@emlWrapText` | Word-wrap text within a rectangular region in Demo window | .x1, .x2, .yTop, .yBottom, .align$, .font$, .text$ | public |
| `@emlDrawNav` | Draw navigation bar (arrows, page counter, progress bar) | .pageNum, .totalPages, .showBack | public |
| `@emlDrawImage` | Draw image placeholder rectangle with centered label | .x1, .x2, .y1, .y2, .label$ | public |
| `@emlPlaceHero` | Place hero-sized text (36pt); returns .nextY | .y, .text$ | public |
| `@emlPlaceTitle` | Place title-sized text (28pt); returns .nextY | .y, .text$ | public |
| `@emlPlaceHeading` | Place heading-sized text (20pt) at left margin; returns .nextY | .y, .text$ | public |
| `@emlPlaceHeadingAt` | Place heading-sized text at specified x; returns .nextY | .y, .x, .text$ | public |
| `@emlPlaceSubhead` | Place subhead-sized text (17pt); returns .nextY | .y, .text$ | public |
| `@emlPlacePartLabel` | Place part label (caption size, light color); returns .nextY | .y, .text$ | public |
| `@emlPlaceModuleNum` | Place large embossed module number at right margin | .y, .text$ | public |
| `@emlPlaceAccent` | Place decorative accent line with typographic clearance | .y, .x, .ownerSize | public |
| `@emlPlaceTextAccent` | Place text with accent decoration at specified size | .y, .x, .size, .text$ | public |
| `@emlPlaceBody` | Place wrapped body text (serif); returns .nextY | .y, .x1, .x2, .color$, .text$ | public |
| `@emlPlaceBodyLine` | Place single line of body text; returns .nextY | .y, .text$ | public |
| `@emlPlaceCodeLine` | Place code-formatted text line (monospace); returns .nextY | .y, .x, .text$ | public |
| `@emlPlaceBullet` | Place bullet point with wrapped text; returns .nextY | .y, .x, .xEnd, .text$ | public |
| `@emlPlaceCaption` | Place caption text with alignment; returns .nextY | .y, .x, .halign$, .text$ | public |
| `@emlPlaceModuleListItem` | Place numbered module list entry; returns .nextY | .y, .num$, .name$ | public |
| `@emlPlaceOption` | Place lettered option (A, B, C) for interactive pages | .y, .letter$, .label$ | public |
| `@emlPlaceTreeBranch` | Place tree branch node with bullet; returns .nextY | .y, .x, .text$ | public |
| `@emlPlaceTreeSub` | Place tree sub-branch node; returns .nextY | .y, .x, .text$ | public |
| `@emlPlaceTreeLeaf` | Place tree leaf node (accent color); returns .nextY | .y, .x, .text$ | public |
| `@emlDemoDrawDot` | Draw colored data point at demo coordinates | .x, .y, .groupIndex, .radius | public |
| `@emlDemoDrawLine` | Draw colored line with specified width in demo coordinates | .x1, .y1, .x2, .y2, .color$, .width | public |
| `@emlDemoDrawHRule` | Draw horizontal rule (mean line, median line, etc.) | .y, .x1, .x2, .color$, .width | public |
| `@emlDemoShowFigure` | Display pre-rendered PNG in Demo window region with fallback | .left, .right, .bottom, .top, .path$ | public |

## Dev: Test Harness
**File:** `dev/tests/eml-test-helpers.praat` (v1.0) — 9 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlTestInit` | Initialize test runner (clear Info window, reset counters) | — | public |
| `@emlTestSection` | Print section header in test output | .title$ | public |
| `@emlTestAssertTrue` | Assert boolean condition | .name$, .condition | public |
| `@emlTestAssertEqualNum` | Assert numeric equality within tolerance | .name$, .expected, .actual, .tolerance | public |
| `@emlTestAssertEqualStr` | Assert string equality | .name$, .expected$, .actual$ | public |
| `@emlTestAssertUndefined` | Assert value is undefined | .name$, .value | public |
| `@emlTestAssertContains` | Assert string contains substring | .name$, .haystack$, .needle$ | public |
| `@emlTestAssertVectorsEqual` | Assert vector equality within tolerance | .name$, .v1#, .v2#, .tolerance | public |
| `@emlTestSummary` | Print pass/fail summary and exit with status | — | public |

---
**Total: 255 procedures** (250 public, 5 internal) across 14 files
