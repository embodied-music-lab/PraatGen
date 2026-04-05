# ============================================================================
# EML Praat Tools — Stats Wizard
# ============================================================================
# Purpose: Question-driven statistical analysis wizard. Routes research
#          questions to the appropriate test via chained dialogs, runs the
#          analysis, and reports results in the Info window.
#
#          Three layers of access (this script = Layer 1):
#            Layer 1 — Wizard: Question-driven entry for clinicians/students
#            Layer 2 — Direct tools: Named tests from EML Tools menu
#            Layer 3 — Scripting API: Include-file procedures for power users
#
# Date: 18 March 2026
# Version: 1.4
# Date: 3 April 2026
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# v1.4: Six @wizardRun* procedures converged to shared reporters —
#        wizardRunIndepT, wizardRunMWU → @emlReportTwoGroupComparison;
#        wizardRunAnova → @emlReportAnovaComparison (doTukey=0);
#        wizardRunKW → @emlReportKWComparison (doDunn=0);
#        wizardRunPearson, wizardRunSpearman → @emlReportCorrelationAnalysis.
#        Test execution retained, inline formatting deleted, CSV rows now
#        populated via shared reporters. Wizard post-hoc flow unchanged.
#        Latent bug fixed: wizardRunPearson and wizardRunSpearman were
#        calling correlation procedures without tails argument (would
#        trigger "tails must be 1 or 2" validation error). Now pass 2.
#        wizardRunPairedT and wizardRunWilcoxonSR also converged to new
#        @emlReportPairedComparison shared reporter. Fixes .wPlus/.wMinus
#        bug (correct output names are .tPlus/.tMinus).
#
# ATTRIBUTION
# Framework: EML Praat Assistant by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Acoustic analysis scripts were developed using the EML Praat
#    Assistant (Howell, Embodied Music Lab) with code generation
#    by Claude (Anthropic). All scripts were reviewed, tested,
#    and validated by [your name]."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat

# Graph includes (for Draw Figure offer)
include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
include ../graphs/eml-draw-procedures.praat

# ── Check Table or TableOfReal selection ──────────────────────────────────

nTables = numberOfSelected ("Table")
nToR = numberOfSelected ("TableOfReal")
hasTable = 0
tableId = 0
nCols = 0

if nTables = 1 and nToR = 0
    tableId = selected ("Table")
    tableName$ = selected$ ("Table")
    displayTable$ = replace$ (tableName$, "_", " ", 0)
    @emlTableColumnNames: tableId
    nCols = emlTableColumnNames.nCols
    if nCols < 2
        exitScript: "Table needs at least two columns."
    endif
    hasTable = 1
elsif nTables = 0 and nToR = 1
    # Convert TableOfReal → Table (row labels become string column)
    torId = selected ("TableOfReal")
    torName$ = selected$ ("TableOfReal")
    selectObject: torId
    To Table: "Group"
    tableId = selected ("Table")
    tableName$ = selected$ ("Table")
    displayTable$ = replace$ (torName$, "_", " ", 0)
    ... + " (converted)"
    @emlTableColumnNames: tableId
    nCols = emlTableColumnNames.nCols
    if nCols < 2
        exitScript: "Converted Table has fewer than 2 columns."
    endif
    hasTable = 1
    appendInfoLine: "Converted TableOfReal """, torName$,
    ... """ to Table. Row labels are in column ""Group""."
    appendInfoLine: ""
elsif nTables = 0 and nToR = 0
    # No selection — will offer example data later
    hasTable = 0
else
    exitScript: "Please select one Table, one TableOfReal, "
    ... + "or nothing (for example data)."
endif


# ###########################################################################
# MAIN WIZARD LOOP
# ###########################################################################

runAgain = 1
while runAgain = 1

wizCanDraw = 0
wizDrawSource$ = ""
wizTestType$ = "parametric"


# ═══════════════════════════════════════════════════════════════════════════
# Q1: RESEARCH GOAL
# ═══════════════════════════════════════════════════════════════════════════

beginPause: "EML Stats Wizard"
    if hasTable
        comment: "Table: " + displayTable$
    else
        comment: "No Table selected — example data will be "
        ... + "created when needed."
    endif
    comment: ""
    comment: "What is your research goal?"
    optionmenu: "Research goal", 1
        option: "Compare groups or conditions"
        option: "Examine a relationship between variables"
        option: "Describe or summarize data"
        option: "Predict an outcome"
        option: "Classify observations"
        option: "Reduce dimensionality / find structure"
clicked = endPause: "Quit", "Continue", 2, 0
if clicked = 1
    exitScript: "User quit."
endif
goal = research_goal


# ═══════════════════════════════════════════════════════════════════════════
# BRANCH A: COMPARE GROUPS OR CONDITIONS
# ═══════════════════════════════════════════════════════════════════════════

if goal = 1

    # ── A1: How many groups / factors? ────────────────────────────────────

    beginPause: "Compare — Design"
        comment: "What describes your comparison?"
        optionmenu: "Comparison type", 1
            option: "Two groups or conditions"
            option: "Three or more groups (one factor)"
            option: "Two-factor design (e.g., Treatment x Sex)"
    clicked = endPause: "Quit", "Continue", 2, 0
    if clicked = 1
        exitScript: "User quit."
    endif
    compType = comparison_type


    # ── A2: TWO GROUPS ────────────────────────────────────────────────────

    if compType = 1

        # ── A2: Independent or paired? ────────────────────────────────────

        beginPause: "Compare — Observation Type"
            comment: "Are the observations..."
            optionmenu: "Observation type", 1
                option: "Independent (different subjects)"
                option: "Paired / repeated (same subjects)"
        clicked = endPause: "Quit", "Continue", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif
        obsType = observation_type


        # ── A2a: TWO INDEPENDENT GROUPS ───────────────────────────────────

        if obsType = 1

            # ── Column picker ─────────────────────────────────────────────

            dataDefault = 1
            groupDefault = min (2, nCols)
            if hasTable = 0
                @wizardCreateExample: "groups"
                tableId = wizardCreateExample.tableId
                tableName$ = selected$ ("Table")
                displayTable$ = replace$ (tableName$, "_", " ", 0)
                @emlTableColumnNames: tableId
                nCols = emlTableColumnNames.nCols
                hasTable = 1
                dataDefault = wizardCreateExample.dataDefault
                groupDefault = wizardCreateExample.groupDefault
            endif

            beginPause: "Compare — Select Columns"
                comment: "Table: " + displayTable$
                optionmenu: "Data column", dataDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                optionmenu: "Group column", groupDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
            clicked = endPause: "Quit", "Continue", 2, 0
            if clicked = 1
                exitScript: "User quit."
            endif
            dataCol$ = data_column$
            groupCol$ = group_column$

            # ── Validate 2 groups ─────────────────────────────────────────

            selectObject: tableId
            @emlCountGroups: tableId, groupCol$
            if emlCountGroups.nGroups <> 2
                exitScript: "Expected 2 groups in """
                ... + groupCol$ + """, found "
                ... + string$ (emlCountGroups.nGroups)
                ... + ". Use ""Three or more groups"" for k-group "
                ... + "comparisons."
            endif
            group1$ = emlCountGroups.groupLabel$[1]
            group2$ = emlCountGroups.groupLabel$[2]

            # ── Extract group data ────────────────────────────────────────

            selectObject: tableId
            @emlExtractGroupVectors: tableId, dataCol$, groupCol$,
            ... group1$, group2$
            if emlExtractGroupVectors.error$ <> ""
                exitScript: emlExtractGroupVectors.error$
            endif
            g1# = emlExtractGroupVectors.group1#
            g2# = emlExtractGroupVectors.group2#
            n1 = emlExtractGroupVectors.n1
            n2 = emlExtractGroupVectors.n2

            if n1 < 2 or n2 < 2
                exitScript: "Each group needs at least 2 "
                ... + "observations. Group 1 has "
                ... + string$ (n1) + ", Group 2 has "
                ... + string$ (n2) + "."
            endif

            # ── Normality check ───────────────────────────────────────────

            selectObject: tableId
            @emlExtractColumn: tableId, dataCol$
            if emlExtractColumn.n < 3
                exitScript: "Column """ + dataCol$
                ... + """ has fewer than 3 valid values."
            endif
            normData# = emlExtractColumn.data#
            normLabel$ = dataCol$

            normalDefault = 1
            normalDone = 0
            while normalDone = 0
                beginPause: "Compare — Normality"
                    comment: "Can you assume the data are normally "
                    ... + "distributed?"
                    optionmenu: "Normality assumption", normalDefault
                        option: "Yes (or large N >= 30 per group)"
                        option: "No / unsure / small sample"
                        option: "Let me check"
                clicked = endPause: "Quit", "Continue", 2, 0
                if clicked = 1
                    exitScript: "User quit."
                endif
                if normality_assumption = 3
                    @wizardNormDiag: normData#, normLabel$
                    normalDefault = wizardNormDiag.recommendation
                    pauseScript: "Review the normality diagnostic "
                    ... + "in the Info window, then click OK."
                else
                    normalDone = 1
                endif
            endwhile
            isNormal = (normality_assumption = 1)

            # ── Dispatch ──────────────────────────────────────────────────

            if isNormal
                @wizardRunIndepT: g1#, g2#, group1$, group2$,
                ... dataCol$, groupCol$
                wizTestType$ = "parametric"
            else
                @wizardRunMWU: g1#, g2#, group1$, group2$,
                ... dataCol$, groupCol$
                wizTestType$ = "nonparametric"
            endif
            wizCanDraw = 1
            wizDrawSource$ = "group"


        # ── A2b: TWO PAIRED GROUPS ────────────────────────────────────────

        else

            # ── Paired column picker ──────────────────────────────────────

            col1Default = 1
            col2Default = min (2, nCols)
            if hasTable = 0
                @wizardCreateExample: "paired"
                tableId = wizardCreateExample.tableId
                tableName$ = selected$ ("Table")
                displayTable$ = replace$ (tableName$, "_", " ", 0)
                @emlTableColumnNames: tableId
                nCols = emlTableColumnNames.nCols
                hasTable = 1
                col1Default = wizardCreateExample.col1Default
                col2Default = wizardCreateExample.col2Default
            endif

            beginPause: "Compare — Select Paired Columns"
                comment: "Table: " + displayTable$
                comment: "Select the two measurement columns "
                ... + "(same subjects, different conditions)."
                optionmenu: "Column 1", col1Default
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                optionmenu: "Column 2", col2Default
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
            clicked = endPause: "Quit", "Continue", 2, 0
            if clicked = 1
                exitScript: "User quit."
            endif
            col1$ = column_1$
            col2$ = column_2$

            if col1$ = col2$
                exitScript: "Please select two different columns."
            endif

            # ── Extract paired data ───────────────────────────────────────

            selectObject: tableId
            @emlExtractPairedColumns: tableId, col1$, col2$
            if emlExtractPairedColumns.error$ <> ""
                exitScript: emlExtractPairedColumns.error$
            endif
            pair1# = emlExtractPairedColumns.data1#
            pair2# = emlExtractPairedColumns.data2#
            nPair = emlExtractPairedColumns.n

            if nPair < 3
                exitScript: "Need at least 3 complete pairs. "
                ... + "Found " + string$ (nPair) + "."
            endif

            # ── Normality of differences ──────────────────────────────────

            diffData# = pair1# - pair2#
            normLabel$ = col1$ + " minus " + col2$

            normalDefault = 1
            normalDone = 0
            while normalDone = 0
                beginPause: "Compare — Normality of Differences"
                    comment: "Can you assume the paired differences "
                    ... + "are normally distributed?"
                    optionmenu: "Normality assumption", normalDefault
                        option: "Yes (or large N >= 30)"
                        option: "No / unsure / small sample"
                        option: "Let me check"
                clicked = endPause: "Quit", "Continue", 2, 0
                if clicked = 1
                    exitScript: "User quit."
                endif
                if normality_assumption = 3
                    @wizardNormDiag: diffData#, normLabel$
                    normalDefault = wizardNormDiag.recommendation
                    pauseScript: "Review the normality diagnostic "
                    ... + "in the Info window, then click OK."
                else
                    normalDone = 1
                endif
            endwhile
            isNormal = (normality_assumption = 1)

            # ── Dispatch ──────────────────────────────────────────────────

            if isNormal
                @wizardRunPairedT: pair1#, pair2#, col1$, col2$
            else
                @wizardRunWilcoxonSR: pair1#, pair2#, col1$, col2$
            endif

        endif


    # ── A3: THREE OR MORE GROUPS (ONE FACTOR) ─────────────────────────────

    elsif compType = 2

        # ── Column picker ─────────────────────────────────────────────────

        dataDefault = 1
        groupDefault = min (2, nCols)
        if hasTable = 0
            @wizardCreateExample: "groups"
            tableId = wizardCreateExample.tableId
            tableName$ = selected$ ("Table")
            displayTable$ = replace$ (tableName$, "_", " ", 0)
            @emlTableColumnNames: tableId
            nCols = emlTableColumnNames.nCols
            hasTable = 1
            dataDefault = wizardCreateExample.dataDefault
            groupDefault = wizardCreateExample.groupDefault
        endif

        beginPause: "Compare k Groups — Select Columns"
            comment: "Table: " + displayTable$
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Group column", groupDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
        clicked = endPause: "Quit", "Continue", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif
        dataCol$ = data_column$
        groupCol$ = group_column$

        # ── Validate >= 3 groups ──────────────────────────────────────────

        selectObject: tableId
        @emlCountGroups: tableId, groupCol$
        if emlCountGroups.nGroups < 2
            exitScript: "Fewer than 2 groups found in """
            ... + groupCol$ + """."
        endif
        if emlCountGroups.nGroups = 2
            exitScript: "Only 2 groups found in """ + groupCol$
            ... + """. Use ""Two groups or conditions"" instead."
        endif

        # ── Normality check ───────────────────────────────────────────────

        selectObject: tableId
        @emlExtractColumn: tableId, dataCol$
        if emlExtractColumn.n < 3
            exitScript: "Column """ + dataCol$
            ... + """ has fewer than 3 valid values."
        endif
        normData# = emlExtractColumn.data#
        normLabel$ = dataCol$

        normalDefault = 1
        normalDone = 0
        while normalDone = 0
            beginPause: "Compare k Groups — Normality"
                comment: "Can you assume normality and "
                ... + "equal variances?"
                optionmenu: "Normality assumption", normalDefault
                    option: "Yes (or large N >= 30 per group)"
                    option: "No / unsure / small sample"
                    option: "Let me check"
            clicked = endPause: "Quit", "Continue", 2, 0
            if clicked = 1
                exitScript: "User quit."
            endif
            if normality_assumption = 3
                @wizardNormDiag: normData#, normLabel$
                normalDefault = wizardNormDiag.recommendation
                pauseScript: "Review the normality diagnostic "
                ... + "in the Info window, then click OK."
            else
                normalDone = 1
            endif
        endwhile
        isNormal = (normality_assumption = 1)

        # ── Dispatch: ANOVA or Kruskal-Wallis ─────────────────────────────

        if isNormal
            @wizardRunAnova: tableId, dataCol$, groupCol$
            wizCanDraw = 1
            wizDrawSource$ = "group"
            wizTestType$ = "parametric"
            anovaNGroups = emlOneWayAnova.nGroups
            anovaP = emlOneWayAnova.p

            # ── ANOVA post-hoc ────────────────────────────────────────────

            if anovaP < 0.05 and anovaNGroups >= 3
                beginPause: "ANOVA Post-Hoc Comparisons"
                    comment: "The omnibus ANOVA was significant."
                    comment: "Choose a post-hoc method:"
                    optionmenu: "Post hoc method", 1
                        option: "Tukey HSD (all pairwise)"
                        option: "Scheffe (all pairwise, conservative)"
                        option: "Pairwise t (Bonferroni)"
                        option: "Pairwise t (Holm)"
                        option: "Pairwise t (BH / FDR)"
                clicked = endPause: "Quit", "Skip", "Run", 3, 0
                if clicked = 1
                    exitScript: "User quit."
                endif

                if clicked = 3
                    phMethod = post_hoc_method
                    if phMethod = 1
                        @emlTukeyHSD: tableId, dataCol$,
                        ... groupCol$, 0.05
                        phNGroups = emlTukeyHSD.nGroups
                        phPMatrix## = emlTukeyHSD.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlTukeyHSD.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Tukey HSD"
                    elsif phMethod = 2
                        @emlScheffe: tableId, dataCol$, groupCol$
                        phNGroups = emlScheffe.nGroups
                        phPMatrix## = emlScheffe.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlScheffe.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Scheffe"
                    elsif phMethod = 3
                        @emlPairwiseT: tableId, dataCol$,
                        ... groupCol$, "bonferroni", "welch"
                        phNGroups = emlPairwiseT.nGroups
                        phPMatrix## = emlPairwiseT.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlPairwiseT.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Pairwise t (Bonferroni)"
                    elsif phMethod = 4
                        @emlPairwiseT: tableId, dataCol$,
                        ... groupCol$, "holm", "welch"
                        phNGroups = emlPairwiseT.nGroups
                        phPMatrix## = emlPairwiseT.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlPairwiseT.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Pairwise t (Holm)"
                    elsif phMethod = 5
                        @emlPairwiseT: tableId, dataCol$,
                        ... groupCol$, "bh", "welch"
                        phNGroups = emlPairwiseT.nGroups
                        phPMatrix## = emlPairwiseT.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlPairwiseT.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Pairwise t (BH)"
                    endif
                endif
            endif

        else
            # Kruskal-Wallis
            @wizardRunKW: tableId, dataCol$, groupCol$
            wizCanDraw = 1
            wizDrawSource$ = "group"
            wizTestType$ = "nonparametric"
            kwNGroups = emlKruskalWallis.nGroups
            kwP = emlKruskalWallis.p

            # ── KW post-hoc ───────────────────────────────────────────────

            if kwP < 0.05 and kwNGroups >= 3
                beginPause: "Kruskal-Wallis Post-Hoc Comparisons"
                    comment: "The omnibus test was significant."
                    comment: "Choose a post-hoc method:"
                    optionmenu: "Post hoc method", 1
                        option: "Dunn's test (Bonferroni)"
                        option: "Dunn's test (Holm)"
                        option: "Dunn's test (BH / FDR)"
                        option: "Pairwise Wilcoxon (Bonferroni)"
                        option: "Pairwise Wilcoxon (Holm)"
                clicked = endPause: "Quit", "Skip", "Run", 3, 0
                if clicked = 1
                    exitScript: "User quit."
                endif

                if clicked = 3
                    phMethod = post_hoc_method
                    if phMethod = 1
                        @emlDunnTest: tableId, dataCol$,
                        ... groupCol$, "bonferroni"
                        phNGroups = emlDunnTest.nGroups
                        phPMatrix## = emlDunnTest.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlDunnTest.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Dunn (Bonferroni)"
                    elsif phMethod = 2
                        @emlDunnTest: tableId, dataCol$,
                        ... groupCol$, "holm"
                        phNGroups = emlDunnTest.nGroups
                        phPMatrix## = emlDunnTest.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlDunnTest.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Dunn (Holm)"
                    elsif phMethod = 3
                        @emlDunnTest: tableId, dataCol$,
                        ... groupCol$, "bh"
                        phNGroups = emlDunnTest.nGroups
                        phPMatrix## = emlDunnTest.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlDunnTest.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Dunn (BH)"
                    elsif phMethod = 4
                        @emlPairwiseWilcoxon: tableId, dataCol$,
                        ... groupCol$, "bonferroni"
                        phNGroups = emlPairwiseWilcoxon.nGroups
                        phPMatrix## = emlPairwiseWilcoxon.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlPairwiseWilcoxon.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Pairwise Wilcoxon (Bonferroni)"
                    elsif phMethod = 5
                        @emlPairwiseWilcoxon: tableId, dataCol$,
                        ... groupCol$, "holm"
                        phNGroups = emlPairwiseWilcoxon.nGroups
                        phPMatrix## = emlPairwiseWilcoxon.pMatrix##
                        for iPH from 1 to phNGroups
                            phGroupName$[iPH] =
                            ... emlPairwiseWilcoxon.groupName$[iPH]
                        endfor
                        @wizardReportPairwise: phNGroups,
                        ... "Pairwise Wilcoxon (Holm)"
                    endif
                endif
            endif
        endif


    # ── A4: TWO-FACTOR DESIGN ─────────────────────────────────────────────

    elsif compType = 3

        dataDefault = 1
        f1Default = min (2, nCols)
        f2Default = min (3, nCols)
        if hasTable = 0
            @wizardCreateExample: "twofactor"
            tableId = wizardCreateExample.tableId
            tableName$ = selected$ ("Table")
            displayTable$ = replace$ (tableName$, "_", " ", 0)
            @emlTableColumnNames: tableId
            nCols = emlTableColumnNames.nCols
            hasTable = 1
            dataDefault = wizardCreateExample.dataDefault
            f1Default = wizardCreateExample.factor1Default
            f2Default = wizardCreateExample.factor2Default
        endif

        beginPause: "Two-Factor Design — Select Columns"
            comment: "Table: " + displayTable$
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Factor 1", f1Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Factor 2", f2Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
        clicked = endPause: "Quit", "Run", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif
        twDataCol$ = data_column$
        twFactor1$ = factor_1$
        twFactor2$ = factor_2$

        if twFactor1$ = twFactor2$
            exitScript: "Factor 1 and Factor 2 must be "
            ... + "different columns."
        endif

        @wizardRunTwoWay: tableId, twDataCol$, twFactor1$,
        ... twFactor2$

    endif


# ═══════════════════════════════════════════════════════════════════════════
# BRANCH B: EXAMINE A RELATIONSHIP
# ═══════════════════════════════════════════════════════════════════════════

elsif goal = 2

    # ── B1: Variable types ────────────────────────────────────────────────

    beginPause: "Relationship — Variable Types"
        comment: "What types of variables are you comparing?"
        optionmenu: "Variable types", 1
            option: "Both continuous"
            option: "Both categorical"
            option: "One continuous, one categorical"
    clicked = endPause: "Quit", "Continue", 2, 0
    if clicked = 1
        exitScript: "User quit."
    endif
    varTypes = variable_types

    if varTypes = 3
        # Redirect to Branch A
        appendInfoLine: "A continuous variable compared across "
        ... + "categories is a group comparison."
        appendInfoLine: "Re-run the wizard and choose ""Compare "
        ... + "groups or conditions""."
        pauseScript: "One continuous + one categorical = a group "
        ... + "comparison. Re-run and choose Branch A."

    elsif varTypes = 2
        # Chi-squared — stub
        @wizardStub: "Chi-squared test of independence",
        ... "Batch 10"

    else
        # Both continuous

        # ── Column picker ─────────────────────────────────────────────────

        col1Default = 1
        col2Default = min (2, nCols)
        if hasTable = 0
            @wizardCreateExample: "correlation"
            tableId = wizardCreateExample.tableId
            tableName$ = selected$ ("Table")
            displayTable$ = replace$ (tableName$, "_", " ", 0)
            @emlTableColumnNames: tableId
            nCols = emlTableColumnNames.nCols
            hasTable = 1
            col1Default = wizardCreateExample.col1Default
            col2Default = wizardCreateExample.col2Default
        endif

        beginPause: "Relationship — Select Columns"
            comment: "Table: " + displayTable$
            optionmenu: "Column 1", col1Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Column 2", col2Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
        clicked = endPause: "Quit", "Continue", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif
        corrCol1$ = column_1$
        corrCol2$ = column_2$

        if corrCol1$ = corrCol2$
            exitScript: "Please select two different columns."
        endif

        # ── B2: Strength or prediction? ───────────────────────────────────

        beginPause: "Relationship — Goal"
            comment: "What do you want to know?"
            optionmenu: "Relationship goal", 1
                option: "Strength and direction (correlation)"
                option: "Predict one from the other (regression)"
        clicked = endPause: "Quit", "Continue", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif
        relGoal = relationship_goal

        if relGoal = 2
            @wizardStub: "Linear regression", "Batch 11"
        else

            # ── Extract data ──────────────────────────────────────────────

            selectObject: tableId
            @emlExtractPairedColumns: tableId, corrCol1$, corrCol2$
            if emlExtractPairedColumns.error$ <> ""
                exitScript: emlExtractPairedColumns.error$
            endif
            corrX# = emlExtractPairedColumns.data1#
            corrY# = emlExtractPairedColumns.data2#
            corrN = emlExtractPairedColumns.n

            if corrN < 3
                exitScript: "Need at least 3 complete pairs "
                ... + "of values. Found " + string$ (corrN) + "."
            endif

            # ── Normality check ───────────────────────────────────────────

            normalDefault = 1
            normalDone = 0
            while normalDone = 0
                beginPause: "Correlation — Normality"
                    comment: "Can you assume linearity and "
                    ... + "bivariate normality?"
                    optionmenu: "Normality assumption", normalDefault
                        option: "Yes (Pearson r)"
                        option: "No / ordinal / ranks (Spearman rho)"
                        option: "Let me check"
                clicked = endPause: "Quit", "Continue", 2, 0
                if clicked = 1
                    exitScript: "User quit."
                endif
                if normality_assumption = 3
                    @wizardNormDiag: corrX#, corrCol1$
                    normalDefault = wizardNormDiag.recommendation
                    pauseScript: "Review the normality diagnostic "
                    ... + "in the Info window, then click OK."
                else
                    normalDone = 1
                endif
            endwhile

            # ── Dispatch ──────────────────────────────────────────────────

            if normality_assumption = 1
                @wizardRunPearson: corrX#, corrY#,
                ... corrCol1$, corrCol2$
            else
                @wizardRunSpearman: corrX#, corrY#,
                ... corrCol1$, corrCol2$
            endif
            wizCanDraw = 1
            wizDrawSource$ = "correlation"
        endif
    endif


# ═══════════════════════════════════════════════════════════════════════════
# BRANCH C: DESCRIBE OR SUMMARIZE
# ═══════════════════════════════════════════════════════════════════════════

elsif goal = 3

    beginPause: "Describe — What to Summarize"
        comment: "What do you want to describe?"
        optionmenu: "Describe goal", 1
            option: "Distribution of a single variable"
            option: "Compare distributions across groups"
            option: "Check normality"
    clicked = endPause: "Quit", "Continue", 2, 0
    if clicked = 1
        exitScript: "User quit."
    endif
    descGoal = describe_goal

    if descGoal = 1
        # ── Single variable ───────────────────────────────────────────────

        dataDefault = 1
        if hasTable = 0
            @wizardCreateExample: "describe"
            tableId = wizardCreateExample.tableId
            tableName$ = selected$ ("Table")
            displayTable$ = replace$ (tableName$, "_", " ", 0)
            @emlTableColumnNames: tableId
            nCols = emlTableColumnNames.nCols
            hasTable = 1
            dataDefault = wizardCreateExample.dataDefault
        endif

        beginPause: "Describe — Select Column"
            comment: "Table: " + displayTable$
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
        clicked = endPause: "Quit", "Run", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif

        selectObject: tableId
        @emlExtractColumn: tableId, data_column$
        if emlExtractColumn.n < 1
            exitScript: "Column """ + data_column$
            ... + """ has no valid numeric values."
        endif
        @wizardRunDescribe: emlExtractColumn.data#, data_column$

    elsif descGoal = 2
        # ── By group ──────────────────────────────────────────────────────

        dataDefault = 1
        groupDefault = min (2, nCols)
        if hasTable = 0
            @wizardCreateExample: "groups"
            tableId = wizardCreateExample.tableId
            tableName$ = selected$ ("Table")
            displayTable$ = replace$ (tableName$, "_", " ", 0)
            @emlTableColumnNames: tableId
            nCols = emlTableColumnNames.nCols
            hasTable = 1
            dataDefault = wizardCreateExample.dataDefault
            groupDefault = wizardCreateExample.groupDefault
        endif

        beginPause: "Describe by Group — Select Columns"
            comment: "Table: " + displayTable$
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Group column", groupDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
        clicked = endPause: "Quit", "Run", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif

        @wizardRunDescribeByGroup: tableId, data_column$,
        ... group_column$

    else
        # ── Normality check ───────────────────────────────────────────────

        dataDefault = 1
        if hasTable = 0
            @wizardCreateExample: "describe"
            tableId = wizardCreateExample.tableId
            tableName$ = selected$ ("Table")
            displayTable$ = replace$ (tableName$, "_", " ", 0)
            @emlTableColumnNames: tableId
            nCols = emlTableColumnNames.nCols
            hasTable = 1
            dataDefault = wizardCreateExample.dataDefault
        endif

        beginPause: "Normality Check — Select Column"
            comment: "Table: " + displayTable$
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
        clicked = endPause: "Quit", "Run", 2, 0
        if clicked = 1
            exitScript: "User quit."
        endif

        selectObject: tableId
        @emlExtractColumn: tableId, data_column$
        if emlExtractColumn.n < 3
            exitScript: "Column """ + data_column$
            ... + """ has fewer than 3 valid values."
        endif
        @wizardNormDiag: emlExtractColumn.data#, data_column$
    endif


# ═══════════════════════════════════════════════════════════════════════════
# BRANCHES D, E, F: STUBS
# ═══════════════════════════════════════════════════════════════════════════

elsif goal = 4
    @wizardStub: "Prediction (regression, curve fitting)",
    ... "Batches 11-12"
elsif goal = 5
    @wizardStub: "Classification (discriminant analysis)",
    ... "Batch 13"
elsif goal = 6
    @wizardStub: "Dimensionality reduction (PCA, MDS)",
    ... "Batch 12"
endif


# ═══════════════════════════════════════════════════════════════════════════
# RE-RUN?
# ═══════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════
# WHAT NEXT?
# ═══════════════════════════════════════════════════════════════════════════

@emlCSVInit

label WIZ_WHAT_NEXT

if wizCanDraw
    beginPause: "Analysis Complete"
        comment: "Results are in the Info window."
    clicked = endPause: "Quit", "Export CSV", "Draw Figure", "New Analysis", 4, 0
    if clicked = 1
        runAgain = 0
        goto WIZ_LOOP_END
    elsif clicked = 2
        goto WIZ_EXPORT_CSV
    elsif clicked = 3
        goto WIZ_DRAW_FIGURE
    else
        runAgain = 1
        goto WIZ_LOOP_END
    endif
else
    beginPause: "Analysis Complete"
        comment: "Results are in the Info window."
    clicked = endPause: "Quit", "New Analysis", 2, 0
    if clicked = 1
        runAgain = 0
    else
        runAgain = 1
    endif
    goto WIZ_LOOP_END
endif

# ── CSV Export ────────────────────────────────────────────────────────────

label WIZ_EXPORT_CSV

beginPause: "Export Results"
    folder: "Output folder", defaultDirectory$
    word: "File name", tableName$ + "_results"
clicked = endPause: "Quit", "Save", 2, 0
if clicked = 1
    goto WIZ_WHAT_NEXT
endif
csvPath$ = output_folder$ + "/" + file_name$ + ".csv"
@emlExportStatsCSV: csvPath$
if emlExportStatsCSV.success
    beginPause: "Export Complete"
        comment: "Saved to: " + emlExportStatsCSV.actualPath$
    endPause: "OK", 1, 0
else
    beginPause: "Export Failed"
        comment: "Could not write CSV file."
    endPause: "OK", 1, 0
endif
goto WIZ_WHAT_NEXT

# ═══════════════════════════════════════════════════════════════════════════
# DRAW FIGURE
# ═══════════════════════════════════════════════════════════════════════════

label WIZ_DRAW_FIGURE

prev_wizDrawTitle$ = ""
prev_wizDrawSubtitle$ = ""
prev_wizDrawColorMode = 1
prev_wizDrawGridMode = 1

label WIZ_DRAW_LOOP

if wizDrawSource$ = "group"
    # Group comparison draw dialog
    @emlCapitalizeLabel: groupCol$
    defaultXLabel$ = emlCapitalizeLabel.result$
    @emlCapitalizeLabel: dataCol$
    defaultYLabel$ = emlCapitalizeLabel.result$

    beginPause: "Draw Figure"
        optionmenu: "Graph type", 1
            option: "Violin Plot"
            option: "Box Plot"
            option: "Bar Chart"
            option: "Histogram"
        comment: "Data: " + dataCol$ + "    Group: " + groupCol$
        optionmenu: "Significance style", 1
            option: "p-value"
            option: "stars"
            option: "both"
        boolean: "Show nonsignificant", 0
        boolean: "Show effect sizes", 1
        optionmenu: "Color mode", prev_wizDrawColorMode
            option: "Color"
            option: "Black and white"
        real: "Value minimum (0 = auto)", "0"
        real: "Value maximum (0 = auto)", "0"
        optionmenu: "Gridline mode", prev_wizDrawGridMode
            option: "On"
            option: "Off"
            option: "Horizontal only"
        sentence: "X axis label", ""
        sentence: "Y axis label", ""
        sentence: "Title", prev_wizDrawTitle$
        sentence: "Subtitle", prev_wizDrawSubtitle$
    clicked = endPause: "Back", "Draw", 2, 0
    if clicked = 1
        goto WIZ_WHAT_NEXT
    endif

    prev_wizDrawTitle$ = title$
    prev_wizDrawSubtitle$ = subtitle$
    prev_wizDrawColorMode = color_mode
    prev_wizDrawGridMode = gridline_mode
    emlSubtitle$ = subtitle$
    drawStyle$ = significance_style$
    drawShowNS = show_nonsignificant
    drawShowEffect = show_effect_sizes
    if color_mode = 1
        drawColorMode$ = "color"
    else
        drawColorMode$ = "bw"
    endif
    drawVMin = value_minimum
    drawVMax = value_maximum
    drawGridMode = gridline_mode
    drawXLabel$ = x_axis_label$
    drawYLabel$ = y_axis_label$
    drawTitle$ = title$
    if drawXLabel$ = ""
        drawXLabel$ = defaultXLabel$
    endif
    if drawYLabel$ = ""
        drawYLabel$ = defaultYLabel$
    endif
    if drawTitle$ = ""
        drawTitle$ = "Title"
    endif

    drawW = 6
    drawH = 4
    Erase all
    Select inner viewport: 0, drawW, 0, drawH

    @emlClearAnnotations
    @emlBridgeGroupComparison: tableId, dataCol$, groupCol$, 0.05, drawStyle$, drawShowNS, drawShowEffect, wizTestType$, 2
    if emlBridgeGroupComparison.error$ <> ""
        appendInfoLine: "NOTE: Annotation skipped — " + emlBridgeGroupComparison.error$
    endif

    if emlBridgeGroupComparison.error$ = "" and annotBracketN > 0
        @emlSetAdaptiveTheme: drawW, drawH
        if drawVMin = 0 and drawVMax = 0
            selectObject: tableId
            tmpDataMin = Get minimum: dataCol$
            tmpDataMax = Get maximum: dataCol$
            @emlComputeAxisRange: tmpDataMin, tmpDataMax, 10, 0
            drawVMin = emlComputeAxisRange.axisMin
            drawVMax = emlComputeAxisRange.axisMax
        endif
        annotYRange = drawVMax - drawVMin
        dataYMax_forAnnotation = drawVMax
        drawVMax = drawVMax + annotBracketN * annotYRange * 0.08 + annotYRange * 0.05
    endif

    drawGraphType = graph_type
    if drawGraphType = 1
        @emlDrawViolinPlot: tableId, drawTitle$, drawXLabel$, drawYLabel$, drawW, drawH, drawColorMode$, drawGridMode, groupCol$, dataCol$, drawVMin, drawVMax
    elsif drawGraphType = 2
        @emlDrawBoxPlot: tableId, drawTitle$, drawXLabel$, drawYLabel$, drawW, drawH, drawColorMode$, drawGridMode, groupCol$, dataCol$, drawVMin, drawVMax
    elsif drawGraphType = 3
        @emlDrawBarChart: tableId, drawTitle$, drawXLabel$, drawYLabel$, drawW, drawH, drawColorMode$, drawGridMode, groupCol$, dataCol$, "", drawVMin, drawVMax
    elsif drawGraphType = 4
        @emlDrawHistogram: tableId, drawTitle$, drawXLabel$, drawYLabel$, drawW, drawH, drawColorMode$, drawGridMode, dataCol$, groupCol$, 0, 1, drawVMin, drawVMax, 0
    endif

    if emlBridgeGroupComparison.error$ = "" and annotBracketN > 0
        @emlDrawAnnotations: drawVMin, drawVMax, dataYMax_forAnnotation, annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize
    endif

elsif wizDrawSource$ = "correlation"
    # Scatter plot draw dialog
    @emlCapitalizeLabel: corrCol1$
    defaultXLabel$ = emlCapitalizeLabel.result$
    @emlCapitalizeLabel: corrCol2$
    defaultYLabel$ = emlCapitalizeLabel.result$

    beginPause: "Draw Scatter Plot"
        comment: "X: " + corrCol1$ + "    Y: " + corrCol2$
        optionmenu: "Color mode", prev_wizDrawColorMode
            option: "Color"
            option: "Black and white"
        real: "X minimum (0 = auto)", "0"
        real: "X maximum (0 = auto)", "0"
        real: "Y minimum (0 = auto)", "0"
        real: "Y maximum (0 = auto)", "0"
        optionmenu: "Gridline mode", prev_wizDrawGridMode
            option: "On"
            option: "Off"
            option: "Horizontal only"
        sentence: "X axis label", ""
        sentence: "Y axis label", ""
        sentence: "Title", prev_wizDrawTitle$
        sentence: "Subtitle", prev_wizDrawSubtitle$
    clicked = endPause: "Back", "Draw", 2, 0
    if clicked = 1
        goto WIZ_WHAT_NEXT
    endif

    prev_wizDrawTitle$ = title$
    prev_wizDrawSubtitle$ = subtitle$
    prev_wizDrawColorMode = color_mode
    prev_wizDrawGridMode = gridline_mode
    emlSubtitle$ = subtitle$
    if color_mode = 1
        drawColorMode$ = "color"
    else
        drawColorMode$ = "bw"
    endif
    drawXLabel$ = x_axis_label$
    drawYLabel$ = y_axis_label$
    drawTitle$ = title$
    if drawXLabel$ = ""
        drawXLabel$ = defaultXLabel$
    endif
    if drawYLabel$ = ""
        drawYLabel$ = defaultYLabel$
    endif
    if drawTitle$ = ""
        drawTitle$ = "Title"
    endif

    scatterDotSize = 2
    scatterShowDots = 1
    scatterRegressionLine = 1
    scatterShowFormula = 0
    annotAlpha = 0.05
    annotStyle$ = "p-value"
    if normality_assumption = 2
        annotCorrType$ = "spearman"
    else
        annotCorrType$ = "pearson"
    endif

    drawW = 6
    drawH = 4
    Erase all
    Select inner viewport: 0, drawW, 0, drawH

    @emlClearAnnotations
    @emlDrawScatterPlot: tableId, drawTitle$, drawXLabel$, drawYLabel$, drawW, drawH, drawColorMode$, gridline_mode, corrCol1$, corrCol2$, "", x_minimum, x_maximum, y_minimum, y_maximum, 1
endif

# Post-draw
beginPause: "Figure drawn"
    comment: "What would you like to do next?"
clicked = endPause: "Quit", "Export CSV", "New Analysis", "Draw Another", 4, 0
if clicked = 1
    runAgain = 0
    goto WIZ_LOOP_END
elsif clicked = 2
    goto WIZ_EXPORT_CSV
elsif clicked = 3
    runAgain = 1
    goto WIZ_LOOP_END
elsif clicked = 4
    goto WIZ_DRAW_LOOP
endif

label WIZ_LOOP_END

endwhile


# ###########################################################################
# PROCEDURES
# ###########################################################################


# ============================================================================
# @wizardNormDiag — Normality diagnostic (skewness + kurtosis)
# ============================================================================

procedure wizardNormDiag: .data#, .label$
    .recommendation = 1
    @emlSkewness: .data#
    @emlKurtosis: .data#
    .sk = emlSkewness.result
    .ku = emlKurtosis.result
    .n = size (.data#)

    writeInfoLine: "── Normality Diagnostic ──"
    appendInfoLine: "Variable: ", .label$
    appendInfoLine: "N: ", .n
    appendInfoLine: "Skewness: ", fixed$ (.sk, 3)
    appendInfoLine: "Kurtosis: ", fixed$ (.ku, 3)
    appendInfoLine: ""

    if abs (.sk) < 1 and abs (.ku) < 3
        .recommendation = 1
        appendInfoLine: "Skewness and kurtosis are within typical "
        ... + "limits (|skew| < 1, |kurt| < 3)."
        appendInfoLine: "The normality assumption is likely "
        ... + "reasonable."
    else
        .recommendation = 2
        if abs (.sk) >= 1
            appendInfoLine: "Skewness (", fixed$ (.sk, 3),
            ... ") is outside typical limits."
        endif
        if abs (.ku) >= 3
            appendInfoLine: "Kurtosis (", fixed$ (.ku, 3),
            ... ") is outside typical limits."
        endif
        appendInfoLine: "Consider using a nonparametric test."
    endif
    appendInfoLine: ""
endproc


# ============================================================================
# @wizardRunIndepT — Welch t-test + Cohen's d
# ============================================================================

procedure wizardRunIndepT: .g1#, .g2#, .label1$, .label2$,
... .dataCol$, .groupCol$
    @emlTTest: .g1#, .g2#, 2, 0
    @emlCohenD: .g1#, .g2#

    @emlMean: .g1#
    .mean1 = emlMean.result
    @emlSD: .g1#
    .sd1 = emlSD.result
    @emlMedian: .g1#
    .med1 = emlMedian.result
    .n1 = size (.g1#)

    @emlMean: .g2#
    .mean2 = emlMean.result
    @emlSD: .g2#
    .sd2 = emlSD.result
    @emlMedian: .g2#
    .med2 = emlMedian.result
    .n2 = size (.g2#)

    @emlReportTwoGroupComparison: tableName$, .dataCol$, .groupCol$,
    ... .label1$, .label2$, .n1, .mean1, .sd1, .med1,
    ... .n2, .mean2, .sd2, .med2, "parametric"
endproc


# ============================================================================
# @wizardRunMWU — Mann-Whitney U + rank-biserial r
# ============================================================================

procedure wizardRunMWU: .g1#, .g2#, .label1$, .label2$,
... .dataCol$, .groupCol$
    @emlMannWhitneyU: .g1#, .g2#, 2
    @emlRankBiserialR: .g1#, .g2#, 2

    @emlMean: .g1#
    .mean1 = emlMean.result
    @emlSD: .g1#
    .sd1 = emlSD.result
    @emlMedian: .g1#
    .med1 = emlMedian.result
    .n1 = size (.g1#)

    @emlMean: .g2#
    .mean2 = emlMean.result
    @emlSD: .g2#
    .sd2 = emlSD.result
    @emlMedian: .g2#
    .med2 = emlMedian.result
    .n2 = size (.g2#)

    @emlReportTwoGroupComparison: tableName$, .dataCol$, .groupCol$,
    ... .label1$, .label2$, .n1, .mean1, .sd1, .med1,
    ... .n2, .mean2, .sd2, .med2, "nonparametric"
endproc


# ============================================================================
# @wizardRunPairedT — Paired t-test + matched-pairs r
# ============================================================================

procedure wizardRunPairedT: .v1#, .v2#, .col1$, .col2$
    @emlTTestPaired: .v1#, .v2#, 2
    @emlMatchedPairsR: .v1#, .v2#, 2

    .n = size (.v1#)
    @emlMean: .v1#
    .mean1 = emlMean.result
    @emlSD: .v1#
    .sd1 = emlSD.result
    @emlMedian: .v1#
    .med1 = emlMedian.result

    @emlMean: .v2#
    .mean2 = emlMean.result
    @emlSD: .v2#
    .sd2 = emlSD.result
    @emlMedian: .v2#
    .med2 = emlMedian.result

    @emlReportPairedComparison: tableName$, .col1$, .col2$, .n,
    ... .mean1, .sd1, .med1, .mean2, .sd2, .med2, "parametric"
endproc


# ============================================================================
# @wizardRunWilcoxonSR — Wilcoxon signed-rank + matched-pairs r
# ============================================================================

procedure wizardRunWilcoxonSR: .v1#, .v2#, .col1$, .col2$
    @emlWilcoxonSignedRank: .v1#, .v2#, 2
    @emlMatchedPairsR: .v1#, .v2#, 2

    .n = size (.v1#)
    @emlMean: .v1#
    .mean1 = emlMean.result
    @emlSD: .v1#
    .sd1 = emlSD.result
    @emlMedian: .v1#
    .med1 = emlMedian.result

    @emlMean: .v2#
    .mean2 = emlMean.result
    @emlSD: .v2#
    .sd2 = emlSD.result
    @emlMedian: .v2#
    .med2 = emlMedian.result

    @emlReportPairedComparison: tableName$, .col1$, .col2$, .n,
    ... .mean1, .sd1, .med1, .mean2, .sd2, .med2, "nonparametric"
endproc


# ============================================================================
# @wizardRunAnova — One-way ANOVA
# ============================================================================

procedure wizardRunAnova: .tableId, .dataCol$, .groupCol$
    @emlOneWayAnova: .tableId, .dataCol$, .groupCol$, 0
    if emlOneWayAnova.error$ <> ""
        exitScript: emlOneWayAnova.error$
    endif

    @emlReportAnovaComparison: tableName$, .dataCol$, .groupCol$,
    ... .tableId, emlOneWayAnova.nGroups, 0
endproc


# ============================================================================
# @wizardRunKW — Kruskal-Wallis + epsilon-squared
# ============================================================================

procedure wizardRunKW: .tableId, .dataCol$, .groupCol$
    @emlKruskalWallis: .tableId, .dataCol$, .groupCol$
    if emlKruskalWallis.error$ <> ""
        exitScript: emlKruskalWallis.error$
    endif

    @emlReportKWComparison: tableName$, .dataCol$, .groupCol$,
    ... emlKruskalWallis.nGroups, 0
endproc


# ============================================================================
# @wizardRunTwoWay — Two-way ANOVA
# ============================================================================

procedure wizardRunTwoWay: .tableId, .dataCol$, .factor1$, .factor2$
    @emlTwoWayAnova: .tableId, .dataCol$, .factor1$, .factor2$
    if emlTwoWayAnova.error$ <> ""
        exitScript: emlTwoWayAnova.error$
    endif

    @emlReportTwoWayAnova: tableName$, .dataCol$, .factor1$, .factor2$
endproc


# ============================================================================
# @wizardRunPearson — Pearson correlation
# ============================================================================

procedure wizardRunPearson: .x#, .y#, .col1$, .col2$
    @emlPearsonCorrelation: .x#, .y#, 2
    .n = size (.x#)

    @emlReportCorrelationAnalysis: tableName$, .col1$, .col2$,
    ... .n, "pearson"
endproc


# ============================================================================
# @wizardRunSpearman — Spearman correlation
# ============================================================================

procedure wizardRunSpearman: .x#, .y#, .col1$, .col2$
    @emlSpearmanCorrelation: .x#, .y#, 2
    .n = size (.x#)

    @emlReportCorrelationAnalysis: tableName$, .col1$, .col2$,
    ... .n, "spearman"
endproc


# ============================================================================
# @wizardRunDescribe — Full descriptive battery
# ============================================================================

procedure wizardRunDescribe: .data#, .col$
    @emlDescribe: .data#
    .dCol$ = replace$ (.col$, "_", " ", 0)

    @emlReportHeader: "Descriptive Statistics"
    @emlReportLineString: "Table", displayTable$
    @emlReportLineString: "Column", .dCol$
    @emlReportLine: "N", emlDescribe.n, 0
    @emlReportBlank

    @emlReportSection: "Central Tendency"
    @emlReportLine: "Mean", emlDescribe.mean, 4
    @emlReportLine: "Median", emlDescribe.median, 4
    @emlReportLine: "95% CI (mean)", emlDescribe.ci95Lower, 4
    appendInfoLine: "     to ", fixed$ (emlDescribe.ci95Upper, 4)

    @emlReportBlank
    @emlReportSection: "Dispersion"
    @emlReportLine: "SD", emlDescribe.sd, 4
    @emlReportLine: "Variance", emlDescribe.variance, 4
    @emlReportLine: "SEM", emlDescribe.sem, 4
    @emlReportLine: "IQR", emlDescribe.iqr, 4
    @emlReportLine: "Range", emlDescribe.range, 4
    @emlReportLine: "Min", emlDescribe.min, 4
    @emlReportLine: "Max", emlDescribe.max, 4

    @emlReportBlank
    @emlReportSection: "Shape"
    @emlReportLine: "Skewness", emlDescribe.skewness, 3
    @emlReportLine: "Kurtosis", emlDescribe.kurtosis, 3

    @emlReportFooter
endproc


# ============================================================================
# @wizardRunDescribeByGroup — Descriptives per group
# ============================================================================

procedure wizardRunDescribeByGroup: .tableId, .dataCol$, .groupCol$
    selectObject: .tableId
    @emlCountGroups: .tableId, .groupCol$
    .nG = emlCountGroups.nGroups

    .dData$ = replace$ (.dataCol$, "_", " ", 0)
    .dGrp$ = replace$ (.groupCol$, "_", " ", 0)

    @emlReportHeader: "Descriptive Statistics by Group"
    @emlReportLineString: "Table", displayTable$
    @emlReportLineString: "Data column", .dData$
    @emlReportLineString: "Group column", .dGrp$
    @emlReportLine: "Groups", .nG, 0
    @emlReportBlank

    @emlReportDescriptiveHeader

    @emlExtractMultipleGroups: .tableId, .dataCol$, .groupCol$
    if emlExtractMultipleGroups.error$ <> ""
        exitScript: emlExtractMultipleGroups.error$
    endif

    for .g from 1 to .nG
        @eml_getGroupData: .g
        .gLabel$ = replace$ (
        ... emlExtractMultipleGroups.groupLabel$[.g],
        ... "_", " ", 0)
        .gN = eml_getGroupData.n
        @emlMean: eml_getGroupData.data#
        .gMean = emlMean.result
        @emlSD: eml_getGroupData.data#
        .gSD = emlSD.result
        @emlMedian: eml_getGroupData.data#
        .gMed = emlMedian.result
        @emlReportDescriptiveRow: .gLabel$, .gN,
        ... .gMean, .gSD, .gMed
    endfor

    @emlReportFooter
endproc


# ============================================================================
# @wizardReportPairwise — Report pMatrix upper triangle
# ============================================================================
# Reads from main-body variables: phGroupName$[i], phPMatrix##

procedure wizardReportPairwise: .nGroups, .method$
    @emlReportBlank
    @emlReportSection: "Pairwise Comparisons (" + .method$ + ")"
    appendInfoLine: ""

    for .i from 1 to .nGroups
        for .j from .i + 1 to .nGroups
            @emlFormatP: phPMatrix##[.i, .j]
            .sigFlag$ = ""
            if phPMatrix##[.i, .j] < 0.001
                .sigFlag$ = " ***"
            elsif phPMatrix##[.i, .j] < 0.01
                .sigFlag$ = " **"
            elsif phPMatrix##[.i, .j] < 0.05
                .sigFlag$ = " *"
            endif
            .label$ = replace$ (phGroupName$[.i], "_", " ", 0)
            ... + " vs "
            ... + replace$ (phGroupName$[.j], "_", " ", 0)
            appendInfoLine: "  ", .label$, ": ",
            ... emlFormatP.formatted$, .sigFlag$
        endfor
    endfor
    appendInfoLine: ""
    appendInfoLine: "  Significance: * p < .05, ** p < .01, "
    ... + "*** p < .001"
endproc


# ============================================================================
# @wizardCreateExample — Create example data set for exploration
# ============================================================================

procedure wizardCreateExample: .hint$
    .tableId = 0
    .dataDefault = 1
    .groupDefault = 2
    .col1Default = 1
    .col2Default = 2
    .factor1Default = 2
    .factor2Default = 2

    if .hint$ = "twofactor"
        .defChoice = 2
    else
        .defChoice = 1
    endif

    beginPause: "Create Example Data"
        comment: "No Table is selected. Choose an example "
        ... + "data set to explore this analysis:"
        optionmenu: "Example data", .defChoice
            option: "Iris (4 measures, 3 species)"
            option: "Peterson and Barney 1952 (formants by "
            ... + "vowel and sex)"
    clicked = endPause: "Quit", "Create", 2, 0
    if clicked = 1
        exitScript: "User quit."
    endif

    if example_data = 1
        Create iris data set
        .torId = selected ("TableOfReal")
        To Table: "Species"
        .tableId = selected ("Table")
        removeObject: .torId
        # Iris columns after conversion:
        # Species(1), Sepal.Length(2), Sepal.Width(3),
        # Petal.Length(4), Petal.Width(5)
        .dataDefault = 2
        .groupDefault = 1
        .col1Default = 2
        .col2Default = 4
        .factor1Default = 1
        .factor2Default = 1
    else
        Create formant table (Peterson & Barney 1952)
        .tableId = selected ("Table")
        # P&B columns:
        # Type(1), Sex(2), Speaker(3), Vowel(4),
        # IPA(5), F0(6), F1(7), F2(8), F3(9)
        .dataDefault = 6
        .groupDefault = 4
        .col1Default = 6
        .col2Default = 7
        .factor1Default = 2
        .factor2Default = 4
    endif
endproc


# ============================================================================
# @wizardStub — Standard message for unimplemented terminals
# ============================================================================

procedure wizardStub: .analysis$, .batch$
    writeInfoLine: "── Not Yet Available ──"
    appendInfoLine: ""
    appendInfoLine: "  ", .analysis$, " is planned for a "
    ... + "future update (", .batch$, ")."
    appendInfoLine: ""
    appendInfoLine: "  In the meantime:"
    appendInfoLine: "  - Use the Layer 2 tools in the EML "
    ... + "Tools menu"
    appendInfoLine: "  - Export your Table to CSV and analyze "
    ... + "in R"
    appendInfoLine: ""
endproc
