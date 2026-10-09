# PRAATGEN RULES — SANDBOX

Part of the PraatGen Master Prompt 16.0.0. Part of EML PraatGen
GPL-3.0-or-later — Ian Howell, Embodied Music Lab.

**Read this file in full:** Before installing or running Praat, in any mode. The core prompt's rule index governs when this file is read.

These rules are as binding as the core prompt. Rule, step and phase
numbers are unchanged from earlier versions; the core prompt's rule
index says which file holds each one. "This prompt" means the core
together with the six RULES files.

---

### STEP 2B: SANDBOX MODE (if user replies SANDBOX)

Makes testing before delivery required. In SANDBOX, every script is run
in Praat before it is delivered, and a script with a `form:` or
`beginPause:` block is driven through its real dialogs (see "Form-driven
verification" below and Rule 24C item 6B). Installing Praat on demand is
available in every session under Rule 24C; SANDBOX adds the testing
requirement. SANDBOX uses the full GUI edition with Xvfb unless the user
asks for barren or the Rule 24C platform check rules the GUI stack out.
Composable with any other mode.

**Setup (when SANDBOX work first needs Praat):**

1. Make the Rule 24C readiness request (see "Readiness request").
   - **Refused:** Quote the refusal to the user and offer the manual
     upload fallback per Rule 24C.
   - **Succeeded:** Proceed to installation.

2. Run the Rule 24C platform check (see "Platform check"). If it passes,
   install Praat (full + Xvfb). If it fails, install the barren edition
   per Rule 24C and say which check failed.

        apt-get install -y -qq --no-install-recommends xvfb libgtk-3-0 pulseaudio \
            openbox xcompmgr xdotool imagemagick
        # openbox   — window manager; xdotool activate/focus needs a WM
        # xcompmgr  — compositor; without it, screenshots of occluded
        #             windows come back BLACK (see Rule 24C, "Screenshot
        #             capture under Xvfb")
        # xdotool / imagemagick — GUI driving and capture
        work="$(pwd)"
        base="https://www.fon.hum.uva.nl/praat"
        # Resolve the build by INTENT — never pin an architecture token. Praat
        # renamed the 64-bit x86 Linux build (linux-intel64 -> linux-x64v3,
        # May 2026); a pinned arch string is a defect of the same class as a
        # pinned version. Download from fon.hum: it hosts the files. Do NOT
        # switch to the GitHub release mirror it links to — that is 403-blocked
        # by the egress proxy. Read the filename shape from the newest 64-bit x86
        # full build (exclude 32-bit / arm64 / s390x / -barren), then apply the
        # version pin.
        # dl.html is the page the readiness request saved; fetch only if absent.
        [ -s "$work/dl.html" ] || curl -sS "$base/download_linux.html" > "$work/dl.html"
        ver=$(grep -oE 'praat[0-9]+_linux' "$work/dl.html" | grep -oE '[0-9]+' | sort -n | tail -1)
        fn=$(grep -oE "praat${ver}_linux[A-Za-z0-9._-]*\.tar\.gz" "$work/dl.html" \
             | grep -vE 'arm64|s390x|linux32|-barren' | sort -u | head -1)
        pin=6630   # the one sanctioned version pin; see Rule 24C, Version management
        pinfn=$(echo "$fn" | sed "s/praat${ver}_/praat${pin}_/")
        curl -fL -o "$work/praat.tar.gz" "$base/$pinfn" \
          || { echo "Pinned $pin not found; installing newest ($ver)"; curl -fL -o "$work/praat.tar.gz" "$base/$fn"; }
        tar xzf "$work/praat.tar.gz" -C "$work"
        # Binary extracts as: "$work/praat"

   Verify: `xvfb-run -a "$work/praat" --run --version`

3. If a plugin zip is uploaded:
   - Extract to `"$work/eml"` (or appropriate directory)
   - Fix UTF-16 files:

         for f in $(find eml -name "*.praat"); do
             enc=$(file -b "$f" | grep -o "UTF-16")
             if [ -n "$enc" ]; then
                 iconv -f UTF-16 -t UTF-8 "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
             fi
         done

   - Run test suite if one exists
   - Report baseline: `"Praat [version] installed on [platform]. [N] assertions pass."`

4. Start virtual audio (required for `asynchronous Play`,
   `Play`, and any script that produces audio output):

        pulseaudio --start --exit-idle-time=-1

   Verify: `pactl info | head -1` should show a server string.
   Without this, `asynchronous Play` hangs indefinitely and
   synchronous `Play` blocks until timeout. PulseAudio's default
   null sink accepts audio output with no hardware.

5. Sandbox remains available for the rest of the conversation.

**Usage contexts (non-exhaustive):**
- Plugin development and refactoring
- PraatGen debugging (probe a command's existence and argument count
  empirically instead of requesting user verification via Rule 24B snippets)
- Running Rule 24B verification snippets directly
- Testing generated scripts before delivery
- Verifying editor commands, GUI rendering, or encoding behavior

**Form-driven verification (hard).** When a script under test has a `form:`
or `beginPause:` block, sandbox verification MUST drive the real script
through its real form — `runScript: "path", arg1, arg2, ...` with arguments
in form-field order, after creating and `selectObject:`-ing any objects the
script expects at launch. Do NOT verify by setting the script's derived
variables directly in a harness. Direct assignment bypasses the form parser
and the Rule 20 derivation step, so it CANNOT catch (a) label→variable
derivation mismatches (Rule 20), (b) bare-vs-quoted numeric default-type
errors (Rules 18/19), or (c) field count/order/type errors. A green sandbox
pass on a form-bypassing harness is false confidence — it certifies code the
real entry path rejects. To exercise the form: create + select the launch
objects, then `runScript:` the script file with positional form arguments;
a negative control (wrong value) should change the outcome.

**Scope:** SANDBOX is about testing. It does not change gate
structure, approval flow, or delivery cadence. Those are controlled
by the active execution mode (standard, SCAFFOLD, DEBUGGING, or
AUTONOMOUS).

**Interaction with Rule 24C:** Rule 24C makes installing Praat on
demand available in every session, with or without SANDBOX. SANDBOX
adds one requirement: every script is tested before delivery, so
installation happens at the first test instead of waiting for a
doubtful command. All Rule 24C guidance (readiness request, platform
check, where tests run, edition selection, `--new-send` vs `--run`,
`--utf8`, `--pref-dir`, TextGridEditor scoping, process lifecycle)
remains in force.

**Version management:** The filename is resolved at fetch time (above), so
a new Praat release needs no prompt edit. The filename shape and the
architecture token are read from the newest 64-bit x86 build — never pin an
architecture token. The version follows the one sanctioned pin in Rule 24C;
no other version number is hardcoded. The arch name has changed before (`linux-intel64` ->
`linux-x64v3`, May 2026); a pinned arch string fails silently exactly like a
pinned version. If resolution returns nothing, the download page structure
changed — inspect
`https://www.fon.hum.uva.nl/praat/download_linux.html` and adjust the
selection logic before reporting failure. Download from fon.hum; the GitHub
release mirror it links to is 403-blocked by the egress proxy. Never
reintroduce a hardcoded version number or arch token as a "fix."

**One version pin is currently in force (6.6.30, set 17 August 2026).** It
is stated once, under Rule 24C's Version management block, with its reason,
its evidence and its review trigger. Read it there; do not restate it here.

---

### Rule 24C: Sandbox verification (hard)

When empirical verification is needed and the user cannot immediately
test (or when the question is about Praat internals rather than
task-specific behavior), Praat can be installed and tested directly
in the sandbox environment. The platform observed so far is Ubuntu
24.04 x86_64 with root access; that is an observation, not a
guarantee, and the platform check below confirms it before the GUI
stack is installed. The working directory is whatever the shell
reports: every shell block sets `work="$(pwd)"` once and uses
`"$work"`; never assume a fixed path. The filesystem resets
between tasks — Praat must be installed fresh each session — but it
persists *within* a session, including across a container recycle. See
"Container recycle" below: the disk survives, the processes do not.

**Readiness request (hard).** At the first moment verification is
needed, request the Praat download page once, from the shell:

    work="$(pwd)"
    code=$(curl -sS -D "$work/dl.headers" -o "$work/dl.html" -w '%{http_code}' \
           "https://www.fon.hum.uva.nl/praat/download_linux.html")
    echo "HTTP $code"
    # 200: installation is available. The install blocks reuse dl.html.
    # Anything else, or a curl error, is a refusal.

- **Success:** Installation is available. Proceed to installation.
- **Refusal:** Installation is not available. Quote the refusal to the
  user verbatim — the status code, any `x-deny-reason` header in
  `dl.headers`, and curl's error text — and offer the manual upload
  fallback (below).

Access to `www.fon.hum.uva.nl` depends on the Claude plan and its
settings, and is not fully documented. An individual Max account
reached the site by default when tested on 8 October 2026; other plans
are untested. On Team and Enterprise plans, the organization owner
controls the allowed domains. **Never tell the user installation is
unavailable without having made the request.**

Installation happens on demand — only when a verification question
arises (Rule 24 confidence check, Rule 24B snippet alternative,
debugging hypothesis testing), or at the first test in SANDBOX
(Step 2B). Do not install preemptively.

**Platform check (hard).** Before installing the GUI stack (Xvfb, GTK,
PulseAudio, openbox, xcompmgr, xdotool, imagemagick), check the OS
version and root access, then try the install itself:

    . /etc/os-release && echo "OS: $PRETTY_NAME $(uname -m)"
    [ "$(id -u)" -eq 0 ] && echo "root: yes" || echo "root: no"
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq --no-install-recommends xvfb libgtk-3-0 pulseaudio \
        openbox xcompmgr xdotool imagemagick >/dev/null 2>&1 \
        && echo "GUI packages: ok" || echo "GUI packages: FAILED"

The install's result decides, not `apt-get update`'s. Update can print
warnings about third-party package sources the image ships with (observed:
the Docker source refused with 403 on 8 October 2026) and still succeed;
those warnings are harmless. Observed on 8 October 2026: Ubuntu 24.04
x86_64, root, update and install both succeeded.

If a check fails, or the GUI packages fail to install, fall back to
the barren edition, which needs none of them, and tell the user which
check failed. The barren edition cannot verify editors, the Picture
window, dialogs or playback (see the edition table below); say which
parts of the script that leaves untested.

**Where tests run (hard).** The Linux sandbox is the reference for a
pass. A test run on the user's own machine is additional evidence; it
does not replace the sandbox run. Every reported test result names the
platform and the Praat version it ran on. Behavior that depends on the
platform — file dialogs, fonts, `Insert picture from file:`, Demo window
size — counts as verified only on the platform where it ran. Example:
`Insert picture from file:` draws nothing on Linux builds of Praat, so a
sandbox pass says nothing about how a script that uses it draws on macOS
or Windows, and a pass on macOS says nothing about Linux.

**Two editions, two capability tiers:**

| Edition | Install size | Capabilities | Cannot do |
|---------|-------------|-------------|-----------|
| Barren | ~60 MB | Object window commands, Formula syntax, variable scoping, file I/O, data queries, all non-GUI scripting | No editors (`View & Edit` fails: "Cannot edit from batch"), no Picture window, no playback |
| Full + Xvfb + PulseAudio | ~60 MB + ~25 MB deps | Everything: editors, `View & Edit`, `editor:` / `endeditor` blocks, editor commands, Picture window, `asynchronous Play`, `Play` | Requires process lifecycle management; output must go to files not stdout |

**Installation — Barren edition (non-GUI verification):**

    work="$(pwd)"
    base="https://www.fon.hum.uva.nl/praat"
    # Read the filename shape from the newest 64-bit x86 BARREN build, then apply
    # the version pin below; never pin the arch
    # token (linux-intel64 -> linux-x64v3, May 2026). fon.hum hosts the files;
    # do NOT switch to the GitHub mirror it links to (403, proxy-blocked).
    # dl.html is the page the readiness request saved; fetch only if absent.
    [ -s "$work/dl.html" ] || curl -sS "$base/download_linux.html" > "$work/dl.html"
    ver=$(grep -oE 'praat[0-9]+_linux' "$work/dl.html" | grep -oE '[0-9]+' | sort -n | tail -1)
    fn=$(grep -oE "praat${ver}_linux[A-Za-z0-9._-]*-barren\.tar\.gz" "$work/dl.html" \
         | grep -vE 'arm64|s390x|linux32' | sort -u | head -1)
    pin=6630   # the one sanctioned version pin; see Rule 24C, Version management
    pinfn=$(echo "$fn" | sed "s/praat${ver}_/praat${pin}_/")
    curl -fL -o "$work/praat_barren.tar.gz" "$base/$pinfn" \
      || { echo "Pinned $pin not found; installing newest ($ver)"; curl -fL -o "$work/praat_barren.tar.gz" "$base/$fn"; }
    tar xzf "$work/praat_barren.tar.gz" -C "$work"
    # Binary extracts as: "$work/praat_barren"
    # Verify:
    "$work/praat_barren" --version

    # Run a test:
    cat > "$work/test.praat" << 'EOF'
    writeInfoLine: "Working: ", praatVersion$
    EOF
    "$work/praat_barren" --run "$work/test.praat"
    # Output goes to stdout

**Installation — Full GUI edition (editor verification):**

    # Run the platform check (above) first. If it fails, or this install
    # fails, use the barren edition and say which check failed.
    # Install display server and GTK dependencies
    apt-get install -y -qq --no-install-recommends xvfb libgtk-3-0

    work="$(pwd)"
    base="https://www.fon.hum.uva.nl/praat"
    # Read the filename shape from the newest 64-bit x86 FULL build, then apply
    # the version pin below; never pin the arch
    # token (linux-intel64 -> linux-x64v3, May 2026). fon.hum hosts the files;
    # do NOT switch to the GitHub mirror it links to (403, proxy-blocked).
    # dl.html is the page the readiness request saved; fetch only if absent.
    [ -s "$work/dl.html" ] || curl -sS "$base/download_linux.html" > "$work/dl.html"
    ver=$(grep -oE 'praat[0-9]+_linux' "$work/dl.html" | grep -oE '[0-9]+' | sort -n | tail -1)
    fn=$(grep -oE "praat${ver}_linux[A-Za-z0-9._-]*\.tar\.gz" "$work/dl.html" \
         | grep -vE 'arm64|s390x|linux32|-barren' | sort -u | head -1)
    pin=6630   # the one sanctioned version pin; see Rule 24C, Version management
    pinfn=$(echo "$fn" | sed "s/praat${ver}_/praat${pin}_/")
    curl -fL -o "$work/praat_gui.tar.gz" "$base/$pinfn" \
      || { echo "Pinned $pin not found; installing newest ($ver)"; curl -fL -o "$work/praat_gui.tar.gz" "$base/$fn"; }
    tar xzf "$work/praat_gui.tar.gz" -C "$work"
    # Binary extracts as: "$work/praat"

**Full GUI usage — critical details:**

1. **Use `--new-send`, NOT `--run`.** `--run` is batch mode — it
   CANNOT open editors. `View & Edit` fails with "Cannot edit a
   Sound from batch." `--new-send` starts a GUI instance.

2. **Output goes to files, not stdout.** Use `writeFileLine:` /
   `appendFileLine:` to write results to disk.

3. **`--utf8` is NOT sufficient (hard) — sandbox-verified, Praat 6.6.30, 29 Jul 2026.**
   `--utf8` alone does not guarantee UTF-8 output. **A single non-ASCII
   character anywhere in a written string makes Praat write the ENTIRE file
   as UTF-16 BE, with `--utf8` set.** Verified triggers include:
   `—` `–` `…` `’` `“` `°` `µ` `±` `Δ` `é` `≥` — every one of them flips the
   file. Once flipped, later `appendFileLine:` calls keep it UTF-16.

   This is the actual cause of the historical UTF-16 `eml-batch-process.txt`
   incident, and it means the old note "em-dashes in string literals are
   harmless unless something re-encodes" was wrong: writing one to a file IS
   the re-encoding.

   **Rule: any string literal written to a file with `writeFileLine:`,
   `appendFileLine:`, `writeFile:` or `appendFile:` must be pure ASCII.**
   Use `->` not `→`, `-` not `—`, `deg` not `°`, `+/-` not `±`, `u` not `µ`.
   Non-ASCII is fine in Info-window output and in Picture text (where
   APPENDIX_E's escape conventions govern); it is the FILE path that breaks.
   Downstream tools — R `read.csv`, pandas, Excel import, `grep` — read a
   UTF-16 CSV as binary or garbage.

   **ASCII is stricter than valid UTF-8.** Every ASCII file is valid UTF-8;
   the reverse is not true, and Praat switches the whole output file to
   UTF-16 BE the moment a written literal leaves the ASCII range. An em-dash
   is perfectly good UTF-8 and still flips the file. Verified with `--utf8`
   set: a pure-ASCII write produced `ASCII text`, the same line with one
   em-dash produced `Unicode text, UTF-16, big-endian`.

   **The sweep covers copied library text, not just your own (hard).** The
   shipped `eml-*` sources contain roughly 140 non-ASCII string literals —
   em-dashes, ellipses, middots. They are harmless where they are, because
   they reach `appendInfoLine` and not a file. They stop being harmless the
   moment a procedure carrying one is pasted into a script that writes
   output. When library text is copied in, sweep it too.

   SELF-AUDIT (Rules 26/27 line): when the script writes any file, confirm
   every written literal is ASCII **and state the scope of the sweep** — own
   code only, or own code plus copied library text. If any non-ASCII survives,
   name it and say why it cannot reach a file.

4. **Use `--pref-dir` with a fresh directory.** Stale lock files
   cause "An instance of Praat that is not me is already running."

5. **Kill stale processes and clear the X lock between runs — never with
   `pkill -f` (hard).** `pkill -f` matches the FULL command line of every
   process, and the pattern you typed is sitting in the command line of the
   shell running the `pkill`. It kills that shell. This is not about Praat
   and not about Xvfb: sandbox-verified 3 August 2026, a pattern matching
   **no process anywhere** (`pkill -9 -f zzz_no_such_pattern_zzz`) still
   killed the issuing shell with signal 9. `-f praat` and `-f Xvfb` did the
   same. Match the process NAME instead:

       pkill -9 -x praat 2>/dev/null
       pkill -9 -x Xvfb 2>/dev/null
       rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
       sleep 2

   `-x` matches the name, not the command line, so the shell cannot match
   itself; both survived. `pkill -9 -f '[p]raat'` also survives if you need
   `-f`. The lock removal is not optional — see "Container recycle" below.

6. **End test scripts with `Quit`.** Without it, the GUI stays
   open indefinitely after the script completes.

6B. **Choose the installation to match what the script contains, before
   writing the test (hard).** `--run` is batch: no GUI at all, so it cannot
   open an editor and cannot show a pause form. `--new-send` under the Xvfb
   stack is the full GUI. Decide which you need by reading the script, not
   by starting in batch and discovering a wall.

   **A wall you hit because you picked the wrong installation is a setup
   choice, not a finding.** Never report "this could not be verified in the
   sandbox" for anything the other installation would have verified — switch
   and verify it. If the script has a pause form, an editor block, or Picture
   output, bring up Xvfb + openbox + xcompmgr from the start.

   Driving the GUI once it is up, sandbox-verified 3 August 2026:

   - **Use XTEST — never `--window` targeting.** `xdotool key --window <id>`
     and `xdotool click --window <id>` are both silently discarded by GTK
     (it ignores `send_event` input). Bare `xdotool key Return` and
     `xdotool mousemove X Y click 1` both drive the dialog correctly. The
     split is transport, not keyboard-versus-mouse.
   - **Take coordinates from a ROOT capture.** `import -window root`, then OCR
     it; the coordinates are already root-absolute. Capturing the window
     instead and adding its origin double-counts the window-manager
     decoration and the click lands nowhere.
   - Verified end to end on a `beginPause`/`endPause` form: both buttons
     clicked, the boolean read back at both settings, and the branch that
     writes a preferences file exercised.

7. **Screenshots: a black frame is a capture defect, not a render
   failure (hard).** See "Screenshot capture under Xvfb" below before
   reporting that a dialog or window "did not render."

---

#### Screenshot capture under Xvfb (hard)

Diagnosed and verified 29 July 2026, Praat 6.6.30 / Xvfb / GTK3. Symptom:
`import -window <id>` returns an all-black or partially-black PNG even
though the application is running and the window exists.

**Cause.** Plain X11 has no compositing. A window's pixels live in the
shared framebuffer, so any region covered by another window is simply not
stored anywhere. `import -window <id>` reads that framebuffer region, and
occluded areas come back black. This is not a Praat bug and not an
`import` bug — the content genuinely does not exist to be read.

**Verified behaviour matrix:**

| Condition | `import -window <id>` | `import -window root` |
|---|---|---|
| Window fully visible | OK | OK |
| Window partly occluded, no compositor | **black in the occluded region** | OK (shows the occluder) |
| Window partly occluded, `Xvfb +bs` | **still black** | OK |
| Window partly occluded, `xcompmgr` running | **OK** | OK |
| Application exited / nothing mapped | 100% black | 100% black |

Note that `Xvfb +bs` does **not** fix it: the X server option only
*permits* backing store, which the client must then request per-window.
GTK3 does not request it.

#### Driving dialogs, and running several Praat instances at once (hard)

Verified 21 September 2026, Praat 6.6.30 under Xvfb + openbox + xcompmgr.

**Click with window-relative coordinates.** `xdotool mousemove --window <id>
<x> <y>` takes the coordinates that `import -window <id>` produces, and lands
on the target with no correction. Absolute screen coordinates need an offset
that changes with the window manager and the screen size, and they go stale
if the window moves between the capture and the click. Measured: a control at
(467, 500) in the captured window resolved to (655, 692) on screen, dead on
the button.

**Poll for the window; do not sleep.** Wait for `xdotool search --name` to
return the dialog before acting, the same way the display probe polls
`xdotool getdisplaygeometry` at startup. Fixed sleeps dominate the wall clock
of a scripted walk and fail intermittently under load.

**One Praat instance per display and per preferences folder.** Give each
instance its own `:9N` display and its own `--pref-dir`. Delete the stale
`pid` and `message` files in that folder before every launch: a relaunch that
finds a live-looking pid forwards its script to a dead process and exits
silently. The filenames differ by major version — `pid` and `prefs5` on 6.x,
`pid.txt`, `Message.txt`, `Preferences.txt` and `Buttons.txt` on 7.x.

**Assert that the plugin loaded.** A harness that isolates a plugin by
`--pref-dir` alone loads no plugin at all on Praat 7, with no error, and the
walk then fails in a way that looks like a missed click. Redirect `HOME`,
place the plugin at the version-correct path, and confirm at startup that a
plugin-created object or menu entry exists. Absence must fail loudly.

**Fix, in order of preference:**

1. **Run a compositing manager.** `xcompmgr` redirects window contents to
   offscreen pixmaps, so direct window capture always succeeds regardless
   of stacking. Add to the sandbox GUI setup:

        export DISPLAY=:99
        # Unconditional, not a recovery step: a container recycle leaves the
        # lock behind and Xvfb then dies with "Server is already active for
        # display 99", DISPLAY resolves to null, and every later xdotool or
        # import call fails in a way that looks like a Praat problem.
        pkill -9 -x Xvfb 2>/dev/null; rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
        Xvfb :99 -screen 0 1400x1000x24 &
        # Probe readiness; do not sleep and hope.
        for i in $(seq 20); do xdotool getdisplaygeometry >/dev/null 2>&1 && break; sleep 0.5; done
        openbox &                      # a WM — xdotool windowactivate
        sleep 1                        #   needs _NET_ACTIVE_WINDOW
        xcompmgr &                     # the compositor — fixes black frames
        sleep 1

   **Readiness probe (hard).** Use `xdotool getdisplaygeometry` — it returns
   e.g. `1500 1100` with rc=0 once the server is up. The two obvious
   alternatives are both wrong, and both fail *silently as "never ready"*:
   `xdpyinfo` **is not installed in the sandbox image**, and
   `xdotool search --name "."` returns rc=1 on a live display that has no
   windows yet, which is exactly the state you are probing.

2. **Raise the window immediately before capturing** —
   `xdotool windowraise <id>; sleep 1; import -window <id> out.png`.
   Works without a compositor (verified 0% black), but is racy if
   anything else maps a window in between.

3. **Capture root and crop** to the window's geometry:

        eval $(xdotool getwindowgeometry --shell $wid)
        import -window root -crop ${WIDTH}x${HEIGHT}+${X}+${Y} +repage out.png

**Always validate the frame (hard).** A capture that is ~100% black means
nothing was mapped — usually the application died. Do not report such a
frame as evidence of anything. Check the pixels, then check the process:

        pct=$(python3 -c "from PIL import Image;im=Image.open('out.png').convert('L');p=list(im.getdata());print(round(100*sum(1 for v in p if v<8)/len(p),1))")
        # >95 means: pgrep praat (did it crash?), pgrep xcompmgr (compositor up?)

**Two more traps, both verified:**

- **`xdotool windowactivate` fails with no window manager** — "Your
  windowmanager claims not to support _NET_ACTIVE_WINDOW". Start a WM
  (openbox) before any activate/focus call, or use `windowraise`, which
  needs no WM.
- **`--run` cannot show dialogs.** A script whose `beginPause` you need to
  see must be opened in the GUI script editor and run with Ctrl+R
  (`xdotool key ctrl+r`); under `--run` the dialog aborts with a GTK
  "Trace/breakpoint trap" and no Praat error.

#### Container recycle: processes die, the filesystem does not (hard)

Background processes usually survive from one tool call to the next. They do
**not** survive a container recycle, which can happen between calls and has been
observed coinciding with context compaction. The filesystem is a separate
persistent volume and comes through intact.

That asymmetry is the whole problem. After a recycle the installed Praat binary,
your scripts and your captured PNGs are all still on disk, so the environment
*looks* healthy — while Xvfb, the window manager, the compositor and any running
Praat are gone. The next call fails as `Can't open display: (null)`, or returns a
screenshot of a display that no longer exists.

**The design rule is the fix; detection only explains the symptom.**

**Make every GUI interaction one self-contained call** that brings up the display
stack, drives Praat, captures to disk, and exits. Never build a workflow that
depends on a process staying alive across calls. **Files are the handoff medium
between calls — not processes.** Follow this and a recycle costs you nothing,
because you rebuild the stack every time anyway.

**If you need to confirm one happened,** compare the boot ID rather than guessing
from symptoms:

    cat /proc/sys/kernel/random/boot_id     # changes on recycle

Write it to a file in the output folder when you start anything long-lived, and
compare on the next call — a value held in context is exactly what a compaction
takes from you. A changed boot_id means rebuild; do not try to reattach.
`ps -p 1 -o etimes=` (PID 1 uptime in seconds) corroborates it for a human reader,
but do not make it the test: it requires knowing the wall-clock gap since your last
call, which you do not reliably have. The boot_id comparison needs no clock.

Provenance: EML PraatGen sandbox session, 29 July 2026, Praat 6.6.30
(linux-x64v3), Ubuntu 24.04. Recycle observed directly — PID 1 uptime of 24 minutes
in a session nine hours old, with a Praat binary installed at the start of it still
running fine from disk.

---

**Complete test template:**

     pkill -9 -x praat 2>/dev/null        # -x not -f: see item 5
     pkill -9 -x Xvfb 2>/dev/null
     rm -f /tmp/.X99-lock /tmp/.X11-unix/X99      # stale after a recycle
     pulseaudio --check 2>/dev/null || pulseaudio --start --exit-idle-time=-1
     sleep 2

    work="$(pwd)"
    rm -f "$work/test_results.txt"
    mkdir -p "$work/praat_prefs"

    cat > "$work/test_editor.praat" << 'EOF'
    # defaultDirectory$ is the folder holding this script, i.e. "$work"
    outFile$ = defaultDirectory$ + "/test_results.txt"
    soundId = Create Sound from formula: "test", 1, 0, 0.5, 44100,
        ... ~sin(2*pi*200*x)
    selectObject: soundId
    View & Edit
    editor: soundId
        Zoom: 0.1, 0.4
        visStart = Get start of visible part
    endeditor
    writeFileLine: outFile$, "Zoom verified: ", fixed$(visStart, 3)
    removeObject: soundId
    appendFileLine: outFile$, "DONE"
    Quit
    EOF

    timeout 15 xvfb-run -a "$work/praat" --new-send \
        --pref-dir="$work/praat_prefs" \
        --utf8 "$work/test_editor.praat" 1>/dev/null 2>/dev/null

    cat "$work/test_results.txt"

**TextGridEditor scoping rule (hard):** In a TextGridEditor (Sound +
TextGrid open together), `editor:` MUST target the **TextGrid** ID,
not the Sound ID. The editor is registered under the TextGrid.

    selectObject: soundId, gridId
    View & Edit
    editor: gridId              # CORRECT — TextGrid is primary
        Mute channels: "1 2 3"  # Sound command works from gridId
    endeditor

Using `editor: soundId` in a TextGridEditor hangs indefinitely.

**If the readiness request is refused (manual upload fallback):**

User downloads the pinned build (6.6.30; see Version management) by direct
link. The download page does not list it:
- Barren: `https://www.fon.hum.uva.nl/praat/praat6630_linux-x64v3-barren.tar.gz`
- Full: `https://www.fon.hum.uva.nl/praat/praat6630_linux-x64v3.tar.gz`

If those links fail, the user downloads the newest 64-bit x86 Linux build from
`https://www.fon.hum.uva.nl/praat/download_linux.html`, and the model says that
the pin could not be applied. (The arch token changed from `linux-intel64` to
`linux-x64v3` in May 2026; match whatever the page shows.) User uploads the
`.tar.gz` file to the conversation. The upload location differs between
setups, so find the archive by file name — do not assume a folder, the
number or the arch — and untar whatever arrived:

    work="$(pwd)"
    # Newest match wins: an older Praat archive can already be on disk.
    archive=$(find / -path /proc -prune -o -name 'praat*_linux*.tar.gz' \
              -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    echo "Found: $archive"     # confirm this is the file the user uploaded
    tar xzf "$archive" -C "$work"

For the full edition, `apt-get install xvfb libgtk-3-0` still needs
`apt-get` to reach the Ubuntu package repositories. The platform check
above tests this; if it fails, install the barren archive instead.

**When to use which method:**

| Question | Method |
|----------|--------|
| "Does this syntax work?" | Snippet (Rule 24B) — user pastes into Praat |
| "What does this command return?" | Snippet |
| "Does this editor command exist?" | Sandbox (full + Xvfb) |
| "Does this dialog render correctly?" | Sandbox (full + Xvfb) |
| "Is this Formula valid?" | Sandbox (barren) |
| "What encoding does this produce?" | Sandbox (barren) |
| "Does variable scoping work this way?" | Sandbox (barren) |
| "How many parameters does this command take?" | Sandbox (barren or full — error messages reveal expectations) |

Preference order: Snippet > Sandbox barren > Sandbox full + Xvfb.

**Version management:** The install commands above resolve the filename at
fetch time, so a new Praat release needs no prompt edit. The filename shape
and the architecture token are read from the newest 64-bit x86 build — never
pin an architecture token. The version follows the pinned exception below;
no other version number is hardcoded. The arch name changed from `linux-intel64`
to `linux-x64v3` in May 2026; a pinned arch string fails silently exactly
like a pinned version (this is what broke the snippet on 3 Jun 2026). If
resolution returns nothing, inspect
`https://www.fon.hum.uva.nl/praat/download_linux.html` and adjust the
selection logic before reporting failure. Download from fon.hum; the GitHub
release mirror it links to is 403-blocked by the egress proxy. Never
reintroduce a hardcoded version number or arch token as a "fix."

**Pinned exception — resolve the VERSION to 6.6.30, not newest.** Set
17 August 2026. Review when Praat 7's trust behaviour changes, or at the
next 7.x point release, whichever comes first. This is the only sanctioned
pin. The arch token stays resolved by intent; the paragraph above governs
it unchanged.

**Prefer 6.6.30 whenever Praat is installed.** This covers the sandbox and
any advice to the user about which build to install for writing and testing
scripts. It does not move the 6.4.39 floor or change the §S15 version check.
- **Nothing PraatGen uses requires 7.0.02 or later.** The newest
  version-gated feature in `PRAAT_VERSION_FLOOR.txt` is already present in
  6.6.30. The additions in 7.0.01 and 7.0.02 (the CPP object,
  `Sound: To CPP...`, Corpus and CGN extraction) appear nowhere in the PKB or
  the eml procedures (checked against Praat's release notes, 8 October 2026).
  If a request ever needs a 7.x-only feature, say so in the pre-flight, add
  it to the script's version check, and test it on 7.x.
- **7.0.02 and later carry a security feature that slows development.** It
  arrived in 7.0, so every later build has it. A script that writes a file
  or runs a system command stops for the user's permission in the GUI; the
  grant lasts one run; and `--run` needs `--FULL-TRUST`.
- **Anything that runs on 6.6.30 also runs on the current version.** On 7.x
  the user answers the permission prompt and the script proceeds.

Why: Praat 7.0 requires the user's permission before a script may write a
file or run a system command. A `--run` verification that writes anything
fails without `--FULL-TRUST`, which breaks the sandbox self-verification
loop. Adding the flag unconditionally is not safe either — 6.4.62 and
earlier reject it, print usage, run nothing, and **exit 0**, so a rejected
flag reads as a clean pass.

What the pin costs: nothing measurable. The floor probe returns identical
values on 6.6.30 and 7.0 — CPPS 12.114037, Formant F1 161.676520 /
F2 456.216348, LPC 191 frames — with only the version line differing
(sandbox, 17 August 2026).

When the pin is lifted: add `--FULL-TRUST` to every `--run` invocation, and
assert on expected output rather than on exit status alone.

Provenance: Established 7 May 2026. Praat 6.4.65 barren and full
editions tested in Ubuntu 24.04 sandbox. 15 editor commands verified
via Xvfb. TextGridEditor scoping rule discovered empirically.

---

---

End of RULES_SANDBOX.md. Read token: alder-699
