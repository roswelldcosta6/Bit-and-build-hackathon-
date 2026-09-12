# FLUTTER_INTEGRATION.md — SignBridge (text/speech → ISL video pipeline)

## 1. What Flutter sends

```json
{
  "text": "Thank you",
  "language": "en"
}
```

- `text`: raw user input (typed or STT transcript).
- `language`: `"en"`, `"hi"`, or `"auto"` (auto-detects Hindi via Devanagari script).

This calls `translate(text, language)` in `text_to_isl.py`. If the ML layer is exposed as a local HTTP/REST service, wrap `translate()` in a thin endpoint — the function itself has no I/O dependencies, so any transport works.

## 2. What Flutter receives

**Complete** — every word resolved:
```json
{
  "status": "complete",
  "gloss_sequence": [
    {"gloss": "THANK_YOU", "video": "assets/isl/Thank You.mp4"}
  ]
}
```

**Partial** — some words had no matching sign:
```json
{
  "status": "partial",
  "gloss_sequence": [
    {"gloss": "I", "video": "assets/isl/I.mp4"}
  ],
  "unknown": ["need", "water"]
}
```

**Unknown** — nothing in the input matched any sign:
```json
{
  "status": "unknown",
  "gloss_sequence": [],
  "unknown": ["xyzzy"]
}
```

## 3. Video naming & asset directory

- Videos keep their **original dataset filenames**, including spaces and capitalization (e.g. `Thank You.mp4`, `Do Not.mp4`). Do not rename them — `video_manifest.json` and `isl_dictionary.json` reference these exact names.
- Place all 151 files under `assets/isl/` in the Flutter project, matching the `video` field paths returned by the API (e.g. `assets/isl/Thank You.mp4`).
- Register the folder in `pubspec.yaml`:
  ```yaml
  flutter:
    assets:
      - assets/isl/
  ```
- Format: H.264 `.mp4`, mostly 1280×720 (a handful are 960×540), ~0.8–2.5s each. A standard Flutter video player (e.g. `video_player` package) handles both resolutions fine without special-casing.

## 4. Playing the sequence

For each item in `gloss_sequence`, in order:

1. Load `assets/isl/<video>` into the video player controller.
2. Play from start.
3. On completion (`controller.value.position >= controller.value.duration`, or the player's "ended" callback), dispose/advance and load the next item.
4. When the sequence is exhausted, show a "done" state.

No manual "next" button — auto-advance. Pre-loading the next video while the current one plays avoids visible gaps (a few frames of buffering are acceptable; nothing in the dataset needs special buffering).

Pseudocode:
```dart
int i = 0;
void playNext() {
  if (i >= glossSequence.length) { onSequenceDone(); return; }
  controller = VideoPlayerController.asset(glossSequence[i].video)
    ..initialize().then((_) => controller.play());
  controller.addListener(() {
    if (controller.value.position >= controller.value.duration) {
      i++;
      playNext();
    }
  });
}
```

## 5. Handling unknown signs

If `status` is `"partial"` or `"unknown"`:

- Play whatever *is* in `gloss_sequence` (may be empty).
- Show the `unknown` words in the UI — e.g. "No sign available for: water, need" — so the user knows the message is incomplete. Do not silently drop this; the whole point of reporting `unknown` is that the app must surface it, not hide it.
- Do **not** attempt to invent or substitute a sign client-side either.

## 6. Handling missing video files

Before shipping, verify every path in `video_manifest.json` actually exists under `assets/isl/`. If a video is missing at runtime (e.g. asset not bundled), catch the video player's load error per-item and skip to the next item in the sequence while logging/surfacing which gloss failed — don't crash the whole playback.

## 7. Hindi input

Set `"language": "hi"`, or `"auto"` and let Devanagari script detection choose.

Hindi support lives in `hindi_lexicon.json` and covers **218 surface forms mapped to 111 of the 151 signs**, plus 39 Hindi phrase rules. It is a normalization layer, not a translator — the video played is still the English-labelled sign from the dataset, so Hindi in gives the same ISL clip out.

What that means in practice:

- Common sentences resolve fully: `घर कहाँ है` → `WHERE, HOME`, `आपका नाम क्या है` → `WHAT, YOUR, NAME`, `मत जाओ` → `DO_NOT, GO`, `मैं व्यस्त हूँ` → `I, BUSY`.
- Copulas and the ergative `ने` are dropped (no sign exists for them), so a normal spoken sentence doesn't drown in spurious unknowns. Content words like `फिर` / `भी` are never dropped.
- Five signs are deliberately left untranslated (AT, BE, GLITTER, HOMEPAGE, INVENT) rather than guessed at.
- Anything outside the lexicon comes back in `unknown` exactly like an unmapped English word — same UI handling as section 5. `मुझे पानी चाहिए` returns `partial` with `["पानी", "चाहिए"]` because the dataset has no WATER or NEED sign; that is correct behaviour, not a bug.

**Romanized Hindi is not supported.** Detection keys off the Devanagari Unicode range, so `"mujhe paani chahiye"` is treated as English. Have your STT layer return Devanagari (Whisper does), or transliterate before calling `translate()`.

Want more Hindi coverage? Add words/phrases to `hindi_lexicon.json` — its values are validated against `isl_dictionary.json` at import time, so pointing Hindi at a sign that has no video raises an error instead of silently shipping.

## 8. Speech input

Two supported arrangements — pick whichever fits the client:

1. **On-device STT, send text** (simplest, no Python runtime needed on the client): run any off-the-shelf recognizer (Android `SpeechRecognizer`, Google Cloud STT, …) and send the transcript through the same `{"text", "language"}` contract as typed input. Set `language` from the recognizer's locale (`hi-IN` → `"hi"`).
2. **Let this module transcribe**: `speech_to_isl.py` wraps local `faster-whisper` — audio in, the same `translate()` result out plus extra fields.

```python
from speech_to_isl import speech_to_isl
result = speech_to_isl("recording.wav")   # language=None auto-detects hi/en
# {
#   "status": "complete",
#   "gloss_sequence": [{"gloss": "WHERE", "video": "assets/isl/Where.mp4"}, ...],
#   "transcript": "घर कहाँ है",
#   "detected_language": "hi",
#   "stt": {"engine": "faster-whisper", "language": "hi", "language_probability": 0.98, "error": null}
# }
```

`gloss_sequence` is unchanged, so section 4 playback and section 5 unknown-handling apply as-is. Two extra rules for the speech path:

- If `stt.error` is set and `transcript` is empty, recognition did not run or heard nothing — show your "couldn't hear you / speech unavailable" state. **Never** fall back to playing a default phrase: the module returns an empty `gloss_sequence` precisely so a fabricated message can't reach the user.
- `speech_to_text.transcribe()` never raises for a missing engine or an undecodable file. It returns an empty transcript plus an `error` string to display or log.

Requires `pip install faster-whisper` (optional; not needed for the on-device path).

## 9. Known-good demo phrases

Given actual dataset coverage (see `README.md` for the full gap list), these resolve to `"complete"` and are safe for a live demo:

- "Thank you"
- "Where is home"
- "Come here"
- "Who are you"
- "Do not go"
- "Does not work"
- "My name" / "Your name"

"I need water" (the brief's own MVP example) will return `"partial"` with this dataset — useful to show off the honest-partial-reporting behavior, but don't rely on it for a "wow, it fully works" moment unless WATER/NEED videos are added.
