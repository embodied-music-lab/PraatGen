# Best Practices: EGG Contact Quotient Measurement

**Author:** Ian Howell, Embodied Music Lab (embodiedmusiclab.com)
**Compiled from:** EML PraatGen sandbox verification session, 29 July 2026
**Praat version:** 6.6.30
**Status:** Empirically validated against synthetic signals with analytically known crossings, graded-SNR variants, and a real stereo audio+EGG recording.
**Revised:** 30 July 2026. Method selection (§5) is a PRE-FLIGHT discussion, not a dialog field, and the SNR figures are guidance to reason from rather than thresholds to branch on: dEGG is the default, and in the 10–20 dB band dEGG and hybrid-at-0.43 are taken together and compared. `Derivative` is the default differentiator (§3). Sub-10 dB signals are refused on signal quality. There is no de-noising path (§4).

**Maintainers:** version history for this file, including what was removed and why, is in `PRAATGEN_CHANGELOG.md`. Nothing about the library's own development belongs in a reply to the user.

For command syntax, arity, return types, and failure modes: see `COMMANDS_Electroglottogram.txt`.

---

## 0. Provenance — read before citing

Sections 1–4 are literature-sourced and cited. **Section 5 is a lab recommendation and carries no external authority.** Do not attribute it to the cited authors.

The published sources describe algorithms and study exclusion criteria. They do not specify a runtime decision procedure for a software tool. Where this document turns a study design decision into tool behaviour, it says so.

---

## 1. The three CQ methods

### (a) dEGG

- Contacting instant = positive peak of the EGG derivative
- De-contacting instant = negative peak of the derivative
- Period = GCI[i+1] − GCI[i]; CQ = (GOI − GCI) / period

Herbst et al. (2017) found that, disregarding low-quality signals, the best agreement between CQegg and the videokymographic closed quotient came from an algorithm operating on the first derivative. **This is the default method for adequate signals.**

### (b) Hybrid (Howard's method)

- Contacting instant = positive peak of the EGG **derivative**
- De-contacting instant = descending crossing of a fixed threshold on the EGG **waveform**
- Threshold: 3/7 = 0.4286, conventionally written 0.43
- Origin: Davies et al. (1986); Howard (1995)

Rationale: the derivative's de-contacting trough is broad and shallow compared with its contacting peak, so the GOI degrades first as noise rises. The waveform crossing is more stable.

**The two landmarks come from different signals.** Derivative for closing, undifferentiated waveform for opening. Implementing both on one signal is wrong.

Praat cannot do this natively. `To TextGrid (closed glottis)` applies its threshold to *both* crossings, so it cannot produce a dEGG closure with a threshold opening. The hybrid must be hand-rolled — see §6.

### (c) Threshold-only (criterion level)

Both instants from waveform threshold crossings — what `To TextGrid (closed glottis)` implements natively. Common criteria: 0.20, 0.25, 0.35. Herbst & Ternström (2006) found 0.20 or 0.25 gave the best match to videokymography.

### CQ values are not comparable across methods or criteria

Always report the method and the threshold. Measured on one real recording (F0 244 Hz, SNR 27.1 dB, 1874 cycles):

| method | CQ |
|---|---|
| dEGG | 0.4280 |
| hybrid at 0.43 | 0.4559 |
| threshold at 0.25 | 0.5524 |

A spread of 0.124 on identical data.

---

## 2. EGG signal-to-noise ratio

Herbst et al. (2017) report that phonations with an EGG SNR below 10 dB are not suited to CQegg analysis. That criterion is actionable, and the measurement is three lines using canonical Appendix D parameters:

```praat
selectObject: eggSoundId
h = noprogress To Harmonicity (cc): 0.01, 75, 0.1, 1.0
selectObject: h
snr = Get mean: 0, 0
```

**Validated** against signals with known added noise:

| true SNR | measured |
|---|---|
| 40 | 39.7 |
| 30 | 29.9 |
| 20 | 20.1 |
| 15 | 15.3 |
| 10 | 10.5 |
| noise only | −7.6 |

Accurate within 0.5 dB across the usable range.

### Glide robustness

Praat's harmonicity window is six periods of the pitch floor — 80 ms at floor 75 — which raises a legitimate concern that F0 movement inside the window would smear the autocorrelation and depress the reading. Tested:

| condition | true SNR | measured | error |
|---|---|---|---|
| static 200 Hz | 30 | 30.02 | +0.02 |
| static 200 Hz | 20 | 20.14 | +0.14 |
| static 200 Hz | 10 | 10.44 | +0.44 |
| octave glide 176–350 | 30 | 29.64 | −0.36 |
| octave glide 176–350 | 20 | 20.07 | +0.07 |
| octave glide 176–350 | 10 | 10.40 | +0.40 |

**An octave glide costs under 0.4 dB at realistic noise levels.** The glide penalty and the noise do not add; the larger dominates, and at 10–30 dB the noise is far larger. HNR is therefore valid on gliding and non-sustained material, and Herbst's 10 dB criterion transfers.

**Caveat:** on a *noiseless* signal the glide is the only thing left to measure and dominates completely — a noiseless octave glide reads 41.8 dB against 133.6 dB static. HNR therefore saturates around 40–50 dB on gliding material and cannot distinguish "very clean" from "extremely clean." Nothing downstream depends on that distinction.

**No quiescent segment is required.** Do not impose one as a protocol burden.

---

## 3. Which derivative

`First central difference` is the literature-standard differentiator and the correct choice when replicating published dEGG values. It applies **no band limiting** — the single argument is a rescale factor. `Derivative` applies a low-pass.

Measured consequence on synthetic signals at graded SNR — GCI detection yield:

| SNR | First central difference | Derivative: 5000, 100, 0 |
|---|---|---|
| clean | 297 | 297 |
| 40 | 297 | 297 |
| 30 | 297 | 297 |
| 20 | **0** | 297 |
| 15 | **0** | 268 |
| 10 | 0 | 0 |

**`Derivative` is the default. Offer `First central difference` when it is
appropriate** — that is, when the task replicates a published protocol that
specifies FCD, or when the user asks for it. Say which one ran, in the output.

`Derivative` extends usable GCI detection two SNR steps further, and FCD's
collapse to zero at SNR 20 is not a graceful degradation — it is a cliff, at an
SNR that real recordings routinely sit at or below.

**Caveat on the low-pass, and it is a real one.** `5000, 100, 0` is a *chosen*
parameter set, not a validated optimum, and the 5000 Hz cutoff is doing the work
that produces the advantage in the table above. The right cutoff depends on
sampling rate, F0 and the sharpness of the closure peak: too low smears the GCI
and biases CQ, too high forfeits the noise rejection. The comparison above was
run at one cutoff on one synthetic waveform shape. Treat 5000 Hz as a sensible
starting point that should be sanity-checked against the peak timing on real
material, not as a settled value — and if a task turns on the choice, sweep it.

### The derivative is the binding constraint

Measured on a real recording:

- EGG waveform HNR: 22.1 dB
- dEGG HNR: 14.0 dB

Differentiation cost 8 dB. Ternström (2024) makes the same point — that no current EGG hardware has sufficient SNR *of the derivative*. **A waveform SNR comfortably above 10 dB does not guarantee a usable derivative.**


### Polarity: the derivative peak test (PraatGen practice)

Praat expects an EGG whose value rises with contact. An inverted EGG doesn't
error, and its dEGG CQ reads as 1 minus the true CQ. That value usually lies
inside the 0.15–0.85 plausibility bound, so the bound doesn't catch it.

PraatGen tests polarity from the derivative instead. The contacting peak of the
derivative is sharp and tall, and the de-contacting trough is broad and shallow
(§1b). On an upright EGG the derivative's largest positive value is larger than
the size of its largest negative value. When the negative value is larger, the
EGG is inverted. This test is PraatGen's own practice. It doesn't come from a
published source.

Make the test the default and offer it as a workflow option. State it in
PRE-FLIGHT as the default. The user can instead fix polarity as recorded or as
inverted, for example when they know their hardware. The test runs on the whole
analysis window, before cycle detection, with the same differentiator as the
CQ measurement:

```praat
# Lab judgement, not a validated value
polarityAmbiguity = 1.25

selectObject: soundId
eggId = Extract Electroglottogram: eggChannel, "no"
selectObject: eggId
polDerivId = Derivative: 5000, 100, 0
selectObject: polDerivId
dMax = Get maximum: 0, 0, "Sinc70"
selectObject: polDerivId
dMin = Get minimum: 0, 0, "Sinc70"
removeObject: polDerivId
polarityRatio = undefined
if dMin < 0
    polarityRatio = dMax / abs (dMin)
endif
eggInverted$ = "no"
polarityUndecided = 0
if polarityRatio = undefined
    polarityUndecided = 1
elsif polarityRatio < 1 / polarityAmbiguity
    removeObject: eggId
    selectObject: soundId
    eggId = Extract Electroglottogram: eggChannel, "yes"
    eggInverted$ = "yes (auto)"
elsif polarityRatio < polarityAmbiguity
    polarityUndecided = 1
endif
# polarityUndecided = 1: keep the polarity as recorded and warn
```

- Report the ratio and whether the EGG was inverted, in the Info window and in
  every output row.
- A ratio near 1 means the test can't decide. An EGG whose rise and fall take
  the same time gives a ratio of 1.000 either way up. Between `1 / polarityAmbiguity`
  and `polarityAmbiguity`, keep the polarity as recorded and warn.
  `polarityAmbiguity = 1.25` is a lab judgement, not a validated value.
- One large artifact in the window can decide a whole-window maximum. When the
  ratio is close to the band, look at the signal.

Provenance: sandbox-verified 6.6.30, 8 Oct 2026, on synthetic EGGs.
`Derivative` returns a Sound. Ratios: 3.278 upright and 0.305 inverted (fast
rise, 300 Hz); 1.484 and 0.614 with noise SD 0.1; 4.127 at 150 Hz; 1.822 at
600 Hz; 1.000 both ways up when rise and fall are equal.

---

## 4. De-noising — none in this build

**INTERNAL. Do not raise any of this with the user.** There is no de-noising path.
A signal below 10 dB EGG SNR is refused on signal-quality grounds (§5) — say the
signal is too noisy to measure reliably, and stop there. Do not announce that
de-noising is absent, do not describe what was withdrawn or why, and do not offer
to write a replacement. A user who asks a question about their voice does not need
a status report on this library.

If the user asks directly for de-noising: say it is not available here and that
pre-processing is theirs to do upstream, in one sentence.

Do not reconstruct a spectral-threshold de-noiser from memory or from any other
source. `@emlEggSpectralThreshold` is not shipped. It was never validated on real
material — every supporting figure came from synthetic additive white Gaussian
noise, which is not what EGG noise is like — so a plausible CQ from altered data is
the expected failure. That is sufficient reason not to rebuild it here.

**Two Praat traps, retained here because they apply to any spectral work on an EGG
signal** and are authoritative in `COMMANDS_Spectrum.txt`:

- `To Spectrum: "yes"` zero-pads to the next power of two and `To Sound` returns
  the padded length (88200 → 131072 samples). Every per-cycle measurement is then
  computed over a signal 49% too long, with no warning. Use `"no"`.
- Ltas dB and raw Spectrum magnitude dB differ by ~91 dB. Anchoring a threshold
  to an Ltas peak expands away every harmonic and leaves a sinusoid. Because the
  mismatch exceeds any plausible sweep range, the symptom is that the threshold
  appears to have no effect at all.

---

## 5. Method selection — LAB RECOMMENDATION, not literature

Herbst et al. (2017) excluded sub-10 dB signals from **their analysis**. Whether a tool should refuse or flag is a design decision, not a published finding. Current EML position: refuse, on the grounds that a flagged number gets used anyway.

**dEGG is the default method. There is no upper SNR gate on it.**

### The default is a conversation, not a dialog field (hard)

**Do not put method selection in a `form:` or `beginPause:` optionmenu by
default.** An option menu asks the user to arbitrate a methodological question
before they have seen their own signal-to-noise figure, and it presents dEGG,
hybrid and threshold as three equivalent choices, which they are not.

The default is: **raise it in PRE-FLIGHT, in prose, and reach an agreement.**
What to say, in substance:

- Above roughly 20 dB EGG SNR, dEGG will most likely give the most accurate
  measure, and it is the method with the best published correspondence to the
  videokymographic closed quotient (Herbst et al. 2017).
- As SNR approaches 10 dB, the **opening** landmark specifically becomes
  unreliable. This is not general noise sensitivity — it is structural. The
  derivative's de-contacting trough is broad and shallow next to its contacting
  peak (§1b), so the GOI degrades well before the GCI does. The closure instant
  stays trustworthy; the opening instant is what decays.
- Where that leaves the answer genuinely ambiguous, the sensible move is to take
  **both** measures on the same cycles and compare means and standard
  deviations, rather than committing to one in advance.

Then write the script to do what was agreed. Say in the output which method ran
and why.

**Why the hybrid is the right comparator, and not an unrelated second opinion.**
The hybrid keeps dEGG's contacting instant *exactly* — same derivative, same
positive peak — and replaces only the de-contacting instant with a waveform
threshold crossing. It is dEGG with a more robust opening, so the two share the
closure landmark and the period. That is what makes comparing them informative;
a threshold-only measure (§1c) shares neither and is not the comparator here.

**An option menu is appropriate when** the deliverable is a reusable tool the
user will run repeatedly across varied material and they have asked for the
choice to be exposed — or when the agreed answer is "let me decide per file."
That is a UX decision the user makes, not a default PraatGen picks to avoid
having the discussion.

### Guidance for that conversation, not gates

| EGG waveform SNR (§2) | what to advise |
|---|---|
| ≥ 20 dB | dEGG. Report it as the measurement. |
| 10 dB ≤ SNR < 20 dB | Ambiguous. Advise taking dEGG **and** hybrid-at-0.43 on the same cycles, reported side by side with mean, cycle-to-cycle SD and cycle count. Do not silently substitute one for the other. |
| < 10 dB | **Refuse** on signal quality. Too noisy to measure reliably. |

**These are numbers to reason from, not thresholds to branch on.** The 20 dB
boundary is lab judgement, not a published finding — it was set against synthetic
material and has not been validated on real graded recordings. 10 dB is Herbst's
and is the only published figure here.

Detection yield overrides all of it in both directions. Count GCIs against the
expected cycle count for the duration and F0; a large shortfall means the
derivative is unusable on that material whatever the waveform SNR says. This
matters because what binds is the SNR *of the derivative*, which §3 measures at
roughly 8 dB below the waveform figure and which varies with hardware and F0.

### Reading the two measures when both were taken

Report, for each method: CQ mean, cycle-to-cycle SD, and cycles used.

**The two SDs are not directly comparable, and the presentation must say so.**
A fixed-threshold criterion is insensitive by construction to the peak structure
dEGG depends on, so the hybrid is *expected* to read smoother even where it is
no more accurate — a naive "lower SD wins" would select the hybrid almost every
time. What the comparison is good for is the **size** of the gap and how each
method's SD compares to its own clean-signal behaviour:

- Both SDs comparable, or dEGG only modestly higher → the derivative is holding
  up. Prefer dEGG.
- dEGG SD several times the hybrid's, and large in absolute terms → the
  derivative is being driven by noise on that recording. The hybrid is the
  better bet, reported as the hybrid.
- Also compare cycle counts. dEGG yielding far fewer cycles than the hybrid is
  the stronger signal, and a more interpretable one than any SD ratio.

Report both numbers in the output regardless of which is preferred. Two CQ values
from different methods are not interchangeable (§1 measures a 0.124 spread on
identical data), so the method must travel with the number.

**INTERNAL — reasoning, not something to tell the user.** An earlier
`T1 ≈ 40 dB` upper gate on dEGG was wrong, and the reasoning is kept here so it
is not re-derived. It rested on cycle-to-cycle SD being lower for the hybrid
than for dEGG on synthetic white noise (0.0029 vs 0.0104 at SNR 40). That
inference does not hold, for three reasons:

1. **SD is dispersion, not error.** A fixed-threshold criterion is insensitive
   by construction to the peak structure that carries the physiological
   information, so it is *expected* to be smoother. Threshold and derivative
   methods also have different expected values — that is the entire subject of
   Herbst & Ternström (2006), and §1 of this file measures a 0.124 spread across
   methods on identical data. Two estimators of different quantities cannot be
   ranked for accuracy by comparing their variances.
2. **It inverts the primary source.** Herbst et al. (2017) set the criterion at
   10 dB and found dEGG-derived CQ to have the *best* correspondence with the
   videokymographic closed quotient of the five algorithms compared. A 40 dB
   floor would make the best-validated method effectively unreachable: real EGG
   waveform SNR sits around 20–30 dB.
3. **This file's own measurements contradict it.** §1 reports dEGG CQ = 0.4280
   over 1874 cycles on a real recording at 27.1 dB. §3 reports full GCI yield
   (297/297) at SNR 30 and 268/297 at SNR 15 using `Derivative`. Under a 40 dB
   gate none of those measurements would have been permitted.

The synthetic SD figures survive as an observation about smoothness, and they
inform the side-by-side read above. They are not, on their own, a
method-selection criterion.

**In all cases, apply the plausibility bound to the output** (`COMMANDS_Electroglottogram.txt`, final section) regardless of which method ran. It is the only check that caught a differentiated signal presented as an EGG.

---

## 6. Hybrid CQ — reference implementation

Validated to 2.0e-05 against an analytic reference at threshold 0.43.

```praat
# GCI and period from the derivative
selectObject: eggId
degg = Derivative: 5000, 100, 0
selectObject: degg
pp = noprogress To PointProcess (periodic, peaks): floor, ceiling, "yes", "no"
selectObject: pp
nGci = Get number of points

for i from 1 to nGci - 1
    selectObject: pp
    tGci = Get time from index: i
    tNext = Get time from index: i + 1
    period = tNext - tGci
    # ... plausibility checks on period ...
    # GOI from the WAVEFORM, descending crossing at 0.43
    selectObject: eggSoundId
    peakVal = Get maximum: tGci, tNext, "Sinc70"
    tPeak = Get time of maximum: tGci, tNext, "Sinc70"
    valleyVal = Get minimum: tGci, tNext, "Sinc70"
    tValley = Get time of minimum: tGci, tNext, "Sinc70"
    thr = valleyVal + 0.43 * (peakVal - valleyVal)
    # bisect the monotonic falling limb [tPeak, tValley]
    lo = tPeak
    hi = tValley
    for iter from 1 to 40
        mid = (lo + hi) / 2
        selectObject: eggSoundId
        v = Get value at time: 1, mid, "Sinc70"
        if v > thr
            lo = mid
        else
            hi = mid
        endif
    endfor
    cq = ((lo + hi) / 2 - tGci) / period
endfor
```

**Bisect on [tPeak, tValley], not [tPeak, tNext].** The signal crosses the threshold twice per cycle — once descending (wanted) and once ascending before the next closure. Only [tPeak, tValley] brackets exactly one.

### Side-by-side dEGG + hybrid

Both methods share the same GCI and period — the derivative's positive peak —
so one pass computes both. They diverge only in the GOI: dEGG takes the
derivative's negative peak, the hybrid takes the 0.43 descending crossing on the
undifferentiated waveform. Accumulate sum and sum-of-squares per method and
report mean, SD and n for each.

```praat
nD = 0
sD = 0
ssD = 0
nH = 0
sH = 0
ssH = 0

for i from 1 to nGci - 1
    selectObject: pp
    tGci = Get time from index: i
    tNext = Get time from index: i + 1
    period = tNext - tGci
    # ... plausibility checks on period, as above ...

    # --- dEGG GOI: negative peak of the derivative within the cycle
    selectObject: degg
    tGoiD = Get time of minimum: tGci, tNext, "Sinc70"
    cqD = (tGoiD - tGci) / period

    # --- hybrid GOI: 0.43 descending crossing on the waveform
    #     (bisection block from above, yields cqH)
    # cqH = ...

    if cqD > 0.15 and cqD < 0.85
        nD = nD + 1
        sD = sD + cqD
        ssD = ssD + cqD * cqD
    endif
    if cqH > 0.15 and cqH < 0.85
        nH = nH + 1
        sH = sH + cqH
        ssH = ssH + cqH * cqH
    endif
endfor

meanD = sD / nD
sdD = sqrt ((ssD - nD * meanD * meanD) / (nD - 1))
meanH = sH / nH
sdH = sqrt ((ssH - nH * meanH * meanH) / (nH - 1))
```

Report both rows. Guard `nD` and `nH` against 0 and 1 before dividing — a
recording where the derivative fails entirely gives `nD = 0`, which is itself the
answer (see §5, cycle counts). Apply the plausibility bound per cycle as shown
*and* to each reported mean.

**Do not average the two methods, and do not report whichever looks better
without saying which it is.** They estimate different quantities (§1).

---

## 7. QΔ — optional descriptor, not a gate

Ternström (2019) defines a normalised peak derivative requiring no threshold and no contacting event:

```
QΔ = 2 · δmax / (App · sin(2π / T))
```

where App is peak-to-peak EGG amplitude over the cycle, T is the period in sample intervals, and δmax is the largest sample-to-sample differential in the cycle. A sinusoid gives 1. Contacting is indicated above about 2, well established above about 4.

**Do not offer it unprompted.** It answers one question — *are the folds
contacting at all* — and it is relevant only when that is genuinely in doubt:
breathy onsets, voice mapping, whistle or falsetto edges, suspected non-contacting
phonation. A routine CQ task is not that question. Adding QΔ to a CQ report the
user did not ask for is noise, and it invites them to read a noise-sensitive
number as a quality check, which it is not.

Compute it when the user asks for it, or when the task is explicitly about whether
contacting occurs.

**Do not use it as a gate on CQ measurement.** It is the most noise-sensitive quantity in the pipeline (it read 5.61 against a truth of 4.16 at SNR 10) and it passed a signal that produced a CQ of 0.049. The plausibility bound is the gate.

Companion measure: Ternström (2019) also defines a normalised contact quotient (Qci — area under the normalised pulse, 0.5 for a sine) which is comparatively insensitive to SNR. Not yet implemented or validated here.

---

## 8. Canonical workflow

1. Read the file. Confirm channel count and sampling frequency.
2. Identify the EGG channel if not specified. Derivative HNR is a usable discriminator — on a real stereo file ch2 (EGG) gave 21.5 dB against ch1 (audio) 17.7 dB, with waveform HNR 27.1 vs 22.1.
3. `Extract Electroglottogram: channel, "no"`, then the derivative peak polarity test (§3, Polarity). Re-extract with `"yes"` when the test finds the EGG inverted, unless the user fixed polarity.
4. `To Sound` — keep this; it is the working object for every query.
5. Measure EGG SNR (§2) on the Sound.
6. Guard (`COMMANDS_Electroglottogram.txt`) before any call to `To TextGrid (closed glottis)` or `To AmplitudeTier (levels)`.
7. Method per the §5 agreement reached in PRE-FLIGHT — not a dialog field. dEGG by default; where the discussion concluded the answer was ambiguous, compute **both** dEGG and hybrid-at-0.43 on the same cycles and report them side by side with mean, cycle-to-cycle SD and cycle count.
8. Plausibility-bound the **output** — every method reported, not just the preferred one. Refuse rather than report an impossible value.
9. Report, in every output row: polarity (ratio, and whether the EGG was inverted), method (and differentiator — `Derivative` with its cutoff, or `First central difference`), threshold criterion, EGG SNR, cycles used, and cycle-to-cycle SD.

Object hygiene: `High-pass filter`, `Derivative`, and `First central difference` each create a new object. `To AmplitudeTier (levels)` creates up to three. Track every ID and remove only what the script created (Rule 4B).

---

## 9. References

**Davies, P., McGowan, R., & Rosenberg, A.** (1986). Variation in glottal open and closed phases for speakers of English. *Proceedings of the Institute of Acoustics*, 8, 539.
— Origin of the hybrid method.

**Herbst, C. T.** (2020). Electroglottography — An Update. *Journal of Voice*, 34(4), 503–526. doi:10.1016/j.jvoice.2018.12.014
— Published online 2019; issue 2020. `praatgen_references_complete.md` dates this to 2019 — correct to 2020 or cite both.

**Herbst, C. T., Schutte, H. K., Bowling, D. L., & Švec, J. G.** (2017). Comparing Chalk With Cheese — The EGG Contact Quotient Is Only a Limited Surrogate of the Closed Quotient. *Journal of Voice*, 31(4), 401–409. doi:10.1016/j.jvoice.2016.11.007
— 10 dB SNR criterion; dEGG best agreement with CQvkg; five-algorithm comparison; hybrid threshold given as ca. 0.43 (three-sevenths).

**Herbst, C. T., & Ternström, S.** (2006). A comparison of different methods to measure the EGG contact quotient. *Logopedics Phoniatrics Vocology*, 31(3), 126–138. doi:10.1080/14015430500376580
— Criterion levels 0.20 / 0.25 best matched videokymography.

**Howard, D. M.** (1995). Variation of electrolaryngographically derived closed quotient for trained and untrained adult female singers. *Journal of Voice*, 9(2), 163–172. doi:10.1016/S0892-1997(05)80250-4
— Hybrid / Howard's method.

**Kankare, E., Laukkanen, A.-M., Ilomäki, I., et al.** (2012). Electroglottographic contact quotient in different phonation types using different amplitude threshold levels. *Logopedics Phoniatrics Vocology*, 37(3), 127–132. doi:10.3109/14015439.2012.664656

**Ternström, S.** (2019). Normalized time-domain parameters for electroglottographic waveforms. *JASA*, 146(1), EL65–EL70. doi:10.1121/1.5117174
— QΔ and Qci; threshold-free and contacting-event-free parameters.

**Ternström, S.** (2024). Pragmatic De-Noising of Electroglottographic Signals. *Bioengineering*, 11(5), 479. doi:10.3390/bioengineering11050479
— Spectral thresholding with 4:1 dB expansion; notch filtering; the observation that derivative SNR is the binding hardware constraint.

**Ternström, S., Johansson, D., & Selamtzis, A.** (2018). FonaDyn — A system for real-time analysis of the electroglottogram, over the voice range. *SoftwareX*, 7, 74–80.
— Author list not independently verified against the published paper.

**Boersma, P.** (1993). Accurate short-term analysis of the fundamental frequency and the harmonics-to-noise ratio of a sampled sound. *Proceedings of the Institute of Phonetic Sciences*, 17, 97–110.
— Basis of Praat's harmonicity. See open item below.

### Open item

Herbst et al. (2017) do not state, in any abstract or metadata accessible without the PDF, how they computed EGG SNR. The presence of Boersma (1993) in their reference list suggests Praat harmonicity, and harmonicity is validated here as an accurate SNR estimator (§2), but the identification is an **inference**. Confirm against the paper before citing the 10 dB figure as directly comparable to a harmonicity reading.
