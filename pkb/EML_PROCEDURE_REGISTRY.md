# EML Praat Tools — Procedure Registry

Generated: 8 April 2026 | **Updated 29 July 2026 (PraatGen v14.1.0) directly from plugin source** | Source: plugin_EML_Praat_Tools + vibrato/tutorial/egg libraries

# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab

> **Path convention.** Every `**File:**` entry uses the *plugin tree* path
> (`stats/…`, `graphs/…`, `*.praat`). In Project Knowledge these ship
> **flattened**: `graphs/eml-graph-procedures.praat` is the file
> `eml-graph-procedures.txt` (drop the subdir, `.praat`→`.txt`). Retrieve an
> implementation with the linter's `--procedure` extract, never by reading
> the whole file or by a Project Knowledge search (`RULES_RETRIEVAL.md`, step 12).
> `include ../graphs/….praat` lines inside sources are plugin-tree references
> and are not expected to resolve in the flat PK layout.

> **Generated code must never `include` these files (hard).** The paths above
> describe a plugin tree that the end user is NOT assumed to have. When a
> generated script uses a library procedure, copy the procedure body into the
> delivered script (or into a sibling folder shipped with it) — never emit
> `include ../graphs/….praat`, `preferencesDirectory$`, or any absolute path.
> Copy transitively: a copied procedure's own `@eml…` calls come too. See
> `RULES_RETRIEVAL.md`, Retrieval Protocol step 12.

> **The `Parameters` column is inputs only — it does NOT list return
> variables.** A procedure that returns a value does so through a local
> `.something` / `.something$` in its own namespace, and that name is often NOT
> the input parameter name. `@emlGenerateUniquePath` is the trap: it takes
> `.path$` and returns `.result$`, so `emlGenerateUniquePath.path$` compiles,
> reads back the unchanged candidate path, and silently defeats the collision
> guard. **Read the `Outputs:` line in the procedure's own header comment, or
> the procedure body, before consuming a return value.** Never infer the return
> variable from this table or from a snippet elsewhere in the PKB — Retrieval Protocol step 11 (`RULES_RETRIEVAL.md`)
> applies: the source file governs.

> **Version discipline.** Each `**File:**` version below is the PLUGIN's version,
> copied verbatim into the PKB file header. PKB version == plugin version, always.
> A mismatch means the PKB has drifted and must be re-synced from source — that
> check is the whole point of carrying the number.

---

## Stats: Descriptive
**File:** `stats/eml-core-descriptive.praat` (v1.1) — 20 procedures (19 public, 1 internal)

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
| `@eml_swPoly` | Evaluate polynomial by Horner's method (internal helper for Shapiro-Wilk). | .c#, .x | internal |
| `@emlShapiroWilk` | - Second pair (n>=7): m[n-1]/ssumm2 + poly(c2, 1/sqrt(n)) | .data# | public |

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
**File:** `stats/eml-extract.praat` (v1.4) — 16 procedures (13 public, 3 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlExtractColumn` | Extract numeric column from Table as vector | .tableId, .columnName$ | public |
| `@emlExtractColumnAsStrings` | Extract string column from Table as string array | .tableId, .columnName$ | public |
| `@emlExtractGroupVectors` | Split column into two vectors by group labels | .tableId, .measureCol$, .groupCol$, .label1$, .label2$ | public |
| `@emlExtractPairedColumns` | Extract two paired numeric columns as vectors | .tableId, .col1$, .col2$ | public |
| `@emlExtractPitchValues` | Extract defined F0 frames from Pitch object as vector | .pitchId, .unit$ | public |
| `@emlExtractFormantValues` | Extract formant values from Formant object as vector | .formantId, .formantNumber, .unit$ | public |
| `@emlExtractIntensityFrames` | Extract all frames from Intensity object as vector | .intensityId | public |
| `@emlExtractHarmonicityFrames` | Extract defined frames from Harmonicity object as vector | .harmonicityId | public |
| `@emlValidateTable` | Check Table has required columns; exitScript if not | .tableId, .requiredColumns$ | public |
| `@emlValidateNumericColumn` | Check column contains numeric data | .tableId, .columnName$ | public |
| `@emlTableColumnNames` | List all column names in a Table | .tableId | public |
| `@emlCountGroups` | Count distinct group labels in a column | .tableId, .groupCol$ | public |
| `@eml_getGroupData` | Extract one group's data from Table by label (internal helper) | .tableId, .dataCol$, .groupCol$, .groupLabel$ | internal |
| `@eml_getGroupPairedData` | Extract two numeric columns for one group, keeping only rows where BOTH | .tableId, .colX$, .colY$, .groupCol$, .groupLabel$ | internal |
| `@eml_kwScan` | (internal helper) | .colName$, .kwList$ | internal |
| `@emlGuessColumnRoles` | string columns get baseline group score 5. | .tableId | public |

## Stats: Output
**File:** `stats/eml-output.praat` (v1.7) — 42 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlPadRight` | Pad string with trailing spaces to target length | .text$, .targetLength | public |
| `@emlUnderscoreToSpace` | Replace all underscores with spaces | .text$ | public |
| `@emlClearInfo` | Explicit Info window clear for dialog handlers | (none) | public |
| `@emlReportHeader` | Print report header with borders (clears Info window) | .title$ | public |
| `@emlReportFooter` | Print report footer with borders | (none) | public |
| `@emlReportSection` | Print section divider with title | .title$ | public |
| `@emlReportLine` | Print label + numeric value row | .label$, .value, .decimals | public |
| `@emlReportLineString` | Print label + string value row | .label$, .value$ | public |
| `@emlReportBlank` | Print blank line in report | (none) | public |
| `@emlFormatP` | Format p-value (< .001, = .023, etc.) | .pValue | public |
| `@emlFormatCI` | Format confidence interval as [lower, upper] | .lower, .upper, .level | public |
| `@emlFormatTestResult` | Format complete test result line (stat, df, p, effect) | .testName$, .statSymbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper | public |
| `@emlFormatEffectLabel` | Format effect size with interpretive label (small/medium/large) | .effectValue, .effectType$ | public |
| `@emlReportDescriptiveHeader` | Print column headers for descriptive stats table | (none) | public |
| `@emlReportDescriptiveRow` | Print one row of descriptive stats | .label$, .n, .mean, .sd, .median | public |
| `@emlReportAPA` | Format result in APA style (e.g., t(28) = 2.31, p = .028) | .testType$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper | public |
| `@emlReportToFile` | Write current Info window contents to a file | .filePath$, .content$ | public |
| `@emlSaveInfoToFile` | Save Info window to file with overwrite protection | .filePath$ | public |
| `@emlCSVInit` | Initialize CSV export accumulator arrays | (none) | public |
| `@emlCSVAddRow` | Add one row to CSV accumulator | .table$, .dataCol$, .groupCol$, .g1$, .g2$, .test$, .stat, .df, .p, .es, .esType$, .esLabel$, .n1, .n2, .mean1, .sd1, .median1, .mean2, .sd2, .median2 | public |
| `@emlExportStatsCSV` | Export accumulated CSV data to file | .filePath$ | public |
| `@emlWrapperCommonFields` | `stats/eml-output.praat` | comment: "--- Options ---" | public |
| `@emlHandleCommonFields` | Post-endPause handler for those shared fields (clears Info if toggled) | if clear_Info_window | public |
| `@emlWrapperInit` | WRAPPER INFRASTRUCTURE — shared init and post-analysis procedures | .minCols | public |
| `@emlWrapperExportCSV` | ──────────────────────────────────────────────────────────────────────────── | .tableName$ | public |
| `@emlWizardExplainP` | WIZARD EXPLANATION HELPERS | .p | public |
| `@emlWizardExplainEffectD` | Cohen's d magnitude label | .d | public |
| `@emlWizardExplainEffectG` | Hedges' g magnitude label | .g | public |
| `@emlWizardExplainEffectR` | Rank-biserial r magnitude label | .r | public |
| `@emlWizardExplainEffectEta2` | Eta-squared magnitude with % variance | .eta2 | public |
| `@emlWizardExplainCorrelation` | Correlation strength + direction label | .r | public |
| `@emlWizardExplainR2` | R-squared as % variance explained | .r2 | public |
| `@emlWizardExplainT` | t-statistic as signal-to-noise ratio | .t | public |
| `@emlWizardExplainF` | F-statistic as variance ratio | .f | public |
| `@emlWizardExplainDfBetween` | ANOVA between-groups df explanation | .df, .nGroups | public |
| `@emlWizardExplainDfWithin` | ANOVA within-groups df explanation | .df, .nTotal, .nGroups | public |
| `@emlWizardExplainDfTTest` | t-test df explanation (Welch vs standard) | .df, .method$ | public |
| `@emlWizardExplainDfPaired` | Paired t-test df explanation | .df, .nPairs | public |
| `@emlWizardExplainDfCorrelation` | Correlation df explanation | .df, .n | public |
| `@emlWizardExplainNormW` | Shapiro-Wilk W interpretation | .w | public |
| `@emlWizardExplainSkewness` | Skewness direction and magnitude label | .skew | public |
| `@emlWizardExplainKurtosis` | Kurtosis tail weight label | .kurt | public |

All `@emlWizardExplain*` helpers set `emlWizardExplain$`, consumed by the next `@emlReportLine` / `@emlReportLineString` call. They are no-ops when `emlWizardMode = 0` (callers gate on the flag). They live in `eml-output.praat`, a **core** file — they are not part of the excluded wizard script.

## Stats: Inferential
**File:** `stats/eml-inferential.praat` (v1.2) — 27 procedures (24 public, 3 internal)

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
| `@emlPairwiseT` | All pairwise t-tests with p-value adjustment | .tableId, .dataCol$, .factorCol$, .method$, .type$ | public |
| `@emlPairwiseWilcoxon` | All pairwise Wilcoxon tests with p-value adjustment | .tableId, .dataCol$, .factorCol$, .method$ | public |
| `@emlScheffe` | Scheffe post-hoc test after ANOVA | .tableId, .dataCol$, .factorCol$ | public |
| `@emlLinearRegression` | `stats/eml-inferential.praat` | .x#, .y# | public |
| `@emlTheilSen` | Theil-Sen robust median-based regression (Conover intercept, scipy-verified) | .x#, .y# | public |

## Stats: Analysis Dispatchers
**File:** `stats/eml-analysis.praat` (v1.1) — 21 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlRunTwoGroupAnalysis` | @emlReportPairwiseComparison — extracted from eml-pairwise.praat | .tableId, .dataCol$, .groupCol$, .testType$, .equalVar | public |
| `@emlRunAnovaAnalysis` | 2. ONE-WAY ANOVA | .tableId, .dataCol$, .groupCol$, .doTukey | public |
| `@emlRunKWAnalysis` | 3. KRUSKAL-WALLIS | .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$ | public |
| `@emlRunPairwiseAnalysis` | 4. PAIRWISE COMPARISONS | .tableId, .dataCol$, .groupCol$, .test$, .adjMethod$ | public |
| `@emlReportPairwiseComparison` | Extracted from inline code in eml-pairwise.praat. | .tableName$, .dataCol$, .groupCol$, .test$, .adjMethod$ | public |
| `@emlRunTwoWayAnalysis` | 5. TWO-WAY ANOVA | .tableId, .dataCol$, .factor1$, .factor2$ | public |
| `@emlRunPairedAnalysis` | 6. PAIRED COMPARISON | .tableId, .col1$, .col2$, .testType$ | public |
| `@emlRunCorrelationAnalysis` | 7. CORRELATION | .tableId, .colX$, .colY$, .testType$ | public |
| `@emlRunDescriptiveAnalysis` | 8. DESCRIPTIVE STATISTICS | .tableId, .dataCol$ | public |
| `@emlReportDescriptiveAnalysis` | Extracted from inline code in eml-describe-table.praat. | .tableName$, .dataCol$, .nValid, .nUndefined | public |
| `@emlRunRegressionAnalysis` | PHASE 4 STUBS | .tableId, .depCol$, .predCol$ | public |
| `@emlRunNormalityAnalysis` | Orchestrator: normality assessment (Shapiro-Wilk, skewness, kurtosis) with recommendation | .tableId, .dataCol$, .testType$ | public |
| `@emlRunReliabilityAnalysis` | Orchestrator: reliability analysis (internal consistency) | .tableId, .subjectCol$, .raterCols$, .measure$, .scale$ | public |
| `@emlExtractConditionMatrix` | Row-wise COMPLETE-CASE extraction of k condition columns into a matrix. | .tableId, .conditionCols$ | public |
| `@emlFriedmanTest` | Friedman rank test for k related samples (tie-corrected). | .data##, .n, .k | public |
| `@emlGGEpsilon` | Greenhouse-Geisser sphericity epsilon for RM-ANOVA. | .data##, .n, .k | public |
| `@emlRMAnovaTest` | one-way repeated-measures ANOVA with GG correction. | .data##, .n, .k | public |
| `@emlRunRepeatedMeasuresAnalysis` | parametric RM-ANOVA orchestrator. | .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$ | public |
| `@emlRunFriedmanAnalysis` | nonparametric repeated-measures orchestrator. | .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$ | public |
| `@emlRMPostHoc` | pairwise post-hoc for repeated-measures designs. | .data##, .n, .k, .testType$, .adjMethod$ | public |
| `@emlRunLMMAnalysis` | request, 95% Wald CIs. DRY: every path calls THIS, so a change here | .tableId, .formula$, .contrastCoding$, .useREML, .doR2, .doCI | public |

## Graphs: Core
**File:** `graphs/eml-graph-procedures.praat` (v3.21) — 45 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlSetPanelOrigin` | Set panel origin for multi-panel figures | .x, .y | public |
| `@emlResetDrawnExtent` | Reset drawn extent tracker to zero | (none) | public |
| `@emlExpandDrawnExtent` | Expand drawn extent bounding box (single SOT for extent tracking) | .left, .right, .top, .bottom | public |
| `@emlSetPanelViewport` | Select outer viewport from theme-computed bounds | Select outer viewport: emlSetAdaptiveTheme.outerLeft, | public |
| `@emlInitDrawingDefaults` | Initialize panel origin globals and drawing defaults | (none) | public |
| `@emlSetAdaptiveTheme` | Set font sizes, margins, and spacing from viewport dimensions | .vpWidth, .vpHeight | public |
| `@emlSetColorPalette` | Populate Okabe-Ito or B/W color arrays for up to 10 groups | .mode$ | public |
| `@emlOptimizePaletteContrast` | Reorder palette entries for maximum perceptual contrast | .nGroups | public |
| `@emlComputeAxisRange` | Compute nice axis min/max with buffer from data range | .dataMin, .dataMax, .roundTo, .isPercentage | public |
| `@emlComputeNiceStep` | Round tick interval to a human-friendly value (1, 2, 5 multiples) | .range, .targetTicks | public |
| `@emlDrawGridlines` | Draw both horizontal and vertical gridlines | .xMin, .xMax, .yMin, .yMax, .targetTicksX, .targetTicksY, .useMinor | public |
| `@emlDrawHorizontalGridlines` | Draw horizontal gridlines at tick positions | .xMin, .xMax, .yMin, .yMax, .targetTicksY, .useMinor | public |
| `@emlDrawVerticalGridlines` | Draw vertical gridlines at tick positions | .xMin, .xMax, .yMin, .yMax, .targetTicksX, .useMinor | public |
| `@emlDrawInnerBoxIf` | Draw inner box if config flag is set | Font size: emlSetAdaptiveTheme.bodySize | public |
| `@emlExpandAxisControls` | Parse per-axis tick/value/label visibility flags | (none) | public |
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
| `@emlAssertFullViewport` | Select full outer viewport from drawn extent globals | Select outer viewport: emlDrawnMinX, emlDrawnMaxX, | public |
| `@emlApplyChannelChoice` | Batch-mode stereo handler — applies pre-selected channel handling without dialog | .soundId, .channelHandling | public |
| `@emlHandleStereo` | Single-file stereo handler with beginPause dialog for channel choice | .soundId, .fileName$ | public |
| `@emlCheckChannels` | Check Sound channel count; present dialog if stereo (wraps @emlHandleStereo) | .soundId | public |
| `@emlCheckPlausibility` | Warn if acoustic measure falls outside expected range | .value, .lowerBound, .upperBound, .measureName$, .unit$ | public |
| `@emlDrawLegend` | Draw legend box with colored swatches and labels | .xMin, .xMax, .yMin, .yMax, .position$, .fontSize | public |
| `@emlCheckNumericColumn` | Validate Table column contains numeric data by sampling | .tableId, .colName$ | public |
| `@emlInitAlphaSprites` | Locate sprites/ directory; set .available and .dir$ | if variableExists ("emlAlphaSpritesInitialized") | public |
| `@emlSetAlphaDotGeometry` | Compute aspect-corrected stamp dimensions for alpha dots | .axisXMin, .axisXMax, .axisYMin, .axisYMax, .innerLeft, .innerRight, .innerTop, .innerBottom, .dotHalf | public |
| `@emlDrawAlphaDot` | Stamp alpha-composited PNG dot or fall back to Paint circle (mm) | .x, .y, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$ | public |
| `@emlDrawAlphaRect` | Stamp alpha-composited PNG rectangle (bar fills) | .x1, .x2, .y1, .y2, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$ | public |
| `@emlLightenColor` | Blend an RGB color toward white by a given fraction | .rgb$, .amount | public |
| `@emlFitCategoricalLabels` | Binary search for font size that fits all category labels | .nLabels, .xMin, .xMax | public |
| `@emlExtractUniqueValues` | Extract unique group labels from Table column (sorted) | .tableId, .colName$ | public |
| `@emlMeasureCategoricalLabels` | Measure label widths for categorical axis layout | .tableId, .colName$, .vpW, .vpH | public |
| `@emlMeasureGraphLayout` | Compute viewport, margins, and label placement for a graph | .vpW, .vpH, .title$, .xLabel$, .yLabel$ | public |
| `@emlDrawCategoricalXAxis` | Draw category labels on x-axis (truncated if needed) | .nLabels, .xMin, .xMax, .yMin, .yMax, .xLabel$ | public |
| `@emlMeasureBarData` | Extract means, errors, and ranges for bar chart groups | .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$ | public |

## Graphs: Draw
**File:** `graphs/eml-draw-procedures.praat` (v1.18) — 15 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlDrawF0Contour` | Draw F0 pitch contour from Pitch object | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .fMin, .fMax, .yUnit | public |
| `@emlDrawWaveform` | Draw Sound waveform | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .aMin, .aMax | public |
| `@emlDrawSpectrum` | Draw Spectrum (frequency domain) | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax | public |
| `@emlDrawLTAS` | Draw Long-Term Average Spectrum (multi-method support) | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax, .showCurve, .showBars, .showPoles, .showSpeckles | public |
| `@emlDrawTimeSeries` | Draw time series line plot from Table columns | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax | public |
| `@emlDrawTimeSeriesCI` | Draw time series with confidence interval band | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax | public |
| `@emlDrawSpaghettiPlot` | Draw individual subject lines overlaid (spaghetti plot) | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .condCol$, .valueCol$, .idCol$, .groupCol$, .showMean, .vMin, .vMax | public |
| `@emlDrawBarChart` | Draw grouped bar chart with error bars | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .errorMode, .errorCol$, .vMin, .vMax | public |
| `@emlDrawViolinPlot` | Draw violin plot with embedded box plot and data points | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax | public |
| `@emlDrawScatterPlot` | Draw scatter plot with optional regression line | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .colX$, .colY$, .groupCol$, .xMin, .xMax, .yMin, .yMax, .annotate | public |
| `@emlDrawBoxPlot` | Draw box-and-whisker plot | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax | public |
| `@emlDrawHistogram` | Draw frequency histogram with optional faceting | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .valueCol$, .groupCol$, .binCount, .displayMode, .vMin, .vMax, .freqMax | public |
| `@emlDrawGroupedViolin` | Draw side-by-side violin plots for grouped data | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax | public |
| `@emlDrawGroupedBoxPlot` | Draw side-by-side box plots for grouped data | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax | public |
| `@emlDrawLMMForest` | fixed-effect coefficient forest plot for a fitted LMM. | (none) | public |

## Graphs: Annotation & Shared Reporters
**File:** `graphs/eml-annotation-procedures.praat` (v3.17) — 25 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlClearAnnotations` | Reset all annotation arrays to empty | (none) | public |
| `@emlFormatStars` | Convert p-value to significance stars (*, **, ***, ns) | .p | public |
| `@emlFormatAnnotLabel` | Format annotation label (p-value, stars, or both) | .p, .d, .style$, .showEffect, .effectLabel$ | public |
| `@emlStackBrackets` | Compute non-overlapping vertical positions for brackets | (none) | public |
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
| `@emlReportKWComparison` | Shared reporter for Kruskal-Wallis with optional Dunn's (Info + CSV) | .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doDunn | public |
| `@emlReportCorrelationAnalysis` | Shared reporter for Pearson / Spearman correlation (Info + CSV) | .tableName$, .colX$, .colY$, .n, .testType$ | public |
| `@emlReportRegressionAnalysis` | `graphs/eml-annotation-procedures.praat` | .tableName$, .depCol$, .predCol$, | public |
| `@emlReportNormalityAnalysis` | Formatted Info window report for normality assessment (Shapiro-Wilk, skewness, kurtosis, recommendation) | .tableName$, .dataCol$, | public |
| `@emlReportPairedComparison` | Shared reporter for paired t-test / Wilcoxon SR (Info + CSV) | .tableName$, .col1$, .col2$, .n, | public |
| `@emlReportTwoWayAnova` | Shared reporter for two-way ANOVA (Info + CSV) | .tableName$, .dataCol$, .factor1$, .factor2$ | public |

## Scripts: Graphs Main
**File:** `scripts/eml-graphs.praat` (v3.0) — 0 procedures

## Scripts: Graphs Form & Workflow
**File:** `graphs/eml-graphs-form.praat` (v1.9) — 8 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlGenerateUniquePath` | Generate non-colliding output filename with ascending integer | .path$ | public |
| `@emlPickFromMultiple` | Let user pick one object when multiple are selected | .type$ | public |
| `@emlCleanConvertedTable` | Clean auto-converted Table (from TableOfReal/Matrix) | .tableId | public |
| `@emlLoadConfig` | Load saved graph settings from preferences file | (none) | public |
| `@emlSaveConfig` | Save current graph settings to preferences file | (none) | public |
| `@emlDetectContext` | Detect selected object type and configure graph options | (none) | public |
| `@emlBuildFilteredMenu` | Build graph type menu filtered by selected object type | (none) | public |
| `@emlGraphsWorkflow` | Unified graph creation workflow (standalone and stats-wrapper entry) | .objectId | public |

## Scripts: Batch Processing
**File:** `scripts/eml-batch-process.praat` (v1.1) — 3 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlBuildDateStamp` | Generate YYYY-MM-DD date string from Praat date info | (none) | public |
| `@emlCheckStopSentinel` | Check if user requested batch stop via sentinel file | .sentinelPath$ | public |
| `@emlInitSentinel` | Create stop-sentinel file for graceful batch interrupt | .sentinelPath$ | public |

## Vibrato
**File:** `vibrato/eml-vibrato-procedures.praat` (v2.0) — 16 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlVibratoScanTextGrid` | Find labeled intervals in TextGrid for vibrato analysis | .textGridId, .tierNum | public |
| `@emlVibratoSelectIntervals` | Let user select which intervals to analyze | (none) | public |
| `@emlVibratoAxisRange` | Compute axis ranges for vibrato scatter/summary plots | .min, .max, .median, .nDivisions, | public |
| `@emlVibratoAutoFilename` | Generate output filename from source Sound name | .baseName$, .suffix$, .extension$ | public |
| `@emlVibratoPitchSetup` | Create and configure Pitch object for vibrato detection | .soundId, .lowPitch, .highPitch, .interpolate | public |
| `@emlVibratoDetectCycles` | Detect vibrato cycles via peak/valley detection in PitchTier | .pitchSmoothId, .ppAudioId, .intensityId, | public |
| `@emlVibratoInsertHalfCycles` | Insert half-cycle boundaries into TextGrid | .tableId | public |
| `@emlVibratoSmooth` | Apply smoothing to PitchTier for cycle detection | .tableId, .avgCycles, .lowRate, .highRate | public |
| `@emlVibratoFilter` | Filter vibrato cycles by rate and extent thresholds | .tableId, .lowRate, .highRate, | public |
| `@emlVibratoJitter` | Compute cycle-to-cycle jitter for vibrato regularity | .tableId, .lowRate, .highRate, | public |
| `@emlVibratoSummary` | Compute summary statistics for detected vibrato | .includeId, .smoothIncludeId, | public |
| `@emlVibratoDrawDualScatter` | Procedure index (drawing): | .includeId, .excludeId, | public |
| `@emlVibratoDrawCoV` | Draws the Coefficient of Variation time-series panel. Two line series: | .tableId, .startTime, .endTime | public |
| `@emlVibratoDrawPitchIntensity` | Draws dual-axis pitch contour + intensity curve with cycle overlay markers. | .pitchSmoothId, .intensityId, | public |
| `@emlVibratoDrawSummaryTable` | Renders the averaged measures summary table in the Picture window. | .vpLeft, .vpRight, .vpTop, .vpBottom | public |
| `@emlVibratoDrawFigure` | Master procedure: draws the full 8-panel vibrato figure. | .smoothedTableId, .includeId, .excludeId, | public |

## EGG: Electroglottogram
**File:** `egg/eml-egg-procedures.praat` (v1.1) — 1 procedure

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlEggCycleGuard` | Segfault guard for To TextGrid (closed glottis) / To AmplitudeTier (levels); sets `.safe` (1 = analyzable) | .eggId, .floor, .ceiling | public |

## Dev: Test Harness
**File:** `dev/tests/eml-test-helpers.praat` (v1.0) — 9 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlTestInit` | Initialize test runner (clear Info window, reset counters) | (none) | public |
| `@emlTestSection` | Print section header in test output | .title$ | public |
| `@emlTestAssertTrue` | Assert boolean condition | .name$, .condition | public |
| `@emlTestAssertEqualNum` | Assert numeric equality within tolerance | .name$, .expected, .actual, .tolerance | public |
| `@emlTestAssertEqualStr` | Assert string equality | .name$, .expected$, .actual$ | public |
| `@emlTestAssertUndefined` | Assert value is undefined | .name$, .value | public |
| `@emlTestAssertVectorsEqual` | Assert vector equality within tolerance | .name$, .v1#, .v2#, .tolerance | public |
| `@emlTestAssertContains` | Assert string contains substring | .name$, .haystack$, .needle$ | public |
| `@emlTestSummary` | Print pass/fail summary and exit with status | (none) | public |

---
**Total: 263 procedures** (255 public, 8 internal) across 15 files.

**Withdrawn at 1.1:** `@emlEggSpectralThreshold`. Untested on real material — every figure behind it came from synthetic additive white Gaussian noise. Not distributed; do not reconstruct it. See `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` §4.

All entries above are backed by source shipped in the PKB. There is no
quarantine section any more: the six procedures previously listed as
"plugin-tree-only" (`emlLinearRegression`, `emlTheilSen`,
`emlReportRegressionAnalysis`, `emlReportNormalityAnalysis`,
`emlWrapperCommonFields`, `emlHandleCommonFields`) were never missing from the
plugin — the PKB was shipping truncated copies of the files that contain them.
The refresh restored all six.

**Removed at 14.1.0:** the Demo-window layout-helper library (`eml-demo-procedures`, 31 procedures). It was never the source of truth for driving the Demo window — `COMMANDS_DemoWindow.txt` and `BEST_PRACTICES_DEMO_WINDOW.md` are, and neither depends on it. It was a convenience wrapper around documented `demo` commands, dated April 2026, of uncertain current quality, and its source could not be reconciled. Write Demo layout from the documented commands instead.

**Deliberately NOT in the PKB:** `stats/eml-lmm.praat` (linear mixed models —
not ready for general use) and its private numerical dependencies
`stats/eml-linalg.praat` and `stats/eml-optimizer.praat` (Cholesky / BOBYQA,
called by nothing else). `@emlRunLMMAnalysis` in `eml-analysis.txt` therefore
has unresolvable calls and carries a hard do-not-route warning at its
definition. Also excluded: `scripts/eml-wizard.praat` (vestigial).
