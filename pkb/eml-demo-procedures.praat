# ============================================================================
# EML Demo Window Procedures — Layout Engine
# ============================================================================
# Reusable procedures for building interactive Demo window applications
# in Praat. Provides typography placement, text wrapping, navigation,
# and page layout infrastructure for the Demo window canvas.
#
# Part of plugin_EMLTools.
# Location: plugin_EMLTools/tutorial/eml-demo-procedures.praat
#
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# Version: 1.2
# Date: 2 April 2026
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Provides:
#   Core:  @emlResetSans, @emlClearPage, @emlAccentLine, @emlGuideTick,
#          @emlDrawGuides, @emlWrapText, @emlDrawNav, @emlDrawImage
#   Place: @emlPlaceHero, @emlPlaceTitle, @emlPlaceHeading,
#          @emlPlaceHeadingAt, @emlPlaceSubhead, @emlPlacePartLabel,
#          @emlPlaceModuleNum, @emlPlaceAccent, @emlPlaceTextAccent,
#          @emlPlaceBody,
#          @emlPlaceBodyLine, @emlPlaceCodeLine, @emlPlaceBullet,
#          @emlPlaceCaption,
#          @emlPlaceModuleListItem, @emlPlaceOption,
#          @emlPlaceTreeBranch, @emlPlaceTreeSub, @emlPlaceTreeLeaf
#   Data:  @emlDemoDrawDot, @emlDemoDrawLine, @emlDemoDrawHRule
#   Image: @emlDemoShowFigure
#
# Dependencies: Calling script must set these globals before use:
#   Typography: bodySize, captionSize, subheadSize, headingSize,
#               titleSize, heroSize, numSize, codeSize,
#               lineHeightFactor, ambientSize, sans$, serif$, mono$
#   Steps:      heroStep, titleStep, headingStep, subheadStep,
#               captionStep, bodyLineH, codeLineH, bulletStep, stepRatio,
#               clearanceRatio
#   Grid:       zProgressBottom, zProgressTop, zPageCounterY,
#               zContentTop, zContentBottom, zNavTop, zNavY,
#               topPad, mL, mR, mB, colLEnd, colR, accentLen,
#               accentWeight
#   Palette:    bg$, ink$, text$, light$, faint$, accent$,
#               accentPale$, warmGray$, embossShadow$, progressBg$,
#               progressFill$, arrowColor$
#   Dev:        showGrid (0 or 1)
#   Grid dev:   gridColor$, tickColor$ (only needed if showGrid = 1)
#   Data:       groupA$, groupB$, groupC$ (Okabe-Ito group colors)
#               meanLine$, medianLine$, annotGray$ (annotation colors)
# ============================================================================

# ============================================================================
# CORE PROCEDURES
# ============================================================================

procedure emlResetSans
    demo Helvetica
    demo Font size: ambientSize
    demo Axes: 0, 100, 0, 100
endproc

procedure emlClearPage
    @emlResetSans
    demo Paint rectangle: bg$, -10, 110, -10, 110
endproc

procedure emlAccentLine: .x, .y
    demo Colour: accent$
    demo Line width: accentWeight
    demo Draw line: .x, .y, .x + accentLen, .y
    demo Line width: 1
endproc

procedure emlGuideTick: .y
    if showGrid
        demo Colour: tickColor$
        demo Line width: 0.5
        demo Draw line: 0, .y, 4, .y
        demo Line width: 1
    endif
endproc

procedure emlDrawGuides
    if showGrid = 0
        goto GUIDES_DONE
    endif
    demo Colour: gridColor$
    demo Line width: 0.5
    demo Draw line: 0, zProgressBottom, 100, zProgressBottom
    demo Draw line: 0, zContentTop, 100, zContentTop
    demo Draw line: 0, zContentBottom, 100, zContentBottom
    demo Draw line: 0, zNavTop, 100, zNavTop
    demo Draw line: mL, zContentBottom, mL, zContentTop
    demo Draw line: mR, zContentBottom, mR, zContentTop
    demo Draw line: mB, zContentBottom, mB, zContentTop
    demo Colour: "{0.85, 0.90, 0.96}"
    demo Draw line: colLEnd, zContentBottom, colLEnd, zContentTop
    demo Draw line: colR, zContentBottom, colR, zContentTop
    demo Line width: 1
    label GUIDES_DONE
endproc

procedure emlWrapText: .x1, .x2, .yTop, .yBottom, .align$, .font$, .text$
    if .font$ = "Times"
        demo Times
    else
        demo Helvetica
    endif
    .lineH = bodyLineH
    .availW = .x2 - .x1
    .currentY = .yTop
    .remaining$ = .text$
    .currentLine$ = ""
    while .remaining$ <> ""
        if .currentY - .lineH < .yBottom
            goto WRAP_END
        endif
        .spacePos = index (.remaining$, " ")
        if .spacePos = 0
            .word$ = .remaining$
            .remaining$ = ""
        else
            .word$ = left$ (.remaining$, .spacePos - 1)
            .remaining$ = mid$ (.remaining$, .spacePos + 1,
            ... length (.remaining$) - .spacePos)
        endif
        if .currentLine$ = ""
            .testLine$ = .word$
        else
            .testLine$ = .currentLine$ + " " + .word$
        endif
        .testW = demo Text width (world coordinates): .testLine$
        if .testW > .availW and .currentLine$ <> ""
            if .align$ = "left"
                demo Text special: .x1, "left", .currentY, "top",
                ... .font$, bodySize, "0", .currentLine$
            elsif .align$ = "centre"
                .cx = (.x1 + .x2) / 2
                demo Text special: .cx, "centre", .currentY, "top",
                ... .font$, bodySize, "0", .currentLine$
            else
                demo Text special: .x2, "right", .currentY, "top",
                ... .font$, bodySize, "0", .currentLine$
            endif
            .currentY = .currentY - .lineH
            .currentLine$ = .word$
        else
            .currentLine$ = .testLine$
        endif
    endwhile
    if .currentLine$ <> "" and .currentY - .lineH >= .yBottom
        if .align$ = "left"
            demo Text special: .x1, "left", .currentY, "top",
            ... .font$, bodySize, "0", .currentLine$
        elsif .align$ = "centre"
            .cx = (.x1 + .x2) / 2
            demo Text special: .cx, "centre", .currentY, "top",
            ... .font$, bodySize, "0", .currentLine$
        else
            demo Text special: .x2, "right", .currentY, "top",
            ... .font$, bodySize, "0", .currentLine$
        endif
    endif
    label WRAP_END
    demo Helvetica
endproc

# ============================================================================
# NAVIGATION
# ============================================================================
procedure emlDrawNav: .pageNum, .totalPages, .showBack
    demo Paint rectangle: progressBg$, 0, 100, zProgressBottom, zProgressTop
    .fillW = (.pageNum / .totalPages) * 100
    if .fillW > 0
        demo Paint rectangle: progressFill$, 0, .fillW,
        ... zProgressBottom, zProgressTop
    endif
    demo Colour: arrowColor$
    demo Text special: mR, "right", zNavY, "half",
    ... sans$, titleSize, "0", "→"
    if .showBack
        demo Text special: mL, "left", zNavY, "half",
        ... sans$, titleSize, "0", "←"
    endif
    demo Colour: light$
    demo Text special: 50, "centre", zNavY, "half",
    ... sans$, captionSize, "0", "Press Q to quit"
    .str$ = string$ (.pageNum) + " / " + string$ (.totalPages)
    demo Text special: mR, "right", zPageCounterY, "half",
    ... sans$, captionSize, "0", .str$
endproc

procedure emlDrawImage: .x1, .x2, .y1, .y2, .label$
    demo Paint rectangle: warmGray$, .x1, .x2, .y1, .y2
    demo Colour: light$
    .cx = (.x1 + .x2) / 2
    .cy = (.y1 + .y2) / 2
    demo Text special: .cx, "centre", .cy, "half",
    ... sans$, captionSize, "0", .label$
endproc

# ============================================================================
# PLACEMENT PROCEDURES
# ============================================================================
# Each encodes one typographic role. Returns .nextY for element chaining.

procedure emlPlaceHero: .y, .text$
    demo Colour: ink$
    demo Text special: mL, "left", .y, "top",
    ... sans$, heroSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - heroStep
endproc

procedure emlPlaceTitle: .y, .text$
    demo Colour: ink$
    demo Text special: mL, "left", .y, "top",
    ... sans$, titleSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - titleStep
endproc

procedure emlPlaceHeading: .y, .text$
    demo Colour: ink$
    demo Text special: mL, "left", .y, "top",
    ... sans$, headingSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - headingStep
endproc

procedure emlPlaceHeadingAt: .y, .x, .text$
    demo Colour: ink$
    demo Text special: .x, "left", .y, "top",
    ... sans$, headingSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - headingStep
endproc

procedure emlPlaceSubhead: .y, .text$
    demo Colour: ink$
    demo Text special: mB, "left", .y, "top",
    ... sans$, subheadSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - subheadStep
endproc

procedure emlPlacePartLabel: .y, .text$
    demo Colour: light$
    demo Text special: mL, "left", .y, "top",
    ... sans$, captionSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - captionStep
endproc

procedure emlPlaceModuleNum: .y, .text$
    demo Colour: embossShadow$
    demo Text special: mR + 1, "right", .y - 0.7, "top",
    ... sans$, numSize, "0", .text$
    demo Colour: faint$
    demo Text special: mR, "right", .y, "top",
    ... sans$, numSize, "0", .text$
endproc

procedure emlPlaceAccent: .y, .x, .ownerSize
    @emlAccentLine: .x, .y
    @emlGuideTick: .y
    .nextY = .y - .ownerSize * lineHeightFactor * clearanceRatio
endproc

procedure emlPlaceTextAccent: .y, .x, .size, .text$
    # Text with tight accent line below
    demo Colour: ink$
    demo Text special: .x, "left", .y, "top",
    ... sans$, .size, "0", .text$
    @emlGuideTick: .y
    # Accent line — tight below text (raw descent only)
    .accentY = .y - .size * lineHeightFactor
    @emlAccentLine: .x, .accentY
    # Generous clearance below accent for body text
    .nextY = .accentY - bodyLineH * stepRatio
endproc

procedure emlPlaceBody: .y, .x1, .x2, .color$, .text$
    demo Colour: .color$
    @emlWrapText: .x1, .x2, .y, zContentBottom, "left", serif$, .text$
    @emlGuideTick: .y
    .nextY = emlWrapText.currentY - bodyLineH * stepRatio
endproc

procedure emlPlaceBodyLine: .y, .text$
    demo Colour: text$
    demo Text special: mL, "left", .y, "top",
    ... serif$, bodySize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - bodyLineH
endproc

procedure emlPlaceCodeLine: .y, .x, .text$
    demo Colour: ink$
    demo Text special: .x, "left", .y, "top",
    ... mono$, codeSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - codeLineH * stepRatio
endproc

procedure emlPlaceBullet: .y, .x, .xEnd, .text$
    demo Paint circle: accent$, .x - 3, .y - 1.5, 0.5
    demo Colour: text$
    @emlWrapText: .x, .xEnd, .y, .y - bulletStep, "left", serif$, .text$
    @emlGuideTick: .y
    .nextY = .y - bulletStep
endproc

procedure emlPlaceCaption: .y, .x, .halign$, .text$
    demo Colour: light$
    demo Text special: .x, .halign$, .y, "top",
    ... sans$, captionSize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - captionStep
endproc

procedure emlPlaceModuleListItem: .y, .num$, .name$
    demo Colour: light$
    demo Text special: mB, "left", .y, "top",
    ... sans$, captionSize, "0", .num$
    demo Colour: text$
    demo Text special: mB + 5, "left", .y, "top",
    ... sans$, captionSize, "0", .name$
    .nextY = .y - captionStep
endproc

procedure emlPlaceOption: .y, .letter$, .label$
    demo Colour: accent$
    demo Text special: mB, "left", .y, "top",
    ... sans$, bodySize, "0", .letter$
    demo Colour: text$
    demo Text special: mB + 5, "left", .y, "top",
    ... sans$, bodySize, "0", .label$
    @emlGuideTick: .y
    .nextY = .y - subheadStep
endproc

procedure emlPlaceTreeBranch: .y, .x, .text$
    demo Paint circle: accent$, .x - 2, .y - 1.5, 0.5
    demo Colour: text$
    demo Text special: .x, "left", .y, "top",
    ... sans$, bodySize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - bodyLineH * stepRatio
endproc

procedure emlPlaceTreeSub: .y, .x, .text$
    demo Paint circle: faint$, .x - 2, .y - 1.5, 0.4
    demo Colour: text$
    demo Text special: .x, "left", .y, "top",
    ... sans$, bodySize, "0", .text$
    @emlGuideTick: .y
    .nextY = .y - bodyLineH * stepRatio
endproc

procedure emlPlaceTreeLeaf: .y, .x, .text$
    demo Colour: accent$
    demo Text special: .x, "left", .y, "top",
    ... sans$, bodySize, "0", .text$
    .nextY = .y - bodyLineH * stepRatio
endproc

# ============================================================================
# DATA VISUALIZATION
# ============================================================================
# Procedures for drawing data elements in the Demo window.
# Requires group color globals: groupA$, groupB$, groupC$ (etc.)
# and annotation colors: meanLine$, medianLine$, annotGray$.

procedure emlDemoDrawDot: .x, .y, .groupIndex, .radius
    # Draw a data point at demo coordinates.
    # .groupIndex: 1 = groupA$, 2 = groupB$, 3 = groupC$
    # .radius: in demo coordinate units (0.7 typical)
    if .groupIndex = 1
        .color$ = groupA$
    elsif .groupIndex = 2
        .color$ = groupB$
    elsif .groupIndex = 3
        .color$ = groupC$
    else
        .color$ = annotGray$
    endif
    demo Paint circle: .color$, .x, .y, .radius
endproc

procedure emlDemoDrawLine: .x1, .y1, .x2, .y2, .color$, .width
    # Draw a line in demo coordinates with specified color and width.
    # Restores line width to 1 afterward.
    demo Colour: .color$
    demo Line width: .width
    demo Draw line: .x1, .y1, .x2, .y2
    demo Line width: 1
endproc

procedure emlDemoDrawHRule: .y, .x1, .x2, .color$, .width
    # Draw a horizontal rule (e.g., mean line, median line).
    @emlDemoDrawLine: .x1, .y, .x2, .y, .color$, .width
endproc

# ============================================================================
# PRE-RENDERED FIGURE DISPLAY
# ============================================================================
# Display pre-rendered PNG figures in the Demo window. Figures are
# generated in the Picture window using EML Graphs procedures and
# saved as high-resolution PNGs. This procedure handles viewport
# setup, image insertion, and coordinate restoration.
#
# CRITICAL: demo Select inner viewport: uses 0-100 demo units with
# parameter order (left, right, BOTTOM, TOP) — Y-up, opposite of
# Picture window. demo Axes: must be restored after insertion.

procedure emlDemoShowFigure: .left, .right, .bottom, .top, .path$
    # Display a pre-rendered PNG in the specified demo region.
    # .left, .right: horizontal extent in demo units (0-100)
    # .bottom, .top: vertical extent in demo units (0-100, Y-up)
    # .path$: full path to PNG file
    if fileReadable (.path$)
        demo Select inner viewport: .left, .right, .bottom, .top
        demo Insert picture from file: .path$, 0, 0, 0, 0
        demo Select inner viewport: 0, 100, 0, 100
        demo Axes: 0, 100, 0, 100
    else
        # Fallback: draw placeholder rectangle
        @emlDrawImage: .left, .right, .bottom, .top,
        ... "[Image not found]"
    endif
endproc



