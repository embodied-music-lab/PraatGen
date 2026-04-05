# Best Practices: Automatic TextGrid Annotation in Praat
## Whisper ASR, eSpeak Forced Alignment, and VAD Pipelines

**Author:** Ian Howell, Embodied Music Lab (embodiedmusiclab.com)  
**Compiled from:** EML PraatGen development sessions, March–April 2026  
**Praat version:** 6.4.62+  
**Status:** Living document — lessons learned from building and testing the CAPE-V / Rainbow Passage auto-segmenter (v2.4)

---

## 1. Pipeline Architecture

The proven pipeline for auto-annotating known speech material has five stages. Each stage feeds the next; failures at early stages propagate downstream.

```
Sound → VAD → Speech segments
                  ↓
              Whisper ASR → Transcripts per segment
                                ↓
                            Text-driven merge → Sentence identification
                                                     ↓
                                                 eSpeak forced alignment → Word + Phoneme tiers
                                                                              ↓
                                                                          Syllabification → Syllable tier(s)
```

**Design principle:** Each stage is independently testable. The pipeline should degrade gracefully — if Whisper is unavailable, fall back to manual sentence identification; if forced alignment fails on a segment, skip it with a warning rather than crashing.

---

## 2. Voice Activity Detection (Stage 1)

### 2.1 Three VAD options in Praat 6.4.62

| Command | Method | Best for |
|---------|--------|----------|
| `To TextGrid (silences):` | Intensity threshold | Clean recordings, simple speech/silence |
| `To TextGrid (speech activity):` | Spectral flatness (LTSF) | Noise-robust, better for varied recordings |
| `To TextGrid (speech activity, Silero):` | Neural network | Best accuracy, but may not be in compiled builds yet |

**Default recommendation:** LTSF. It handles background noise and breath sounds better than intensity thresholding. Silero is superior but check availability in your build first.

### 2.2 Critical parameter: pitch floor in `To TextGrid (silences):`

The `pitch floor` parameter controls the internal intensity smoothing window:

```
window = 6.4 / pitch_floor seconds

pitch_floor = 50 Hz  → 128 ms window (may fill short gaps)
pitch_floor = 75 Hz  →  85 ms window
pitch_floor = 100 Hz →  64 ms window (Praat dialog default)
```

If silence detection fails to split events with a visible gap between them, increase the pitch floor first — this shortens the smoothing window and may resolve the issue without changing threshold or duration parameters.

### 2.3 LTSF parameters worth tuning

```praat
To TextGrid (speech activity): 0.0, 0.3, 0.1, 70, 6000, -10, -35, 0.1, 0.1, "non-speech", "speech"
```

The `min speech interval` parameter (9th) is critical for CAPE-V recordings: set it short enough to capture brief sentences but long enough to avoid fragmenting words. 0.1 s works for most cases. The `padding` on Silero (4th parameter, 0.03 s default) serves a similar role.

### 2.4 Dysphonic voice challenges

VAD is the first failure point for dysphonic voices. Breathy voices have reduced spectral contrast; rough voices produce aperiodic energy during pauses. Both blur the speech/silence boundary. See Section 8 for ML-based improvement approaches.

---

## 3. Whisper Speech Recognition (Stage 2)

### 3.1 Setup: Installing whisper.cpp models for Praat

1. Find your Praat preferences folder — run `writeInfoLine: preferencesDirectory$` in a script
2. Create `models/whispercpp/` inside that folder
3. Download a model from `https://huggingface.co/ggerganov/whisper.cpp/tree/main`
4. Place the `.bin` file (e.g., `ggml-base.en.bin`) in the folder
5. Restart Praat

**Model recommendation:** `ggml-base.en.bin` for English speech. Good balance of speed and accuracy. Larger models (medium, large) improve accuracy but increase processing time substantially.

### 3.2 Verified command signatures

```praat
# Creation — two string arguments: model filename, language
Create SpeechRecognizer: "ggml-base.en.bin", "English"

# Transcription — no arguments, cross-type command (SpeechRecognizer & Sound)
# Both objects must be selected
selectObject: recognizerId, soundId
Recognize sound

# Query commands on SpeechRecognizer
Get Whisper model name
Get language name
```

### 3.3 Lessons learned the hard way

**`Create SpeechRecognizer` takes two arguments.** The catalogue lists it without parameter expansion, making it look like a no-argument command. It requires the model filename and language. Calling it without arguments produces `Command not available for current selection`.

**Selection state matters for creation.** If other objects are selected when you call `Create SpeechRecognizer`, it may fail. Clear the selection first:

```praat
# Safe creation pattern
selectObject: soundId
minusObject: soundId
# Nothing selected now
recognizerId = Create SpeechRecognizer: "ggml-base.en.bin", "English"
```

**The transcription command is `Recognize sound`, not `Transcribe`.** The catalogue's cross-type entry says `Transcribe` but the actual command (confirmed via Paste Commands) is `Recognize sound`. No colon, no arguments.

**`Recognize sound` writes to the Info window.** Every call clears and overwrites the Info window. If you need transcripts from multiple segments, capture each one immediately:

```praat
selectObject: recognizerId, segSoundId
Recognize sound
rawTranscript$ = info$ ()
```

**`nocheck` must NOT be used on `Create SpeechRecognizer`.** Unlike most Praat commands, `nocheck` on this command causes silent failure — no object created, no error raised, and interpreter variable state may be corrupted. Use `fileReadable` to check the model path before calling:

```praat
modelPath$ = preferencesDirectory$ + "/models/whispercpp/" + whisperModel$
if not fileReadable (modelPath$)
    appendInfoLine: "Whisper model not found at: ", modelPath$
    # Fall back to manual pathway
else
    recognizerId = Create SpeechRecognizer: whisperModel$, "English"
endif
```

**`nocheck` corrupts interpreter state more broadly.** When `nocheck` prevents a command from executing, subsequent variable assignments and queries may silently fail or return stale values. Never use `nocheck` as a diagnostic branching mechanism. Check preconditions explicitly instead.

**Sustained vowels produce `[BLANK_AUDIO]`.** Whisper returns `[BLANK_AUDIO]` for non-speech segments like sustained /a/ phonation. Filter these before the merge stage or they get absorbed into adjacent sentence matches.

**Create the SpeechRecognizer once, reuse for all segments.** The model loads on creation. Pair it with different Sound objects for each segment rather than creating and destroying it repeatedly.

**Progress bars appear during recognition.** Use `noprogress` where available. The `Recognize sound` command itself does not support `noprogress`, but upstream analysis commands (`To TextGrid (silences):`, `To Harmonicity (cc):`) do.

---

## 4. Text-Driven Sentence Merging (Stage 3)

### 4.1 The problem

VAD may split a single sentence into multiple segments (e.g., "Peter will keep" + pause + "at the peak"). Whisper transcribes each segment independently. The merge stage must reassemble them.

### 4.2 Algorithm (proven in v2.4)

1. Run Whisper on ALL speech segments first, store every transcript in an array
2. Filter out `[BLANK_AUDIO]` entries
3. Walk through segments sequentially, accumulating text
4. After each accumulation, check accumulated text against a sentence bank using key phrases
5. Try tightest span first (single segment) before widening — this prevents garbage segments from being absorbed into valid matches
6. Duration cap (8 seconds for CAPE-V) prevents unreasonable spans
7. Match found → record the full span, advance past consumed segments
8. No match after 5–6 segments → label segment as unmatched, advance by one, retry

### 4.3 Key phrase matching over full-text matching

Use distinctive sub-phrases rather than matching entire sentences. Each CAPE-V sentence has a unique key phrase:

```praat
sentenceKey$[1] = "blue spot"
sentenceKey$[2] = "hard did he hit"
sentenceKey$[3] = "were away"
sentenceKey$[4] = "eat eggs"
sentenceKey$[5] = "mama makes"
sentenceKey$[6] = "keep at the peak"
```

Whisper may hallucinate, truncate, or rephrase parts of the sentence. Key phrase matching is more robust than requiring the full sentence text to appear.

### 4.4 Text normalization before matching

Strip punctuation and normalize case before comparison:

```praat
rawTranscript$ = replace_regex$ (rawTranscript$, "[.,'!?]", "", 0)
rawTranscript$ = replace_regex$ (rawTranscript$, "  +", " ", 0)
```

Use `index_caseInsensitive()` for the key phrase search.

---

## 5. Forced Alignment with eSpeak (Stage 4)

### 5.1 The `Align interval` command

```praat
# Requires BOTH TextGrid AND Sound selected simultaneously
selectObject: gridId, soundId
Align interval: tierNumber, intervalNumber, "English (America)", "yes", "yes"
```

**Parameters:**
1. Tier number — which tier contains the text to align
2. Interval number — which interval on that tier
3. Language — must match a SpeechSynthesizer language name
4. Include words — "yes" to generate word tier
5. Include phonemes — "yes" to generate phoneme tier

### 5.2 Critical: selection state

`Align interval` is a cross-type command requiring both TextGrid and Sound. This is the most common source of errors — if only one object is selected, the command fails silently or produces unexpected results. Always explicitly select both objects immediately before the call.

### 5.3 What `Align interval` produces

On first call, it creates two new tiers: `[TierName] / word` and `[TierName] / phon`. It also creates internal tiers for silences and VAD that you probably don't want — remove these in a cleanup stage.

On subsequent calls (to different intervals on the same tier), it populates the same word and phoneme tiers. It does NOT create duplicate tiers.

### 5.4 Tier names

The generated tier names are `"Sentence / word"` and `"Sentence / phon"` (not `"Sentence / phoneme"`). When searching for these tiers programmatically, match on `"phon"` not `"phoneme"`:

```praat
if index (tierName$, "phon") > 0
    # Found the phoneme tier
endif
```

### 5.5 Phoneme labels

eSpeak produces IPA phoneme labels. The inventory includes standard vowels plus variants like ɐ, ɚ, and ᵻ. If building a vowel detection regex, include these:

```praat
procedure isVowelPhoneme: .phon$
    .result = index_regex (.phon$, "[aeiouɑæɒɔəɛɜɪʊʌɐɚᵻːˑ]")
endproc
```

### 5.6 Limitations of eSpeak alignment

eSpeak uses its own synthetic voice as the reference signal for DTW alignment. There is no speaker adaptation. Boundary placement degrades for voices that differ significantly from eSpeak's internal model — particularly dysphonic voices, very high or low voices, and accented speech.

Word boundaries are generally more reliable than phoneme boundaries. Sentence boundaries (from the Whisper merge stage) are the most reliable.

---

## 6. Syllabification (Stage 5)

### 6.1 Two approaches, both useful

**Lexical (lookup table):** For known material, hard-code syllable counts per word. Most reliable for the finite CAPE-V/Rainbow sentence set. Example: `"again"` → 2 syllables.

**Sonority-based (algorithmic):** Detect vowel nuclei from the phoneme tier, place boundaries at consonant-vowel transitions. Works on any text but may under-split complex onsets (e.g., /str/).

### 6.2 Word-bounded vs. sentence-bounded

Generate both for comparison. Sentence-bounded syllabification produces more linguistically valid groupings because consonant clusters naturally resyllabify across word boundaries in connected speech (e.g., /ɔ.nðə/ not /ɔn.ðə/). Word boundary errors from forced alignment also propagate into word-bounded syllable tiers — sentence boundaries (from the Whisper merge) are more accurate.

### 6.3 The v2.4 script generates four parallel syllable tiers

1. Syl (lex, word) — word-bounded, count-limited by lookup table
2. Syl (son, word) — word-bounded, sonority-based
3. Syl (lex, sent) — sentence-bounded, count-limited by total
4. Syl (son, sent) — sentence-bounded, sonority-based

This redundancy is intentional for comparison. Once a winner is identified, collapse to one or two tiers.

---

## 7. SpeechSynthesizer for Canonical Transcriptions

### 7.1 Using eSpeak for IPA output

```praat
synthId = Create SpeechSynthesizer: "English (America)", "Female1"
selectObject: synthId
phonemes$ = Get phonemes from text (space-separated): "The blue spot is on the key again"
```

This gives you canonical IPA transcriptions independent of the recording, useful as a reference tier or for syllable analysis of the expected phonemic content.

### 7.2 `To Sound` with TextGrid output

```praat
selectObject: synthId
To Sound: "The blue spot is on the key again", "yes"
soundId = selected ("Sound")
gridId = selected ("TextGrid")
```

The `"yes"` argument generates a TextGrid with word and phoneme tiers aligned to the synthetic audio. This is how `Align interval` works internally — it synthesizes the text, then DTW-aligns the synthetic audio to the real recording.

---

## 8. ML-Enhanced Segmentation (Research Direction)

### 8.1 Failure points for dysphonic voices

| Stage | Failure mode |
|-------|-------------|
| VAD | Breathy voices blur speech/silence boundary; rough voices produce aperiodic energy in pauses |
| Whisper | Degraded transcription accuracy for severe dysphonia |
| Forced alignment | eSpeak's normative voice model misaligns boundaries |

### 8.2 Praat-native ML tools available

All of these exist in Praat and require no external dependencies:

- **FFNet** (feedforward neural network): `PatternList & Categories: To FFNet`, `Learn`, `Classify`
- **Discriminant analysis:** `PatternList & Categories: To Discriminant`
- **Continuous HMM:** frame-level temporal modeling
- **MFCC extraction:** `Sound: To MFCC` for feature vectors

### 8.3 Two intervention points

**VAD refinement:** Train an FFNet on frame-level features (energy, spectral tilt, HNR, MFCCs) from hand-corrected TextGrids. Labels are binary: speech vs. non-speech. Compare normophonic-trained, dysphonic-trained, and mixed training sets.

**Boundary refinement:** After eSpeak alignment, extract features at each boundary (±50 ms window: energy slope, spectral flux, HNR change, voicing probability change, zero-crossing rate change). Train an FFNet to classify boundaries as correct / shift left / shift right. Apply predicted shifts post-hoc.

### 8.4 Research design principle

Diagnose before intervening. Phase 1 should measure where the pipeline actually breaks for dysphonic voices (systematic error analysis across a corpus) before committing to any specific ML approach.

---

## 9. General Praat Scripting Lessons

### 9.1 `nocheck` is dangerous

`nocheck` on a failing command can corrupt interpreter variable state. Variables may remain undefined, and subsequent commands may fail silently. Never use `nocheck` as a diagnostic branching mechanism. Check preconditions explicitly.

### 9.2 Reserved variable names

`e` (Euler's 2.71828), `pi`, and `undefined` are Praat constants and cannot be used as variable names. Common collision: `for e from 1 to n` causes a cryptic error.

### 9.3 `info$()` captures Info window content

After any command that writes to the Info window, `info$()` returns the current content as a string. This is how you capture Whisper transcripts. But be aware that many commands clear and rewrite the Info window — capture immediately after the command you care about.

### 9.4 Selection discipline for cross-type commands

Commands that operate on multiple object types (like `Align interval` or `Recognize sound`) require all participating objects to be explicitly selected. Use `selectObject: id1, id2` or `selectObject: id1` followed by `plusObject: id2`. Verify with `numberOfSelected()` if uncertain.

### 9.5 `noprogress` for batch processing

Prepend `noprogress` to analysis commands (`To Pitch`, `To Harmonicity`, `To TextGrid (silences)`) to suppress progress bars. This prevents UI lag during batch processing and avoids some Cocoa event dispatch issues on macOS.

---

## 10. Verified Command Reference

Commands verified during auto-segmenter development sessions:

| Command | Arguments | Notes |
|---------|-----------|-------|
| `Create SpeechRecognizer:` | model_filename$, language$ | Two string args, must match installed model |
| `Recognize sound` | (none) | Cross-type: SpeechRecognizer & Sound. Writes to Info window |
| `Get Whisper model name` | (none) | Query on SpeechRecognizer |
| `Get language name` | (none) | Query on SpeechRecognizer |
| `Create SpeechSynthesizer:` | language$, voice$ | e.g., `"English (America)", "Female1"` |
| `Get phonemes from text (space-separated):` | text$ | Returns IPA string |
| `To Sound:` | text$, create_TextGrid$ | On SpeechSynthesizer; `"yes"` creates aligned TextGrid |
| `Align interval:` | tier, interval, language$, words$, phonemes$ | Cross-type: TextGrid & Sound. Both must be selected |
| `To TextGrid (speech activity):` | 11 params | LTSF VAD — alias for the spectral flatness variant |
| `To TextGrid (speech activity, Silero):` | 6 params | Neural VAD — in source but may not be in compiled builds |
| `To TextGrid (silences):` | 7 params | Intensity-based silence detection |

---

*End of document.*
