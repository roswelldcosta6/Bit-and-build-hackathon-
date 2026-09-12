# SignBridge — Text/Speech → ISL pipeline (`signbridge_isl_model/`)

Second pipeline: **English/Hindi text (or transcribed speech) → ISL gloss sequence → real ISL sign videos**, played back sequentially in Flutter. No 3D avatar, no neural translation model — phrase matching + word-level normalization over a fixed, verified vocabulary.

Speech input is handled locally by an optional `faster-whisper` front-end (`speech_to_text.py` / `speech_to_isl.py`). Nothing here fabricates a transcript or a sign: if the speech engine is missing, or a word has no video, the response says so.

## ⚠️ Read this first: dataset coverage

The supplied dataset (`INDIAN SIGN LANGUAGE ANIMATED VIDEOS/`, 151 `.mp4` files) was inspected before any code was written. It is a general/vocabulary-style ISL video set (alphabet A–Z, digits 0–9, pronouns, common verbs/adjectives, a few stock phrases) — **not** an emergency/medical-communication set.

Several words the original brief listed as target vocabulary are **not present** and cannot be shown without fabricating a sign:

| Requested | In dataset? |
|---|---|
| HELLO, THANK_YOU, HELP, HOME, NAME, WHERE, WHAT, WHO, GO, COME | ✅ present |
| GOODBYE, YES, NO, PLEASE, WATER, FOOD, DOCTOR, MEDICINE, PAIN, EMERGENCY, FAMILY, NEED, WANT, STOP | ❌ missing |

Practical effect: the brief's own MVP example, **"I need water"**, will currently come back `status: "partial"` — `["I"]` known, `["need", "water"]` unknown — because none of those signs exist in the dataset. This is the pipeline working correctly (it refuses to hallucinate), not a bug. **Recommended demo phrases that resolve fully with this dataset:** "Thank you", "Where is home", "Come here", "Who are you", "Do not go", "Does not work". Swap the demo script or add more source videos if you need WATER/EMERGENCY-style vocabulary for the actual pitch.

## Files

- `build_from_dataset.py` — scans the dataset folder and *generates* `isl_dictionary.json` and `video_manifest.json` directly from the real filenames (gloss = filename uppercased, spaces → underscores). Re-run this if videos are added/renamed — never hand-edit glosses to "fix" coverage.
- `hindi_lexicon.json` — **the single source of truth for Hindi**: the Hindi→gloss word map (`words`), Hindi phrase rules (`phrases`), per-gloss Hindi `labels`, and the Hindi `drop_words`. `text_to_isl.py` and `build_from_dataset.py` both read it, so the word map and the published labels can never drift apart. Extend Hindi support here — never by hand-editing the generated JSON.
- `isl_dictionary.json` — gloss → `{english, hindi?, video}`. `hindi` is generated from `hindi_lexicon.json`, so it is populated only for words we are confident translating (111 of 151 signs); the rest are left blank rather than guessed.
- `video_manifest.json` — gloss → `{video, duration, english, hindi?}`. This is the file referred to as "animation_manifest.json" in section 8 of the brief — renamed per the deliverables list in section 13, same shape.
- `phrase_rules.json` — Level 1 exact-phrase → gloss-sequence rules. Every gloss in here is validated (at both build time and import time) against `isl_dictionary.json`; a dangling reference raises an error rather than shipping silently.
- `text_to_isl.py` — the pipeline itself: `translate(text, language="auto") -> dict`.
- `speech_to_text.py` — offline STT via **faster-whisper** (optional dependency) with Hindi + English auto-detection. Fails honestly: no engine means an empty transcript plus an install hint, never a canned sentence.
- `speech_to_isl.py` — the full speech front-end: audio → transcript → `translate()` → video sequence. Runnable as a CLI.
- `test_text_to_isl.py` — smoke tests, including an explicit test that missing signs (WATER, DOCTOR, etc.) are reported as unknown and never substituted, plus Hindi coverage/reachability tests.
- `test_speech_to_isl.py` — speech pipeline tests. No model download required (the transcriber is injectable), and the "engine missing" path is asserted to never invent a transcript.

## Pipeline stages

1. **Normalize**: lowercase, strip punctuation, detect Hindi (Devanagari Unicode range) vs. English.
2. **Level 1 — phrase match**: exact normalized text against `phrase_rules.json`.
3. **Bigram collapse**: adjacent tokens that match a dataset multi-word sign (`"thank" "you"` → `THANK_YOU`, `"do" "not"` → `DO_NOT`, `"does" "not"` → `DOES_NOT`) are merged before word matching.
4. **Level 2 — word match**: each remaining token is checked against the dictionary directly, then a small English synonym table (`hi`→HELLO, `thanks`→THANK_YOU, `u`→YOU, …), then — for Hindi input — the Hindi lexicon from `hindi_lexicon.json` (218 surface forms → 111 signs, plus 39 Hindi phrase rules). Pure grammatical function words with no ISL equivalent are dropped: English `a/an/the/is/am/are/was/were`, and Hindi copulas/postpositions (`है/हैं/था/थे/हो/ने/ही/तक/वाला…`). Content words that merely *look* like filler (Hindi `फिर`, `भी`) are deliberately **not** dropped. Everything else that doesn't resolve is reported as **unknown**, never dropped or replaced.
5. **Output**: `{status, gloss_sequence, unknown?}` — see `FLUTTER_INTEGRATION.md` for the exact contract.

## Running

```bash
python3 text_to_isl.py                    # runs the demo inputs (English + Hindi)
python3 test_text_to_isl.py               # text/Hindi smoke tests
python3 test_speech_to_isl.py             # speech pipeline tests (no model needed)
python3 speech_to_isl.py recording.wav    # speech -> ISL glosses + videos
python3 build_from_dataset.py             # regenerate the JSON files from the dataset
```

### Enabling real speech recognition

`faster-whisper` is an **optional** dependency (it pulls in CTranslate2), so it is
not required for the text pipeline or the tests:

```bash
pip install faster-whisper
```

Until it is installed, `speech_to_isl.py` exits with a clear "engine unavailable"
message and an install hint — it will not pretend to have heard something. Model
size and device are configurable without code changes:

```bash
SIGNBRIDGE_STT_MODEL=base python3 speech_to_isl.py recording.wav   # smaller/faster
SIGNBRIDGE_STT_DEVICE=cuda SIGNBRIDGE_STT_COMPUTE=float16 python3 speech_to_isl.py recording.wav
python3 speech_to_isl.py recording.wav hi                          # force Hindi
```

Regenerating the manifests needs `ffprobe` (from ffmpeg) and the extracted
dataset; point at it with `ISL_DATASET_DIR` if it is not the default folder name.

## Known limitations (by design, not oversight)

- No grammar reordering beyond the drop-list above — English/Hindi word order is preserved as ISL gloss order. Real ISL topic-comment ordering is not modeled; flag this if a judge asks and treat it as a stated MVP simplification, not a claim of linguistic accuracy.
- Hindi support is a curated normalization layer, not a translator: 218 surface forms and 39 phrase rules covering 111 of the 151 signs. Five words are deliberately left untranslated (AT, BE, GLITTER, HOMEPAGE, INVENT) rather than guessed at. The underlying clips are still the English-labelled signs from the dataset — Hindi in, same ISL video out. Unmapped Hindi words are reported unknown rather than dropped.
- Speech recognition is local and offline via `faster-whisper`. It is optional; without it the text pipeline is unaffected. Romanized Hindi ("mujhe paani chahiye") is not supported — the language detector keys off Devanagari script, so ask the STT layer to return Devanagari or transliterate before calling `translate()`.
- Vocabulary is exactly the 151 dataset videos. Extending it means adding videos and re-running `build_from_dataset.py`, not editing the JSON by hand.
