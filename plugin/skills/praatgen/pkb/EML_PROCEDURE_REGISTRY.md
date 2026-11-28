# EML Stats & Graphs — Procedure Registry

Generated: 28 November 2026 | Source: plugin_EML_StatsGraphs (stats, graphs, scripts) + vibrato and egg libraries | Built by `tools/build_procedure_registry.py`

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
**File:** `stats/eml-core-descriptive.praat` (v1.2) — 23 procedures (20 public, 3 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_hasUndefined` | Internal helper: does a numeric vector contain any undefined element? | .v# | internal |
| `@emlMean` | Arithmetic mean of a numeric vector | .data# | public |
| `@emlMedian` | Median of a numeric vector | .data# | public |
| `@emlMode` | Mode (most frequent value) of a numeric vector | .data# | public |
| `@emlPercentile` | Compute the p-th percentile using linear interpolation (R type=7) | .data#, .p | public |
| `@emlQuartiles` | Quartiles and interquartile range | .data# | public |
| `@emlVariance` | Sample variance (n-1 denominator) | .data# | public |
| `@emlSD` | Sample standard deviation (n-1 denominator) | .data# | public |
| `@emlSEM` | Standard error of the mean | .data# | public |
| `@eml_pairwiseSum` | Sum a vector by folding it in half and adding the two halves, repeated until one value remains | .v# | internal |
| `@emlSkewness` | Sample skewness (Fisher's definition) | .data# | public |
| `@emlKurtosis` | Excess kurtosis (Fisher's definition, normal = 0) | .data# | public |
| `@emlGeometricMean` | Geometric mean of a numeric vector | .data# | public |
| `@emlHarmonicMean` | Harmonic mean of a numeric vector | .data# | public |
| `@emlTrimmedMean` | Trimmed mean: remove a proportion from each tail before averaging | .data#, .proportion | public |
| `@emlWinsorizedMean` | Winsorized mean: replace tail values instead of removing them | .data#, .proportion | public |
| `@emlMAD` | Median absolute deviation with consistency constant | .data# | public |
| `@emlRange` | Range statistics | .data# | public |
| `@emlCI` | Confidence interval for the mean (t-based) | .data#, .confidenceLevel | public |
| `@emlDescribe` | Comprehensive descriptive statistics summary | .data#, .trim, .confidenceLevel | public |
| `@eml_swPoly` | Evaluate polynomial by Horner's method (internal helper for Shapiro-Wilk) | .c#, .x | internal |
| `@emlShapiroWilk` | Shapiro-Wilk test for normality (Royston 1995, AS R94) | .data# | public |
| `@emlGaussianLogLik` | Gaussian/OLS log-likelihood, AIC and BIC for a least-squares fit — the closed-form numbers R reports for lm() and aov() via logLik()/AIC()/BIC() | .rss, .nobs, .k | public |

## Stats: Utilities
**File:** `stats/eml-core-utilities.praat` (v1.0) — 27 procedures (22 public, 5 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_sortPairsByValue` | INTERNAL HELPER: Shell Sort with Index Tracking Sorts values in ascending order while tracking original indices | .inputValues#, .inputIndices# | internal |
| `@emlRankVector` | Assigns statistical ranks to data values with average tie handling | .data# | public |
| `@emlCountIf` | Counts elements satisfying a comparison condition | .data#, .operator$, .value | public |
| `@emlSubset` | Extracts elements at specified indices | .data#, .indices# | public |
| `@emlUniqueValues` | Finds sorted unique values in a vector | .data# | public |
| `@emlFrequency` | Computes frequency distribution of values | .data# | public |
| `@emlCumulativeSum` | Computes running cumulative sum | .data# | public |
| `@emlDiff` | Computes first differences | .data# | public |
| `@emlLag` | Creates lagged version of data | .data#, .k | public |
| `@emlBinData` | Bins data into histogram | .data#, .nBins | public |
| `@emlZScore` | Standardizes values to z-scores | .data# | public |
| `@emlRemoveUndefined` | Removes undefined values from a vector | .data# | public |
| `@emlSortWithIndex` | Sorts values ascending while tracking original positions | .data# | public |
| `@emlConcatenateVectors` | Concatenates two vectors | .v1#, .v2# | public |
| `@emlRepeatVector` | Repeats a vector n times | .v#, .nReps | public |
| `@emlFileStamp` | A timestamp for a FILE NAME: YYYYMMDD_HHMMSS, local time | (none) | public |
| `@emlGenerateUniquePath` | Appends ascending integer to filename until path is available | .path$ | public |
| `@emlObjMark` | OBJECT-LIFETIME PRIMITIVES Praat gives object ids in strictly increasing order and never reuses them, so a watermark taken on entry cleanly separates objects ... | (none) | public |
| `@eml_reap` | Shared engine: remove every live object with id > .mark whose id is NOT in the space-separated keep-list, in ONE batched removeObject call | .mark, .keep$ | internal |
| `@eml_selStr` | ids of the current selection as a space-separated string. | (none) | internal |
| `@eml_vecStr` | vector of ids as a space-separated string. | .v# | internal |
| `@eml_reselect` | re-select a space-separated id list (restores a saved selection). | .ids$ | internal |
| `@emlScopeClose` | Close a scope keeping NOTHING: remove every object created after .mark. | .mark | public |
| `@emlScopeCloseKeepSel` | Close a scope keeping whatever is SELECTED (and restore that selection). | .mark | public |
| `@emlScopeCloseKeepVec` | Close a scope keeping the objects whose ids are in the vector .keep# (any count). | .mark, .keep# | public |
| `@emlKeepOnly` | Backstop GC: keep ONLY the space-separated ids in .keep$, remove all else. | .keep$ | public |
| `@emlCommaListToVector` | The one comma-string to string-vector bridge for every door that collects its list as free text instead of a native vector -- the repeated-measures and ... | .s$ | public |

## Stats: Extraction
**File:** `stats/eml-extract.praat` (v2.0) — 59 procedures (38 public, 21 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlExtractColumn` | Extract a numeric column from a Table into a vector | .tableId, .columnName$ | public |
| `@emlExtractColumnAsStrings` | Extract a string column from a Table | .tableId, .columnName$ | public |
| `@emlExtractGroupVectors` | Extract two vectors split by a grouping variable with exactly two levels | .tableId, .measureCol$, .groupCol$, .label1$, .label2$ | public |
| `@emlExtractPairedColumns` | Extract two columns for paired analysis, excluding rows where either is undefined | .tableId, .col1$, .col2$ | public |
| `@emlExtractPitchValues` | Extract all voiced F0 values from a Pitch object | .pitchId, .unit$ | public |
| `@emlExtractFormantValues` | Extract formant frequency values from a Formant object | .formantId, .formantNumber, .unit$ | public |
| `@emlExtractIntensityFrames` | Extract intensity values frame by frame | .intensityId | public |
| `@emlExtractHarmonicityFrames` | Extract HNR values (defined frames only) | .harmonicityId | public |
| `@emlValidateTable` | Validate Table has required columns (space-separated string) | .tableId, .requiredColumns$ | public |
| `@eml_normalizeLabel` | (internal helper) Canonical form of a group label for comparison purposes: leading and trailing spaces/tabs removed, then lower-cased | .raw$ | internal |
| `@eml_strictNumericColumn` | (internal helper) Decide whether "Get all numbers in column:" will return the cells' VALUES or Praat's alphabetical RANK substitution | .tableId, .columnName$ | internal |
| `@eml_classifyCell` | (internal helper) Decide what ONE cell actually is | .raw$ | internal |
| `@eml_openColumn` | @eml_strictOneCell (internal helper) Strictness verdict for a single literal, via the same sentinel probe @eml_strictNumericColumn uses on a whole column | .tableId, .columnName$ | internal |
| `@eml_readCell` | (internal helper) The single numeric read | .tableId, .row, .columnName$, .clean | internal |
| `@eml_strictOneCell` | (see source header) | .literal$ | internal |
| `@eml_auditNote` | (internal helper) Render the user-facing remedy sentences for one set of cell-classification tallies -- the same tallies @eml_classifyCell's kinds 1..5 ... | .nLocale, .firstLocaleRow, .firstLocaleValue$, .nCoerced, .firstCoercedRow, .firstCoercedValue$, .nLeadingDot, .firstLeadingDotRow, .firstLeadingDotValue$, .nUnreadable, .firstUnreadableRow, .firstUnreadableValue$, .nEmpty, .firstEmptyRow | internal |
| `@eml_level2Refusal` | (internal helper) THE refusal wording for a LEVEL 2 cell, ONE HOME so every door that refuses says it identically (9 Sep 2026, CORRECTION_LEVEL2_IS_A_REFUSAL) | .role$, .columnName$, .row, .value$ | internal |
| `@eml_emptyCellDisclosure` | (internal helper) THE empty-cell disclosure wording, ONE HOME so every door that drops rows or subjects for empty numeric cells says it identically | .unitMode, .columnName$, .subjectId$, .nRows, .rows#, .values$# | internal |
| `@eml_joinDisclosureClauses` | (internal helper) Joins @eml_emptyCellDisclosure clauses with "; ", skipping any "" clause -- so a caller can call this once per column (ROW mode, in ... | .acc$, .clause$ | internal |
| `@eml_appendWarning` | (internal helper) General-purpose warning/note accumulator: appends .part$ to .acc$ with a single space, skipping whichever side is empty | .acc$, .part$ | internal |
| `@emlAuditColumn` | Classify EVERY cell of a column and report the conditions separately, with the first offending row and its literal contents for each | .tableId, .columnName$ | public |
| `@emlValidateNumericColumn` | Validate column exists and contains numeric data | .tableId, .columnName$ | public |
| `@emlTableColumnNames` | Get all column names from a Table | .tableId | public |
| `@emlColumnIndex` | (see source header) | .name$ | public |
| `@emlKeepChoice` | (see source header) | .name$, .fallback | public |
| `@emlCountGroups` | Discover distinct groups in a column | .tableId, .groupCol$ | public |
| `@eml_groupSubset` | (internal helper) Extract the rows belonging to one group, matching the group label on its normalised form (see @eml_normalizeLabel) so that "Male", "male" and ... | .tableId, .groupCol$, .groupLabel$ | internal |
| `@eml_getGroupData` | Extract one group's numeric data from a Table | .tableId, .dataCol$, .groupCol$, .groupLabel$ | internal |
| `@eml_getGroupPairedData` | Extract two numeric columns for one group, keeping only rows where BOTH columns are defined (row-wise complete-case deletion within the group) | .tableId, .colX$, .colY$, .groupCol$, .groupLabel$ | internal |
| `@eml_twoWayCompleteCase` | THE listwise-exclusion pass for the two-way door (9 Sep 2026, RULING_MISSING_VALUE_TOKENS): a row with a missing cell -- empty, or a @eml_isMissingToken value ... | .tableId, .dataCol$, .factor1$, .factor2$ | internal |
| `@emlColumnRoleKeywordDefaults` | (internal helper, THE defaults procedure for @emlGuessColumnRoles' keyword lists) These keyword lists are not user-choosable settings and never travel as text ... | (none) | public |
| `@eml_kwScan` | (internal helper) Scan a keyword vector against a column name | .colName$, .kwList$# | internal |
| `@emlGuessColumnRoles` | Infers column roles from Table column names using weighted keyword matching and type detection | .tableId | public |
| `@emlCheckDataScheme` | Audit EVERY column of a Table and produce one consolidated, user-facing report of the things that will silently cost the user rows | .tableId | public |
| `@emlCheckSourceFile` | Scan a CSV file as TEXT, before or independently of reading it into a Table | .path$ | public |
| `@eml_isMissingToken` | (internal helper) THE missing-value token list, stated ONCE (9 Sep 2026, RULING_MISSING_VALUE_TOKENS): a non-empty cell whose text is on this list is missing, ... | .s$ | internal |
| `@emlRepairClassify` | Decide whether a single cell has an UNAMBIGUOUS intended value, and what it is | .raw$ | public |
| `@emlCommaColumnMode` | Decide, for a WHOLE column, what its commas mean | .tableId, .columnName$ | public |
| `@eml_cleanVerdict` | (internal helper) THE refuse-or-repair decision for one cell, settled by ruling on 8 Sep 2026 (RULING_DATA_CLEANING_TWO_ITEMS): LEVEL 1 (repair on the fly, ... | .raw$, .commaMode | internal |
| `@eml_repairNote` | (internal helper) Render the user-facing disclosure sentences for one set of LEVEL 1 repair tallies -- the mirror of @eml_auditNote, which renders the LEVEL 2 ... | .nDecimal, .firstDecimalRow, .firstDecimalRaw$, .firstDecimalValue, .nGrouped, .firstGroupedRow, .firstGroupedRaw$, .firstGroupedValue, .nDot, .firstDotRow, .firstDotRaw$, .firstDotValue | internal |
| `@emlRunCleanData` | THE data-cleaning door | .tableId, .mode$ | public |
| `@emlStripHeaderQuotes` | Remove surrounding double quotes from every column LABEL of a Table | .tableId | public |
| `@eml_fpMix` | (internal helper) Folds one string into a running triple of 31-bit state words | .h1, .h2, .h3, .s$ | internal |
| `@eml_fpCompose` | (internal helper) THE ONE PLACE A KEY IS BUILT. All three doors call this and differ only in how many scope items they pass, so the content fold is the same ... | .tableId, .nScope, .scope1$, .scope2$ | internal |
| `@emlDataFingerprint` | THE UNSCOPED DOOR. Hand it a Table; it returns a key describing the whole of that table and naming no analysis | .tableId | public |
| `@emlGroupFingerprint` | THE TWO-COLUMN DOOR, for a group comparison: one value column against one grouping column | .tableId, .dataCol$, .groupCol$ | public |
| `@emlAnalysisFingerprint` | THE LIST DOOR, for an analysis whose declaration is one string the caller wrote — three columns for a two-way design, a covariate beside a factor, a subject ... | .tableId, .columnList$ | public |
| `@emlFingerprintsAgree` | The one place two fingerprints are compared | .a$, .b$ | public |
| `@emlStoreKeyTake` | THE RUN'S READING STAMP: the section (a) data key and the group sort order in force, taken together, at the top of the pass that reads the data | .tableId, .dataCol$, .groupCol$ | public |
| `@emlPublishAbsentMatrix` | (see source header) | .k | public |
| `@emlPublishAnalysisResult` | THE WRITE SITE THE ONE PLACE ANY emlStore NAME IS ASSIGNED. Every publisher calls this and nothing else writes the store, so there is one thing to read and one ... | .producer$, .door$, .kind$, .error$, .key$, .keyError$, .tableId, .tableName$, .dataCol$, .groupCol$, .testType$, .correction$, .alpha, .sort$, .nGroups, .omnibusLabel$, .omnibusStat, .df1, .df2, .omnibusP, .effectLabel$, .effect, .n, .secondLabel$, .secondStat, .secondDf1, .secondP, .secondEffectLabel$, .secondEffect, .postHoc$, .hasMatrix, .statLabel$, .pairEffectLabel$, .pMatrix##, .diffMatrix##, .statMatrix##, .effectMatrix## | public |
| `@emlStoreIdentityAgrees` | THE IDENTITY COMPARISON (punch list item 1.4) | .dataCol$, .groupCol$, .testType$, .correction$, .alpha, .sort$ | public |
| `@emlReadLtasBins` | , .frequencies#, .levels# THE ONE PLACE AN LTAS IS READ BIN BY BIN. `Get number of bins` / `Get frequency from bin number` / `Get value in bin` is the same ... | .ltasId | public |
| `@emlBuildFrameTable` | , .nRows THE ONE TWO-COLUMN NUMERIC TABLE BUILDER @emlToTable'S FRAME-BASED ARMS SHARE. Ltas/Spectrum (frequency, level) and Pitch/Intensity/Harmonicity (time, ... | .col1#, .col2#, .label1$, .label2$ | public |
| `@emlToTable` | -> .tableId, .nRows, .nCols, .sourceType$, .ok, .error$, .warning$, .remedy$ THE OBJECT-TO-TABLE DOOR. One procedure that takes WHATEVER THE USER HAS SELECTED ... | .objectId, .columnNames$# | public |
| `@emlVectorsToTable` | -> .tableId, .nRows, .nCols, .lengths#, .ok, .error$, .warning$ THE ONE MECHANISM THAT SURVIVED PROBING. A user with data sitting in script-level Praat vectors ... | .names$#, .labels$# | public |
| `@emlReshapeSeriesLong` | -> .tableId, .nSeries, .nDataRows SEVERAL COLUMNS BECOME THE ONE SHAPE THE DRAWING LAYER TAKES, and the user is never asked about it | .objectId, .timeCol$, .cols$# | public |
| `@emlReshapeSeriesWide` | -> .tableId, .nSeries, .nDataRows, .nUnlisted THE MIRROR IMAGE OF @emlReshapeSeriesLong, AND IT IS HERE FOR THE SAME REASON: the user is never asked about it | .objectId, .timeCol$, .valueCol$, .nameCol$, .levels$# | public |
| `@emlCleanConvertedTable` | After converting TableOfReal or Matrix -> Table, fix "?" placeholders | .tableId | public |

## Stats: Output
**File:** `stats/eml-output.praat` (v2.4) — 89 procedures (71 public, 18 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlResetExplanations` | Put the explanation gate back to its default (emlShowExplanationsDefault) | (none) | public |
| `@emlEmitMode` | Switch the emit helper between its two modes | .print | public |
| `@emlEmit` | THE ONE DUAL-MODE EMIT HELPER. Every FACTUAL and DISCLOSURE line of the two store-wired doors' reports comes through here and nowhere else | .line$, .explain$ | public |
| `@emlExplainLine` | THE EXPLAIN HELPER, AND IT NEVER BUFFERS. Every whole line of explanation prose — the "Why:" headers in the three shared comparison reporters, ... | .text$, .wrap | public |
| `@emlPadRight` | UTILITY PROCEDURES | .text$, .targetLength | public |
| `@emlUnderscoreToSpace` | Convert all underscores to spaces | .text$ | public |
| `@emlClearInfo` | REPORT STRUCTURE PROCEDURES (write to Info window) | (none) | public |
| `@emlReportContext` | Declare provenance for the NEXT @emlReportHeader | .analysis$, .adjustment$ | public |
| `@emlReportHeader` | Print report header with double-line borders, timestamp, and — when the caller declared them via @emlReportContext — the originating analysis and the ... | .title$ | public |
| `@emlReportFooter` | Print the estimator conventions, then the closing double-line border | (none) | public |
| `@emlReportSection` | Print section divider with title | .title$ | public |
| `@eml_fixed` | PRAAT'S fixed$ IS NOT A FIXED-PRECISION FORMATTER, and every rounded number this plugin prints went through it | .value, .decimals | internal |
| `@eml_sig3` | THREE SIGNIFICANT FIGURES, IN SCIENTIFIC NOTATION, FOR A NUMBER THAT MAY BE 1e-300. This exists for exactly one caller -- @emlFormatP's .exact$ tail -- and ... | .value | internal |
| `@emlReportLine` | Print labeled numeric value with 2-space indent Label padded to 20 characters When emlShowExplanations = 1 and emlWizardExplain$ is set, appends a third ... | .label$, .value, .decimals | public |
| `@emlReportLineString` | Print labeled string value with 2-space indent Label padded to 20 characters | .label$, .value$ | public |
| `@emlReportGroupOrderLine` | one DISCLOSURE line on every grouped comparison report stating which group order is in force, so a reader knows the order was a choice and which choice it was | .groupList$ | public |
| `@emlGroupOrderName` | THE TWO WORDS FOR THE GROUP ORDER, AND THE ONLY PLACE THEY ARE WRITTEN | .alphabetical | public |
| `@emlReportBlank` | Print empty line | (none) | public |
| `@emlReportPWithExact` | Print one p-value row that is BOTH reportable and exact | .label$, .pValue | public |
| `@emlRenderResultSettings` | THE CANONICAL RENDERING OF THE SETTINGS AN ANALYSIS RAN UNDER | .kind$, .dataCol$, .groupCol$, .test$, .correction$, .alpha, .sort$ | public |
| `@emlSettingsChangeNote` | THE ONE LINE, IN THE CONTRACT'S FORM. docs/RULING_RESULT_STORE.md section (c), quoted: "One line, naming the change: 'Recomputed: adjustment method holm -> ... | .field$, .was$, .now$ | public |
| `@emlSettingsVocabulary` | COPY THE RENDERING'S VOCABULARY OUT BEFORE THE RENDERER RUNS AGAIN | (none) | public |
| `@emlFormatP` | Format p-value according to APA guidelines | .pValue | public |
| `@emlFormatCI` | Format confidence interval string | .lower, .upper, .level | public |
| `@emlCILevelLabel` | The confidence level a two-sided interval carries, as the percentage a label prints, derived from the tail probability the interval was built at | .alpha | public |
| `@emlFormatTestResult` | Format complete test result line | .testName$, .statSymbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper | public |
| `@emlFormatEffectLabel` | Return plain-language effect size interpretation | .effectValue, .effectType$ | public |
| `@emlReportDescriptiveHeader` | DESCRIPTIVE TABLE PROCEDURES | (none) | public |
| `@emlReportDescriptiveRow` | Print one data row for descriptive statistics table Same column widths as header, 2 decimal places for values | .label$, .n, .mean, .sd, .median | public |
| `@emlReportAPA` | APA FORMATTING | .testType$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper | public |
| `@emlAsciiFold` | (see source header) | .s$ | public |
| `@emlReportToFile` | Write content to file with overwrite protection | .filePath$, .content$ | public |
| `@emlSaveInfoToFile` | Save current Info window contents to file | .filePath$ | public |
| `@emlCSVInit` | (see source header) | (none) | public |
| `@emlCSVInitRows` | THE ROW HALF OF @emlCSVInit, AND NOTHING ELSE. Empties the collector and leaves emlResult_declared exactly as it was | (none) | public |
| `@emlCSVMark` | REMEMBER HOW MANY ROWS THERE WERE, AND GO BACK TO IT. For a caller that may run a reporting pass it then throws away | (none) | public |
| `@emlCSVRewind` | (see source header) | (none) | public |
| `@emlCSVTermType` | Set the kind of thing the following rows' `term` names | .kind$ | public |
| `@emlCSVSetTable` | Called once per analysis, before any @emlCSVAdd | .table$ | public |
| `@eml_csvQuote` | RFC 4180 quoting, so a column label containing a comma or a quote cannot silently split a row into two fields | .s$ | internal |
| `@emlCSVAdd` | One numeric result | .analysis$, .term$, .field$, .value | public |
| `@emlCSVAddStr` | One string-valued result (a method name, a direction, an effect label) | .analysis$, .term$, .field$, .value$ | public |
| `@eml_csvAppend` | (see source header) | .analysis$, .term$, .field$, .value$ | internal |
| `@emlCSVAddDescriptives` | The group-descriptives block every reporter wants, written as named fields so an absent one is absent rather than zero | .analysis$, .term$, .n, .mean, .sd, .median | public |
| `@emlExportStatsCSV` | Write accumulated CSV rows with overwrite protection | .filePath$ | public |
| `@emlHaveExportableResult` | is there anything for the export step to write? | (none) | public |
| `@emlExportResultFiles` | (see source header) | .folder$, .base$ | public |
| `@emlWrapperCommonFields` | (see source header) | (none) | public |
| `@emlHandleCommonFields` | Post-endPause handler for shared fields | (none) | public |
| `@eml_auditLabelColumn` | CLASSIFY THE LABEL COLUMN A COERCION MANUFACTURES. It does not assume the column holds anything, and it does not invent anything to put in it | .tableId, .columnName$ | internal |
| `@eml_defaultRowLabels` | ONE CONVENTION FOR THE MANUFACTURED ROW-LABEL COLUMN, AND THIS IS IT: r1..rn | .tableId, .columnName$ | internal |
| `@eml_nameUnlabelledColumns` | A MATRIX HAS NO COLUMN NAMES EITHER, and `To Table: "row"` writes the literal "?" as the header of every one of them | .tableId, .insertedCols | internal |
| `@eml_auditTorRowLabels` | @eml_auditTorColumnLabels: .torId     (private) THE SAME CLASSIFICATION AS @eml_auditLabelColumn / @eml_nameUnlabelledColumns, READ FROM THE SOURCE OBJECT ... | .torId | internal |
| `@eml_auditTorColumnLabels` | (see source header) | .torId | internal |
| `@eml_dropStaleConverted` | ONE SOURCE OBJECT, ONE CONVERTED TABLE, however many times a door is pressed | .name$ | internal |
| `@emlWrapperInit` | (see source header) | .minCols | public |
| `@eml_saveSafeBaseName` | THE PANEL OWNS THE NAMING CONTRACT, so it owns the characters too | .raw$ | internal |
| `@eml_saveFolderWritable` | CAN THIS FOLDER BE WRITTEN TO? Asked before the flush, not discovered during it | .folder$, .stamp$ | internal |
| `@eml_saveReceiptLines` | EVERY LINE THE "Saved" RECEIPT WILL DRAW, worked out before any of it is drawn | .fileList$, .note$ | internal |
| `@eml_saveFileLanded` | DID THE FILE ARRIVE? Asked of the disk, not of the command | .path$, .marker$ | internal |
| `@eml_saveAddFormat` | One format name added to a comma-separated list, once | .list$, .fmt$ | internal |
| `@eml_saveMergeFormats` | The union of two comma-separated format lists, in first-seen order | .list$, .more$ | internal |
| `@eml_saveFigureFormats` | (private) ONE FIGURE, WRITTEN IN EVERY FORMAT THAT WAS ASKED FOR, and each one checked onto the disk before it is claimed | .folder$, .name$, .dpi, .wantEPS, .wantPDF | internal |
| `@eml_saveFormatRedirectLines` | WHAT THE USER IS TOLD when a figure format they asked for did not arrive | .missing$, .landed$, .fileList$ | internal |
| `@emlSavePanel` | ONE SAVE, ONE FOLDER, ONE NAME. Everything an analysis produces — the figure, the numbers, the report — written in a single action under a shared stem, so a ... | .offerFigure, .stem$, .folder$ | public |
| `@emlWizardExplainP` | WIZARD EXPLANATION HELPERS Value-anchored interpretation generators for wizard mode third column | .p | public |
| `@emlWizardExplainEffectD` | Cohen's d interpretation | .d | public |
| `@emlWizardExplainEffectG` | Hedges' g interpretation (bias-corrected Cohen's d) | .g | public |
| `@emlWizardExplainEffectR` | Rank-biserial r or matched-pairs r interpretation | .r | public |
| `@emlWizardExplainEffectEta2` | THREE STATISTICS, THREE SENTENCES | .eta2 | public |
| `@emlWizardExplainEffectPartialEta2` | PARTIAL ETA-SQUARED, factorial: SS_effect / (SS_effect + SS_error) | .peta2 | public |
| `@emlWizardExplainEffectEpsilon2` | EPSILON-SQUARED, Kruskal-Wallis: H / (n - 1) | .eps2 | public |
| `@emlCohenMagnitudeEta2` | The 0.01 / 0.06 / 0.14 benchmarks, in one place, for the three procedures above | .value | public |
| `@emlWizardExplainCorrelation` | Pearson/Spearman correlation strength | .r | public |
| `@emlWizardExplainR2` | "ACCOUNTS FOR", NOT "EXPLAINS" | .r2 | public |
| `@emlWizardExplainT` | t IS A DISTANCE IN STANDARD ERRORS, and that is all it is: the observed difference divided by the standard error of that difference | .t | public |
| `@emlWizardExplainF` | F IS A RATIO OF MEAN SQUARES -- between-group over within-group -- and the second sentence gives the reader the one landmark that makes the first one legible | .f | public |
| `@emlWizardExplainDfBetween` | df (between) for ANOVA | .df, .nGroups | public |
| `@emlWizardExplainDfWithin` | df (within) for ANOVA | .df, .nTotal, .nGroups | public |
| `@emlWizardExplainDfTTest` | df for t-test | .df, .method$ | public |
| `@emlWizardExplainDfPaired` | df for paired t-test | .df, .nPairs | public |
| `@emlWizardExplainDfCorrelation` | df for correlation | .df, .n | public |
| `@emlWizardExplainNormW` | Shapiro-Wilk W interpretation | .w | public |
| `@emlWizardExplainSkewness` | (see source header) | .skew | public |
| `@emlWizardExplainKurtosis` | @emlKurtosis already returns EXCESS kurtosis (normal = 0, verified vs scipy bias=False) | .kurt | public |
| `@emlWrapText` | (see source header) | .s$, .width | public |
| `@emlReportNote` | (see source header) | .s$ | public |
| `@emlErrorDialog` | is prose on the public contract (§1b) -- one or more sentences, never a delimited list | .msg$, .remedy$, .mode$ | public |
| `@emlReportDescriptiveAnalysis` | Lives here, in the output module, and not in eml-analysis.praat, because scripts/eml-describe-table.praat calls it and includes only eml-lib-stats.praat, which ... | .tableName$, .dataCol$, .nValid, .nUndefined, .parseNote$, .alpha, .trim | public |

All `@emlWizardExplain*` helpers set `emlWizardExplain$`, consumed by the next `@emlReportLine` / `@emlReportLineString` call. They are no-ops when `emlWizardMode = 0` (callers gate on the flag). They live in `eml-output.praat`, a **core** file — they are not part of the excluded wizard script.

## Stats: Studentized Range
**File:** `stats/eml-studentized-range.praat` (v1.0) — 7 procedures (3 public, 4 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_srqRangeComplement` | P(range > w) for cc iid N(0,1) variates, computed directly from Hartley's range-probability integral -- NOT by R's own term1/term2 split | .w, .cc | internal |
| `@eml_srqWprobComplement` | P(max of rr iid ranges of cc N(0,1) variates > w), computed directly via 1 - g^rr = (1-g) * SUM_{i=0}^{rr-1} g^i -- the same complement-of-a-power identity ... | .w, .rr, .cc | internal |
| `@eml_srqOuterPanel16` | One 16-point Gauss-Legendre evaluation of the outer (chi-scale) integrand density(s) * P(max of nranges ranges of k > q*s), over s in [.sLo, .sHi]. Factored ... | .sLo, .sHi, .q, .k, .df, .nranges, .logConst | internal |
| `@eml_srqPanelOneGeometric` | .geoW0, .geoRatio, .geoMaxSegs Fixed (non-adaptive) geometric refinement of the FIRST outer panel, [0, .sHi], built on @eml_srqOuterPanel16. Sub-panel widths ... | .sHi, .q, .k, .df, .nranges, .logConst, .geoW0, .geoRatio, .geoMaxSegs | internal |
| `@emlSrqFwdCacheInit` | Session-level direct-mapped cache for @emlStudentizedRangeQ's forward probability, keyed on the exact (q, k, df, nranges) | (none) | public |
| `@emlStudentizedRangeQ` | (see source header) | .q, .k, .df, .nranges | public |
| `@emlInvStudentizedRangeQ` | Inverse of @emlStudentizedRangeQ: the q such that P(Q > q) = .p (upper tail), e.g. the Tukey HSD critical value at .p = alpha | .p, .k, .df, .nranges | public |

## Stats: Two-Way ANOVA Kernel
**File:** `stats/eml-anova-kernel.praat` (v1.0) — 12 procedures (5 public, 7 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlAnovaKernelTwoWay` | Two-way ANOVA computed directly from raw data in a Table | .tableId, .dataCol$, .factor1$, .factor2$, .ssTypeRequested | public |
| `@eml_ak2_gather` | Reads the whole table once to discover factor levels, then a second time to resolve each row to a (factor-1 index, factor-2 index, r*s cell index) and ... | .tableId, .dataCol$, .factor1$, .factor2$ | internal |
| `@eml_ak2_designSubset` | Builds a sum-coded (contr.sum) design matrix for one of the five nested models this file needs: intercept only; +A; +B; +A+B; the full (saturated) model | .n, .r, .s, .aIdx#, .bIdx#, .includeA, .includeB, .includeAB | internal |
| `@eml_ak2_ols` | Ordinary least squares via the normal equations, solved with `solve#` -- never an explicit inverse | .x##, .y# | internal |
| `@eml_ak2_buildContrast` | The (r-1) x r simple sum-to-zero contrast matrix for an r-level factor: contrast k has +1 at level k, -1 at the reference level r | .r | internal |
| `@eml_ak2_buildL` | Builds the Type III contrast matrix L for one effect, mapping the r*s cell means (row-major: cell (i,j) at column (i-1)*s + j) to the effect's contrast space: ... | .r, .s, .cA##, .cB##, .isA, .isB | internal |
| `@eml_ak2_typeIIIeffect` | The Wald quadratic form for one Type III effect, per the ruling: Lmu#   = L * mu#                          (mu# = the r*s cell means) LDL'## = L * diag(1/n_ij) ... | .l##, .cellMean#, .cellN# | internal |
| `@emlLeveneTest` | Standard Levene's test for homogeneity of variance, median-centred (Brown & Forsythe 1974's variant, and the default of R's car::leveneTest): for each group, ... | .n, .value#, .groupOf#, .k | public |
| `@emlAnovaKernelTwoWayEMM` | Estimated marginal means (EMMs) for both factors of a two-way design, computed directly from raw data -- no fitted model object, same style as ... | .tableId, .dataCol$, .factor1$, .factor2$, .alpha | public |
| `@eml_ak2_buildLSlice` | Builds the Wald contrast matrix L for ONE SIMPLE EFFECT -- factor 1 within one fixed level of factor 2, or factor 2 within one fixed level of factor 1 -- as ... | .r, .s, .cA##, .cB##, .isA, .isB, .fixedLevel | internal |
| `@emlAnovaKernelTwoWaySimpleEffects` | Simple effects: the effect of factor 1 at each level of factor 2, and the effect of factor 2 at each level of factor 1. This is what should be reported when ... | .tableId, .dataCol$, .factor1$, .factor2$ | public |
| `@emlAnovaKernelTwoWayPostHoc` | Post hoc pairwise comparisons on ONE factor's estimated marginal means (@emlAnovaKernelTwoWayEMM), with a selectable adjustment: Bonferroni, Holm, ... | .tableId, .dataCol$, .factor1$, .factor2$, .factorSelect, .adjMethod$, .alpha | public |

## Stats: Wilcoxon Intervals
**File:** `stats/eml-wilcoxon-interval.praat` (v1.0) — 4 procedures (1 public, 3 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_wciW2` | INTERNAL HELPER: @eml_wciW2  — R's two-sample W(d), ported Translated from wilcox.test.R's asymptotic two-sample block (see ORIGIN NOTICE above): | .v1#, .v2#, .d, .correct | internal |
| `@eml_wciWPaired` | INTERNAL HELPER: @eml_wciWPaired  — R's one-sample/paired W(d), ported Translated from wilcox.test.R's asymptotic one-sample block: | .x#, .d, .correct | internal |
| `@eml_wciZeroin` | INTERNAL HELPER: @eml_wciZeroin  — R's uniroot (R_zeroin2), ported once Brent's zeroin, translated from src/library/stats/src/zeroin.c's R_zeroin2 -- the ... | .form, .v1#, .v2#, .ax, .bx, .fa, .fb, .zq, .tol, .maxit | internal |
| `@emlWilcoxonIntervalApprox` | The Wilcoxon / Hodges-Lehmann confidence interval, APPROXIMATION BRANCH ONLY: R's continuity-corrected z inversion, ported, for both the two-sample ... | .v1#, .v2#, .paired, .level | public |

## Stats: Inferential
**File:** `stats/eml-inferential.praat` (v1.8) — 44 procedures (37 public, 7 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlTTest` | Independent-samples t-test (Welch default, Student optional) | .v1#, .v2#, .tails, .equalVariances | public |
| `@emlTTestPaired` | Paired-samples t-test | .v1#, .v2#, .tails | public |
| `@emlCohenD` | Cohen's d and Hedges' g for independent samples | .v1#, .v2# | public |
| `@emlTTestInterval` | Confidence interval for a t-test mean difference, at whatever degrees of freedom the CALLING VARIANT already computed | .meanDiff, .t, .df, .level | public |
| `@eml_pearsonCore` | (internal) Shared computation kernel for Pearson r and for Spearman rho (which is Pearson r on ranks) | .x#, .y#, .tails | internal |
| `@emlPearsonCorrelation` | (see source header) | .x#, .y#, .tails | public |
| `@emlPearsonFisherInterval` | Fisher r-to-z confidence interval for r z = atanh(r), se = 1/sqrt(n-3), interval = tanh(z +/- zCrit*se), zCrit from the normal quantile (the transform is ... | .r, .n, .alpha | public |
| `@emlSpearmanCorrelation` | Spearman rank-order correlation coefficient | .x#, .y#, .tails | public |
| `@eml_prho` | INTERNAL HELPER: @eml_prho — R's prho() (AS 89), ported A statement-for-statement port of R 4.3.3's C routine `prho`, src/library/stats/src/prho.c, itself AS ... | .n, .is, .lowerTail | internal |
| `@eml_spearmanExactEligible` | INTERNAL HELPER: @eml_spearmanExactEligible — the one copy of the cutoff R reaches the exact Spearman branch only when n <= 1290 ("n*(n^2-1) does not overflow" ... | .n | internal |
| `@eml_spearmanPspearman` | INTERNAL HELPER: @eml_spearmanPspearman — R's pspearman(), ported The closure cor.test.default (src/library/stats/R/cor.test.R, same R-4-3-3 tag as @eml_prho ... | .q, .n, .lowerTail | internal |
| `@emlSpearmanExactP` | The exact-method Spearman p, given the rho and n an existing @emlSpearmanCorrelation call already computed | .rho, .n, .tails | public |
| `@emlSpearmanCorrelationDispatch` | THE ONE COMPUTATION SITE for a Spearman p (Fable's 27 August work order, docs/WORK_ORDER_SPEARMAN_EXACT_2026-08-27.md, "One computation site") | .x#, .y#, .tails | public |
| `@eml_mannWhitneyExactP` | INTERNAL HELPER: Exact p-value for Mann-Whitney U via DP Computes the exact null distribution of U1 using dynamic programming | .u1, .n1, .n2 | internal |
| `@emlMannWhitneyU` | Mann-Whitney U test for two independent samples | .v1#, .v2#, .tails | public |
| `@emlHodgesLehmannTwoSample` | The Hodges-Lehmann shift estimate for two independent samples, and its confidence interval -- the location counterpart of the Mann-Whitney U test, the way a ... | .v1#, .v2#, .level | public |
| `@eml_wilcoxonExactP` | INTERNAL HELPER: Exact p-value for Wilcoxon Signed-Rank via Subset-Sum DP Computes the exact null distribution of T+ (sum of positive ranks) under the no-tie ... | .tPlus, .n | internal |
| `@emlCohenDz` | Cohen's d_z for a paired design: the standardised mean difference using the standard deviation OF THE DIFFERENCES, not of the raw scores | .v1#, .v2# | public |
| `@emlWilcoxonSignedRank` | Wilcoxon signed-rank test for paired samples | .v1#, .v2#, .tails | public |
| `@emlHodgesLehmannPaired` | The Hodges-Lehmann shift estimate for two PAIRED samples, and its confidence interval -- the location counterpart of the Wilcoxon signed-rank test, the way a ... | .v1#, .v2#, .level | public |
| `@emlRankBiserialR` | Rank-biserial correlation: effect size for Mann-Whitney U test | .v1#, .v2#, .tails | public |
| `@emlMatchedPairsR` | Matched-pairs rank-biserial correlation: effect size for the Wilcoxon signed-rank test | .v1#, .v2#, .tails | public |
| `@emlBonferroni` | Bonferroni correction for multiple comparisons | .pValues# | public |
| `@emlHolm` | Holm step-down correction for multiple comparisons (Holm 1979) | .pValues# | public |
| `@emlBenjaminiHochberg` | Benjamini-Hochberg step-up correction for multiple comparisons (1995) | .pValues# | public |
| `@emlTableFromGroups` | Convenience constructor: builds a Praat Table from pre-populated group data stored in indexed variables on this procedure's namespace | .nGroups, .dataColName$, .factorColName$ | public |
| `@eml_tukeyPairwiseFromGroups` | THE canonical Tukey HSD pairwise computation -- pooled MSE, pairwise SE, q, p, mean difference and Cohen's d for every pair -- taking group data that has ... | .nGroups, .allData#, .groupN#, .alpha | internal |
| `@emlOneWayAnova` | Performs one-way ANOVA on a Table with optional Tukey HSD post-hoc | .tableId, .dataColumn$, .factorColumn$, .tukey, .alpha | public |
| `@emlRequireColumnPresent` | THE ONE column-presence guard, and the sentence before @emlRequireNumeric- Column's | .tableId, .role$, .columnName$ | public |
| `@emlRequireNumericColumn` | THE ONE column-type guard | .tableId, .role$, .columnName$, .strict | public |
| `@emlTwoWayAnova` | Performs two-way ANOVA on a Table | .tableId, .dataCol$, .factor1$, .factor2$, .ssType | public |
| `@emlEpsilonSquared` | Epsilon-squared effect size for Kruskal-Wallis H test | .h, .n | public |
| `@emlKruskalWallis` | Kruskal-Wallis H test for k independent samples | .tableId, .dataCol$, .factorCol$ | public |
| `@emlDunnTest` | Dunn's post-hoc test for pairwise comparisons after Kruskal-Wallis | .tableId, .dataCol$, .factorCol$, .method$ | public |
| `@emlPairwiseT` | All-pairs independent t-tests with p-value adjustment and Cohen's d | .tableId, .dataCol$, .factorCol$, .method$, .type$ | public |
| `@emlPairwiseWilcoxon` | All-pairs Mann-Whitney U tests with p-value adjustment and rank-biserial r effect size | .tableId, .dataCol$, .factorCol$, .method$ | public |
| `@emlScheffe` | Scheffé post-hoc test for pairwise (and all-contrast) comparisons | .tableId, .dataCol$, .factorCol$ | public |
| `@emlScheffeInterval` | Simultaneous confidence interval for one Scheffe pairwise mean difference (item 5, 26 August 2026 interval work order, docs/WORK_ORDER_INTERVALS_2026-08-26.md) | .meanDiff, .se, .k, .dfWithin, .alpha | public |
| `@emlBrownForsythe` | Levene's test for homogeneity of variance with MEDIAN centring (Brown & Forsythe 1974), i.e. a one-way ANOVA on the absolute deviations from each group's own ... | .tableId, .dataCol$, .factorCol$ | public |
| `@emlWelchAnova` | Welch's heteroscedastic k-sample F test (Welch 1951): a one-way analysis of means that does not assume equal variances | .tableId, .dataCol$, .factorCol$ | public |
| `@emlGamesHowell` | Games-Howell post-hoc test: all pairwise comparisons with Welch standard errors and Welch-Satterthwaite degrees of freedom, referred to the studentized range ... | .tableId, .dataCol$, .factorCol$, .alpha | public |
| `@emlLinearRegression` | Simple OLS linear regression | .x#, .y# | public |
| `@emlTheilSen` | Theil-Sen robust regression estimator Computes the Theil-Sen slope (median of all pairwise slopes) and intercept | .x#, .y# | public |
| `@emlOLSInfluence` | Leverage, Cook's distance and LEVERAGE-CORRECTED standardised residuals for a SIMPLE ordinary-least-squares regression (one predictor, one response, intercept ... | .tableId, .xCol$, .yCol$ | public |

## Stats: Psychometrics
**File:** `stats/eml-psychometrics.praat` (v1.0) — 3 procedures (2 public, 1 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_listwiseComplete` | Internal helper: remove every row of a matrix that contains at least one undefined cell (listwise deletion) | .data## | internal |
| `@emlCronbachAlpha` | Cronbach's alpha: internal consistency of a k-item scale | .data##, .confidence | public |
| `@emlAlphaInfluence` | Respondent influence on Cronbach's alpha: leave-one-out jackknife over respondents | .data## | public |

## Stats: Categorical
**File:** `stats/eml-categorical.praat` (v1.0) — 2 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlChiSquareIndependence` | Chi-square test of independence with Cramer's V, for a contingency table of counts (category x category) | .observed##, .correction | public |
| `@emlWilsonInterval` | Wilson score confidence interval on a single proportion | .successes, .n, .confidence | public |

## Stats: Result Writer
**File:** `stats/eml-result-writer.praat` (v1.0) — 22 procedures (14 public, 8 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@eml_vocabHas` | Whole-token match | .vocab$, .name$ | internal |
| `@eml_vocabCheck` | Refuses an unknown column name loudly, at the call site, naming the verb and listing what is legal | .verb$, .vocab$, .name$ | internal |
| `@emlResultBegin` | Clears all three collectors | .tableName$, .analysis$ | public |
| `@eml_colIndex` | Index of a column in the named collector, registering it on first use | .which$, .name$ | internal |
| `@emlTidyRow` | Start a new term row | .term$ | public |
| `@emlTidyNum` | Undefined writes nothing, so the cell stays empty and R reads NA | .col$, .value | public |
| `@emlTidyStr` | (see source header) | .col$, .value$ | public |
| `@emlGlanceNum` | GLANCE — one row per model | .col$, .value | public |
| `@emlGlanceStr` | (see source header) | .col$, .value$ | public |
| `@emlAugmentFrom` | Carry the input table through verbatim: same columns, same order, same values, one augment row per table row | .tableId | public |
| `@emlAugmentNum` | (see source header) | .col$, .row, .value | public |
| `@eml_rwQuote` | (see source header) | .s$ | internal |
| `@eml_orderedCols` | Emit order = vocabulary order, filtered to the columns actually used | .vocab$, .which$ | internal |
| `@emlResultClearAll` | Clears all three collectors: tidy, glance, augment | (none) | public |
| `@emlTidyClear` | Empties the tidy collector without touching glance or augment | (none) | public |
| `@eml_renderTidy` | @eml_writeTidyFile: .path$   ->  .wrote Render the current tidy collector to CSV text without writing it | (none) | internal |
| `@eml_writeTidyFile` | THE FLUSH, AND THE CONTRACT THE PATH ARRIVES UNDER. The `writeFile:` below is where two session-killing failures would land, and neither is guarded here | .path$ | internal |
| `@eml_ensureExtraSlots` | @emlResultStageExtra: .suffix$ Freeze the current tidy collector as an additional frame to be written alongside tidy/glance/augment, under ... | (none) | internal |
| `@emlResultClearExtras` | Drop any staged extra frames | (none) | public |
| `@emlResultStageExtra` | (see source header) | .suffix$ | public |
| `@emlResultWriteTidy` | Writes ONLY the tidy collector, as <base>_tidy.csv | .folder$, .base$ | public |
| `@emlResultWrite` | (see source header) | .folder$, .base$ | public |

## Stats: Script Recorder
**File:** `stats/eml-record.praat` (v1.0) — 60 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlRecordInit` | (see source header) | (none) | public |
| `@emlRecordMetaGet` | , .found @emlRecordMetaSet: .key$, .value$ | .key$ | public |
| `@emlRecordMetaSet` | (see source header) | .key$, .value$ | public |
| `@emlRecordSweepOrphans` | >  .removed @emlRecordOrphanCheck    ->  .orphan | (none) | public |
| `@emlRecordOrphanCheck` | (see source header) | (none) | public |
| `@emlPluginFolder` | The install folder's NAME, and the four canonical places Praat keeps it | (none) | public |
| `@emlPluginRoot` | Where this plugin is installed, written the way an `include` line in a file meant for somebody else has to be written | (none) | public |
| `@emlRecordBegin` | (see source header) | .tempFolder$ | public |
| `@emlRecordDiscard` | Throw the buffer away without emitting | (none) | public |
| `@emlRecordHeader` | The provenance the emitted file opens with | .inputName$, .nRows, .nCols, .stamp$ | public |
| `@emlRecordSource` | Record WHICH object the session worked on, as provenance | .tableId | public |
| `@emlRecordAnalysisStep` | .api$, .error$ | .tableId, .label$, .detail$, .caveat$, .code$, .api$, .result$, .error$ | public |
| `@emlRecordDrawStep` | (see source header) | .objectId, .label$, .detail$, .caveat$, .code$, .api$, .result$ | public |
| `@emlRecordConvert` | The auto-conversion the graphs form performs, recorded as its own step | .sourceId, .targetId, .code$, .why$ | public |
| `@emlRecordCleanData` | scripts/eml-check-data.praat's table-mode repair, recorded as its own step -- the door is @emlRunCleanData (stats/eml-extract.praat), settled by the 8 Sep 2026 ... | .sourceId, .targetId, .mode$ | public |
| `@emlRecordCreateStep` | (see source header) | .objectId, .label$, .detail$, .caveat$, .code$, .api$ | public |
| `@emlRecordFilePath` | THE FILE AN OBJECT WAS READ FROM, ASKED OF PRAAT RATHER THAN OF THE PLUGIN | .objectId | public |
| `@emlRecordOriginKnown` | HAS THIS SESSION ALREADY SAID WHERE THIS OBJECT CAME FROM? | .name$ | public |
| `@emlRecordPrecondition` | WHICH OBJECTS THIS SCRIPT CANNOT REBUILD, AND THE HEADER THAT SAYS SO | (none) | public |
| `@emlRecordOriginCapture` | THE ROUTE THE ORIGINAL REPORT NAMED, TAKEN WHILE IT IS STILL THERE | (none) | public |
| `@emlRecordOrigin` | >  .text$ What the emitted script should call the route the recording came from | (none) | public |
| `@emlRecordStampDate` | >  .text$ The recording's date without its clock time | (none) | public |
| `@emlRecordReadStep` | THE FILE THE SESSION OPENED, RECORDED WHERE IT BECOMES KNOWABLE | .objectId, .path$ | public |
| `@emlRecordCaptureEnv` | (see source header) | (none) | public |
| `@emlRecordCapturePage` | (see source header) | (none) | public |
| `@emlRecordCaptureSeriesPens` | (see source header) | (none) | public |
| `@emlRecordCaptureStats` | (see source header) | (none) | public |
| `@emlRecordCaptureAnnotations` | (see source header) | .kind$ | public |
| `@emlRecordNewRun` | THE NEXT STEP RECORDED BEGINS A NEW RUN | (none) | public |
| `@emlRecordClaimRun` | Take the next run number, for the step that is about to be recorded | (none) | public |
| `@emlRecordStep` | (see source header) | .kind$, .intent$, .caveat$, .code$, .api$ | public |
| `@emlRecordMark` | REMEMBER HOW MANY STEPS THERE WERE, AND GO BACK TO IT. For a caller that performs an operation it then throws away | (none) | public |
| `@emlRecordRewind` | (see source header) | (none) | public |
| `@emlRecordResult` | Stream A. Attach an outcome to the step most recently recorded | .text$ | public |
| `@emlRecordHasColumn` | Does the recording buffer carry this column? | .name$ | public |
| `@emlRecordAxisRequest` | WHAT THE USER ASKED FOR, WHICH IS NOT ALWAYS WHAT THE DRAW WAS GIVEN | .fbMin, .fbMax | public |
| `@emlRecordAxisNote` | The RESOLVED axis of the draw step just recorded, kept for the block | .min, .max | public |
| `@emlRecordAxisFixed` | Four decimals, INCLUDING for exact zero | .value | public |
| `@emlRecordLoadPhrases` | Read the shipped phrase registry once | .csvPath$ | public |
| `@emlPhrase` | Positional substitution into a shipped template | .key$, .a1$, .a2$, .a3$, .a4$, .a5$, .a6$ | public |
| `@emlRecordCommentBlock` | Turn a possibly multi-line string into "# " lines | .text$ | public |
| `@emlRecordColumnSpec` | WHICH ARGUMENTS OF WHICH PROCEDURE ARE COLUMN NAMES, AND WHAT EACH IS FOR | .proc$ | public |
| `@emlRecordPageSpec` | IS THIS LINE ONE OF THE SETTINGS WRITTEN AS AN ASSIGNMENT, AND WHICH ONE | .line$ | public |
| `@emlRecordPageGloss` | One short phrase per page setting, for the inline note in the block | .base$ | public |
| `@emlRecordColumnGloss` | One short phrase per role, for the inline note in the block | .base$ | public |
| `@emlRecordSplitArgs` | Split a recorded call's argument list on the commas that separate arguments, and NOT on the commas inside them | .text$ | public |
| `@emlRecordQuotedLiteral` | Is this argument a plain string literal, and if so what does it say? | .arg$ | public |
| `@emlRecordQuotedVectorLiteral` | Is this argument a plain vector literal of quoted string members, and if so what are they? RULING_VECTOR_EMISSION_2026-09-03: a frozen `$#` parameter such as ... | .arg$ | public |
| `@emlRecordRunOf` | WHICH RUN THE STEP IN THAT BUFFER ROW BELONGS TO, AS THE EMITTED FILE COUNTS RUNS: the first run the file contains is 1, the next 2, and so on | .row | public |
| `@emlRecordRunSuffix` | THE END OF EVERY VARIABLE NAME IN THE EDITABLE BLOCK, WRITTEN ONCE | .run, .already | public |
| `@emlRecordColumnManifest` | The column half of the retarget block, and the rewritten steps that read it | (none) | public |
| `@emlRecordAxisGloss` | One short phrase per axis role, the twin of @emlRecordColumnGloss and here for the same reason: the variable name says what the role IS, the gloss says what it ... | .base$ | public |
| `@emlRecordTableManifest` | The block at the top of an emitted script that names every object the session ran on, once each, with the steps that used it | (none) | public |
| `@emlRecordRender` | Walk the buffer in order and build the whole file as one string | (none) | public |
| `@emlRecordFlush` | Render and write | .outPath$ | public |
| `@emlRecordMakeFolder` | (see source header) | .path$ | public |
| `@emlRecordStripStamp` | (see source header) | .name$ | public |
| `@emlRecordReplaySave` | (see source header) | .offerFigure, .stem$, .folder$, .formats$ | public |
| `@emlRecordReplayRead` | (see source header) | .path$ | public |
| `@emlRecordReplayName` | (see source header) | .name$ | public |

## Stats: Shared Reporters
**File:** `stats/eml-report.praat` (v1.0) — 15 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlCIAlphaInForce` | The alpha every confidence interval in this module is built at | (none) | public |
| `@emlReportTwoGroupComparison` | (see source header) | .tableName$, .dataCol$, .groupCol$, .group1$, .group2$, .n1, .mean1, .sd1, .median1, .n2, .mean2, .sd2, .median2, .testType$ | public |
| `@emlReportAnovaComparison` | (see source header) | .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doTukey | public |
| `@emlReportKWComparison` | (see source header) | .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doDunn | public |
| `@emlReportCorrelationAnalysis` | (see source header) | .tableName$, .colX$, .colY$, .n, .testType$ | public |
| `@emlReportRegressionTheilSen` | Printed FIRST, ahead of @emlReportRegressionAnalysis's own OLS report, when the door's .estimator$ is "theil-sen" (order section 4.3: "the report leads with ... | .predCol$, .depCol$ | public |
| `@emlReportRegressionAnalysis` | Formatted Info window report for simple linear regression | .tableName$, .depCol$, .predCol$, .nValid, .nUndefined | public |
| `@emlReportNormalityAnalysis` | Formatted Info window report for normality assessment | .tableName$, .dataCol$, .nValid, .nUndefined | public |
| `@emlReportPairedComparison` | (see source header) | .tableName$, .col1$, .col2$, .n, .mean1, .sd1, .median1, .mean2, .sd2, .median2, .testType$ | public |
| `@emlReportTwoWayOmega` | (private to the two-way report) One omega-squared row | .label$, .value | public |
| `@emlReportTwoWayAnova` | (see source header) | .tableName$, .dataCol$, .factor1$, .factor2$ | public |
| `@emlReportTwoWayEMM` | / @emlReportTwoWayPostHoc The three sections API completion wave section 4.1 adds to the two-way report, printed in this order right after ... | .factor1$, .factor2$ | public |
| `@emlReportTwoWaySimpleEffects` | (see source header) | .factor1$, .factor2$ | public |
| `@emlReportTwoWayPostHoc` | (see source header) | .factorLabel$, .factorSelect | public |
| `@emlReportAnovaHeteroscedastic` | The DOOR's own Brown-Forsythe / Welch / Games-Howell block (API completion wave, order section 4.2) -- reads emlRunAnovaAnalysis.bf*/.welch*/.gh*, computed at ... | .groupCol$ | public |

## Stats: Analysis Dispatchers
**File:** `stats/eml-analysis.praat` (v1.3) — 58 procedures (54 public, 4 internal)

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlRunTwoGroupAnalysis` | TWO-GROUP COMPARISON | .tableId, .dataCol$, .groupCol$, .testType$, .equalVar | public |
| `@emlRunAnovaAnalysis` | ONE-WAY ANOVA | .tableId, .dataCol$, .groupCol$, .doTukey | public |
| `@emlRecordAnova` | The recording half of @emlRunAnovaAnalysis, kept as its own procedure so the orchestrator gains one line rather than thirty, and so the mapping from analysis ... | .tableId, .dataCol$, .groupCol$, .doTukey, .error$ | public |
| `@emlRunKruskalWallisAnalysis` | KRUSKAL-WALLIS | .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$ | public |
| `@emlRunPairwiseAnalysis` | PAIRWISE COMPARISONS | .tableId, .dataCol$, .groupCol$, .test$, .adjMethod$ | public |
| `@emlAdjustMethodDisplay` | display casing for a p-adjustment key The key travels through the plugin lowercase ("bonferroni", "holm", "bh") because that is what @emlPairwiseT, @emlHolm ... | .key$ | public |
| `@emlReportAlpha` | the alpha the report marks significance against No stats dialog in the plugin collects an alpha; only the graphing form does (annotAlpha) | (none) | public |
| `@emlPostHocCaution` | the one line a post-hoc under a quiet omnibus carries THE POLICY THIS BELONGS TO. A post-hoc the user chose runs on every door, whatever the omnibus says ... | .omnibusP | public |
| `@emlEffectMatrixCaption` | what a pairwise effect-size matrix says when no pairwise test was run beside it The effect-size matrix prints whether or not a post-hoc ran; with the post-hoc ... | (none) | public |
| `@emlInlineP` | a p-value inside a running sentence @emlReportPWithExact prints a LABELLED ROW. The repeated-measures and Friedman reporters do not print rows — they compose ... | .pValue | public |
| `@emlSigMark` | significance marker for one p-value | .pValue, .alpha | public |
| `@emlPadCell` | fixed-width column cell for the fixed-pitch report tables @emlPadRight pads but never truncates, so one long group label shifts every column to its right | .text$, .width | public |
| `@emlReportPairwiseDescriptives` | n, mean and SD per group The pairwise report handed the reader Cohen's d for every pair and never printed a single input to it: no group n, no group mean, no ... | .tableId, .dataCol$, .groupCol$ | public |
| `@emlReportPairwiseComparison` | Extracted from inline code in eml-pairwise.praat | .tableId, .tableName$, .dataCol$, .groupCol$, .test$, .adjMethod$ | public |
| `@emlRunTwoWayAnalysis` | TWO-WAY ANOVA | .tableId, .dataCol$, .factor1$, .factor2$, .ssType, .adjMethod$ | public |
| `@emlRunPairedAnalysis` | PAIRED COMPARISON | .tableId, .col1$, .col2$, .testType$ | public |
| `@emlRunCorrelationAnalysis` | CORRELATION | .tableId, .colX$, .colY$, .testType$, .groupCol$ | public |
| `@emlRunDescriptiveAnalysis` | DESCRIPTIVE STATISTICS | .tableId, .dataCol$, .groupCol$, .trim | public |
| `@emlRunRegressionAnalysis` | PHASE 4 STUBS | .tableId, .depCol$, .predCol$, .estimator$ | public |
| `@emlRunGroupedRegressionAnalysis` | per-group regression fits beside the overall one Punch list 4.5 / OPEN_ITEMS "the regression group column" ruling: the correlate dialog's per-group block ... | .tableId, .predCol$, .respCol$, .groupCol$ | public |
| `@emlNormalityRecommendation` | THE normality decision rule | .skewness, .kurtosis, .n, .swP, .swError$ | public |
| `@eml_normalityPress` | (see source header) | .tableName$, .dataCol$, .testType$ | internal |
| `@emlRunNormalityAnalysis` | SELECTS NO TEST. This orchestrator always computes both families of evidence — descriptive shape (skewness/kurtosis) and the formal Shapiro-Wilk test — and ... | .tableId, .dataCol$, .testType$ | public |
| `@emlRunReliabilityAnalysis` | v1.2 item 7: Reliability doorway, survey-row signature frozen by mailbox/to-opus/RULING_SURVEY_ROWS_ACCEPTED_2026-09-03.md -- changes only on Ian's word, the ... | .tableId, .itemCols$#, .confidence, .doInfluence | public |
| `@emlRunCategoricalAnalysis` | Categorical doorway, signature FROZEN by mailbox/to-opus/RULING_CATEGORICAL_DOORWAY_2026-09-03.md -- changes only on Ian's word, the way the reliability and RM ... | .tableId, .rowCol$, .colCol$, .countCol$, .correction | public |
| `@emlRunProportionAnalysis` | Proportion doorway, signature FROZEN by whatever supersedes RULING_CATEGORICAL_DOORWAY_2026-09-03.md for this procedure -- do not alter .tableId, .col$, ... | .tableId, .col$, .successValue$, .countCol$, .confidence | public |
| `@eml_completeCaseDisclosure` | (see source header) | .nRows, .n, .nExcluded, .parseNote$ | internal |
| `@eml_rmCallStrings` | The two strings the recorder needs from a repeated-measures call: the | .format$, .conditionCols$#, .conditionCol$ | internal |
| `@eml_rmResolveMatrix` | (private — the one shape-resolver for both RM doors) RULING_RM_FORMATS: repeated measures accepts BOTH table shapes for 1.0. WIDE is one row per subject and ... | .tableId, .format$, .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$ | internal |
| `@emlExtractConditionMatrix` | Row-wise COMPLETE-CASE extraction of k condition columns into a matrix | .tableId, .conditionCols$# | public |
| `@emlFriedmanTest` | Friedman rank test for k related samples (tie-corrected) | .data##, .n, .k | public |
| `@emlGGEpsilon` | Greenhouse-Geisser sphericity epsilon for RM-ANOVA | .data##, .n, .k | public |
| `@emlRMAnovaTest` | one-way repeated-measures ANOVA with GG correction | .data##, .n, .k | public |
| `@emlRunRepeatedMeasuresAnalysis` | parametric RM-ANOVA orchestrator | .tableId, .format$, .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$, .doPostHoc, .adjMethod$ | public |
| `@emlRunFriedmanAnalysis` | nonparametric repeated-measures orchestrator | .tableId, .format$, .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$, .doPostHoc, .adjMethod$ | public |
| `@emlRMPostHoc` | pairwise post-hoc for repeated-measures designs | .data##, .n, .k, .testType$, .adjMethod$ | public |
| `@emlDeclareOneWayAnovaResult` | Declare a completed one-way ANOVA in broom's three-file shape, so the export surface can write tidy / glance / augment instead of one wide file | .tableName$, .dataCol$, .groupCol$, .tableId, .doTukey | public |
| `@emlDeclareTukeyResult` | tidy(TukeyHSD(fit)) is its own frame: term, contrast, null.value, estimate, conf.low, conf.high, adj.p.value | .groupCol$ | public |
| `@emlDeclareAnovaEffectSizes` | effectsize::eta_squared(fit) and effectsize::cohens_d() are again separate frames in R; base aov and TukeyHSD carry neither | .groupCol$, .doTukey | public |
| `@emlDeclareTwoGroupResult` | 2. Two independent groups --------------------------------------------- tidy(t.test) is ONE row: estimate (the mean difference), estimate1, estimate2, ... | .tableName$, .dataCol$, .groupCol$, .doPar, .doNon, .g1$, .g2$ | public |
| `@emlDeclareTwoGroupEffects` | (see source header) | .doPar, .doNon | public |
| `@emlDeclareKWResult` | --- 3. Kruskal-Wallis ----------------------------------------------------- | .tableName$, .dataCol$, .groupCol$ | public |
| `@emlDeclareDunnResult` | Dunn is a second object: its own frame, with the raw p AND the adjusted p, because which one a reader wants depends on their correction policy and the old ... | .groupCol$ | public |
| `@emlDeclarePairwiseResult` | 4. Pairwise comparisons — a BUILD, not a conversion ------------------- There is no earlier shape to mirror here: @emlRunPairwiseAnalysis calls @emlCSVInit, so ... | .tableName$, .groupCol$, .test$, .adjMethod$ | public |
| `@emlDeclareTwoWayResult` | 5. Two-way ANOVA ------------------------------------------------------ The only orchestrator with a real augment available without re-deriving: .cellOf[r] is ... | .tableName$, .dataCol$, .factor1$, .factor2$, .tableId | public |
| `@emlDeclareTwoWayEffects` | (see source header) | .factor1$, .factor2$ | public |
| `@emlDeclarePairedResult` | --- 6. Paired / repeated pair --------------------------------------------- | .tableName$, .col1$, .col2$, .doPar, .doNon | public |
| `@emlDeclarePairedEffects` | (see source header) | .doPar, .doNon | public |
| `@emlDeclareCorrelationResult` | 7. Correlation -------------------------------------------------------- Reads the ORCHESTRATOR's restored locals rather than the procedure globals, passed in, ... | .tableName$, .colX$, .colY$, .n, .doPear, .pearR, .pearT, .pearDf, .pearP, .doSpear, .spearRho, .spearT, .spearDf, .spearP | public |
| `@emlDeclareRegressionResult` | 8. Simple linear regression ------------------------------------------- This is the one that is literally broom's tidy(lm): one row per coefficient, term / ... | .tableName$, .depCol$, .predCol$, .tableId, .nValid | public |
| `@emlCSVAddDescriptiveRow` | (see source header) | .term$ | public |
| `@emlDeclareNormalityResult` | 9. Normality ---------------------------------------------------------- Reads emlRunNormalityAnalysis.* -- the one orchestrator that copies every value onto ... | .tableName$, .dataCol$, .swW, .swP, .swError$, .skewness, .kurtosis, .nValid, .nUndefined, .recommendation$, .accumulate | public |
| `@emlDeclareRMResult` | --- 10. Repeated-measures ANOVA — a BUILD -------------------------------- | .tableName$, .n, .k | public |
| `@emlDeclarePostHoc` | Post-hoc pair labels are INTEGERS indexing emlExtractConditionMatrix.colLabel$, not strings -- the contrast text is built inline by the printer and stored ... | .kind$ | public |
| `@emlDeclareFriedmanResult` | 11. Friedman — a BUILD ----------------------------------------------- @emlFriedmanTest exposes NO .error$ field | .tableName$, .n, .k | public |
| `@emlDeclareReliabilityResult` | 12. Reliability (Cronbach's alpha) — a survey row --------------------- Reads emlCronbachAlpha.* directly, the way @emlDeclareRMResult reads emlRMAnovaTest.* ... | .tableName$, .itemCols$#, .k, .n, .nExcluded, .warning$ | public |
| `@emlDeclareCategoricalResult` | (see source header) | .tableName$, .rowCol$, .colCol$, .warning$ | public |
| `@emlDeclareProportionResult` | (see source header) | .tableName$, .col$, .successValue$, .n, .nExcluded, .warning$ | public |

## Graphs: Core
**File:** `graphs/eml-graph-procedures.praat` (v3.32) — 90 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlSetPanelOrigin` | Sets the origin for the current drawing panel | .x, .y | public |
| `@emlResetDrawnExtent` | Resets extent tracking to zero | (none) | public |
| `@emlExpandDrawnExtent` | Expands the drawn extent bounding box to include the given rectangle | .left, .right, .top, .bottom | public |
| `@emlBeginPanel` | OPEN A PANEL ON THE PAGE. The one place that decides whether a draw starts a fresh page or adds to the one already there | .originX, .originY, .erase | public |
| `@emlPitchArgsFAC` | The canonical filtered-autocorrelation parameter tail, stated once | .floor, .top | public |
| `@emlSetPanelViewport` | (see source header) | (none) | public |
| `@emlInitializeDrawingDefaults` | Initializes all rendering globals to sensible defaults | (none) | public |
| `@emlSetAdaptiveTheme` | Computes all styling parameters from viewport dimensions | .vpWidth, .vpHeight | public |
| `@emlSetColorPalette` | Populates colour AND FILL-PATTERN arrays for data series | .mode$ | public |
| `@emlOptimizePaletteContrast` | Reorders palette arrays to maximize perceptual distance for K groups | .nGroups | public |
| `@emlSetPatternScale` | Records the world-units-per-inch of the CURRENTLY INSTALLED axes, so that the pattern primitives can lay out a hatch at 45 degrees ON THE PAGE and a dot grid ... | .xMin, .xMax, .yMin, .yMax | public |
| `@emlPointInFrame` | Is this data point inside the plotting frame the current axes describe? | .x, .y | public |
| `@emlResetClipCount` | Zero the running count of points withheld for falling outside the frame | (none) | public |
| `@emlRegisterCollisionPoints` | Publish the points that are actually ON THE PAGE, for @emlPlaceAnnotationBox to place the annotation panel around | .x#, .y#, .n | public |
| `@emlPatternSetup` | Everything a patterned fill needs, in one call: the world-per-inch scales, the stripe/dot geometry in inches scaled to the mark being drawn, and the ink colour | .fillColor$, .lineColor$, .halfWidth, .yMin, .yMax | public |
| `@emlParseRGB` | Pulls the three channels out of a Praat colour string "{r, g, b}" | .rgb$ | public |
| `@emlMarkInk` | The colour a mark's own detail is drawn in: outline, median, whiskers, and the hatch or dot pattern | .fillColor$, .strokeColor$ | public |
| `@emlPaintHatchRow` | One scanline of a 45-degree hatch, clipped to [.xC - .d, .xC + .d] | .xC, .d, .y1, .y2, .yFloor | public |
| `@emlPaintDotRow` | One row of the dot grid, at world y .y, clipped to [.xC - .d, .xC + .d] | .xC, .d, .y, .row, .yFloor | public |
| `@emlScreenSetup` | The screen's geometry for the CURRENTLY INSTALLED axes, in world units | .coverage | public |
| `@emlPaintScreenRect` | Paints the screen over one rectangle | .x0, .x1, .y0, .y1, .ink$, .coverage | public |
| `@emlPaintAlphaBox` | THE background for an on-figure box, by whichever of the three means this platform actually has | .x0, .x1, .y0, .y1 | public |
| `@emlPadDataRange` | , .max, .degenerate | .dataMin, .dataMax, .fraction | public |
| `@emlComputeAxisRange` | Computes axis bounds from data range with buffer and rounding | .dataMin, .dataMax, .roundTo, .isPercentage | public |
| `@emlComputeNiceStep` | Classic nice-number algorithm for human-friendly tick spacing | .range, .targetTicks | public |
| `@emlTickPrecision` | Decide whether Praat may format this axis's tick numbers itself, and if not, how many decimals the plugin has to write instead | .axisMin, .axisMax, .step | public |
| `@emlTickLabelWidth` | What one tick label will READ AS, and how wide it will be on the page | .value, .explicit, .decimals | public |
| `@emlDrawAxisNameLeft` | Draw the y-axis NAME in the left margin without letting the tick numbers run into it | .label$, .wideLabelMM, .xMin, .xMax, .yMin, .yMax | public |
| `@emlDrawGridlines` | Draws gridlines aligned with nice-number tick positions | .xMin, .xMax, .yMin, .yMax, .targetTicksX, .targetTicksY, .useMinor | public |
| `@emlDrawHorizontalGridlines` | Draws only horizontal gridlines aligned with nice-number tick positions (for bar charts, histograms, violins with categorical x-axis) | .xMin, .xMax, .yMin, .yMax, .targetTicksY, .useMinor | public |
| `@emlDrawVerticalGridlines` | Draws only vertical gridlines aligned with nice-number tick positions (for continuous x-axis plots where only vertical lines are wanted) | .xMin, .xMax, .yMin, .yMax, .targetTicksX, .useMinor | public |
| `@emlDrawInnerBoxIf` | Wrapper for Draw inner box with boolean toggle and font state assertion | (none) | public |
| `@emlExpandAxisControls` | Expands 3 dropdown indices (config_showAxisNames, config_showTicks, config_showAxisValues) to 6 per-axis boolean globals | (none) | public |
| `@emlLineStyleName` | The dialog's option index as the word a reader recognises | .style | public |
| `@emlApplyLineStyle` | Sets the Picture window's pen to one of Praat's four line styles | .style | public |
| `@emlResetLineStyle` | Back to solid | (none) | public |
| `@emlPrimaryLineStyle` | >  .style THE PRIMARY'S PEN, READ THROUGH THE GUARD every other request global is read through | (none) | public |
| `@emlSecondAxisScope` | , .reason$, .kind$ THE JUDGE. One place decides which figures may carry a right-hand y-axis, and it decides by NAME rather than by graph-type number, because ... | .type$ | public |
| `@emlSecondAxisGate` | THE ONE LINE EVERY DRAW PROCEDURE CALLS. A request a figure cannot honour is refused OUT LOUD -- in the Info window, and in a global a check can quote -- ... | .type$ | public |
| `@emlSecondAxisRequest` | >  .col$, .min, .max, .label$, .style THE REQUEST, READ THROUGH THE GUARD, ONCE. Five globals, five variableExists tests, and one place they are spelled -- so ... | (none) | public |
| `@emlSecondAxisResolve` | .leftMin, .leftMax, .leftDataMin, .leftDataMax ->  .min, .max THE RIGHT AXIS'S RANGE, AND THE ONE HEADROOM NEGOTIATION BOTH SERIES ARE IN | .dataMin, .dataMax, .reqMin, .reqMax, .leftMin, .leftMax, .leftDataMin, .leftDataMax | public |
| `@emlDrawAlignedMarksLeft` | Draws y-axis tick marks at nice-number positions (for manual axis code) | .yMin, .yMax, .targetTicks, .useMinor | public |
| `@emlDrawAlignedMarksRight` | Draws right y-axis tick marks at nice-number positions (for dual-axis panels) | .yMin, .yMax, .targetTicks, .useMinor | public |
| `@emlDrawAxisNameRight` | The right axis's name, in the right margin, in black -- which is the only ink Praat's margin commands draw in | .label$ | public |
| `@emlDrawAlignedMarksBottom` | Draws bottom x-axis tick marks at nice-number positions | .xMin, .xMax, .targetTicks, .useMinor | public |
| `@emlDrawTitle` | Draws figure title and optional subtitle via Text special, positioned above the inner box and horizontally centered on it | .title$, .vpWidth, .vpHeight, .xMin, .xMax, .yMin, .yMax | public |
| `@emlDrawAxes` | Draws complete axes with box, aligned ticks, labels, and title | .xMin, .xMax, .yMin, .yMax, .xLabel$, .yLabel$, .title$, .vpWidth, .vpHeight | public |
| `@emlEnsureLabelTables` | Defines the label tables if this file's top-level block has not run in the current interpreter (same defensive pattern as the panel-origin guard) | (none) | public |
| `@emlClearLabelOverrides` | Drops every registered axis-label override | (none) | public |
| `@emlSetLabelOverride` | Registers a display label for a column name | .colName$, .display$ | public |
| `@emlLookupLabelOverride` | (see source header) | .colName$ | public |
| `@emlLookupLabelToken` | Case-insensitive exact-token lookup in one of the maps above | .map$, .token$ | public |
| `@emlFormatLabelTokens` | The heuristic itself, with no override lookup — split on underscores, canonicalise every recognised token, lift a trailing unit into a parenthesis, capitalise ... | .raw$ | public |
| `@emlCapitalizeLabel` | Converts a column name to a display label | .raw$ | public |
| `@emlDeriveAxisLabel` | The explicit form of the override | .rawCol$, .override$ | public |
| `@emlCommonMeasureLabel` | Helper for the wide→long reshapes | .colA$, .colB$ | public |
| `@emlPaintSmoothBand` | Paints interpolated confidence/SD band for smooth appearance Requires global arrays before call: bandX#, bandLower#, bandUpper# | .fillColor$, .subsamples | public |
| `@emlDrawViolin` | Draws smooth violin plot with kernel density estimation and quartile box | .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width, .pattern | public |
| `@emlDrawBox` | Draws a single box-and-whisker plot at a categorical x-position | .xCenter, .data#, .fillColor$, .lineColor$, .axisYMin, .axisYMax, .width, .pattern | public |
| `@emlDrawMarker` | One point marker, filled, no outline, at world coordinates (.x, .y) | .x, .y, .halfIn, .shape, .color$ | public |
| `@emlSanitizeLabel` | Escapes Praat text-rendering special characters (%, #, ^, _) so they display as literal characters instead of triggering style toggles | .raw$ | public |
| `@emlDrawJitteredPoints` | Draws individual data points with horizontal jitter at a categorical x-position | .xCenter, .lineColor$, .markerSize, .jitterWidth | public |
| `@emlAssertFullViewport` | Selects the full outer viewport encompassing everything drawn since the last @emlResetDrawnExtent | (none) | public |
| `@emlApplyChannelChoice` | Mechanical core for stereo channel handling | .soundId, .channelHandling$ | public |
| `@emlHandleStereo` | UI wrapper for single-file stereo handling | .soundId, .fileName$ | public |
| `@emlCheckChannels` | Backward-compatible wrapper | .soundId | public |
| `@emlDropStaleChannelSounds` | Remove the channel Sounds a previous press of the stereo gate left behind | .sourceName$ | public |
| `@emlGraphsChannelGate` | The EML Graphs entry to the stereo choice | .soundId, .purpose$ | public |
| `@emlEllipsizeToWidth` | Shortens .text$ until it renders no wider than .maxWidth, appending "..." whenever anything was removed | .text$, .maxWidth | public |
| `@emlMeasureLegendPanel` | Lays the legend out inside a .maxWidth x .maxHeight inch rectangle and reports what it would consume | .maxWidth, .maxHeight, .fontSize | public |
| `@emlDrawLegendPanel` | Draws the legend into EXACTLY the rectangle it is handed | .x0, .x1, .y0, .y1, .fontSize | public |
| `@emlDrawLegend` | Draws the legend for the current panel, WHERE THE USER ASKED FOR IT | .xMin, .xMax, .yMin, .yMax, .position$, .fontSize | public |
| `@emlCheckNumericColumn` | Tests whether a Table column is safe to feed to number() for plotting | .tableId, .colName$ | public |
| `@emlDescribeFilterNumericColumns` | -> .nNumericCols, .numericCol'k'$ | .tableId | public |
| `@emlInitAlphaSprites` | Resolves the sprites/ directory and checks availability | (none) | public |
| `@emlLineTreeColumns` | -> .nNumeric, .numericIdx'k', .numericName'k'$ .nText,    .textIdx'k',    .textName'k'$ | .tableId, .timeCol$ | public |
| `@emlLineTreeRepeats` | -> .found, .maxPerPoint, .nPointsWithRepeats, .nPoints | .tableId, .timeCol$, .groupCol$ | public |
| `@emlSetAlphaDotGeometry` | Computes aspect-corrected stamp dimensions for alpha dots | .axisXMin, .axisXMax, .axisYMin, .axisYMax, .innerLeft, .innerRight, .innerTop, .innerBottom, .dotHalf | public |
| `@emlDrawAlphaDot` | Draws a single alpha-composited dot at the given world coordinates | .x, .y, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$ | public |
| `@emlDrawAlphaRect` | Draws a semi-transparent filled rectangle using a PNG sprite stretched to the specified world-coordinate bounds | .x1, .x2, .y1, .y2, .groupIndex, .colorMode$, .alphaLevel$, .fallbackColor$ | public |
| `@emlLightenColor` | Parse an RGB colour string and blend toward white | .rgb$, .amount | public |
| `@emlFitCategoricalLabels` | Measures categorical x-axis labels against available slot width | .nLabels, .xMin, .xMax | public |
| `@emlExtractUniqueValues` | Extracts unique values from a Table column in encounter order | .tableId, .colName$ | public |
| `@emlMeasureCategoricalLabels` | Orchestrates categorical label measurement: extraction, viewport setup, rotation/truncation/overhang computation | .tableId, .colName$, .vpW, .vpH | public |
| `@emlEnsureCategoricalLabels` | Measures categorical labels unless the current measurement already covers this table, column and viewport | .tableId, .colName$, .vpW, .vpH | public |
| `@emlMeasureGraphLayout` | Universal frame measurement for all graph types | .vpW, .vpH, .title$, .xLabel$, .yLabel$ | public |
| `@emlDrawCategoricalXAxis` | Renders categorical x-axis: tick marks, category labels (horizontal or rotated at 45°), and x-axis label (with rotated offset when needed) | .nLabels, .xMin, .xMax, .yMin, .yMax, .xLabel$ | public |
| `@emlMeasureBarData` | Extracts and aggregates bar chart data from a Table: unique groups, per-group means, per-group error values (SE/SD/custom), and the visible maximum (max of ... | .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$ | public |
| `@emlEnsureBarData` | Measures bar chart data unless the current emlBarData_* state already covers this table, these columns and this error mode | .tableId, .groupCol$, .valueCol$, .errorMode, .errorCol$ | public |
| `@emlConvertForGraph` | Turn whatever the user selected into whatever the figure needs, and record having done it | .sourceId, .targetType$, .pitchFloor, .pitchTop | public |

## Graphs: Draw
**File:** `graphs/eml-draw-procedures.praat` (v1.26) — 20 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlDiscloseBegin` | Opens a disclosure batch | .chart$ | public |
| `@emlDisclose` | One disclosure | .short$, .advice$ | public |
| `@emlDiscloseClipped` | .ySetMax, .xLo, .xHi, .yLo, .yHi Say, on the figure and in the Info window, that a typed axis range withheld points -- and say which range did it | .nOutside, .nTotal, .xSetMin, .xSetMax, .ySetMin, .ySetMax, .xLo, .xHi, .yLo, .yHi | public |
| `@emlDiscloseEnd` | .legendCorner$ Renders whatever @emlDisclose put on the figure, then hands the annotation block back exactly as it was found | .xMin, .xMax, .yMin, .yMax, .qTL, .qTR, .qBL, .qBR, .legendCorner$ | public |
| `@emlDrawColumnIsClean` | Can this column be read with the fast path? Returns .clean, 1 or 0 | .tableId, .colName$ | public |
| `@emlDrawF0Contour` | A REQUEST THIS FIGURE CANNOT HONOUR IS REFUSED OUT LOUD. @emlSecondAxisGate is the judge for all thirteen types and says nothing at all when no second axis was ... | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .fMin, .fMax, .yUnit | public |
| `@emlDrawWaveform` | Draws a publication-quality waveform from a Sound object | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .tMin, .tMax, .aMin, .aMax | public |
| `@emlDrawSpectrum` | Draws a publication-quality Spectrum plot | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax | public |
| `@emlDrawLTAS` | Draws a publication-quality LTAS plot with optional multi-method overlay | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .fMin, .fMax, .pMin, .pMax, .showCurve, .showBars, .showPoles, .showSpeckles | public |
| `@emlDrawTimeSeries` | Draws a publication-quality time series plot: one line, or one line per group, with a marker at every plotted vertex | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax | public |
| `@emlDrawTimeSeriesCI` | Time series with auto-computed confidence interval bands | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .timeCol$, .valueCol$, .groupCol$, .tMin, .tMax, .vMin, .vMax | public |
| `@emlDrawSpaghettiPlot` | Individual subject traces across ordinal conditions with optional mean overlay | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .condCol$, .valueCol$, .idCol$, .groupCol$, .showMean, .vMin, .vMax | public |
| `@emlDrawBarChart` | Draws a publication-quality grouped bar chart with optional error bars | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .errorMode, .errorCol$, .vMin, .vMax | public |
| `@emlDrawViolinPlot` | Draws a publication-quality violin plot with kernel density estimation | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax | public |
| `@emlRecordViolin` | The recording half of @emlDrawViolinPlot, kept separate so the draw procedure gains one line rather than thirty | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax, .nGroups | public |
| `@emlDrawScatterPlot` | Draws a scatter plot from Table with X and Y columns | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .colX$, .colY$, .groupCol$, .xMin, .xMax, .yMin, .yMax, .annotate | public |
| `@emlDrawBoxPlot` | Draws a grouped box-and-whisker plot with Tukey whiskers and outlier dots | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .groupCol$, .valueCol$, .vMin, .vMax | public |
| `@emlDrawHistogram` | Draws a histogram from Table data with optional grouped display | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .valueCol$, .groupCol$, .binCount, .displayMode, .vMin, .vMax, .freqMax | public |
| `@emlDrawGroupedViolin` | Draws a grouped violin plot: categories on x-axis, sub-groups as side-by-side violins within each category | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax | public |
| `@emlDrawGroupedBoxPlot` | Categories on x-axis, sub-groups as side-by-side boxes per category | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, .colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax | public |

## Graphs: Annotation & Bridges
**File:** `graphs/eml-annotation-procedures.praat` (v3.22) — 28 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlClearAnnotations` | Reset all annotation arrays to empty state | (none) | public |
| `@emlFormatStars` | Convert p-value to star notation | .p | public |
| `@emlFormatAnnotLabel` | Format the display label for a bracket annotation | .p, .d, .style$, .showEffect, .effectLabel$ | public |
| `@emlStackBrackets` | Assign vertical tier to each bracket so none overlap | (none) | public |
| `@emlDrawBracket` | Render one significance bracket in the current axes | .xI, .xJ, .yBase, .tierHeight, .tier, .label$, .fontSize, .lineColor$ | public |
| `@emlDrawBracketCaption` | Render the post-hoc/correction caption for a bracket-layout figure, as a band immediately under the frame | .fontSize, .axXMin, .axXMax, .axYMin, .axYMax | public |
| `@emlDrawAnnotation` | (see source header) | .x, .y, .anchor$, .label$, .fontSize, .hasBg, .xRange, .yRange, .axXMin, .axXMax, .axYMin, .axYMax | public |
| `@emlDrawAnnotations` | (see source header) | .xMin, .xMax, .yDataMax, .yRange, .bracketColor$, .fontSize, .axYMin, .axYMax | public |
| `@emlDrawRegressionLine` | Draw a regression line across the scatter plot axes | .xMin, .xMax, .slope, .intercept, .yAxisMin, .yAxisMax, .lineColor$ | public |
| `@emlPlaceElements` | Universal placement algorithm for legend and annotation block | .qTL, .qTR, .qBL, .qBR, .xMid, .nElements | public |
| `@emlComputeAnnotationHeadroom` | Compute how much extra y-axis space a figure needs for the boxes that are drawn ON it | .yDataRange, .fontSize, .legendHeightInches, .legendCorner$ | public |
| `@emlOppositeCorner` | Return the diagonally opposite corner | .corner$ | public |
| `@emlSpaceCount` | Number of space characters in .s$. Used by @emlDrawAnnotationBlock to count words (spaces + 1) so a wrapped line's Praat markup can be cut at the same word ... | .s$ | public |
| `@emlDrawAnnotationBlock` | Render a multi-line text box with background fill in a specified corner | .corner$, .xMin, .xMax, .yMin, .yMax, .fontSize | public |
| `@emlPlaceAnnotationBox` | .qTL, .qTR, .qBL, .qBR, .xMid, .nElements Choose the annotation block's corner by what is UNDER each candidate box, not by how busy the quadrant around it is | .xMin, .xMax, .yMin, .yMax, .fontSize, .qTL, .qTR, .qBL, .qBR, .xMid, .nElements | public |
| `@emlMeasureMatrixLayout` | Measure matrix panel geometry: label rotation/truncation, vertical stacking, cell sizing, legend minimum width | .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize | public |
| `@emlDrawMatrixPanel` | Render a pairwise comparison matrix as a table panel below the plot | .vpLeft, .vpRight, .vpTop, .vpBottom, .fontSize, .colorMode$ | public |
| `@emlBridgeStoreIdentity` | THE GRAPH DOOR'S ANALYSIS, SAID IN THE STORE'S WORDS | .nGroups, .testType$, .correction$ | public |
| `@emlStoreGroupMap` | WHERE EACH OF THE FIGURE'S GROUPS SITS IN THE STORE'S MATRICES | .tableId, .factorCol$ | public |
| `@emlConsumeGroupResult` | THE READ SIDE'S ONE DOOR. Asks whether the published result answers the question this figure is about to ask, and hands back the payload when it does | .tableId, .dataCol$, .factorCol$, .testType$, .correction$, .alpha, .key$, .sort$ | public |
| `@emlBridgeOmnibusLine` | THE OMNIBUS LINE THE FIGURE CARRIES, IN ONE PLACE | .nGroups, .testType$, .stat, .df1, .df2, .p, .effect | public |
| `@emlBridgeEffectPolicy` | WHICH EFFECT SIZE THIS COMPARISON HAS, WHAT IT IS CALLED, AND WHAT SIGN THE STORED NUMBER CARRIES. Four arms of @emlRunAnnotationComparison answered these ... | .nGroups, .testType$ | public |
| `@emlBridgeRenderAnnotations` | THE ONE PLACE A GROUP COMPARISON BECOMES AN ANNOTATION | .nGroups, .useMatrix, .style$, .showNS, .showEffect, .alpha, .effectLabel$, .effectSymbol$, .bracketAbs, .matrixAbs, .omnibus$, .p##, .e## | public |
| `@emlBridgePairEffect` | ONE PAIR'S SIGNED EFFECT SIZE, for the matrix @emlBridgeRenderAnnotations is handed | .tableId, .dataCol$, .factorCol$, .g1$, .g2$, .testType$ | public |
| `@emlRunAnnotationComparison` | For bar chart, violin, box plot, and grouped violin: detect number of groups, run the appropriate statistical test, populate bracket or matrix annotations | .tableId, .dataCol$, .factorCol$, .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode | public |
| `@emlBridgeCorrelation` | For scatter plot: run correlation, populate regression line and text annotation arrays | .tableId, .colX$, .colY$, .alpha, .style$, .corrType$ | public |
| `@emlGraphsReportBridgeIfNew` | the reprint gate THE ONE PLACE THAT DECIDES WHETHER A FIGURE'S ANALYSIS REPORT IS PRINTED | .tableId, .dataCol$, .groupCol$ | public |
| `@emlReportBridgeStats` | thin dispatcher for graphs tool Called by eml-graphs.praat after @emlRunAnnotationComparison has run | .tableId, .dataCol$, .groupCol$ | public |

## Scripts: Graphs Main
**File:** `scripts/eml-graphs.praat` (v3.0) — 0 procedures

## Scripts: Graphs Form & Workflow
**File:** `graphs/eml-graphs-form.praat` (v2.9) — 44 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlPickFromMultiple` | When multiple objects of the same type are selected, present a choice form | .type$ | public |
| `@emlConfigMenu` | @emlConfigFlag: .raw$ | .raw$, .lo, .hi | public |
| `@emlConfigFlag` | A stored boolean is the same problem with a smaller range: anything that is not 0 or 1 becomes 0, and undefined with it | .raw$ | public |
| `@emlLoadConfig` | Set defaults first — these persist if file missing or key absent | (none) | public |
| `@emlSaveConfig` | Writes current config_* variables to config file in preferences directory | (none) | public |
| `@emlGridModeStyle` | Option count of one graph type's Gridline mode menu, with a named refusal for a type nobody registered | .type | public |
| `@emlGridModeToMenu` | Canonical (four-option) value -> the option index of .type's own menu | .type, .canonical | public |
| `@emlGridModeFromMenu` | The option index of .type's own menu -> canonical (four-option) value | .type, .menu | public |
| `@emlSeedGridMode` | Seeds tmpGridMode for the graph type currently being configured | (none) | public |
| `@emlCommitGridMode` | Records the user's choice from the graph type currently being configured | .chosen | public |
| `@emlLegendPlacementStyle` | Option count of one graph type's Legend placement menu, with a named refusal for a type nobody registered | .type | public |
| `@emlLegendPlacementToMenu` | Canonical value -> the option index of .type's own menu | .type, .canonical | public |
| `@emlLegendPlacementFromMenu` | The option index of .type's own menu -> canonical value | .type, .menu | public |
| `@emlSeedLegendPlacement` | Seeds tmpLegendPlacement for the graph type currently being configured | (none) | public |
| `@emlCommitLegendPlacement` | Records the user's choice from the graph type currently being configured | .chosen | public |
| `@emlSeedAxisLabels` | Reads the globals `graph_type` and `config_showAdvanced`; writes the globals `tmpXLabel$` and `tmpYLabel$`. Called at the top of every page | (none) | public |
| `@emlCommitAxisLabels` | Records what the advanced dialog returned, against the type it was typed on | .x$, .y$ | public |
| `@emlDetectContext` | Examines current selection in the Objects window and sets advisory defaults | (none) | public |
| `@emlBuildFilteredMenu` | Builds filtered menu arrays based on which graph types are reachable from the currently detected context object type | (none) | public |
| `@emlComparisonMenuRows` | Emits the option rows | (none) | public |
| `@emlComparisonFromMenu` | (see source header) | .row | public |
| `@emlComparisonToMenu` | The inverse, for seeding the menu from what the page last used | .testType, .adjustIdx, .doPostHoc | public |
| `@emlAdjustMethodName` | (see source header) | .idx | public |
| `@emlGraphsCSVDefaultName` | CSV EXPORT FILENAME BOTH HALVES OF THE PROPOSED NAME COME OFF THE CSV BUFFER THAT IS ABOUT TO BE WRITTEN, not off the drawing state, so the filename describes ... | .fallbackTable$ | public |
| `@emlGraphsCSVRowAnalysis` | Second field of one buffered CSV row — the `analysis` column of table,analysis,term,term_type,field,value | .row$ | public |
| `@emlGraphsIsPercentageColumn` | PERCENTAGE-COLUMN DETECTION @emlComputeAxisRange takes an .isPercentage argument and clamps the axis to 0-100 (or 0-1 for proportions) when it is raised — Rule ... | .tableId, .colName$ | public |
| `@emlGraphsColumnExtent` | The min and max of a numeric column, OVER THE DEFINED CELLS ONLY | .tableId, .colName$ | public |
| `@emlComposeGraphTitle` | DEFAULT FIGURE TITLE A BLANK TITLE FIELD GETS A COMPOSED TITLE, NOT NO TITLE (Rule 28A) | (none) | public |
| `@emlGraphsAxisPairRefusal` | THE ONE PLACE AN AXIS PAIR IS JUDGED. Takes an axis name and the pair the dialog returned for it, and decides one thing: whether the form may proceed | .axis$, .min, .max | public |
| `@emlGraphsShowAxisRefusal` | PUT THE ACCUMULATED REFUSAL ON SCREEN, one headline per refused pair followed by the two remedy sentences the whole set shares | (none) | public |
| `@emlGraphsCheckAxisRanges` | SWEEP EVERY AXIS PAIR THE DIALOGS CAN RETURN THROUGH THE ONE JUDGE ABOVE, and report how many were refused in emlGraphsAxisRefusalN | (none) | public |
| `@emlGraphsPitchRangeRefusal` | THE PITCH FLOOR/CEILING PAIR IS JUDGED HERE, ON ITS OWN. It is not an axis: it sets the search range the analysis algorithm hunts within, not a plot axis, and ... | .floor, .ceiling | public |
| `@emlGraphsShowPitchRefusal` | PUT THE ACCUMULATED REFUSAL ON SCREEN. Same shape as @emlGraphsShowAxisRefusal: one headline, then the remedy, one button, and nothing to choose | (none) | public |
| `@emlGraphsCheckPitchRange` | SWEEPS THE ONE PITCH PAIR THE PITCH CONTOUR PAGE CAN RETURN, WHEN IT EXISTS. The floor/ceiling row only renders — and only assigns pitch_floor and ... | (none) | public |
| `@emlGraphsPublishAxisRequest` | PUBLISH THE AXIS THE USER ASKED FOR, BEFORE ANYTHING IN THIS FILE RESOLVES IT. Sets two globals — emlGraphsAxisYReqMin and emlGraphsAxisYReqMax — from the ... | (none) | public |
| `@emlGraphsPublishSeriesPens` | HAND THE DRAWING LAYER THE PENS AND THE SECOND-AXIS REQUEST, from one place, on every press, for every type | (none) | public |
| `@emlGraphsResetSeriesPens` | AND TAKE THEM BACK AFTERWARDS. Called once the figure and its annotations are on the page, so that nothing this press asked for is still asking when some other ... | (none) | public |
| `@emlGraphsStampAxisRequest` | STAMP THE PUBLISHED PAIR WITH THE STEP IT IS FOR. Sets one global -- emlGraphsAxisYReqStep -- and does nothing else | (none) | public |
| `@emlGraphsPreDispatchHeadroom` | The PRE-DISPATCH (HEADROOM) stage of @emlGraphsWorkflow | (none) | public |
| `@emlGraphsDispatchDraw` | The DISPATCH (DRAW) block of @emlGraphsWorkflow, lifted out verbatim so it can be called more than once | (none) | public |
| `@emlGraphsDrawWithLegendRoom` | The DISPATCH (DRAW) stage of @emlGraphsWorkflow | (none) | public |
| `@emlLegendHeadroomAfterDraw` | Decide, after a figure has been drawn once, whether its legend needs the y-axis widened and by how much | .placement, .legendCorner$, .baseYMin, .baseYMax, .fontSize, .axisKind | public |
| `@emlGraphsPostDispatchAnnotations` | The POST-DISPATCH (ANNOTATE) stage of @emlGraphsWorkflow | (none) | public |
| `@emlGraphsWorkflow` | WORKFLOW — Main interactive graph creation loop WARNING: This procedure reads and writes main-body scope variables (objectId, nCols, colName$[], annotate, ... | .objectId | public |

## Scripts: Batch Processing
**File:** `scripts/eml-batch-process.praat` (v1.3) — 8 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlBuildDateStamp` | Procedures | (none) | public |
| `@emlCheckStopSentinel` | (see source header) | .sentinelPath$ | public |
| `@emlInitSentinel` | (see source header) | .sentinelPath$ | public |
| `@emlSentinelIsOurs` | →  .ours NEVER TRUNCATE SOMEONE ELSE'S FILE. @emlInitSentinel writes with writeFileLine:, which TRUNCATES. Until 14 August 2026 the sentinel path was ... | .path$ | public |
| `@emlResolveSentinelPath` | →  .path$, .displaced THE SAME WALK THE CSV ALREADY DOES (Rule 27, S9): try the wanted name, and on collision append _2, _3, … until a name is acceptable | .folder$ | public |
| `@emlWarnNearRangeEnd` | →  .fired ONE PROCEDURE FOR ALL THREE BOUNDED RANGES, and the reason is arithmetic rather than tidiness | .lo, .hi, .floor, .ceiling, .what$ | public |
| `@emlAppendFailureRow` | A FILE THAT CANNOT BE ANALYSED IS A ROW, NOT AN ABSENCE. Until 14 August 2026 this script had no containment of any kind: `Read from file:` was unguarded, so ... | .table, .row, .stem$, .why$ | public |
| `@emlEnsureOutputFolder` | →  .writable THE FOLDER IS MADE, NOT ASSUMED — the same reasoning as @emlSavePanel in stats/eml-output.praat (14 Aug 2026): `folder:` is a freely editable text ... | .folder$, .probePath$ | public |

## Vibrato
**File:** `vibrato/eml-vibrato-procedures.praat` (v2.0) — 16 procedures

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlVibratoScanTextGrid` | Scan tier 1 of a TextGrid for non-empty intervals | .textGridId, .tierNum | public |
| `@emlVibratoSelectIntervals` | Present checkbox dialog for interval selection | (none) | public |
| `@emlVibratoAxisRange` | Compute axis bounds with nice-number rounding, centered on median | .min, .max, .median, .nDivisions, .allowNegative, .expand | public |
| `@emlVibratoAutoFilename` | Generate a timestamped filename | .baseName$, .suffix$, .extension$ | public |
| `@emlVibratoPitchSetup` | From a mono Sound, create Pitch, smoothed Pitch, and audio PointProcess | .soundId, .lowPitch, .highPitch, .interpolate | public |
| `@emlVibratoDetectCycles` | Detect vibrato peaks and troughs using a hybrid approach: Timing: frame-walk on smoothed Pitch with parabolic interpolation Hz: 3-period average from audio ... | .pitchSmoothId, .ppAudioId, .intensityId, .avgIntensity, .silThreshold | public |
| `@emlVibratoInsertHalfCycles` | Expand table with interleaved 0.5 rows | .tableId | public |
| `@emlVibratoSmooth` | Pairwise averaging with continuity tracking, rolling window smoothing, and CoV time series | .tableId, .avgCycles, .lowRate, .highRate | public |
| `@emlVibratoFilter` | Split table into included/excluded sub-tables by credibility thresholds | .tableId, .lowRate, .highRate, .lowExtent, .highExtent | public |
| `@emlVibratoJitter` | Compute vibrato regularity measures from peak-time PointProcess | .tableId, .lowRate, .highRate, .startTime, .endTime | public |
| `@emlVibratoSummary` | Compute aggregate statistics across included data | .includeId, .smoothIncludeId, .pitchId, .intensityId | public |
| `@emlVibratoDrawDualScatter` | Draws a dual-axis scatter panel: left Y data + right Y data in one viewport | .includeId, .excludeId, .xCol$, .xMin, .xMax, .leftYCol$, .leftYMin, .leftYMax, .rightYCol$, .rightYMin, .rightYMax, .title$, .subtitle$, .leftLabel$, .rightLabel$, .xLabel$, .showGrey, .showBottom | public |
| `@emlVibratoDrawCoV` | Draws the Coefficient of Variation time-series panel | .tableId, .startTime, .endTime | public |
| `@emlVibratoDrawPitchIntensity` | Draws dual-axis pitch contour + intensity curve with cycle overlay markers | .pitchSmoothId, .intensityId, .includeId, .startTime, .endTime, .pitchSTMin, .pitchSTMax, .intMin, .intMax | public |
| `@emlVibratoDrawSummaryTable` | Renders the averaged measures summary table in the Picture window | .vpLeft, .vpRight, .vpTop, .vpBottom | public |
| `@emlVibratoDrawFigure` | Master procedure: draws the full 8-panel vibrato figure | .smoothedTableId, .includeId, .excludeId, .smoothIncludeId, .smoothExcludeId, .pitchSmoothId, .intensityId, .title$, .avgCycles, .lowRate, .highRate, .lowExtent, .highExtent, .showGrey | public |

## EGG: Electroglottogram
**File:** `egg/eml-egg-procedures.praat` (v1.1) — 1 procedure

| Procedure | Purpose | Parameters | Scope |
|-----------|---------|------------|-------|
| `@emlEggCycleGuard` | (see source header) | .eggId, .floor, .ceiling | public |

---
**Total: 632 procedures** (551 public, 81 internal) across 22 files.

**Withdrawn at 1.1:** `@emlEggSpectralThreshold`. Untested on real material — every figure behind it came from synthetic additive white Gaussian noise. Not distributed; do not reconstruct it. See `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` §4.

All entries above are backed by source shipped in the PKB.

**Removed at 14.1.0:** the Demo-window layout-helper library (`eml-demo-procedures`, 31 procedures). It was never the source of truth for driving the Demo window — `COMMANDS_DemoWindow.txt` and `BEST_PRACTICES_DEMO_WINDOW.md` are, and neither depends on it. It was a convenience wrapper around documented `demo` commands, dated April 2026, of uncertain current quality, and its source could not be reconciled. Write Demo layout from the documented commands instead.

**Deliberately NOT in the PKB:** `stats/eml-lmm.praat` (linear mixed models, excluded by author ruling) and its private numerical dependencies `stats/eml-linalg.praat` and `stats/eml-optimizer.praat`, and `@emlDrawLMMForest`, the one procedure in `graphs/eml-draw-procedures.praat` that reads them. Also not in the PKB: `scripts/eml-wizard.praat`, `stats/eml-demo-tables.praat`, `graphs/eml-draw-qq.praat`, the test helpers (`eml-test-helpers`) and the menu wrapper scripts.
