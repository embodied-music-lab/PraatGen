BEST_PRACTICES_DEMO_WINDOW.txt
# Canonical patterns for Demo window applications
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Companion to COMMANDS_DemoWindow.txt (which documents what exists).
# This file documents how to use it well.
#
# Source scripts (verified, working implementations):
#   - oscilloscope v6 (Ian Howell, Feb 2026)
#   - DFT Basis Function Demo v3.8.0 (Ian Howell / Claude, Mar 2026)
#   - EML Tutorial plugin media-procedures (Ian Howell / Claude, Feb 2026)
#   - EGG Analysis Plugin v3.2 (Ian Howell / Claude, Apr 2026)
#
# Co-load: COMMANDS_DemoWindow.txt (always), plus COMMANDS_*.txt for
#          object types being drawn.

# ============================================================================
# §1  THREE-LINE RESET
# ============================================================================
#
# Every drawing procedure and every animation frame must begin with
# these three lines, in this order:
#
#   demo Helvetica
#   demo Font size: 11
#   demo Axes: 0, 100, 0, 100
#
# WHY: Praat's Demo window retains font and coordinate state across
# procedure calls. If procedure A changes Font size to 8 for labels,
# procedure B will inherit that size — affecting not just text but
# also the margin calculations of Select outer viewport, Draw inner
# box, One mark, and all text-positioning commands.
#
# The three-line reset eliminates state contamination by establishing
# a known baseline. "Three-line reset" is the canonical name for
# this pattern throughout the EML codebase.
#
# The font size in the reset (11, or whatever the application's body
# size is) must match the value set once at startup via
# `demo Font size:`. See COMMANDS_DemoWindow.txt §5: set ambient font
# size ONCE, never change it. The three-line reset enforces this.
#
# Source: DFT v3.8 (every @drawP2Panel procedure), oscilloscope v6
# (implicit — Helvetica + Font size + Axes at frame top).

# ============================================================================
# §2  ANIMATION RENDERING: demo Erase all + FULL REDRAW
# ============================================================================
#
# For animation loops that redraw every frame (>10 fps), always use:
#
#   repeat
#       demo Erase all
#       # [draw entire scene from scratch]
#       demoShow ()
#   until [done]
#
# DO NOT use selective erasure (Paint rectangle over changed regions)
# for animation. Selective erasure adds drawing commands to the retained
# display list without removing old ones. Over 1000+ frames, this
# creates monotonic performance degradation — each frame takes longer
# than the last. The EGG plugin v3.0 hit this: an animation that
# started at 15 fps degraded to <1 fps over 1800 cycles.
#
# The flicker from demo Erase all is imperceptible at animation frame
# rates (>10 fps). It IS visible during slow page transitions — use
# selective repaint for those (see COMMANDS_DemoWindow.txt §12).
#
# ANTI-PATTERN — selective erasure in animation (causes snowball):
#
#   # WRONG — display list grows unbounded
#   repeat
#       demo Paint rectangle: bg$, 0, 100, panelBot, panelTop  # accumulates!
#       # [draw updated content]
#       demoShow ()
#   until [done]
#
# Source: oscilloscope v6 (line 369: `demo Erase all` per frame),
# DFT v3.8 (line 920: `demo Erase all` per frame),
# EGG plugin v3.1 (fixed after v3.0 snowball discovery).

# ============================================================================
# §3  AUDIO-SYNCED ANIMATION (STOPWATCH PATTERN)
# ============================================================================
#
# When animation should track audio playback, use the stopwatch
# function to accumulate elapsed time and advance the display to
# match. This handles variable frame rendering times: fast frames
# show more detail, slow frames skip ahead to stay in sync.
#
# CANONICAL PATTERN (abstracted from oscilloscope v6):
#
#   # Start audio
#   selectObject: soundId
#   asynchronous Play
#
#   # Animation loop
#   stopwatch                    # reset timer
#   totalElapsed = resumeElapsed # 0 for first play, >0 after resume
#   paused = 0
#
#   repeat
#       frameDelta = stopwatch
#       totalElapsed = totalElapsed + frameDelta
#       cursorTime = soundStart + totalElapsed
#       if cursorTime > soundEnd
#           cursorTime = soundEnd
#       endif
#
#       # [draw frame using cursorTime as position]
#
#       demo Erase all
#       # ... draw scene ...
#       demoShow ()
#
#       # [check for click-to-pause — see §8]
#
#   until totalElapsed >= duration or paused
#
# KEY DETAILS:
#   - `stopwatch` (no parentheses) returns elapsed time since last call
#     AND resets the timer. This is why it must be called at the TOP of
#     the loop (captures time spent drawing the previous frame).
#   - No sleep() needed — frame rendering time IS the delay.
#   - `asynchronous Play` lets the script continue during playback.
#     Available since Praat 5.3.79 (use appVersion() >= 5379 guard for
#     distributable scripts).
#   - For RESUME after pause: store totalElapsed as resumeElapsed,
#     extract remaining audio via Extract part:, play that portion.
#
# FRAME SKIPPING (from EGG plugin v3.2):
#
# When animation steps are discrete (e.g., per-cycle EGG viewer),
# advance the step index to match elapsed time:
#
#   repeat
#       totalElapsed = totalElapsed + stopwatch
#       # Catch up to current audio position
#       while iCurrent < nSteps and stepTime#[iCurrent] < totalElapsed
#           iCurrent = iCurrent + 1
#       endwhile
#       @drawFrame: iCurrent
#       demoShow ()
#   until iCurrent >= nSteps
#
# This prevents the animation from falling behind during complex frames.
#
# ALTERNATIVE — FRAME-BUDGET ANIMATION (not audio-synced):
# For animations that should take a fixed duration regardless of content
# (e.g., DFT frequency sweep), use adaptive batching:
#
#   binsPerFrame = ceiling (nTotalSteps / 150)   # target ~150 frames
#   sleepTime = 0.08
#   displayStep = 0
#   while displayStep < nTotalSteps
#       displayStep = min (displayStep + binsPerFrame, nTotalSteps)
#       demo Erase all
#       @drawFrame: displayStep
#       demoShow ()
#       sleep (sleepTime)
#   endwhile
#
# Source: DFT v3.8 (lines 904–942).

# ============================================================================
# §4  WAVEFORM DISPLAY VIA NATIVE demo Draw:
# ============================================================================
#
# ALWAYS use the Sound object's native `demo Draw:` command for
# waveform rendering. NEVER plot waveforms manually with hundreds of
# `demo Draw line:` segments or `Get value at time:` + `demo Draw line:`
# loops.
#
# Native demo Draw: is anti-aliased, resolution-independent, and
# renders in a single call regardless of sample count.
# Manual segments are jagged, slow, and scale with sample count.
#
# CANONICAL PATTERN (abstracted from oscilloscope v6):
#
#   selectObject: workId
#   demo Select outer viewport: 0, 100, scopeVpBot, scopeVpTop
#   demo Colour: waveCol$
#   demo Line width: 2
#   demo Draw: winL, winR, -ampBound, ampBound, "no", "Lines"
#
#   # CRITICAL: Restore coordinate system after viewport drawing
#   demo Select outer viewport: 0, 100, 0, 100
#   demo Axes: 0, 100, 0, 100
#
# PARAMETERS:
#   demo Draw: startTime, endTime, yMin, yMax, garnish$, drawingMethod$
#   - garnish$: always "no" (suppress built-in axis labels)
#   - drawingMethod$: "Curve" (smooth) or "Lines" (connected samples)
#   - yMin/yMax: use symmetric bounds (-ampBound, ampBound) for
#     centered display
#
# AMPLITUDE BOUNDS — always pre-compute:
#
#   selectObject: soundId
#   ampMax = Get maximum: startTime, endTime, "Sinc70"
#   ampMin = Get minimum: startTime, endTime, "Sinc70"
#   ampBound = max (abs (ampMax), abs (ampMin)) * 1.15
#   if ampBound = 0
#       ampBound = 1    # guard against silent segments
#   endif
#
# VIEWPORT RESTORATION IS MANDATORY:
# After any `demo Select outer viewport:` call, restore the full
# coordinate system before drawing anything else. Without this,
# subsequent text, rectangles, and click detection use the wrong
# coordinates.
#
# REUSABLE PROCEDURE (from DFT v3.8, lines 2145–2175):
#
#   procedure drawWaveformInDemo: .soundId, .x1, .y1, .x2, .y2,
#       ... .tStart, .tEnd, .colour$
#       # Three-line reset
#       demo Helvetica
#       demo Font size: 10
#       demo Axes: 0, 100, 0, 100
#
#       demo Select outer viewport: .x1, .x2, .y1, .y2
#
#       selectObject: .soundId
#       .ampMax = Get maximum: .tStart, .tEnd, "Sinc70"
#       .ampMin = Get minimum: .tStart, .tEnd, "Sinc70"
#       .ampBound = max (abs (.ampMax), abs (.ampMin)) * 1.15
#       if .ampBound = 0
#           .ampBound = 1
#       endif
#
#       demo Colour: .colour$
#       demo Line width: 1
#       selectObject: .soundId
#       demo Draw: .tStart, .tEnd, -.ampBound, .ampBound, "no", "Curve"
#
#       # Restore
#       demo Line width: 1
#       demo Colour: "Black"
#       demo Select outer viewport: 0, 100, 0, 100
#       demo Axes: 0, 100, 0, 100
#   endproc
#
# NOTE: Viewport parameters are in 0–100 demo units, NOT inches.
# Parameter order: (left, right, bottom, top) — Y-up. This differs
# from the Picture window's (left, right, top, bottom) — Y-down.

# ============================================================================
# §5  MATRIX-BUFFERED ANIMATION
# ============================================================================
#
# For animation that shows different waveform shapes each frame (per-cycle
# EGG views, evolving cosine overlays, DFT product waveforms), pre-compute
# sample values into a matrix, create display Sound objects once, and
# update them each frame via Formula:.
#
# This combines the efficiency of native demo Draw: (§4) with per-frame
# content changes. Total draw cost: O(1) per Sound per frame.
#
# PHASE 1 — PRE-COMPUTATION (before animation loop):
#
#   nFrames = [number of animation frames]
#   nSamplePoints = 100    # samples per normalized frame
#   waveforms## = zero## (nFrames, nSamplePoints)
#
#   for iFrame from 1 to nFrames
#       selectObject: sourceId
#       for iSamp from 1 to nSamplePoints
#           tNorm = (iSamp - 1) / (nSamplePoints - 1)
#           tQuery = tStart + tNorm * (tEnd - tStart)
#           waveforms##[iFrame, iSamp] = Get value at time: 0, tQuery,
#               ... "sinc70"
#       endfor
#   endfor
#
# IMPORTANT: Pre-computation involves nFrames × nSamplePoints queries.
# This is the expensive step — use noprogress on the source object's
# analysis commands, minimize selectObject: calls (move outside inner
# loop), and report progress to Info window.
#
# PHASE 2 — DISPLAY SOUND CREATION (once):
#
#   # Create a Sound with exactly nSamplePoints samples
#   sampleRate = nSamplePoints / displayDuration
#   displayId = Create Sound from formula: "display", 1, 0,
#       ... nSamplePoints / sampleRate, sampleRate, ~0
#
# PHASE 3 — PER-FRAME UPDATE (inside animation loop):
#
#   # Load this frame's waveform from the matrix into the display Sound
#   formulaRow = iCurrent    # MUST be a main-body variable (see below)
#   selectObject: displayId
#   Formula: ~waveforms##[formulaRow, col]
#
#   # Draw using native command
#   demo Select outer viewport: x1, x2, y1, y2
#   demo Draw: 0, displayDuration, -ampBound, ampBound, "no", "Curve"
#
#   # Restore
#   demo Select outer viewport: 0, 100, 0, 100
#   demo Axes: 0, 100, 0, 100
#
# SCOPING CONSTRAINT (hard):
# The matrix variable and row index referenced in Formula: must be
# accessible from the scope where Formula: executes. Formula: runs
# in the object's scope, not the calling procedure's scope.
#   - Global matrices and main-body index variables: ALWAYS work
#   - Procedure-local matrices (.m##) with local indices (.i): needs
#     verification — use a main-body variable for the row index if
#     uncertain. The DFT script and EGG plugin both pass the row
#     index via a main-body variable to avoid this ambiguity.
#
# DEGG MATRIX VIA CENTRAL DIFFERENCE (from EGG plugin v3.2):
# If you need both the signal and its derivative in the matrix, compute
# the derivative from the signal matrix — don't query the DEGG Sound:
#
#   dt = 1 / sampleRate
#   for iFrame from 1 to nFrames
#       deggMatrix##[iFrame, 1] = (waveforms##[iFrame, 2]
#           ... - waveforms##[iFrame, 1]) / dt
#       for iSamp from 2 to nSamplePoints - 1
#           deggMatrix##[iFrame, iSamp] = (waveforms##[iFrame, iSamp + 1]
#               ... - waveforms##[iFrame, iSamp - 1]) / (2 * dt)
#       endfor
#       deggMatrix##[iFrame, nSamplePoints] =
#           ... (waveforms##[iFrame, nSamplePoints]
#           ... - waveforms##[iFrame, nSamplePoints - 1]) / dt
#   endfor
#
# This eliminates 180,000 additional Sound queries (for 1800 frames ×
# 100 samples). The EGG plugin v3.0 did query the DEGG Sound and caused
# a multi-minute beachball; v3.2 uses central difference and is fast.
#
# MULTIPLE DISPLAY SOUNDS (from DFT v3.8):
# The DFT script creates separate display Sounds for cosine overlay
# and product waveform, each updated per-frame via Formula:.
# Create as many display Sounds as you have simultaneous waveforms.
#
# Source: DFT v3.8 (lines 881–888, cosine/product Sounds),
# EGG plugin v3.2 (cycleWaveforms##, displaySounds).

# ============================================================================
# §6  PERIOD-LOCKED / TRIGGER-LOCKED DISPLAY
# ============================================================================
#
# For oscilloscope-style waveform viewers where the display should appear
# stable (waveform stationary, not scrolling), lock the window position
# to detected periodicity.
#
# APPROACH A — PitchTier trigger (from oscilloscope v6):
#
#   # Pre-compute (once)
#   selectObject: soundId
#   ppId = To PointProcess (periodic, cc): 75, 500
#   selectObject: ppId
#   triggerTierId = Up to PitchTier: 100
#   removeObject: ppId
#
#   # Per-frame
#   selectObject: triggerTierId
#   nearIdx = Get nearest index from time: cursorTime
#   if nearIdx >= 1 and nearIdx <= nPulses
#       pulseTime = Get time from index: nearIdx
#       winL = pulseTime - triggerFraction * windowDuration
#       winR = winL + windowDuration
#   else
#       winL = cursorTime - windowDuration / 2
#       winR = cursorTime + windowDuration / 2
#   endif
#
# triggerFraction controls where the pulse appears in the window:
#   0.0 = pulse at left edge
#   0.2 = pulse at 20% from left (oscilloscope v6 default)
#   0.5 = pulse centered
#
# APPROACH B — Contact-centered matrix (from EGG plugin):
# Pre-compute waveform samples centered on a specific event
# (e.g., DEGG closing peak) at a fixed normalized position.
# See §5 for the matrix pattern; the key is centering the sampling
# window on the event rather than on the GCI start.
#
# Source: oscilloscope v6 (lines 82–109 pre-compute, 340–354 per-frame).

# ============================================================================
# §7  SESSION STATE MACHINE
# ============================================================================
#
# Interactive Demo window applications should use a state machine
# architecture with a string-valued state variable:
#
#   sessionState$ = "play"
#   while sessionState$ <> "quit"
#
#       if sessionState$ = "play"
#           # Start audio, run animation loop
#           # demoPeekInput + demoClicked for click-to-pause
#           # On pause: set sessionState$ = "paused"
#           # On completion: set sessionState$ = "finished"
#       endif
#
#       if sessionState$ = "paused"
#           # Draw pause overlay with Resume/Replay/Quit buttons
#           # demoWaitForInput (blocking) for button clicks
#           # On Resume: set sessionState$ = "play"
#           # On Replay: reset elapsed, set sessionState$ = "play"
#           # On Quit: set sessionState$ = "quit"
#       endif
#
#       if sessionState$ = "finished"
#           # Draw finished overlay with Replay/Quit buttons
#           # demoWaitForInput (blocking) for button clicks
#       endif
#
#   endwhile
#
# KEY PRINCIPLE: Non-blocking input (demoPeekInput) during animation,
# blocking input (demoWaitForInput) during interactive states. Never
# use demoWaitForInput during animation — it halts the script.
#
# Source: oscilloscope v6 (lines 260–538, complete implementation).

# ============================================================================
# §8  CLICK-TO-PAUSE DURING ANIMATION
# ============================================================================
#
# Click detection during animation uses the non-blocking pair:
#
#   demoPeekInput ()
#   if demoClicked ()
#       paused = 1
#   endif
#
# This is CONFIRMED STABLE for mouse clicks per COMMANDS_DemoWindow.txt
# Section 6A. Keyboard detection (demoKeyPressed) during animation is
# NOT safe and may cause crashes or dead-code behavior — do not check
# keyboard during animation loops.
#
# Place the click check at the END of the frame-drawing code, after
# demoShow(). Click coordinates are not needed for pause — just the
# boolean.
#
# Source: oscilloscope v6 (lines 444–448, with stability comment
# referencing Section 6A).

# ============================================================================
# §9  BUTTON RENDERING AND CLICK DETECTION
# ============================================================================
#
# RENDERING (reusable procedure from oscilloscope v6):
#
#   procedure drawButton: .x1, .x2, .y1, .y2,
#       ... .bgCol$, .borderCol$, .textCol$, .label$
#       demo Paint rectangle: .bgCol$, .x1, .x2, .y1, .y2
#       demo Colour: .borderCol$
#       demo Line width: 1
#       demo Draw rectangle: .x1, .x2, .y1, .y2
#       demo Colour: .textCol$
#       .midX = (.x1 + .x2) / 2
#       .midY = (.y1 + .y2) / 2
#       demo Text: .midX, "centre", .midY, "half", .label$
#   endproc
#
# CLICK DETECTION — two options:
#
# Option A — demoClickedIn (preferred, fewer lines):
#   if demoClickedIn (btnX1, btnX2, btnY1, btnY2)
#       # button was clicked
#   endif
#
# Option B — manual coordinate comparison (always works):
#   clickX = demoX ()
#   clickY = demoY ()
#   if clickX >= btnX1 and clickX <= btnX2
#       ... and clickY >= btnY1 and clickY <= btnY2
#       # button was clicked
#   endif
#
# IMPORTANT: demoClickedIn() checks against the CURRENT Axes: coordinate
# system. Ensure demo Axes: 0, 100, 0, 100 is set before checking button
# regions defined in demo units.
#
# Source: oscilloscope v6 (lines 188–198 rendering, 477–503 detection).

# ============================================================================
# §10  KEYBOARD NAVIGATION (UNICODE KEY CODES)
# ============================================================================
#
# For interactive (non-animation) keyboard handling, use demoKey$() and
# compare against character literals or unicode() values for special keys.
#
# SPECIAL KEY REFERENCE TABLE:
#
#   Key              | Detection pattern
#   -----------------+----------------------------------
#   Left arrow       | unicode (demoKey$ ()) = 8592
#   Right arrow      | unicode (demoKey$ ()) = 8594
#   Up arrow         | unicode (demoKey$ ()) = 8593
#   Down arrow       | unicode (demoKey$ ()) = 8595
#   Enter / Return   | unicode (demoKey$ ()) = 10 or 13
#   Escape           | unicode (demoKey$ ()) = 27
#   Backspace        | unicode (demoKey$ ()) = 8
#   Space            | demoKey$ () = " "
#   Tab              | unicode (demoKey$ ()) = 9
#
# ALPHABETIC KEYS — compare directly:
#   if demoKey$ () = "q" or demoKey$ () = "Q"
#       sessionState$ = "quit"
#   endif
#
# CANONICAL NAVIGATION PATTERN (from tutorial plugin, DFT v3.8):
#
#   demoWaitForInput ()
#   if demoKeyPressed ()
#       key$ = demoKey$ ()
#       if key$ = " " or unicode (key$) = 10 or unicode (key$) = 13
#           action$ = "next"
#       elsif unicode (key$) = 8594
#           action$ = "next"
#       elsif unicode (key$) = 8592
#           action$ = "back"
#       elsif key$ = "q" or key$ = "Q"
#           action$ = "quit"
#       elsif unicode (key$) = 27
#           action$ = "menu"
#       endif
#   elsif demoClicked ()
#       # handle click...
#   endif
#
# Source: tutorial plugin navigation.praat, DFT v3.8.

# ============================================================================
# §11  PLAYBACK CONTROLS
# ============================================================================
#
# ASYNCHRONOUS PLAY:
#   selectObject: soundId
#   asynchronous Play
#
# Version guard for distributable scripts:
#   if appVersion () >= 5379
#       selectObject: soundId
#       asynchronous Play
#   else
#       # Fallback: blocking Play (animation won't run during playback)
#       selectObject: soundId
#       Play
#   endif
#
# STOP PLAYBACK:
# Praat has no native stop command. Interrupt by playing a 1ms silent
# sound:
#
#   procedure stopPlayback
#       .silentId = Create Sound from formula: "emlSilent",
#           ... 1, 0, 0.001, 44100, ~0
#       selectObject: .silentId
#       Play                     # synchronous — interrupts async playback
#       removeObject: .silentId
#   endproc
#
# RESUME AFTER PAUSE:
# Extract remaining audio and play from the pause point:
#
#   selectObject: sourceId
#   playPartId = Extract part: pauseTime, soundEnd,
#       ... "rectangular", 1, "no"
#   selectObject: playPartId
#   asynchronous Play
#   # Continue stopwatch from resumeElapsed (§3)
#
# Source: oscilloscope v6 (lines 180–186, 276–288, 320–323).

# ============================================================================
# §12  AREA SHADING VIA VERTICAL STRIP SCANLINE
# ============================================================================
#
# Praat has no native "fill area under curve" command. Approximate with
# N vertical strip rectangles:
#
#   .nStrips = 100
#   .stripWidth = (xEnd - xStart) / .nStrips
#   for .s from 1 to .nStrips
#       .tCenter = xStart + (.s - 0.5) * .stripWidth
#       .tLeft = xStart + (.s - 1) * .stripWidth
#       .tRight = .tLeft + .stripWidth
#       selectObject: .dataId
#       .val = Get value at time: 0, .tCenter, "Sinc70"
#       if .val <> undefined
#           if .val >= 0
#               demo Paint rectangle: posColor$,
#                   ... .tLeft, .tRight, 0, .val
#           else
#               demo Paint rectangle: negColor$,
#                   ... .tLeft, .tRight, .val, 0
#           endif
#       endif
#   endfor
#
# Draw the curve on top of the shading:
#   selectObject: .dataId
#   demo Draw: xStart, xEnd, yMin, yMax, "no", "Curve"
#
# This is the same scanline principle used for polygon fills
# (COMMANDS_DemoWindow.txt §7) applied to continuous functions.
#
# Source: DFT v3.8 (lines 1141–1166).

# ============================================================================
# §13  SPLIT-PANEL LAYOUT
# ============================================================================
#
# For multi-panel displays (waveform strip + main view, side-by-side
# panels), define panel boundaries in demo units (0–100 range):
#
#   # Panel boundaries (Y-up: bottom, top)
#   topStripBot = 82
#   topStripTop = 98
#   mainBot = 8
#   mainTop = 78
#   infoBot = 0
#   infoTop = 6
#
# For each panel:
#   1. demo Select outer viewport: left, right, panelBot, panelTop
#   2. Set appropriate Axes:
#   3. Draw content
#   4. Restore: demo Select outer viewport: 0, 100, 0, 100
#      followed by demo Axes: 0, 100, 0, 100
#
# Leave gaps between panels for visual separation (2–4 units).
# The info bar at the bottom works well for rolling metrics.
#
# Source: oscilloscope v6 (scopeVpBot/Top, overVpBot/Top),
# DFT v3.8 (3-panel upper layout), EGG plugin v3.2 (split left/right).

# ============================================================================
# §14  GCI DETECTION APPROACHES
# ============================================================================
#
# Two approaches for detecting Glottal Closure Instants, with different
# tradeoffs.
#
# APPROACH A — DEGG PERIODIC PEAKS (EGG plugin):
# Compute DEGG, then detect positive peaks = closing instants.
# Also detect negative peaks = opening instants.
#
#   selectObject: deggId
#   ppCloseId = noprogress To PointProcess (periodic, peaks):
#       ... pitchFloor, pitchCeiling, "yes", "no"
#   ppOpenId = noprogress To PointProcess (periodic, peaks):
#       ... pitchFloor, pitchCeiling, "no", "yes"
#
# Parameter meaning:
#   "yes", "no" = maxima only (positive DEGG peaks = closing)
#   "no", "yes" = minima only (negative DEGG peaks = opening)
#
# Tradeoffs: Direct, robust for closing instants. Opening instants
# can be unreliable via Get minimum: search — use the PointProcess
# "no", "yes" approach instead.
#
# APPROACH B — PRESSURE MINIMA BACKWARD SEARCH (DFT demo):
# Find periodic pulses, then search backward for the pressure minimum
# in the acoustic waveform.
#
#   selectObject: segmentId
#   ppId = To PointProcess (periodic, cc): ppFloor, pitchCeiling
#   selectObject: ppId
#   nPulses = Get number of points
#   period = 1 / fundamentalHz
#   searchBack = 0.4 * period
#
#   for p from 1 to nPulses
#       selectObject: ppId
#       pulseTime = Get time from index: p
#       searchStart = max (pulseTime - searchBack, domainStart)
#       selectObject: segmentId
#       gciTime = Get time of minimum: searchStart, pulseTime, "Sinc70"
#   endfor
#
# Tradeoffs: Works on audio signal (no DEGG needed). The 0.4-period
# backward search window is adjustable — DFT v3.8 makes it a user-
# configurable form parameter (gci_search_back as percentage).
#
# Source: EGG plugin (Approach A), DFT v3.8 (Approach B, lines 2039–2127).

# ============================================================================
# §15  PERFORMANCE: noprogress AND selectObject: MINIMIZATION
# ============================================================================
#
# Two critical performance rules for Demo window scripts (and batch
# scripts generally):
#
# RULE 1: noprogress before analysis commands in loops.
# Prepend `noprogress` to all analysis commands executed inside loops:
#
#   noprogress To Pitch (filtered autocorrelation): 0, 50, ...
#   noprogress To Harmonicity (cc): 0.01, 75, 0.1, 1.0
#   noprogress To Sound (derivative): 5000, 100, 0
#   noprogress To PointProcess (periodic, peaks): 50, 500, "yes", "no"
#
# Effects: suppresses progress bar window, dramatically improves speed
# (empirically confirmed: significant speedup on 238-file batch), and
# avoids macOS Cocoa event dispatch issues.
#
# RULE 2: Minimize selectObject: calls in inner loops.
# Each selectObject: has overhead. When querying the same object in
# an inner loop, call selectObject: ONCE before the loop:
#
#   # WRONG — selectObject: called 100 times per frame
#   for iSamp from 1 to 100
#       selectObject: eggId
#       val = Get value at time: 0, t, "sinc70"
#   endfor
#
#   # RIGHT — selectObject: called once
#   selectObject: eggId
#   for iSamp from 1 to 100
#       val = Get value at time: 0, t, "sinc70"
#   endfor
#
# When alternating between objects, batch all queries to one object
# before switching:
#
#   # WRONG — 200 selectObject: calls for 100 samples × 2 objects
#   for iSamp from 1 to 100
#       selectObject: eggId
#       eggVal = Get value at time: ...
#       selectObject: deggId
#       deggVal = Get value at time: ...
#   endfor
#
#   # RIGHT — 2 selectObject: calls total
#   selectObject: eggId
#   for iSamp from 1 to 100
#       eggVals#[iSamp] = Get value at time: ...
#   endfor
#   selectObject: deggId
#   for iSamp from 1 to 100
#       deggVals#[iSamp] = Get value at time: ...
#   endfor
#
# Source: EGG plugin v3.0→v3.1 (360,000 → 180,000 queries reduced
# pre-computation from beachball to acceptable).

# ============================================================================
# END OF BEST_PRACTICES_DEMO_WINDOW.txt
# ============================================================================
