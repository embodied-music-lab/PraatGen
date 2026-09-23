# ============================================================================
# PRAATGEN CHANGELOG
# ============================================================================
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Version history for the PraatGen Master Prompt. Entries are newest-first.
# Referenced from the Master Prompt Core via the CHANGELOG section.
# ============================================================================

### Release 1.1.0 — 23 September 2026 (ships Master Prompt 14.21.0)

Cuts the 14.21.0 entry below into a release. Upgrade notes are in
`RELEASE_NOTES_1.1.0.md`. The three corrections it carries come from a bug
report by Eric Armstrong (https://voiceguy.ca/about).

### 14.21.0 — 23 September 2026

**Extract Formant on a FormantPath no longer appears in generated scripts.**
It reads the middle candidate ceiling, not the optimal one Get optimal
ceiling reports, on a fresh FormantPath as much as one that has had Set
path: or Set optimal path: applied. `APPENDIX_D_CLINICAL_DEFAULTS.txt` §4A's
query workflow and `COMMANDS_Formant.txt` now query Get optimal ceiling and
run a plain To Formant (burg) at that ceiling instead. F1 and F2 from a
FormantPath-based script change accordingly.

**The Extract Formant segfault range is corrected to 6.4.30–7.0.02**, from
the previously documented 6.4.60–6.4.62, and its root cause is now recorded:
Set path: and Set optimal path: both overwrite the FormantPath's stored
candidate index with the candidate's ceiling frequency, and the corrupted
value persists to disk. Down to Table (optimal interval) recomputes the
optimum rather than reading the stored path, so it is unaffected;
`COMMANDS_Formant.txt` now flags its field list as unresolved between 14 and
15 arguments and withholds a "Verified" line until a call is pasted from the
Praat GUI.

**§4A's query workflow carries a plausibility check.** The selected ceiling is
a search result and can land on a value that breaks tracking: on a synthesized
/i/ at F0 210 Hz the search chose 6718 Hz and the analysis returned F1
2362 Hz, where every ceiling from 4300 to 6300 Hz measured the same token at
F1 ~340 Hz. The check warns against the §7 formant bands. It substitutes
nothing and does not exitScript:, which is §7 practice for every other
measure.

**`BEST_PRACTICES_DRAWING.txt` gains a mandatory rule for circles on a
reversed axis.** Paint circle: and Draw circle: compute radius in world
x-coordinates, which goes negative when an axis is reversed — the normal
case for a vowel chart — and Praat then draws nothing without an error.
Paint circle (mm): and Draw circle (mm): are required instead;
`COMMANDS_PictureWindow.txt` notes the same failure mode at both commands.

**`APPENDIX_B_FUNCTIONS.txt`'s upperCase$ (string$) entry is corrected.** It
was reported as broken in procedure context; it is instead absent from Praat
builds through 6.4.39 and present from 6.4.46 onward, the same boundary
`PRAAT_VERSION_FLOOR.txt` §2 already documents for related case and
app-info functions.

### Release 1.0.6 — 21 September 2026 (ships Master Prompt 14.20.0)

Cuts the 14.18.0 through 14.20.0 entries below into a release. Upgrade notes
are in `RELEASE_NOTES_1.0.6.md`.

### 14.20.0 — 21 September 2026

**`APPENDIX_B_FUNCTIONS.txt` §4.8 — new.** The operators that refuse matrix
and vector operands, with the error text each produces. `/` is one: division
is available by composition, as `m## * (1 / x)` and `a## * (b## ^ -1)`.
`min ()`, `max ()` and `<` work through a Matrix object's `Formula:` and
`Get` commands. §4.1's row and column idioms use `row#` and `col#`, one call
where the documented pattern took two.

**`BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` §§8–9 — new.** §8 sets out the
naming registers — public `<prefix>CamelCase`, internal `<prefix>_lowerCamel`,
`config_snake_case`, kebab-case file names — and reserves the `emlPG` prefix
on the plugin side. §9 covers packaging: a generated plugin ships a build
target that emits `plugin_<name>` from the same declaration the include lines
read, normalizes file modes to 0644 and 0755, and verifies itself by
installing into a scratch home and confirming the menu entry appears.

**The capability-verification rule gained an absence test.** Before reporting
a function missing: try the `x`, `x#` and `x##` spellings, probe the
catalogue's spelling rather than a guess, and check both the script surface
and `Formula:`.

**`APPENDIX_D_CLINICAL_DEFAULTS.txt` §10 — heading supplied.** Subsections
10A through 10J existed with no `## 10.` heading, and two cross-references
pointed at nothing.

### 14.19.0 — 21 September 2026

**Copied library procedures are renamed to the `emlPG` prefix.** A generated
script that pastes in `@emlDrawViolinPlot` now defines and calls
`@emlPGDrawViolinPlot`. This is the only exception to copying a procedure
verbatim; the body, parameters and local names are untouched.

The collision it prevents: a user who owns the EML plugin can write a script
that `include`s library files and paste generated code beside it, which puts
two definitions of one name in the same parse unit. Praat warns that the
script will run and that the winner is unpredictable. On 6.6.30 the included
copy won and the script's own definition was ignored. `emlPG` is reserved on
the plugin side, so the two name sets cannot overlap.

Each copied procedure also carries a comment naming its library original.
The three self-audit checklists now confirm the prefix at every definition
and call site.

### 14.18.0 — 17 August 2026

**The sandbox Praat version is pinned to 6.6.30.** Praat 7.0 requires the
user's permission before a script may write a file or run a system command, so
a `--run` verification that writes anything fails without `--FULL-TRUST`, and
that flag is rejected by 6.4.62 and earlier — where it prints usage, runs
nothing, and exits 0. The pin is stated once, under Rule 24C's Version
management block, with its reason, its evidence and a review trigger; STEP 2B
points at it rather than restating it. Nothing else about version resolution
changes, including the architecture token.

**The pin costs no measurement fidelity.** The floor probe returns identical
values on 6.6.30 and 7.0: CPPS 12.114037 dB, Formant F1 161.676520 /
F2 456.216348, LPC 191 frames. Matrix operators, elementwise idioms and
form-widget marshalling are identical as well.

**`PRAAT_VERSION_FLOOR.txt` §4B — new.** What changes above the floor at
Praat 7.0: which write and system calls are gated, which are not, that the
permission dialog is deliberately absent from the §S15 check because it
neither halts a script nor changes a number, and that `--FULL-TRUST` must
never be added to a harness unconditionally. The floor stays at 6.4.39.

**`BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt` §1 — corrected.** All three OS
preference paths moved in Praat 7.0 and the file documented only the 6.x ones.
Adds the 7.x paths, `XDG_CONFIG_HOME` on Linux, the fact that Praat 7 still
reads plugins from the 6.x folder, the message printed when a plugin occurs in
both, and that `--pref-dir` no longer redirects plugin discovery on 7.x — a
harness that isolates by `--pref-dir` alone loads no plugin and says nothing.

### Release 1.0.5 — 5 August 2026 (ships Master Prompt 14.17.0)

Cuts the 14.13.0 through 14.17.0 entries below into a release. Upgrade notes are
in `RELEASE_NOTES_1.0.5.md`.

### 14.17.0 — 3 August 2026

**Seven Praat builds were downloaded and run.** 6.4.14, 6.4.20, 6.4.24,
6.4.30, 6.4.39, 6.4.46, 6.6.30, identical fixtures, every argument explicit.
Two entries in this file were contradicted by the results.

**The floor moves from 6.4.15 to 6.4.39.** The old floor was set on the belief
that `To Pitch (filtered autocorrelation)` took a different parameter set below
it. It does not: 6.4.14 and 6.6.30 both answer "Command requires only 11
arguments", and the canonical call returns 149.999960 Hz against 150.000009 Hz.
The eighth significant figure, on a fixture chosen to be hostile.

The floor now sits where numbers actually converge. Maryn/AVQI CPPS, measured:

    6.4.14  18.615235
    6.4.24  17.244598      first revision of the cepstral tilt fit
    6.4.39  18.994932      second revision — from here, current
    6.6.30  19.037906      +0.043 dB from the floor

Below 6.4.39 a user is 1.75 dB from current. At or above it, within 0.05 dB.
Not 6.4.24, which is only the first of the two revisions — a floor there would
declare "supported" a build whose numbers do not compare.

**The effect depends on the tilt-line settings, not on the command.** At the
6.4.24 boundary, straight tilt lines move -0.01 to +0.41 dB while both
exponential-decay fits move more than 3 dB. The raw cepstrum peak moves 0.04
dB; peak prominence moves 3.91 dB. So version entries are now keyed to the call
the script emits: `Get CPPS` with a straight line and `Get CPPS` with
exponential decay do not get the same warning.

**Praat's release notes name only 6.4.39.** The 6.4.24 revision was announced
as formant fixes, with no mention of cepstral measures, and it is the larger
change for anyone on Praat's own dialog defaults (-3.25 dB). Found by running
builds, not by reading. The floor file's coverage note is now a worked example
rather than a disclaimer.

**New hard-failure entry: `Get CPPS` fit method "Robust slow".** Accepted on
6.4.14, 6.4.24 and 6.6.30; REJECTED on 6.4.39 and 6.4.46. The option vocabulary
is not monotonic — a value can be valid, then invalid, then valid again — and
this one breaks inside the supported range with no release note. Prefer
"Robust", accepted on every build tested.

**Function availability, measured rather than assumed.** `padLeft$` absent at
6.4.14 and present at 6.4.20; `clock()` absent through 6.4.30, present at
6.4.39; the case-conversion family absent through 6.4.39 and present at 6.4.46
— previously recorded as "exact version not established"; `randomImax` absent
through 6.4.46. With the floor at 6.4.39, the first two are no longer triggers
and are kept only for inherited scripts.

**§S15 rewritten: the check reports a list, not a number.** Each entry names
one thing the script uses, its minimum, and which of two consequences applies —
**STOPS** (does not exist; the script halts at that line) or **DIFFERS** (runs,
returns a different number). Only entries the running Praat is actually below
are reported. A user past every entry sees nothing.

**The generic advisory added in 14.16.0 is removed.** "Your Praat is several
versions old" is a nanny message: it fires on people whose script is fine, and
a user who dismisses it reflexively will dismiss a real warning the same way.
Every line must name something in the script in front of them. `vc_builtAgainst`
and the second suppression key go with it; one notice needs one key.

**`APPENDIX_F` §S0-WRAP — break your own lines (hard).** Found by rendering
the dialog rather than reading it. An over-long `comment:` wraps, but the
dialog reserves only ONE line of height for it, so the remainder is drawn on
top of whatever comes next. Nothing errors and nothing is clipped — the layout
just does not know the wrap happened, and every line below is corrupted.
Measured under GTK: one long comment between two short ones wrapped to three
lines and obliterated the comment after it.

The rule is one idea per `comment:`, under roughly 60 characters, and never
concatenate a variable of unknown length onto a label. Wrap width is
platform-dependent, so short enough to fit everywhere is the only safe target.
This applies to every pause form PraatGen emits, not only the version check.

**Verified.** Decision logic across 15 cases — nine builds against a
two-entry list, six suppression combinations — confirming that a dismissal
below the list maximum does not silence the check and that a user past every
entry is silent whether or not a dismissal exists.

### 14.16.0 — 3 August 2026

**The floor was an assumption, never a check.** §S15A said to emit the version
check only when the script used a post-floor feature — so a script whose most
demanding call was a floor-level one emitted nothing at all. A user below 6.4.15
running such a script got no warning and failed partway through, which is
exactly what the feature exists to prevent. Whether they were warned depended on
whether the script happened to reach above the floor for some unrelated reason.

**Every script now emits the check.** `vc_minVersion` is the highest post-floor
requirement the script uses, or **6415** when it uses nothing above it. Never
unset.

**Second trigger: an advisory for users who are current enough to run, but well
behind.** Someone sitting at 6.4.15 with a floor-only script passes cleanly and
is also pre-6.4.39, so the next CPPS script they receive returns numbers that do
not compare to anyone else's. The advisory tells them before that happens:

    HARD      praatVersion < vc_minVersion
    ADVISORY  not HARD, and floor(praatVersion/100) < floor(vc_builtAgainst/100)

HARD supersedes ADVISORY — one dialog, and the hard message already says update.
The advisory threshold is a MINOR version, not a patch: firing on every patch
release makes it noise, and a user who dismisses reflexively will dismiss the
hard warning too.

**`vc_builtAgainst` is known offline and must never be polled.** PraatGen cannot
emit a command newer than the build its references were verified against, so the
number is already in hand. The message therefore says "this script was generated
against Praat 6.6.30" rather than "the current version is" — true when written,
true forever, and it understates the gap as time passes rather than overstating
it. Making it a network lookup would mean no network, no script, or a silently
wrong stamp when the fetch fails.

**Two suppression keys, independent.** `suppressed_for_min` silences HARD while
it is >= `vc_minVersion`; `suppressed_advisory_at` silences ADVISORY while it is
>= `vc_builtAgainst`. One key would let "your Praat is old, stop telling me"
silence a genuine feature warning, or the reverse. Both expire the same way, and
`@vcSavePrefs` writes both stamps on every save so dismissing one never erases
the other.

**Verified, Praat 6.6.30.** The decision logic across 11 builds (6.3.0, 6.4.14,
6.4.15, 6.4.16, 6.4.38, 6.4.39, 6.4.67, 6.5.0, 6.6.29, 6.6.30, 6.7.0) x 4
requirement levels (floor-only, 6418, 6439, 6462) = 44 cells, every one matching
the specified verdict. Plus 17 suppression cases: each key alone, both together,
each failing to silence the other, stale dismissals surviving an upgrade, a
preference file with no keys, and no file at all. A user ahead of
`vc_builtAgainst` is silent, not warned.

**Known limit, stated in §S15F rather than glossed.** `vc_minVersion` is fixed
at generation, so a script carries the view of the world PraatGen had that day.
A Praat change announced later will not be caught by a script written earlier.
The route to currency is regeneration.

### 14.15.0 — 3 August 2026

**`BEST_PRACTICES_DRAWING.txt` prohibited `Marks left:` / `Marks bottom:` and
then used them.** Its "Pattern for Spectrum" block, given as the pattern to
follow, ended with `Draw inner box` / `Marks bottom: 5` / `Marks left: 5` —
roughly 250 lines below its own NEVER. The "Pattern for Ltas" said "same
structure" and inherited it by reference.

This reframes 14.14.0. That release fixed Rule 28H on the reasoning that the
Master Prompt contradicted the PKB and the remedy was to make the model load
the PKB. But the PKB contradicted itself, in the spectrum pattern, and the
3 August incident task was a spectrum figure. A model that loaded the file,
found the pattern matching its task and followed it would have emitted
`Marks bottom:` from the authoritative source. Loading was never sufficient;
14.14.0's fix was necessary and not sufficient.

The spectrum pattern now uses `@emlDrawAlignedMarksBottom` / `Left`, and gains
the `Axes:` re-assertion after `Draw:` that it was missing. Ltas states that it
inherits both rather than implying it. The prohibition itself now says it
governs every pattern in the file, which is what would have caught this when
the pattern was written.

**`COMMANDS_PictureWindow.txt` marks the two commands DO NOT EMIT.** The
entries stay — a command reference must list the commands Praat has — but a
model reading only that file previously saw them documented with no indication
they are prohibited, and with a verified example to copy.

**Found by the eval, not by inspection.** Two independent agents in a
retrieval eval reported the contradiction unprompted. Neither the 3 August
incident report nor the Master-Prompt-versus-PKB sweep that preceded it caught
it, because both compared *across* files and this defect class lives *within*
one.

**`MAINTENANCE.md` and `tools/` are new.** Maintainer-only, deliberately
outside `pkb/` so nothing here is ever retrieved into a script-writing
conversation. `tools/sweep_self_contradiction.py` finds a prohibited construct
used outside a block labelled WRONG; `tools/list_mp_code_blocks.py` lists the
Master Prompt's Praat snippets for diffing against their sources. Triaged-clean
hits live in `tools/sweep_allow.txt` rather than as markers in the PKB.

The sweep currently reports 20 hits, all in `eml-*` library source carried
verbatim from the plugin: `@emlDrawLMMForest` uses bare `Marks bottom:`, and
the vibrato drawing family changes the ambient font size mid-panel to place
axis names and captions. Those are not editable here without desyncing the PKB
from the plugin; they are reported upstream and stay visible in the sweep until
the fix lands and the copies are resynced.

### 14.14.0 — 3 August 2026

**Rule 28H shipped axis code that violated a MANDATORY pattern in the file it
points at.** Its canonical garnish-suppression snippet emitted
`Marks left:` / `Marks bottom:`, which `BEST_PRACTICES_DRAWING.txt` prohibits
outright and Rule 34 lists as an anti-pattern. A model following 28H faithfully
violated both. Reported from a 3 August debugging session that shipped exactly
that; confirmed by reading the two texts against the emitted script.

The snippet is gone rather than corrected. Replacing it with a
`@emlDrawAlignedMarksLeft` snippet would swap one copyable answer for another
and drift the same way. 28H now states the prohibition, gives the reason, and
points at the source — a pointer cannot go stale, and it forces the load.

**The reason was not what the file implied, and this is worth recording.** The
prohibition sits three lines below the font-state invariant, so the nearest
available explanation is the wrong one, and the first draft of this fix
asserted that `Marks` "does not respect the ambient font size." It does —
sub-rule L already says so correctly, listing `Marks`/`One mark` together as
both laid out at "whatever font size is active when *that* command runs."

The actual reason is tick values. `Marks left: N` divides the data range into
N-1 equal intervals, so labels inherit whatever the range divides into.
Verified on a 0-87.3 dB axis, Praat 6.6.30:

    Marks left: 5             ->  0, 21.825, 43.65, 65.475, 87.3
    @emlComputeNiceStep       ->  step 20
    @emlDrawAlignedMarksLeft  ->  0, 20, 40, 60, 80

`BEST_PRACTICES_DRAWING.txt` now carries that reason and the worked example
next to the prohibition, marked as a separate rule from the font-state
invariant, so the conflation is not available to the next reader.

**SELF-AUDIT evidence rule: `AND/OR` becomes `AND`.** The rule's own rationale
says "producing the citation is the check" — and `AND/OR` made the citation
optional. Every Picture-window item in the 3 August session was satisfied with
script lines alone; the audit passed and the governing file was never opened. A
script line proves what the output IS; only a citation proves it was checked
against a source. For silent-failure items they are not interchangeable.

**The pre-delivery compliance check runs in DEBUGGING mode (STEP 2C, STEP 2D
item 6, House Rule 17).** It was AUTO-only, on the reasoning that standard
mode's PRE-FLIGHT -> COMMAND PLAN -> gate -> SELF-AUDIT pipeline covers the
same surface. That does not extend to DEBUGGING, where PRE-FLIGHT and COMMAND
PLAN do not run at all — so the mode with the thinnest gates was excluded from
the strongest check. Both recorded instances of this failure class (4 June, 3
August 2026) occurred in DEBUGGING. Gated on trigger-domain presence, and the
in-turn re-load is stated as the point of it: inherited code guarantees command
novelty is zero, so the Step 4 mini-preflight structurally cannot fire on it.

**Rule 24C: never `pkill -f` (hard).** `-f` matches full command lines, and the
pattern is in the argv of the shell running the `pkill`. Sandbox-verified 3
August: a pattern matching NO process anywhere still killed the issuing shell
with signal 9. Not a Praat quirk and not an Xvfb quirk. `-x` matches the
process name and survives; so does `-f '[p]raat'`. Corrected in item 5, the
recycle snippet and the complete test template.

**Rule 24C item 6B: pick the installation before writing the test.** `--run` is
batch and has no GUI; `--new-send` under Xvfb is the full thing. A wall reached
because the wrong one was chosen is a setup decision, not a finding, and must
not be reported as "could not be verified in the sandbox."

Driving the GUI, verified 3 August: use XTEST. `xdotool key --window` and
`xdotool click --window` are BOTH silently discarded by GTK, which ignores
`send_event` input — the split is transport, not keyboard-versus-mouse. Bare
`xdotool key` and `xdotool mousemove ... click` both work. Take coordinates
from a root capture; OCR of a window capture plus the window origin
double-counts the decoration.

**`APPENDIX_F` §S15E is now verified end to end** with the dialog actually
driven: both buttons, the boolean at both settings, the preferences write, and
a silent second run. Previously only its parse block was tested.

**Two sweep findings.** All five Praat code blocks in the Master Prompt were
diffed against their PKB sources after 28H, since nothing cross-checks them.
The `@emlGenerateUniquePath` and stereo-guard blocks are correct. The 28D2
legend key restored `Colour: "Black"` where the theme supplies
`emlSetAdaptiveTheme.axisColor$`; corrected. (`Line width: 1` stays — the theme
has no line-width field, so the Praat default is the right restore, and the
comment now says so.) Going the other way, `APPENDIX_F` §S14B hand-rolled the
entire stereo dialog that `@emlHandleStereo` implements; the expansion is kept
as documentation and explicitly marked as not the thing to paste.

### 14.13.0 — 31 July 2026

**The floor list is compiled from release notes, not from execution.**
`PRAAT_VERSION_FLOOR.txt` v1.1 reads every Praat release note from 6.4.15 to
6.6.30. Probing establishes what you happened to test; the release notes are the
complete set of announced changes. Reorganised by consequence: §1 silent
numerical changes, §2 new scripting functions, §3 new commands, §4 behavioural
and environment changes, §5 verified safe at the floor.

**§1 is the section that matters.** These commands exist on both sides of the
floor and return different numbers, with no error and nothing missing:

- **6.4.39 `PowerCepstrogram: Get CPPS...` — calibrated CPPS.** 14.12.0 recorded
  CPPS as safe at the floor because the command executes at 6.4.16. It does. That
  established the command exists, not that it agrees. Values before and after
  6.4.39 are not comparable; clinical, AVQI and longitudinal CPPS work must gate
  on it. Single most consequential entry in the file.
- **6.4.47 `Sound: To LPC` defaults to channel averaging.** Multi-channel input
  yields a different LPC than before.
- **6.4.24** FormantPath sampling-frequency fix plus autocorrelation and robust
  formant measurement fixes.

The lesson generalises: an execution probe answers "does this run", and the
version question is "does this agree". Probing cannot detect recalibration.

**`APPENDIX_F` §S15D — the opt-out is version-stamped (hard).** 14.12.0 wrote a
permanent flag: one tick and the check never fired again, including for
requirements that did not exist at tick time. The preference file now stores
`suppressed_for_min` (the minVersion in force when the user opted out) and
`suppressed_at_praat` (diagnostic), and the check is suppressed only when
`suppressed_for_min >= minVersion`. A hard note forbids writing a bare
`check_version 0`.

Verified in 6.6.30 across six cases: no prefs file; same requirement dismissed
again; a later higher requirement after an upgrade; a lower requirement than the
one dismissed; Praat already past the minimum with a stale dismissal present; and
a prefs file containing no suppression key. All six behave as specified.

**Renumbered §S11 to §S15.** The version-check section landed on a number the
file already used for INTEGRATION WITH MASTER PROMPT. Cross-references updated in
the Master Prompt, this changelog and `PRAAT_VERSION_FLOOR.txt`.

### Release 1.0.4 — 31 July 2026 (ships Master Prompt 14.12.0)

The package leaves the 0.9.x beta track at **release 1.0.1**, shipping **Master
Prompt 14.8.1**. (1.0.0 shipped on 29 July and is superseded by this build.) These are two independent numbers and both are correct: the
release versions the whole package, the Master Prompt versions the instruction
set inside it. Quote both in any bug report.

What made it stable rather than beta: the PKB is reconciled against the EML
plugin source instead of audited against itself; the procedure registry is
updated from that source rather than maintained alongside it; every library
file is syntax-checked against a real Praat 6.6.30 install; every PKB file
carries the plugin's version verbatim so drift is detectable; and the clinical
values a benchmark actually turns on were read off the live dialog.

### 14.12.0 — 31 July 2026

**Version floor, and a warning that lets you through.** Users on older Praat had
no way to find out except by hitting a failure mid-run — after objects were
created and files written.

**Floor: Praat 6.4.15**, set by `To Pitch (filtered autocorrelation)`. 6.4.15 is
the release that distinguished "pitch top" from "pitch ceiling", which is the
parameter set that command now takes. 6.4.15 is not published for download, so it
is verified at 6.4.16: the 11-argument FAC call executes there.

New `pkb/PRAAT_VERSION_FLOOR.txt`, built by executing candidate features against
6.4.16 and 6.6.30 side by side. Confirmed post-floor: `padLeft$()` and its family,
`clock()`, `moveAndOrRenameFile()` — all «Unknown function» at 6.4.16.

**Two suspicions raised from the changelog were wrong, and execution killed both.**
`Sound: To PowerCepstrogram` works at 6.4.16 despite a 6.4.58 entry reading "New
command" — CPPS work is safe at the floor. And `Select outer viewport: 0, 40, 0,
40` is accepted at 6.4.16 despite the 6.4.45 expansion of the Picture window from
12x12 to 60x60, so drawing scripts are not gated on it either. Both were about to
become rules on the strength of a changelog read that had already contradicted
itself once.

Two further candidates failed on BOTH builds, which means the test call was wrong
rather than the feature version-gated; they are recorded as unresolved rather than
as findings.

**The file states its own incompleteness.** A command absent from it has an
UNKNOWN minimum, not a safe one. Full coverage is a sweep across the 42
downloadable 6.4.x patch releases, sharing its fixture table and probe harness
with the catalogue parity pass.

**`APPENDIX_F` §S15 — the check itself.** Emitted only when the script uses
something post-floor, placed before the first object creation and the first file
write. It **warns and offers to continue; it never refuses** — the user's Praat
may be fine, and a script that will not start is worse than one that might not
finish. The message goes to the pause dialog *and* the Info window, because a
`comment:` line cannot be selected and the update URL needs to be copyable. It
ends warmly rather than sternly. A "Check again next time" boolean, default on,
writes an opt-out to `preferencesDirectory$`, shared across EML scripts so
switching it off once switches it off everywhere — which is what someone who has
just updated actually wants. Pattern verified in 6.6.30.

---

### 14.11.0 — 30 July 2026

**The legend must encode every channel used to separate the series (Rule 28D2).**
28D required a legend to exist and never said what it must carry, so a key showing
colour while the lines also differed by dash pattern was fully compliant. Observed
in the dry run: correct drawing code, correct colours, correct solid/dashed
distinction — and a legend that documented only the colour. The same key destroys
the greyscale version, where colour is gone and the reader is left with two lines
and no way to tell them apart.

A key is now **drawn, not described**: a short line segment rendered with the same
`Colour:`, `Line style` and `Line width` calls as the series it labels, text
beside it. Never a filled swatch, never coloured text, never prose describing the
style. If a channel cannot be shown in the key, it must not be used to separate
series. SELF-AUDIT states which channels are in play and confirms each appears.

**Greyscale reordered around line style (BEST_PRACTICES_DRAWING).** The B/W
palette's first two entries are 0.00 and 0.35 — two dark values, adjacent by
construction — so a two-series plot taking entries in index order gets the worst
available pair. That is what shipped.

Measured in the sandbox: lines rendered at 300 dpi and pixel-sampled.

    nominal grey   1 pt   3 pt
       0.00         42      0
       0.175        79     44
       0.35        116     89
       0.525       154    134
       0.70        192    179

Antialiasing lightens thin strokes and lightens black most, so a 1 pt "black" line
renders at 42, not 0 — the palette's 0.00 does not anchor the range the number
implies. The usable span at 1 pt is 42-192, roughly 150 levels, and the default
0.00/0.35 pair spends only 74 of it. Entries 1 and 6 (0.00/0.65) roughly double
the separation for free. Raising line width also restores contrast faster than
darkening the value: 0.35 at 3 pt is darker than 0.175 at 1 pt.

Rule: in greyscale, separate series by line style first, width second, grey value
third. Grey value remains reliable for filled areas, where stroke compression does
not apply. Index-order palette selection is called out explicitly, with per-K
guidance.

---

### 14.10.0 — 30 July 2026

**Benchmark dry-run remediation.** Five tasks run against v1.0.1 and verified
independently against Praat 6.6.30. Every claim below was re-verified here before
being written.

- **One file is the delivery default, always (protocol 12).** Shape was chosen by
  library size; it is now not chosen at all. A multi-file delivery requires the
  user's affirmative agreement in the conversation — no length threshold, no
  complexity score, no "this would be cleaner". A relative `include` sent as loose
  files cannot resolve, and this broke a deliverable in a user's hands. If the user
  does agree, it ships as one archive with the layout stated before sending.
- **Shape changes must prove inertness.** Re-render every figure and compare
  checksums to the pre-merge build; state the hashes.
- **Merging relocates module-level state.** Procedure definitions are
  position-independent; top-level statements are not, so a library's bare
  assignments run after the main body when pasted at the bottom. Verified both
  directions. Relocate them into the host's constants block and say so.
- **Counts are computed, not remembered.** A manifest claimed 504 lines for a
  519-line file.
- **Bundles are checksummed before the manifest is written.** Five byte-identical
  PNGs were described as five distinct captures, one of them as evidence of a
  corrected build it predated.
- **The ASCII sweep covers copied library text.** The shipped `eml-*` sources hold
  ~140 non-ASCII literals — harmless in Info output, not harmless once pasted into
  a script that writes files. Verified with `--utf8` set: pure ASCII writes `ASCII
  text`, the same line with one em-dash writes `UTF-16, big-endian`.
- **Bounded ranges are guarded at both ends** (APPENDIX_D), and a user's stated
  range is checked against the measurement, since the stated value feeds ceiling
  derivation.
- **Batch counters are per reason** (APPENDIX_F). Remaining work is files without
  output, not files not touched this session.
- **Editor blocks guard the opener** (COMMANDS_Editor). `nocheck` protects only the
  command it prefixes, so `nocheck Close` inside the block is unreachable when the
  user has closed the window by hand. Verified: `editor: tg` -> «Editor 2 does not
  exist», script aborts; `nocheck editor: tg` -> block skipped, execution continues.
- **Demo window layout** (BEST_PRACTICES_DEMO_WINDOW). `demoWindowWidth()` does not
  exist — verified — so layout cannot query the window and does not need to: demo
  coordinates are always 0-100. What varies is aspect ratio, and the documented
  1.726:1 was measured on a 16:9 screen. Text pages take a maximum measure and
  centre, so an unusual aspect gives symmetric margins rather than dead space.

**PKB corrections.**

- `Spectrogram: Paint` in the catalogue corrected 8 -> 10, restoring the dropped
  leading time-range pair. First hand-correction in that file; corrected entries
  are marked and the banner now carries a corrections log.
- `To Sound (derivative)` in `COMMANDS_Sound.txt` **was wrong on all three
  parameter names and their order** — it read "smoothing, low pass, high pass".
  Praat's own field names, read back by type probe: `Low-pass frequency`,
  `Smoothing`, `New absolute peak`. Found while implementing, not in the dry run.
  Adds a domain note: canonical audio smoothing of 100 Hz is a 46% magnitude error
  on respiratory-band signals, and a non-zero third argument destroys calibration.
- `Get value at sample number` argument order documented as a silent-failure
  hazard. An out-of-range channel does not error — Praat clamps to channel 1 and
  returns the requested sample — so a swapped call returns sample 1 forever with
  plausible magnitudes and no error. Demonstrated.

**Catalogue de-escalated (step 10 and the retrieval row).** The dry run showed the
model resolving `Spectrogram Paint` correctly from the curated COMMANDS file and
then reporting the answer as a *correction of the catalogue* — it had cross-checked
a fallback it had no reason to open. The arity warning had grown across three
places and was pulling attention toward the file it warned about. Step 10 now opens
with a stop condition: **if the command is in the object's COMMANDS file, you are
done; do not cross-check the catalogue.** The defect detail moved into the
catalogue's own banner, where it is read at the point of use, and the named phrase
"documented range-pair arity defect" is gone — a named thing invites citation.
Step 10 is 252 words, down from 372.

---

### 14.9.0 — 30 July 2026

**Opus 4.8 reclassified as a toggle model.** The prompt asserted that the extended-
thinking toggle was retired in Opus 4.8 and treated everything from 4.8 up as an
"effort model". That is wrong: 4.6, 4.7 and 4.8 all have the toggle; **only Opus 5
lacks it.** Corrected in fourteen places — the HARD GATE turn split, the Phase 3B
gate-behaviour table, both reporting branches, the model-tier guidance, the
deliberation lines in both SELF-AUDIT templates, and the STEP 1 greeting. The
practical effect is that on Opus 4.8 the post-plan wait applies again when the score
recommends a thinking change, where 14.8.1 and earlier would have skipped it.

**The greeting names compaction in the user's own word.** It described the
`VERIFY YOUR STATE` trigger as the conversation being "summarized". What the user
actually sees on screen is "compacting" — the summary is the output, not the label.
A user watching the bell ring had no way to match it to the instruction. The
greeting and the README heading now lead with "compacting", and the recovery
trigger list carries a note to use the user's word rather than the internal one.

---

### 14.8.1 — 30 July 2026

**Correction to 14.8.0: direct cell access does exist.** 14.8.0 claimed
`object[id].z[row,col]` does not work and told the model to route through
`Down to Matrix`. The claim came from testing the wrong syntax. The `.field` form is
metadata only — hence the error listing `xmin`, `xmax`, `nx`, `ny` — but the cell
form drops the field name entirely and works on any Matrix-shaped object. All three
verified 6.6.30: `object[id][1,i]`, `Sound_name[1,i]`, `Sound_name[i]`.

Read-only; `object[id][1,5] = 0.9` is a parse error.

This changes the advice, because indexing is measurably faster than a query call
(88,200 samples): `Get value at sample number` loop 0.286 s, `object[s][1,i]` loop
0.078 s (3.7x), `Formula:` 0.0031 s (25x faster again). So the ordering is
`Formula:`/vector read first, and **if a loop is genuinely required, index directly
rather than calling a query command per element** — a per-element `Get`/`Set` loop
is the worst of the three with no remaining justification. The prompt also warns
that the `.z` error message is easy to misread as "cell access is unavailable",
which is exactly the mistake 14.8.0 made.

---

### 14.8.0 — 30 July 2026

**Vectorize by default (hard).** The prompt previously carried one clause on this,
inside the elegance/DRY section: "If a vector operation replaces an element-wise
loop, use the vector operation." Filed under style, no magnitudes, no list of the
vectorized forms — weak enough that a loop which occurs first survives to delivery.
It is now its own hard subsection with measured numbers, on the grounds that a model
changes behaviour for a benchmark and not for an adjective.

Measured in the sandbox, Praat 6.6.30:

| operation | loop | vectorized | speedup |
|---|---|---|---|
| scale 88,200 Sound samples | 0.368 s | 0.0025 s | 146x |
| read 19,961 Pitch frames | 0.121 s | 0.0003 s | 415x |
| read a 20,000-row Table column | 0.049 s | 0.0049 s | 10x |
| scale a 20,000-row Table column | 0.099 s | 0.021 s | 5x |

The spread matters and is stated: sample- and frame-level loops are catastrophic
while Table row loops are merely wasteful. Scaled up, the first row is 2 seconds of
audio — a 60 s recording costs ~11 s per pass and a 100-file batch ~18 minutes for
work `Formula:` finishes in 0.15 s, which users misdiagnose as "Praat is slow".

Adds a task-to-command table (`Formula:`, `List values in all frames`,
`List values at times`, `Get all numbers in column`, `Down to Matrix`, vector and
matrix variables), and names the loops that are correct and stay: iteration over
files, over TextGrid intervals or PointProcess points where the per-item work is an
object-level operation, anything with early exit or per-item branching, and
genuinely sequential algorithms such as bisection.

**Trap documented:** `object[id].z[row,col]` does not work. Object field access
exposes only metadata (`xmin`, `xmax`, `nx`, `ny`, `dx`, `dy`, `nrow`, `ncol`) —
verified 6.6.30. Use the object's listing command or `Down to Matrix`. SELF-AUDIT
must justify any loop whose body is arithmetic on samples, frames or cells.

---

### 14.7.2 — 30 July 2026

**No status reports, no unrequested measures.** Two house rules, both from observed
behaviour in a live EGG task: the build announced to the user that it had no
de-noising, and offered QDelta unprompted.

*Do not narrate the library's own state (hard).* PKB files carry maintainer-facing
material — corrections, rationale, notes on what is deliberately absent — so a model
does not repeat a mistake. It is not reply content. §4 of the EGG best practices had
been written as a prominent "PARKED, not distributed" essay with no instruction to
keep it internal, so the model did the natural thing and reported it. §4 is now
short and explicitly internal: a sub-10 dB signal is refused in the user's terms
("too noisy to measure reliably"), with no mention of what was withdrawn or why. The
T1 correction block in §5 is marked INTERNAL for the same reason — the reasoning
must survive so it is not re-derived, but it is not something to tell anyone. The
file header now points maintainers at the changelog and backlog for history.

*Do not volunteer optional measures.* QDelta answers one question — are the folds
contacting at all — and §7 said only "use it as a descriptor when the question is
whether the folds are contacting", which was permissive enough to attach it to any
CQ task. It now says explicitly not to offer it unprompted, and names the cases
where it belongs (breathy onsets, voice mapping, whistle and falsetto edges,
suspected non-contacting phonation). An unrequested noise-sensitive number invites
the user to read it as a quality check, which it is not.

---

### 14.7.1 — 30 July 2026

**Neither outcome of the recycle check is assumed.** 14.7.0 said what to do when
`boot_id` changed and left the other branch implicit. A reload MAY coincide with a
recycle; often it does not. Unchanged boot_id means the same container — it is NOT
proof the processes survived, since they can die for other reasons — so confirm by
execution (`pgrep Xvfb`, `pgrep praat`, `xdotool getdisplaygeometry`) before relying
on anything started earlier. Both branches are now spelled out, with the note that
the setup block is safe to re-run, so when in doubt, rebuild.

---

### 14.7.0 — 30 July 2026

**`VERIFY YOUR STATE` is not only for compaction.** The trigger list now covers any
event that may have cost context or continuity: the conversation was summarized; an
error told the user to reload, retry or start again; a response failed partway and
was regenerated; the user returns after a long gap unsure what landed. Compaction
was only the most predictable of these — a reload loses just as much and announces
itself even less.

Section renamed `CONTEXT COMPACTION` -> `STATE PERSISTENCE AND RECOVERY`, since the
title was narrower than the rule.

**Recovery step 4 added, tying this to Rule 24C.** In SANDBOX mode a reload or retry
can coincide with a container recycle: the filesystem survives, but Xvfb, the window
manager, the compositor and any running Praat do not. `VERIFY YOUR STATE` now
compares `/proc/sys/kernel/random/boot_id` against the stored value and rebuilds the
display stack rather than reattaching. The two failure modes were documented
separately and are in practice the same moment.

Greeting and README updated to name reloads and errors alongside summaries.

---

### 14.6.1 — 29 July 2026 (same day, post-release)

**APPENDIX_D §3D — cross-program comparability (hard).** Praat jitter and shimmer
values are not MDVP values, and most published clinical norms are MDVP-derived.
Sourced from the Praat manual, "Voice 5. Comparison with other programs", whose URL
is now in the file so it can be given to the user directly.

Boersma's worked case: a computer-generated constant-period glottal source, vocal
tract filtered, plus 1% additive white noise ("a quite usual amount") — Praat reads
0.02% jitter, MDVP reads 0.6%, against a true jitter of zero. The cause is method:
Praat locates period boundaries by waveform matching (cross-correlation), which
averages noise out; MDVP peak-picks, which follows it. On clean synthetic signals
both recover 1%, so the divergence is a noise effect that grows with recording
quality problems. Voicing differs too — MDVP quantizes amplitude to -1/0/+1 before
autocorrelation, skips the window-autocorrelation division and the sinc-interpolated
peak, and uses a 0.29 voicing threshold against Praat's 0.45, so it calls more
frames voiced.

MDVP's pathology thresholds are reproduced (jitter local 1.040%, local absolute
83.200 us, rap 0.680%, ppq5 0.840%; shimmer local 3.810%, local dB 0.350, apq11
3.070%) along with the manual's caveat that they came from noise-influenced
measurements so "the correct threshold is probably lower". **The clinical direction
matters: applying an MDVP cutoff to a Praat value UNDER-calls pathology**, because
the Praat number is systematically smaller on any noisy recording. Plausible, in
range, wrong for the comparison — the silent-failure shape. `COMMANDS_PointProcess`
carries a pointer. The manual also states both x3 identities outright, corroborating
the sandbox measurements from 14.6.0.

---

### 14.6.0 — 29 July 2026 (same day, post-release)

**APPENDIX_D §3D — perturbation variant selection (hard).** Jitter and shimmer each
have several variants; they are not interchangeable and the difference can invert a
clinical reading. All eleven are now documented with verified arity in §3D and
`COMMANDS_PointProcess.txt` (previously only `local` and `local_dB` appeared).

The core finding: `local` is a first difference and absorbs smooth F0/amplitude
modulation in proportion to extent x rate, so on a sustained tone with vibrato it
measures the vibrato rather than phonatory stability. `rap`/`ppq5` are
second-difference measures and reject it. Monte Carlo at 8000 cycles: `rap` holds
0.117-0.128% across every modulation condition while `local` varies 2.9x.

**The local/rap ratio is the cheap self-interpreting check** and is now emitted by
default alongside both measures: ~1.73 clean, >2.2 smooth modulation present,
approaching 1.5 period-alternating structure. Adds a task-appropriateness matrix
(sustained / with vibrato / pitch-varying / connected speech — the last invalid for
perturbation entirely) and a runtime guard that costs no extra analysis object.
Clarification is ONE question — the phonation task, which governs validity — not a
variant menu; consistent with the EGG §5 rule that method choice is a discussion,
not a dialog field.

Three corrections made during verification before adoption. `dda = 3 x apq3` was
submitted as unverified: confirmed exactly (3.000000), as was `ddp = 3 x rap`, so
both are redundant and neither should be reported alongside its base. The
"ratio < 1.5" diplophonia test could never fire — pure alternation gives exactly
1.5000 regardless of depth, analytically and by Monte Carlo, so 1.5 is a floor and
the test must be for approach to it. And the ratio is asymptotic: measured 95%
spread is 1.64-1.86 at 100 cycles versus 1.72-1.75 at 8000, so the approach-to-1.5
flag is unreliable below ~500 cycles and the cycle count must be reported with the
ratio. The >2.2 flag is safe at any length. §7's plausibility band is annotated as
unable to catch a wrong-variant reading — it passed a 0.4431% `local` that was ~60%
vibrato.

---

### 14.5.1 — 29 July 2026 (same day, post-release)

**Changelog removed from the Master Prompt.** The prompt carried a full in-file
changelog — nine versions, ~2,950 words, 9.6% of the file — duplicating this file,
which already held all of it plus history back to 12.1. That cost was paid on every
conversation, in the one file that is always loaded. The prompt now carries a
pointer, a one-line "current version" note, and an instruction not to append history
there. Master Prompt down from 29,627 to 26,785 words. Nothing was lost: the five
recent entries were the fuller versions, so they replaced their counterparts here
before deletion. Nothing in a changelog entry was load-bearing for generation — any
rule that matters is stated in the body of the prompt, which is the standing test
for whether something belongs in it.

---

### 14.5.0 — 29 July 2026 (same day, post-release)

**Rule 24C: container recycle and the display readiness
probe.

- **Container recycle (new 24C subsection).** Background processes usually survive
  between tool calls but do not survive a container recycle, which can occur between
  calls and has been observed coinciding with compaction. The filesystem persists,
  so the environment looks healthy while Xvfb, the WM, the compositor and Praat are
  all dead — presenting as `Can't open display: (null)` or a screenshot of a display
  that no longer exists. **The design rule is the fix:** every GUI interaction is one
  self-contained call that raises the stack, drives Praat, captures to disk and
  exits; files are the handoff medium between calls, never processes. Detection
  (`/proc/sys/kernel/random/boot_id`, stored in the output folder — not in context,
  which is what a compaction takes) is diagnostic, for explaining a confusing
  failure. PID 1 uptime is corroboration only: it needs a wall-clock gap the
  assistant does not reliably have, while the boot_id comparison needs no clock.
- **Readiness probe corrected (hard).** `xdotool getdisplaygeometry` is the probe.
  `xdpyinfo` **is not installed in the sandbox image**, and
  `xdotool search --name "."` returns rc=1 on a live display with no windows yet —
  both fail silently as "never ready", which is the worst failure shape for a probe.
  The GUI setup snippet now polls for readiness instead of sleeping and hoping.
- **X lock cleanup is unconditional**, in the setup snippet, the test template and
  critical-detail 5 — not a recovery step. A recycle leaves `/tmp/.X99-lock` behind;
  Xvfb then dies with "Server is already active for display 99" and DISPLAY resolves
  to null. `rm -f` costs nothing and removes the class.

All claims re-verified in a live sandbox before adoption.

---

### 14.4.2 — 29 July 2026 (same day, post-release)

**Compaction survival and a way to skip the greeting.

- **`CONTEXT COMPACTION` (new, hard).** Long sessions get summarized and a summary
  is lossy prose, not the work. The current script, test results and open items are
  written to the output folder and kept current there, as you go. This applies in
  every environment — chat, SANDBOX and Cowork all have an output folder and it
  survives compaction. Delivering the `.praat` file (Phase 3C) is still required,
  but delivery is for the user; the folder is what the assistant reads back.
  *(14.4.1 corrects 14.4.0, which wrongly claimed plain chat has no filesystem and
  made the rule conditional on the environment. It is unconditional.)*
- **`VERIFY YOUR STATE` (new command).** Reorient from disk, never from memory —
  list the output folder, read the current script, read the open items, then state
  what is actually there and name every point where the summary or recollection
  disagrees. It is a command the **user** gives, typically after a compaction — the
  assistant does not self-invoke it by trying to sense its own context, which it
  cannot do. **The file wins:** reconcile by reading, never regenerate delivered
  work from a recollection of what it should contain. Announced in the STEP 1
  response so the user knows it exists and can reach for it.
  *(14.4.2 corrects 14.4.0–14.4.1, which had the assistant treat a post-summary turn
  as an implicit invocation — the same sense-your-own-state error the checkpoint
  cadence exists to avoid.)*
- **`NOINTRO` (new command).** In the user's first message, skips the STEP 1
  greeting — straight to PRE-FLIGHT if the four items are supplied, otherwise ask
  only for what is missing. It suppresses the greeting and nothing else; every rule
  still applies, and it composes with the other mode keywords. The greeting is the
  only "no matter how the user starts" response in the prompt, so the exception is
  stated at that gate rather than inferred.

---

### 14.3.1 — 29 July 2026 (same day, post-release)

**EGG method selection is a discussion, not a dialog
field. `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md` §5 previously read as a behaviour
table, which invited two wrong implementations: a runtime branch on an SNR
threshold, and a `form:` optionmenu offering dEGG / hybrid / threshold as three
equivalent choices. Neither is the default. **Raise it in PRE-FLIGHT, in prose,
and agree.** Substance to convey: above roughly 20 dB dEGG will most likely be
most accurate and has the best published correspondence to the videokymographic
closed quotient; as SNR approaches 10 dB the **opening** landmark specifically
decays — structurally, because the derivative's de-contacting trough is broad and
shallow next to its contacting peak, so the GOI degrades well before the GCI —
and where that leaves the answer ambiguous, take both measures on the same cycles
and compare means and SDs. The SNR figures are numbers to reason from, not
thresholds to branch on: 10 dB is Herbst's, 20 dB is lab judgement. §5 also now
states why the hybrid is the right comparator rather than an unrelated second
opinion — it keeps dEGG's contacting instant exactly and replaces only the
opening, so the two share closure and period. An optionmenu is correct only when
the user has asked for the choice to be exposed in a reusable tool.

---

### 14.3.0 — 29 July 2026 (same day, post-release)

**Spectral thresholding parked. `@emlEggSpectralThreshold`
and the whole §4 de-noising section of `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md`
are **withdrawn from distribution**. They were **never tested on real material** —
every figure behind them (the 8× clean-signal penalty, the zero-to-297 GCI
recovery at SNR 20/15/10, the 30–60 dB CQ plateau, the self-calibrating threshold
sweep) came from synthetic signals with additive white Gaussian noise. That is
the easy case and it is not what EGG noise is like: hum, wandering side tones,
electrode drift and movement artefact were never in the test set. Shipping a
runnable de-noiser on that basis invites its use on real recordings, where it
would alter data silently and plausibly.

Removed from `eml-egg-procedures.txt` (v1.0 → v1.1, 2 procedures → 1) and from
the registry (264 → 263 procedures). §4 is replaced by an explicit parked notice
with a do-not-reconstruct instruction; the withdrawn material is recoverable from
git history rather than reproduced, because a reader who finds a runnable listing
will run it. **Consequence:** there is no de-noising path, so §5 now refuses
sub-10 dB EGG signals outright instead of offering a rescue. Two Praat traps are
kept, being independent of de-noising and generally true of spectral work on EGG:
`To Spectrum: "yes"` zero-padding inflating `To Sound` length, and the ~91 dB
Ltas-vs-raw-magnitude mismatch. `@emlEggCycleGuard` is unaffected — it is
validated and remains mandatory.

---

### 14.2.0 — 29 July 2026 (same day, post-release)

**Script delivery format made explicit. Phase 3C said
only "Output ONE COMPLETE SCRIPT" and specified no format, so on a chat surface
it resolved to a code block by default. `present_files` had only ever appeared
inside AUTO mode, and the standing rule "no partial code blocks" tacitly assumed
code blocks were the medium — so the ordinary single-script path was the one case
with no stated mechanism. **Generated scripts are now delivered as `.praat`
files (hard).** The rationale is correctness, not tidiness: copy-paste out of a
rendered code block is where curly quotes, en-dashes and non-breaking spaces get
substituted into source, which Praat either rejects or, per Rule 24C, converts to
UTF-16 BE output. Delivery shape (b) — script plus sibling `*_lib/` folder — has
no code-block form at all and is now stated as file-only. Code blocks remain
correct for excerpts, single-line debugging fixes, and anything the user asks to
see inline. SELF-AUDIT stays inline. The Cowork build carries the same rule.

---

### 14.1.0 — 29 July 2026 (same day, post-plugin reconciliation)

The v14.0.0 audit was run against the PKB alone. Reconciling it against the
actual `plugin_EML_Praat_Tools` source reversed several of its conclusions.

**The core finding: the PKB was shipping TRUNCATED copies of the plugin
sources.** The registry was not indexing ghosts — it was describing the plugin
correctly while the PKB shipped incomplete files. Measured, per file:

| PKB file | had | plugin has | was missing |
|---|---|---|---|
| `eml-output` | 21 | 42 | `emlWrapperCommonFields`, `emlHandleCommonFields`, `emlWrapperInit`, `emlWrapperExportCSV`, 16× `emlWizardExplain*` |
| `eml-inferential` | 25 | 27 | `emlLinearRegression`, `emlTheilSen` |
| `eml-extract` | 13 | 16 | `emlGuessColumnRoles`, `eml_getGroupPairedData`, `eml_kwScan` |
| `eml-annotation-procedures` | 23 | 25 | `emlReportRegressionAnalysis`, `emlReportNormalityAnalysis` |
| `eml-core-descriptive` | 18 | 20 | `emlShapiroWilk`, `eml_swPoly` |
| `eml-draw-procedures` | 14 | 15 | `emlDrawLMMForest` |
| `eml-vibrato-procedures` | 11 | 16 | `emlVibratoDrawFigure` + 4 panel procedures |

**Reversals of v14.0.0 decisions:**
- **C2 was wrong in principle.** The 37 "ghost" procedures were real. Six were
  quarantined mid-session on the maintainer's correction; the rest were deleted.
  All are now restored by refreshing from source, and the quarantine section is
  gone. The 16 `emlWizardExplain*` deserve specific mention: they live in
  `stats/eml-output.praat`, a **core** file — deleting them as "wizard ghosts"
  was a category error. The wizard script itself stays excluded (vestigial).
- **M10 was wrong.** `@emlVibratoDrawFigure` was removed from the Guide as a
  dead reference. It is real — it and four companion panel procedures were
  simply absent from the truncated PKB vibrato copy. Restored.
- **The v14.0.0 version bumps were wrong.** That pass bumped five PKB files
  past the plugin's real versions (PKB `eml-graphs` 3.1 vs plugin 3.0, etc.),
  destroying the only signal that catches this drift. **New policy: the PKB
  file carries the PLUGIN's version verbatim. PKB version == plugin version,
  always; a mismatch means the PKB has drifted.** PKB-only edits (the license
  header) are recorded in a separate provenance block, not by bumping.

**Refresh performed.** 14 PKB sources replaced with plugin-verbatim content
(license line normalized to GPL-3.0-or-later, provenance block added), plus a
newly supplied `eml-vibrato-procedures` v2.0 with the drawing family. Registry
**rebuilt programmatically from source**, not hand-edited: **295 procedures
(287 public, 8 internal) across 16 files**, verified equal in both directions
against the shipped sources — no registry row without source, no source
procedure unlisted. All 295 carry a purpose string.

**Removed:** `eml-demo-procedures.txt` (31 procedures). It was carried on the
assumption that Demo-deck generation depended on it. It does not: the source of
truth for driving the Demo window is `COMMANDS_DemoWindow.txt` (16 sections —
the `demo` keyword, coordinate system, the font-metric contamination bug,
`Text special` alignment, animation input handling, the Polygon bug, lifecycle,
known bugs) plus `BEST_PRACTICES_DEMO_WINDOW.md`, and **neither references it**.
It was a convenience wrapper around already-documented `demo` commands, dated
April 2026, of uncertain current quality, whose source could not be reconciled
because the plugin archive omitted the `tutorial/` folder. Registry: 295 → 264
procedures across 15 files. The Demo window remains fully supported.

**Added:** `eml-analysis.txt` (21 `@emlRun*Analysis` dispatchers) — the layer
the plugin's menu wrappers call. Brings regression, normality, RM-ANOVA,
Friedman and reliability into reach.

**Deliberately excluded, and stated as such:** `eml-lmm.praat` (mixed models,
not ready) and its private numerical dependencies `eml-linalg.praat` /
`eml-optimizer.praat` (Cholesky, BOBYQA, Nelder-Mead — called by nothing else,
so they have no consumer without LMM). Consequence handled rather than left to
rot: `@emlRunLMMAnalysis` is the one dispatcher with unresolvable calls and now
carries a hard do-not-route warning at its own definition. `eml-wizard.praat`
also excluded (vestigial).

**Style exception, deliberate.** PKB copies are byte-faithful to plugin source
so Rule 223 ("copy exactly from source") is satisfiable. That reintroduces 39
`+=` and 2 `elif` that v14.0.0 had rewritten. Rather than let the PKB diverge
from source again, the style fix belongs upstream in the plugin. The MP names
this as a known SOT exception so a model does not "correct" the library it is
copying from.

**Self-containment rule added (hard) — retrieval protocol step 12.** Generated
scripts must never `include` the EML plugin. The end user is not assumed to
have it installed, at any path, ever. This became urgent precisely because the
refresh above made the PKB byte-faithful to plugin source: `eml-graphs.txt` now
ships nine real `include ../graphs/….praat` lines, which a model copying from
it could carry straight into delivered code, producing a script that dies with
"Cannot open file" on any machine without the plugin.

Two accepted delivery shapes: (a) procedure bodies pasted into the delivered
script under a marked block — the default; (b) script plus a sibling `*_lib/`
folder included by a script-relative path only. Never `../`, never
`preferencesDirectory$`, never absolute. Copying is transitive: a copied
procedure's own `@eml…` calls come with it, until every `@`-call in the
delivery resolves inside the delivery.

Enforced on all four surfaces a model can reach: retrieval protocol step 12
(the rule), both SELF-AUDIT templates (a line item requiring the delivery shape
be named and the closure confirmed), the AUTO pre-delivery domain table (AUTO
suppresses SELF-AUDIT, so it needs its own row), the registry header, a new §0
in EML_PROCEDURE_GUIDE.md, and a warning banner directly above the include
block in `eml-graphs.txt` itself.

**Verified:** all 16 refreshed sources parse in Praat 6.6.30 (the sole flag is
`eml-graphs.txt`'s plugin-tree `include` paths — known, M11). Zero signature
drift on shared procedures, confirming `emlReportKWComparison` was the only one.

### 14.0.0 — 29 July 2026

**Major version.** Full-codebase audit remediation ahead of the frozen benchmark
run. Promoted from a point release because the pass changes the routing layer
(retrieval table, registry contents and counts, a new source file), the gate
semantics (Phase 3B is now model-conditional; a new mode section), and the
license declared in nine source headers — all breaking-ish changes for anyone
running an older PKB against the new prompt or vice versa. **The Master Prompt
file is renamed `MASTER_PROMPT_CORE_v14_0_0.md`; re-paste it into your project
instructions and re-upload the PKB folder together — the two are not
independently versioned.** Fixes are
keyed to the audit report's item IDs (C = critical, M = moderate, E = EGG
addendum, T3 = tier-3 cosmetic).

**Routing layer (the ghost-file class of defect):**
- **C1 — `EML_DRAWING_PROCEDURES.txt` no longer exists anywhere.** The retrieval
  table's only drawing row pointed at a file that does not exist, while
  `BEST_PRACTICES_DRAWING.txt` (mandatory co-load per protocol step 2) had no
  row at all. Row replaced; the stale name swept from all six PKB files
  (APPENDIX_F ×2, DEVELOPER_MODE_ADDON, COMMANDS_DemoWindow ×2,
  BEST_PRACTICES_CONFIDENCE_FIGURES ×5) and repointed to the real source files.
- **C2 — registry regenerated against measured ground truth.** Header claimed
  251/15, body carried 273 rows, MP claimed 255/14; actual is 236 procedures
  whose source is present in the PKB, across 14 files. The registry had been
  indexing procedures that exist in the **plugin tree** but whose source was
  never copied into Project Knowledge — an important distinction, since MP
  Rule 223 ("copy exactly from source") is unsatisfiable for them.
  - Removed as not-shipped-and-not-needed: the Wizard section (15 procedures;
    the wizard exists in the plugin tree but is vestigial), 18 Output rows
    (`emlWrapperCommonFields`, `emlHandleCommonFields`, 16×
    `emlWizardExplain*`).
  - **Retained, but explicitly quarantined:** `emlLinearRegression`,
    `emlTheilSen`, `emlReportRegressionAnalysis`, `emlReportNormalityAnalysis`.
    These are real, implemented procedures in the plugin tree — the Guide's
    "Regression: not yet implemented" refers to workflow *wiring*, not to
    their existence — but their source is absent from `eml-inferential.txt`
    v1.2 and `eml-annotation-procedures.txt` v3.15. New **"Plugin-tree-only
    procedures"** section at the end of the registry lists them with accurate
    signatures, a hard handling rule (do not invent a body; ask the user to
    paste it, or route to an implemented alternative), and instructions for
    closing the gap by copying the four bodies in and bumping the count to 242.
  - With the two newly registered EGG procedures (E5), **238 procedures are
    PKB-resident across 15 files**, plus the 4 quarantined. Counts describe
    what the loading protocol can actually retrieve. MP retrieval row synced.
- **NEW — dangling `@emlWrapperCommonFields` in APPENDIX_C_GUI.txt.** Not in the
  original audit. The appendix's worked "shared wrapper fields" example called a
  procedure that is not shipped in the PKB, so a reader following the example
  would route to nothing. Rewritten as an explicit `@myCommonFields` placeholder
  with a note on what happened. Found by a reference-vs-definition sweep run
  after the registry rebuild; that sweep is now the check that would catch this
  class of defect again.
- **M4 / E1 / E2 — five missing retrieval rows added:** `COMMANDS_DemoWindow.txt`,
  `BEST_PRACTICES_DEMO_WINDOW.md`, `BEST_PRACTICES_CONFIDENCE_FIGURES.txt`
  (1,296 lines with zero inbound references), `COMMANDS_Electroglottogram.txt`,
  and `BEST_PRACTICES_EGG_CONTACT_QUOTIENT.md`. The Demo deck and EGG analysis
  are both scored benchmark tasks that were previously unreachable by the
  stated trigger mechanism.
- **M9 — `emlReportKWComparison` signature corrected.** Registry listed 5
  params; source takes 6 including `.tableId` in 4th position, so a
  registry-faithful call misbound three arguments.
- **M10 — Guide dead references removed.** `@emlVibratoDrawFigure` and
  `vibrato-procedures-manual.md` exist nowhere; the vibrato library is
  analysis-only. Repointed to the general drawing procedures.
- **M11 — plugin-path vs flat-PKB mapping stated explicitly** at the top of the
  registry. `**File:**` entries use the plugin tree (`graphs/….praat`); PKB
  ships flattened `.txt`. Previously implicit and unstated.

**EGG integration (E-series):**
- **E5 — `emlEggCycleGuard` and `emlEggSpectralThreshold` promoted to registered
  library procedures.** Both were complete runnable procedures living only
  inside documentation (a `.txt` comment block and a `.md` fenced block),
  indexed nowhere — a drift-generating state. New source file
  `eml-egg-procedures.txt`; both documentation copies now marked illustrative
  with a pointer to canonical source per Rule 223.
- **E3 — mandatory EGG co-load** added as loading-protocol step 4a, sibling to
  the APPENDIX_D clinical rule. An EGG task now auto-pulls both EGG files
  rather than depending on a judgement call.
- **E4 / M12 / M13 — catalogue "not found" is no longer read as "does not
  exist."** Protocol step 10 rewritten with an explicit gap carve-out, and the
  catalogue itself gained a staleness-and-completeness banner (pinned 6.4.62
  while other files are verified at 6.4.65/6.4.67/6.6.30) plus a §2 note on the
  dropped from-time/to-time fields in Formant and Pitch query blocks. Where they
  disagree, the object-specific COMMANDS file governs.
- New AUTO pre-delivery domain row for EGG (cycle guard + CQ plausibility bound).

**Sandbox verification (Praat 6.6.30 installed and driven, 29 July 2026):**
- **`elif` confirmed accepted.** Both `elif` and `elsif` parse and execute.
  The eml-inferential normalization is style conformance with the MP's own
  prohibition list, not a bug fix.
- **Get CPPS dialog defaults observed directly.** §5B had said the Maryn set
  differs from Praat's defaults on three values; a source-extraction reading
  during this audit said five; the dialog shows **six**. The two missed are
  the enum fields (Trend type = Exponential decay, Fit method = Robust slow) —
  precisely the fields the catalogue exposes without their default values.
  §5B is now a field-by-field table with a sandbox stamp, the Praat-default
  call is recorded in COMMANDS_PowerCepstrogram.txt for contrast, and the
  lesson is stated in-file: treat catalogue enum defaults as unknown, not
  absent.
- **Rule 19 overclaimed the form/beginPause quoting asymmetry.** 13.9.3 stated
  that `beginPause:` numeric defaults "must be bare," and added a SELF-AUDIT
  item enforcing it. Verified: the asymmetry is ONE-DIRECTIONAL. Bare in
  `form:` is a hard parse error (`Only "choice", "optionmenu" and "boolean"
  fields can take a number`); quoted in `beginPause:` parses, renders and
  binds correctly. Bare in beginPause is a house convention. As written the
  audit item would have flagged compliant code — including this library's own
  `eml-batch-process.txt`. Corrected in Rule 19, both SELF-AUDIT templates,
  the AUTO domain table, and APPENDIX_C.
- **Black-screenshot failure mode diagnosed and fixed.** `import -window <id>`
  under Xvfb returned all-black or partly-black frames. Cause: plain X11 has
  no compositing, so pixels of an occluded window region are not stored
  anywhere and the capture reads empty framebuffer. Verified that `Xvfb +bs`
  does NOT help (the client must request backing store; GTK3 does not), that
  `xcompmgr` fixes it completely, and that raise-then-capture or root+crop
  work as fallbacks. A 100%-black frame means nothing was mapped — usually a
  dead application — and must never be reported as evidence. Full behaviour
  matrix, the fix, the validation check, and two related traps (`windowactivate`
  needs a WM; `--run` cannot show dialogs) documented in Rule 24C under
  "Screenshot capture under Xvfb"; openbox/xcompmgr/xdotool/imagemagick added
  to the STEP 2B install step.

**Gate logic (contradictions that made gate-compliance scoring ill-defined):**
- **C3 — AUTO domain table said "Rule 28 A–K."** The whole point of 13.9.4 was
  promoting the font-state invariant to sub-rule L; the AUTO check — the *only*
  compliance check when gates are suppressed — still keyed on the pre-fix list,
  so AUTO would re-ship exactly the defect 13.9.4 closed. Now A–L.
- **C4 + extended-thinking retirement — Phase 3B reworked as model-conditional.**
  HARD GATE said "continue in the same turn if no thinking change is
  recommended"; Phase 3B said "wait for GO — this is a hard gate." Both were
  marked hard and could not both be obeyed. Compounding this, extended thinking
  as a user-facing toggle was retired in Opus 4.8, so the gate's on/off
  vocabulary no longer described reality. Resolution: the complexity score is
  retained unchanged, but its *reporting* is now model-conditional — on toggle
  models (4.6/4.7) it recommends thinking on/off and a recommended **change**
  opens the wait; on effort models (4.8+) it is an advisory reasoning-effort
  recommendation and opens **no wait**. Gate-behavior table added; HARD GATE,
  Rule 31 thinking-gates block, and both SELF-AUDIT templates synced.
- **C5 — the STEP 1 menu offered a forbidden combination.** It advertised "AUTO
  … Combines with SANDBOX and DEBUGGING" while MP:638 declares AUTO and
  DEBUGGING mutually exclusive. A user replying "AUTO DEBUGGING" per the menu
  invoked an undefined state. Menu corrected with the reason stated inline.
- **M1 — DEBUGGING mode had no defining section.** STEP 1 sold it, STEP 2A/2B/2C
  defined SCAFFOLD/SANDBOX/AUTO, and nothing handled "user replies DEBUGGING"
  (STEP 4 triggers on an error report, not the keyword, and never states the
  approval-for-any-changes property). Added **STEP 2D** with the five behaviors
  the STEP 1 text promises.
- **M2 — VERBOSE was silently cancelled by GO.** GO is the proceed keyword at
  every gate, so a VERBOSE user replying GO at the thinking gate reverted to
  SPARSE unintentionally. GO/EXECUTE no longer change compression mode; SPARSE
  is the sole return keyword.
- **M5 — AUTO domain table had no file-output/GUI/UX row.** With SELF-AUDIT
  suppressed in AUTO, Rules 26/27 (file safety), 18/19/20 (GUI derivation), and
  33/App F had no compliance check at all — an AUTO batch script could hardcode
  paths and overwrite files with nothing firing. Row added.
- **M6 — dangling "I know the following commands:"** in the mandated verbatim
  STEP 1 response now reads "I understand the following mode keywords:".

**SELF-AUDIT templates (M3):**
- Added `File output (26,27)` line items to **both** templates. The 13.9.4
  evidence rule names file-output safety as a silent-failure item requiring
  citation, but neither template had a slot, so the requirement could never
  fire. Also added Rule 4B (object preservation) and Rule 37 to the compressed
  template, added 5E to the compressed Syntax line, and de-duplicated the
  twice-listed "No unverified commitments" item in the verbose template.

**Source-of-truth hygiene:**
- **M7 —** `BEST_PRACTICES_DRAWING.txt` said "NEVER use `Marks left:`/`Marks
  bottom:`" and its very next "# CORRECT:" example used both. Example rewritten
  with the `@emlDrawAlignedMarks*` nice-number calls.
- **M8 —** Demo font-state House Rule ("set `demo Font size:` exactly once at
  initialization") flagged the mandatory three-line per-frame reset required by
  COMMANDS_DemoWindow and BEST_PRACTICES_DEMO_WINDOW as a violation. Reworded to
  "one fixed value, re-asserted via the three-line reset; never a different value."
- **M15 —** the library stopped violating its own prohibition list: 37×
  `+=` in `eml-vibrato-procedures.txt` rewritten to `x = x + n`; 2× `elif` in
  `eml-inferential.txt` normalized to `elsif` (the other 154 branches already
  used `elsif`). These files are pasted into model context as exemplars.
- **M16 —** Appendix D: §9's dangling `HANDOFF_A2_Batch_Analyzer.md §4` pointer
  repointed to §10 (which exists to replace it); §5B's "differs on three values"
  corrected to five (time averaging 0.01 vs 0.02 and quefrency averaging 0.001
  vs 0.0005 were missing); `"Parabolic"` normalized to verified `"parabolic"`.
- Catalogue §3 footer count corrected 369 → 365 (matches its own header and the
  actual entry count).

**Publication hygiene:**
- **M14 — license incoherence resolved.** Eight `eml-*` headers declared
  "Creative Commons Share-Alike" and one declared "Creative Commons
  Non-Commercial with Attribution" — CC-NC is incompatible with GPL and with the
  other files. All normalized to GPL-3.0-or-later, matching the repo and MP.
- **M17 —** `praatgen_references_complete.md` no longer stamps v13.5; MP routes
  script header attribution through this file, so generated scripts were
  self-citing a stale version. Now version-agnostic. Praat source repo cite
  corrected (`praat/praat`, with the website repo listed separately).
- **T3 —** `changlog` typo + filename; jammed Table/Strings retrieval rows split;
  duplicated STEP 2 heading removed; stale "(Turn 2 only)" labels reconciled with
  the Turn-2/3 split; VERBOSE scope wording aligned (58 vs 123); duplicate 13.6
  changelog entry disambiguated as 13.6b; command-count claims reconciled across
  README/MP/catalogue (3,300+ registered; 365 Formula functions); PKB snapshot
  date synced; `pub/tmp` placeholder deleted; last `[NEEDS PASTE]` placeholder
  replaced with an explicit not-verified warning; duplicated Formant "Draw tracks
  vs. Speckle" note collapsed to a pointer; doubled CONFIDENCE_FIGURES footer
  deduped and its TODO-049/050 residue marked closed; legacy "EML Praat
  Assistant" branding replaced in HANDOFF_TEMPLATE, DEVELOPER_MODE_ADDON, and
  eml-batch-process; `BEST_PRACTICES_DEMO_WINDOW.txt` → `.md` references fixed.
- **Duplicate source file resolved:** `eml-annotation-procedures.praat` and
  `eml-annotation-procedures.praat.txt` were byte-identical. Consolidated to
  `eml-annotation-procedures.txt`, matching every sibling.

**Model recommendations updated:** Opus 5 preferred; Opus 4.8 performs well;
Opus 4.6 with Extended Thinking remains the original validation baseline and the
token-conscious choice; Opus 4.7 noted as agentic and superseded. **Sonnet and
Haiku are now explicitly unsupported** rather than "may work for simple scripts."
The "PraatGen will tell you when you can safely turn thinking off" promise is
retained only for toggle models, where it is still true.

**Effort guidance is deliberately soft, and labelled provisional.** On effort
models the prompt states only what is currently supportable: there does not
appear to be an advantage to setting effort higher than the default ("high");
setting it higher can actually derail a project, largely through context
exhaustion; there is some evidence that effort may be set lower once the
COMMAND PLAN is established; users should experiment and find what works for
their own workflows. Phase 3B's line is explicitly not to be presented as a
settled recommendation, and the Rule 31 phase-value table carries a note that
it is not a licence to raise effort. Revisit when there is better evidence.

**Carried forward, not fixed:** C6 (PulseAudio startup was commented out in both
the SANDBOX install step and the Rule 24C test template — now uncommented) and
C7 (UTF-16BE `eml-batch-process.txt`) were both resolved; C7 at source before
this pass. Standing caution on C7: any editor round-trip can silently restore
UTF-16/BOM — re-check with `file` after manual edits.

### 13.9.4 — 4 June 2026

**MP edits (this pass):**
- **SELF-AUDIT evidence rule (hard) — new block before the compressed template;
  governs BOTH the compressed (SPARSE) and verbose templates.** For the
  silent-failure items (Picture/drawing 28/34, clinical App D, viewport 28I,
  file-output 26/27), "compliant"/"confirmed" is no longer an acceptable audit
  value — each must cite the governing PKB source (file + sub-rule, or line)
  and/or paste the exact script line that satisfies it. Rationale: "confirm"
  constrains the claim, not the act, and is satisfiable from memory; a citation
  cannot be generated without the lookup. Scoped to the silent-failure items by
  design (blanket citation would bloat the audit and raise skip-pressure).
- **Rule 28 sub-rule L — Picture-window font-state invariant (hard).** The
  ambient font size sets the Picture-window margins, which set the world->page
  mapping; every margin-dependent element (Draw inner box, Marks/One mark, axis
  value numbers and name labels, gridlines, any Paint/Draw/Text placed in world
  coordinates) must run at ONE ambient size or they misalign. Lead symptom (the
  common case): inner box at one size, ticks/value labels at another, so they
  no longer meet the box edges; the same mechanism misplaces filled shapes and
  annotations. RULE: set `Font size:` once per panel, never change it
  mid-sequence; use `Text special:` (own size, no global state change) for
  differently-sized text. Promoted from BEST_PRACTICES_DRAWING into the MP as a
  Rule-28 sub-rule (parity with the existing Demo-window font-state House Rule);
  the "confirm all sub-rules" line now reads A-L.
- **Audit Picture lines (both templates) now demand evidence:** cite the script
  line for the single per-panel `Font size:` (L) and the viewport reset before
  each save (I); list every variable-text call with its sanitization method (J).
  The verbose template carries a cross-reference to the evidence rule.
- **Re-grounding under context depth (hard) — Retrieval Protocol.** A reference
  file loaded earlier in the conversation does not count as "loaded" for
  audit/fix purposes once intervening turns accumulate; re-open the governing
  PKB file in-turn before any drawing/clinical audit and before any Step 4 fix
  touching drawing, clinical parameters, or GUI.
- **Rule 24B — When-NOT-to-use + trip-wire (hard).** Added "how a documented
  built-in command behaves" (world/font side effects of Paint/Draw tracks/
  Speckle, margin/font interactions, what resets the world window) to the
  not-for-the-sandbox list. Trip-wire: building an experiment to learn how a
  built-in command behaves is the tell that the PKB was skipped — the sandbox
  verifies your script, not engine behavior the PKB already records.
- **Rule 34 anti-pattern:** drawing in-panel text (titles, axis labels, legend
  keys, annotation bands) with `Font size:` + `Text:` instead of `Text special:`
  now named explicitly (violates 28L).
- **Version/date:** 13.9.3 -> 13.9.4 / 4 June 2026.

**PKB edits (this pass):**
- This file (`PRAATGEN_CHANGELOG.md`) updated with this entry — the mirror the
  MP CHANGELOG section requires.
- `BEST_PRACTICES_DRAWING.txt` unchanged: it already states the font-state
  invariant ("Font state invariant (MANDATORY)"). The defect was that the MP
  audit checklist did not enumerate it; sub-rule L closes that, no source-file
  change needed.

**Provenance / follow-through:**
- Surfaced in the 4 June 2026 RIP figure-redesign debugging session: a
  Picture-window font-state-invariant violation (ambient font size changed
  mid-panel via `Font size:` + `Text:` for ribbon/legend labels) shipped
  through three consecutive SELF-AUDITs that each attested "Picture compliant."
- Two root causes, both addressed above: (1) coverage — the invariant lived
  only in BEST_PRACTICES_DRAWING and was absent from the Rule-28 A-K checklist
  the audit keys on (fixed by sub-rule L); (2) attestation vs evidence —
  "confirm/compliant" is satisfiable from memory without re-reading the source
  (fixed by the evidence rule). A secondary drift — treating the sandbox as the
  primary reference and rediscovering documented engine behavior with probes —
  is addressed by the Rule 24B trip-wire and the re-grounding rule.
- README (GitHub repo, not in the PKB): no change this pass.

### 13.9.3 — 3 June 2026

**MP edits (this pass):**
- **Sandbox install resolves by INTENT, not an architecture token (STEP 2B,
  Rule 24C full + barren + manual fallback, version-management notes).** The
  snippet pinned `linux-intel64`; Praat renamed the 64-bit x86 Linux build to
  `linux-x64v3` (May 2026), so the pattern matched only a stale older-release
  entry and 404'd on fetch. Now resolves the newest version + 64-bit x86 build
  by exclusion (`grep -vE 'arm64|s390x|linux32'`; for full, also `-barren`).
  Download stays on fon.hum — the GitHub release mirror it links to is
  403-blocked by the egress proxy. Empirically verified 3 Jun 2026.
- **Dependency-currency house rule:** extended to name "architecture token"
  alongside version/tag/filename as something that must never be pinned.
- **Rule 18 (form numeric defaults — hard):** `form:` numeric/vector field
  defaults MUST be quoted strings (`natural: "Tier", "1"`); a bare number is a
  parse error (`Only "choice"/"optionmenu"/"boolean" can take a number`).
- **Rule 19 (beginPause numeric defaults — hard):** mirror note — in
  `beginPause:` numeric defaults are BARE. The asymmetry is the trap.
  (APPENDIX_C already documented this; the MP now audits it.)
- **STEP 2B (form-driven verification — hard):** scripts with a
  `form:`/`beginPause:` must be sandbox-verified by driving the real form via
  `runScript:` with positional args, never by setting derived variables
  directly — direct assignment bypasses the parser and Rule 20 derivation and
  gives false-pass confidence.
- **Context-budget rule + Debugging Invariant 9:** the handoff iteration
  counter is now explicit — open each Step 4 turn with `📋 Debug iteration N`
  and check the 3-offer/5-escalate thresholds against that surfaced tally
  rather than relying on recall.
- **SELF-AUDIT (compressed + full GUI lines):** added the default-type and
  form-driven-verification checks.
- **Model recommendation:** STEP 1 response and PRE-FLIGHT Item 1 now
  recommend **Opus 4.8 with Thinking in high-effort mode, to start.**
  PraatGen was originally developed/validated on **Opus 4.6 with Extended Thinking** (still a solid
  baseline); **Opus 4.7** is more agentic than 4.6 or 4.8 and may excel at
  AUTO SANDBOX refactoring. Removed the stale "4.7 in testing" framing.
- **Terminology sweep (Thinking vs Extended Thinking):** generic gate/feature
  references — Rule 31, the Phase 3B / Step 4 thinking gates, PRE-FLIGHT Item 1,
  the SELF-AUDIT field, OUTPUT-COMPRESSION table, and the README — renamed from
  "Extended Thinking" / "ET" to **"Thinking"**, the current feature name (Opus
  4.8 exposes Thinking with effort levels). "Extended Thinking" is retained,
  spelled out, ONLY where it refers specifically to Opus 4.6; the bare "ET"
  abbreviation no longer appears in active text (changelog history untouched).

**PKB edits (this pass):**
- None required. The download snippet lives only in the MP; APPENDIX_C already
  documents the form/beginPause default-quoting asymmetry; DEVELOPER_MODE_ADDON
  and HANDOFF_TEMPLATE carry no model or install content needing sync.

**Provenance / follow-through:**
- Failure modes surfaced in the 3 Jun 2026 RIP session (see HARNESS_CASE_G_RIP).
- `README.md` (GitHub repo, not in the PKB) carries a model-recommendation line
  that should be synced to the 4.8 / 4.6-origin / 4.7-agentic framing.
- NOTE: 13.9.2 (3 Jun 2026) is not logged in this file — the entry jumps from
  13.9.1 to 13.9.3. 13.9.2 introduced the fetch-time install resolver and the
  initial 4.8 STEP-1 wording; backfill its entry if a complete record matters.
- NOTE: there is likewise no 13.9.0 entry. 13.9.1 is the first 13.9.x entry
  logged here. Both gaps are known and deliberate-by-omission, not data loss.

### 13.9.1 — 17 May 2026

**MP edits (this pass):**
- **Rule 5C (procedure-local vs caller-scope):** Explicit statement that
  dot-prefix variables are procedure-local; from caller scope, procedure
  outputs are accessed as `procedureName.variableName`. Persistence
  semantics documented.
- **Rule 5C (`empty$#` bug status):** FIXED in Praat 6.4.65 (sandbox
  verified 15 May 2026). Warning made version-conditional; literal-init
  workaround retained for scripts targeting ≤ 6.4.63.
- **Rule 7 (comment hygiene rewrite):** `#` for line-start only, `;` for
  inline only. Hard separation. No `#` after code; no `;` at line start.
  SELF-AUDIT item added.
- **Rule 27 (non-destructive file output rewrite):** `@emlGenerateUniquePath`
  is the last line of defense for all file output. Date stamps alone fail
  uniqueness. Pattern D (interactive overwrite dialog) retired as
  standalone pattern. Overwrite only on explicit user request.
- **STEP 2C Item 4 (AUTONOMOUS):** Added exception clause —
  PKB-encoded methodology decisions are pre-decided, not deferrals.
- **STEP 2C (new subsection, "Pre-delivery domain compliance check"):**
  Mandatory itemized check before `present_files` in AUTO mode, with
  per-command catalog tables for voice quality, formant, statistical,
  Picture window, Demo window, and tutorial domains.
- **Debugging Invariant #17:** AUTO-mode pre-delivery compliance check
  is mandatory.
- **House Rules additions:**
  - `for` loops always increment in Praat (no decrement direction)
  - `and`/`or` do not short-circuit (both sides always evaluated)
  - `nocheck` corrupts interpreter variable state on failure (cannot be
    used as diagnostic branching tool)
  - Zip delivery protocol — single zip with MANIFEST.txt; no loose-file
    delivery; no summary-instead-of-original; verify presence before
    packaging
- **SELF-AUDIT (compressed + full):** `ET:` → `ET recommended:`. System
  cannot detect actual ET state, only what it recommended.
- **House Rule alignment:** Comment-style bullet updated from "# comments
  only" to reflect new Rule 7 (separation of `#` line-start and `;` inline).

**PKB edits (this pass):**
- **COMMANDS_Table.txt:** Box plots entry cleaned up (uncommented from
  prior correction block; contaminated Normal probability plot line
  fixed). ANOVA commands verified present.
- **COMMANDS_PointProcess.txt:** Added `Get number of points`,
  `Get time from index`, `Get low index`, `Get high index`,
  `Get nearest index` with explicit note distinguishing PointProcess
  from TimeTier-family `Get low/high index from time:`.
- **COMMANDS_Pitch.txt:** Added `Get time of maximum:` and
  `Get time of minimum:` (4-parameter form including unit$) with explicit
  contrast against Sound's 3-parameter signature.
- **COMMANDS_Editor.txt:** Added `Close` command with documented
  `nocheck Close` editor-cleanup pattern (narrow safe use of `nocheck`).
- **PRAAT_DEFINITIVE_CATALOGUE.txt:** `FormantModeler: Draw variances of
  shifted tracks` — sandbox-verified 17 May 2026 (Praat 6.4.65 barren).
  Confirmed OPTIONMENU position (5th parameter, between right Variance
  range and left Formant range), and enumerated valid values ("no",
  "up", "down" — case-insensitive). Earlier session memory describing
  OPTIONMENU position as "between formant range and garnish" was wrong;
  catalogue position was correct. Entry annotated with verified enum
  values and provenance.
- **COMMANDS_Sound.txt:** Added four sandbox-verified entries (Praat
  6.4.65, 15 May 2026):
  - `Save as 32-bit WAV file:` — ±1.0 hard-clip data-loss hazard
  - `Save as raw 32-bit big/little-endian file:` — NaN propagation
    hazard on out-of-range input
  - `Combine to stereo` — accepts arbitrary N selected Sounds; selection
    order = channel index
  - `Get mean:` — three-argument form (channel, fromTime, toTime)
    documented alongside two-argument form

**Verified-current (no edit needed):**
- A3: All three channel-handling procedures exist in
  `eml-graph-procedures.praat` v3.18 (`@emlHandleStereo`,
  `@emlApplyChannelChoice`, `@emlCheckChannels`); MP references
  validated.
- A4: Canary value `What_About___Oleicat-67-55Δ` current.
- A10, A11: CSV default delimiter and pauseScript newline limitation
  already in House Rules / Rule 21.
- B4: COMMANDS_DemoWindow.txt — three errata (font lock, viewport
  units/order, rotation as string) already documented in current file.
- B5: COMMANDS_PowerCepstrogram.txt — per-frame CPPS workflow
  already documented; column names still pending Paste Commands.
- B6: APPENDIX_B_FUNCTIONS.txt — reserved identifiers note already
  present.
- B7: COMMANDS_PictureWindow.txt — font state and Text special
  self-containment already documented.
- B11: COMMANDS_Formant.txt — FormantPath Extract Formant segfault
  errata and workaround already documented.
- B15: `eml-annotation-procedures.praat` — single mention of
  `@emlAutoPlaceLegend` is a correctly-worded changelog entry (rename
  history), not dead documentation.

**Identified for future passes:**
- B1, B2: EML_PROCEDURE_REGISTRY.md missing entries and signature
  mismatches — deferred per user (procedures work).
- B12: Some vibrato commands redistributed already (B8, B9 added this
  pass); remaining unspecified commands require original 18 Mar handoff
  document.
- B16: `eml-core-descriptive.praat` PKB v1.0 lags local v1.1
  (@emlShapiroWilk addition) — requires file upload.
- B17: PKB plugin files lag local versions
  (annotation-procedures 3.15→3.17, output 1.3→1.6, graphs-form 1.4→1.7) —
  requires file uploads, not header edits.
- B18: `eml-wizard.praat` missing from PKB — requires file upload.
- C2: Paper scope edits — deferred per user.

**PKB version bump:** 0.9.3 beta 1.

---

### 13.8.3 — 7 May 2026
- **Rule 21 erratum:** `pauseScript:` does not render `newline$` as
  line breaks. Single-line messages only. Multi-line instructions
  require `beginPause` with `comment:` lines. Empirically confirmed
  in Praat 6.4.65.
- **Rule 28 scope:** Explicit statement that Rule 28 applies to ALL
  Picture window output including wireframes and mockups. No casual
  mode.
- **Rule 29D (Multi-channel input):** New sub-rule for multi-channel
  Sound files. Sampling rate is shared across all channels; channel
  roles must be confirmed during PRE-FLIGHT.
- **PRE-FLIGHT Item 3C (Multi-channel check):** Channel assignment,
  sampling rate, and annotation channel must be established before
  code generation.
- **Step 1B (Label solicitation):** When script logic depends on
  exact label strings, those strings must be surfaced during design,
  made configurable, and validated at runtime.
- **Step 1B (Methodological decisions):** Decisions affecting
  scientific interpretation (which channel to segment from, how to
  compute volume change) are the researcher's job, not the compiler's.
- **House Rule (Editor capability check):** Check COMMANDS_Editor.txt
  before engineering workarounds for editor interactions.
- **NEW FILE: COMMANDS_Editor.txt v1.1** — Editor scripting reference
  extracted from Praat source code (FunctionEditor.cpp, SoundArea.cpp,
  SoundAnalysisArea.cpp, TextGridArea.cpp). ~100 commands across 5
  sections. 15 commands empirically verified via Praat 6.4.65 + Xvfb.
  Critical finding: TextGridEditor registers under TextGrid ID, not
  Sound ID — using Sound ID hangs.
- **Rule 24C (Sandbox verification):** Praat can be installed in the
  sandbox for empirical testing. Barren edition for non-GUI commands;
  full edition + Xvfb for editor commands. Allowed domains frozen at
  conversation start (empirically verified). Installation, usage, and
  lifecycle management documented.
- **Debugging Invariant 15:** Editor capability check added.
- **Reference Retrieval Protocol:** COMMANDS_Editor.txt added with
  trigger for `editor:` / `endeditor` blocks and editor interaction
  workflows.

### 13.8.2 — 25 April 2026
- **BEST_PRACTICES_CONFIDENCE_FIGURES.txt v2.0:** §10 rewritten. Former
  §10A–G (measure-specific notes) replaced with locked panel specs.
  Four base panel types (time-series, spectral snapshot, waveform+overlay,
  spectrogram+overlay) with constrained layout, overlay vocabularies,
  and procedure signatures.
- CPP/CPPS: same panel geometry, different input preparation. Smoothing
  on cepstrogram before slice extraction for CPPS. Heatmap prohibited.
- Spectrum: flexible overlay vocabulary (vertical lines, spreads,
  frequency bands, point markers, regression) replacing hardcoded
  M1–M4 layout.
- Formant routing: sustained vowel → spectrum panel; dynamic → spectrogram
  with three-layer stack (spectrogram → speckle → tracks, one color).
- Perturbation: 1.3× padded amplitude bounds, full-height pulse marks
  behind waveform, solid-line-only prohibition.
- Two-rule viewport/axes contract codified (§10.1A): single outer
  viewport + axes reassertion after every draw call. Validated
  empirically.
- Proof-sheet preview workflow (§10.7) for pre-batch layout verification.
- All annotation text black; colors referenced by palette index only.


### 13.8.1 — 23 April 2026
- **APPENDIX_D §0 (new): Canonical Parameter Discipline.** All
  clinical parameter deviations now require signal-loss justification.
  "Extra headroom," "doesn't hurt," and "closer to expected range"
  are explicitly listed as invalid justifications. Narrowing a
  parameter below canonical is treated equivalently to widening one.
  PRE-FLIGHT must ask about range only when the task suggests the
  canonical window may be insufficient — not preemptively adjust.
- **Rule 22B strengthened:** Canonical parameter integrity paragraph
  added, cross-referencing APPENDIX_D §0.
- **House Rules updated:** Voice analysis parameter rule now references
  signal-loss standard.
- **SELF-AUDIT templates updated:** Clinical parameter entries now
  require "all canonical per §0" or explicit signal-loss evidence
  for each deviation.
- **Provenance:** Singing voice quality script (23 April 2026) —
  RCC pitch floor lowered from 75→50 and ceiling narrowed from
  600→500 without signal-loss justification. HNR pitch floor
  deviation (75→50) changed analysis output. All three deviations
  reverted to canonical after review.

### 13.8 — 23 April 2026
- **Rule 4B (Object preservation):** Scripts must never remove objects that existed before the script ran. Only script-created objects may
be cleaned up. Starting state is a contract.
- **WHITELIST_CURRENT.txt fully redistributed and reset.** All accumulated
  entries moved to their target COMMANDS files. No entries remain.
- **COMMANDS_Universal.txt:** New Selection Management section documenting
  `selectObject:`, `plusObject:`, `minusObject:`, `removeObject:`,
  `select all`, and selection query functions (`numberOfSelected`,
  `selected`, `selected$`, `selected#`). Selection-is-a-set interpreter
  behavior note. `nocheck` state corruption errata added to Syntax Notes.
- **COMMANDS_PictureWindow.txt:** Text special, Insert picture from file,
  Text width (world coordinates) uncommented from pending state. Full
  Measure subsection added (8 commands, all catalogue-verified). Paint/Draw
  rounded rectangle with catalogue-verified parameter counts. Font behavior
  notes uncommented. New Photo Object section with Create simple Photo,
  Create Photo, Formula (transparency), Paint image, and two errata.
- **COMMANDS_Table.txt:** New TableOfReal section — To Table (verified),
  12 statistical analysis commands (To PCA, To Discriminant, To SSCP,
  etc.), 5 hidden commands, 1 cross-type command. Header updated to
  "Table + TableOfReal".
- **COMMANDS_SpeechSynthesizer.txt:** KlattGrid section added — Create
  KlattGrid from vowel (12 params) and To Sound (no params). Header
  updated to "SpeechSynthesizer + KlattGrid".
- **COMMANDS_Ltas.txt:** Get number of bins, Get frequency from bin
  number, Get value in bin uncommented from pending state.
- **APPENDIX_B_FUNCTIONS.txt:** Usage notes added for `appVersion()`
  (integer encoding + version guard pattern), `chooseReadFile$`
  (callable anywhere, returns "" on cancel), `unicode()` (special key
  code reference table for Demo window).
- **NEW FILE: BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt** — 7 sections
  covering plugin directory structure, setup.praat registration, Add
  menu command / Add action command full parameter documentation,
  submenu cascade patterns, include path behavior, plugin-conflict
  guards.
- **Reference Retrieval Protocol:** Four updates — new row for
  BEST_PRACTICES_PLUGIN_ARCHITECTURE.txt; COMMANDS_Table.txt trigger
  expanded to include TableOfReal; COMMANDS_SpeechSynthesizer.txt
  trigger expanded to include KlattGrid; COMMANDS_PictureWindow.txt
  trigger expanded to include Photo objects.

### 13.7 — 22 April 2026
- **Rule 5C: Matrix (`##`) variables** — creation (`zero##`,
  `randomGauss##`, `outer##`, `transpose##`, literals), element access,
  dimension queries (`numberOfRows`, `numberOfColumns`), operations
  (`mul##`, `mul#` both directions, `solve#`, `solve##`, `rowSums#`,
  `columnSums#`, `sum`, `mean`), elementwise arithmetic (`+`, `*`,
  scalar `*`). Preference rule over flat vectors and interpolated
  indexed variables. Matrix variables vs. Matrix objects distinction.
  Catalogue ghosts documented (`inner##`, `object##`, `linear##` — not
  exposed to scripting engine). All 17 functions verified empirically
  in Praat 6.4.63.
- **Rule 5C: String vector (`$#`) variables** — creation (literals,
  `readLinesFromFile$#`, `fileNames$#`, `folderNames$#`,
  `splitByWhitespace$#`, `splitBy$#`), element access, `size()`,
  operations (`sort$#`, `sort_numberAware$#`, `shuffle$#`). Batch
  processing pattern (`fileNames$#` as simpler alternative to
  `Create Strings as file list:`). All 14 functions verified
  empirically. Known Praat 6.4.63 bug: `empty$#` crashes (segfault
  in `str32cmp` — NULL pointer in allocated string vector slots).
- **Rule 24B: Empirical verification snippets** — when uncertain about
  syntax or behavior, offer a 2–10 line self-contained snippet for the
  user to paste into Praat. Counts as "asking the user" for Rule 24
  circuit breaker.
- **Rule 24 circuit breaker clarification:** "Two-alternative" includes
  parameter variations of the same approach. Adjusting a threshold
  three times is one approach tried three times, not three approaches.
- **House Rule (`noprogress`):** `noprogress` must precede all analysis
  commands in loops and batch contexts (`To Pitch`, `To Formant`,
  `To Harmonicity`, `To PointProcess`, `To Intensity`, `To Spectrogram`,
  `To PowerCepstrogram`, `Filter (pass Hann band)`, etc.). Applies to
  Demo window animation and batch file processing.
- **NEW FILE: BEST_PRACTICES_DEMO_WINDOW.txt** — 7 sections covering
  animation loop architecture, selective vs. full erasure, `noprogress`
  performance, font state management, coordinate system, aspect ratio
  compensation, and template patterns.
- **COMMANDS_DemoWindow.txt:** Paint rounded rectangle example corrected
  (5 → 6 parameters, missing radius). Animation caveat added to
  selective erasure section. Troubleshooting table updated.
- **WHITELIST_CURRENT.txt redistribution:** Ltas queries, Text special,
  Insert picture from file, Text width, font behavior notes,
  selection-is-a-set moved to target COMMANDS files. Added Paint rounded
  rectangle (6 params), Add action command (10 params), Add menu command
  (6 params). Praat bug logged: `empty$#` segfault in 6.4.63.

### 13.6 — 22 April 2026
- **APPENDIX_B_FUNCTIONS.txt rebuilt from scratch:** Complete rebuild
  from official Praat Functions manual page merged with Formula.cpp
  source verification. 375 unique entries (up from 343). Key additions:
  `folderExists`, `between_by#`, `between_count#`, `empty$#`, `clock`,
  `col#`, `combine#`, `correlation`, `padLeft$`/`padRight$` family,
  `randomImax`, `chooseFolder$`, `chooseReadFile$`, `chooseWriteFile$`.
  Alias pairs documented. `unicode()` key code reference table added.
  `appVersion()` added with version-guard usage pattern.
- **House Rule (Accessible palette):** Okabe-Ito is the default palette
  for all EML graph output. Exact RGB values documented in
  BEST_PRACTICES_DRAWING.txt. B/W is the only alternative. API users
  may override `.line$[n]` / `.fill$[n]` after `@emlSetColorPalette`.
- **COMMANDS_Harmonicity.txt:** Draw parameter count corrected (4
  parameters, no garnish).
- **COMMANDS_Formant.txt:** Added `Speckle:` command (5 parameters).
  Usage note: weaker formants (F4–F5) may not appear with Draw tracks
  — speckle all formants first, then overlay tracks.
- **COMMANDS_Sound.txt:** Draw usage note for Harmonicity overlay.
- **COMMANDS_Intensity.txt:** Draw usage note added.
- **BEST_PRACTICES_DRAWING.txt:** Accessible palette section with
  Okabe-Ito exact RGB values for line, fill, and light-line variants.
- **README.md:** Version 0.9.2-beta.14, Opus 4.6 requirement (not
  4.7 — context tracking failures), PKB snapshot date updated.

### 13.6b — 22 April 2026 (same-day second pass)
- **Model language softened:** "Required model" → "Recommended model."
  Opus 4.6 ET remains the validated choice. Sonnet and Opus 4.7 acknowledged
  as potentially viable for simple projects with caveat that advanced
  generation may fail silently. Haiku removed as a named option. Adaptive
  thinking limitation (no user-controlled ET) noted for Opus 4.7 and Sonnet.
- **Script header model-agnostic:** Removed hardcoded "Claude 4.6 Extended
  Thinking" from research disclosure boilerplate and attribution chain.
  Users note their actual model in their own disclosure.

### 13.5 — 21 April 2026
- **COMMANDS_Formant.txt v2.0:** Combined Formant + FormantPath +
  FormantModeler into a single reference file with routing decision.
  FormantPath is now the default algorithm when formant ceiling is
  uncertain. Formant (burg) with manual ceiling selection is the
  override for protocol-specified ceilings.
- **APPENDIX_D §4 rewrite:** FormantPath (burg) is now §4A (default).
  Formant (burg) is §4B (override). Routing decision at section top.
  Hard rule amended: manual ceiling selection required only when using
  Formant (burg), not when using FormantPath.
- **Rule 37 (Automated parameter optimization):** New rule — prefer
  Praat's automated parameter search commands over manual selection
  when no protocol-specified value exists.
- **Debugging Invariant 12:** Check for automated alternatives before
  adding manual parameter dialogs.
- **Formant query commands expanded:** Get mean, Get standard deviation,
  Get minimum, Get maximum, Get quantile, Get quantile of bandwidth,
  Get time of minimum, Get time of maximum, List formant slope —
  all added to COMMANDS_Formant.txt with verified signatures from
  Praat manual.
- **FormantPath commands promoted** from WHITELIST_CURRENT.txt to
  COMMANDS_Formant.txt: Extract Formant (with segfault bug
  documentation), Get optimal ceiling, Get stress of candidate,
  Get number of candidates, Draw as grid, Set path, Set optimal path.
- **FormantModeler commands promoted** from WHITELIST_CURRENT.txt to
  COMMANDS_Formant.txt: 15 commands covering query, draw, and convert.
- **FormantModeler scope limitation documented:** FormantModeler
  assumes smoothly varying formants and is valid only for sustained
  vowels or single tokens. On connected speech spanning multiple
  vowels, the polynomial model smooths away real transitions and
  flags real vowel targets as outliers. Connected speech requires
  per-vowel segmentation before FormantModeler is applied. Limitation
  documented in COMMANDS_Formant.txt (FormantModeler section header)
  and APPENDIX_D §4D with provenance from /u i u/ empirical test
  (21 April 2026).
- **APPENDIX_D §5B citation dates corrected:** Watts, Awan & Maryn
  2017 (was "Watts & Awan 2020"), Vojtech et al. 2020 (was "2023"),
  Heller Murray et al. 2022 (was "2021"). Reference file
  `praatgen_references_complete.md` added to Project Knowledge.

### 13.4 — 19 April 2026
- **Rule 5E (Command/function boundary):** Praat commands are statements
  (assigned via `=`); functions are expressions (composable). Commands
  cannot appear inside function calls, as arguments to other commands,
  or inside formula expressions. Diagnostic: `Unknown symbol «Get» in
  formula`. Added to Debugging Invariants (item 11) and SELF-AUDIT
  syntax check.

### 13.3 — 9 April 2026
- **Output compression is now default.** Compressed COMMAND PLAN,
  SELF-AUDIT, and inter-turn prose on all generation turns. Full
  verification still runs internally. Reply VERBOSE at any execution
  gate for expanded output. See OUTPUT COMPRESSION section.
- Step 1 mode list updated: VERBOSE is opt-in, compressed is default.
- Step 2 execution gate updated: GO/EXECUTE triggers compressed output.
- Step 3 Phase 3C testing block conditional on compression mode.

### 13.2 — 5 April 2026
- **Rule 5C (Interpolation scope constraint):** Single-quote variable
  name interpolation (`var'.i'`) works only inside procedure bodies
  (dot-prefixed variables). Fails in main script body at any depth.
  Bracket and vector notation work in all scopes. Verified empirically
  with four test scripts.

### 13.1 — 4 April 2026
- **Rule 28I:** Note added that `@emlAssertFullViewport` takes no
  parameters (reads from drawn extent globals), preferred over raw
  `Select outer viewport:` per Rule 34.
- **Rules 28J, 28K, 29, 30:** Stale file references
  (`EML_DRAWING_PROCEDURES.txt`) updated to
  `EML_PROCEDURE_REGISTRY.md`.
- **Rule 29:** `@emlHandleStereo` and `@emlApplyChannelChoice` now
  implemented in `eml-graph-procedures.praat` v3.18. `@emlCheckChannels`
  refactored to present user dialog instead of silent mono conversion.
  Guard patterns and specification unchanged — code now matches spec.

### 13.0 — 3 April 2026
- **Debugging Invariants:** New section after Rule 35. Compact list of
  constraints that must survive into deep debugging sessions regardless
  of context depth. Addresses observed drift where Claude drops MP rules
  as conversations lengthen.
- **Rule 5D (Reserved variable names):** `e`, `pi`, and `undefined` are
  Praat constants that cannot be used as variable names. Common collision
  with loop counters and procedure parameters.
- **Rule 36 (Tutorial content verification):** GUI step-by-step
  instructions (menu paths, editor actions, button labels) must never be
  generated from training data. All GUI steps must be empirically verified
  or sourced from the Praat manual.
- **House Rule (Demo window font state):** `demo Font size:` must be set
  exactly once. Use `demo Text special:` for all text rendering to avoid
  font-size-dependent x-offset drift.
- **Handoff template extracted** to `HANDOFF_TEMPLATE.md` in Project
  Knowledge. Step 4 now references the external file instead of inlining
  ~80 lines of template that consumed context on every turn.
- **Developer Mode extracted** to `DEVELOPER_MODE_ADDON.md`. Removed from
  core prompt to reduce token load for PraatGen users. Development
  projects add the addon file to Project Knowledge.

### 12.2 — 20 March 2026
- **PRAAT_DEFINITIVE_CATALOGUE.txt** added to Project Knowledge — complete
  Praat capability inventory extracted from v6.4.62 C++ source code via
  git clone and automated parsing. Contains 2,089 single-class commands
  with parameter defaults, 360 cross-class commands, 318 menu commands,
  336 Formula engine functions, class hierarchy for all 136 object types,
  and scripting engine reference. Verified 483/483 random-sampled commands
  against source with 0 errors, 0 parameter mismatches.
- **Reference Retrieval Protocol:** New table entry for the catalogue as
  fallback/verification source. New loading protocol rule (item 10):
  check catalogue before concluding a command or capability does not exist.
- **Rule 12 (Command verification):** PRAAT_DEFINITIVE_CATALOGUE.txt added
  as a Tier 1 instant-verification source alongside COMMANDS_*.txt and
  WHITELIST_CURRENT.txt.
- **Rule 24 (Confidence and escalation):** New "Capability verification
  (hard)" sub-rule — before asserting Praat cannot do something, load and
  search the catalogue. Lists the most commonly underestimated capabilities.
- **Coverage gap closed:** David Weenink's extensions (dwtools/) now have
  command-level reference coverage via the catalogue.

### 12.1 — 2 March 2026
- Extended thinking management protocol (Rule 31)
- Computational verification via Python/scipy sandbox (Rule 32)
- UX standards (Rule 33, APPENDIX_F)
- ET gates at COMMAND PLAN, code generation, and debugging phases
- Context budget awareness and handoff escalation in debugging loop
- Thinking token discipline and efficiency constraints