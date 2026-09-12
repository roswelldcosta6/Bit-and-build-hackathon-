"""
speech_to_isl.py — SignBridge: spoken audio -> transcript -> ISL gloss sequence
-> real ISL video sequence.

The final step is identical to typed input: this module only adds the audio
front-end, so the Flutter contract in FLUTTER_INTEGRATION.md is unchanged apart
from the extra `transcript` / `stt` fields in the response.

    audio file --> speech_to_text.transcribe() --> text_to_isl.translate()

Usage:
    python3 speech_to_isl.py recording.wav              # auto-detect language
    python3 speech_to_isl.py recording.wav hi           # force Hindi
    python3 speech_to_isl.py recording.wav --model small
"""

from __future__ import annotations

import argparse
import json
from typing import Any, Callable, Dict, Optional

from text_to_isl import translate
from speech_to_text import DEFAULT_MODEL_SIZE, transcribe


def speech_to_isl(
    audio_path: str,
    language: Optional[str] = None,
    model_size: str = DEFAULT_MODEL_SIZE,
    transcriber: Optional[Callable[..., Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Full speech -> ISL pipeline.

    Input:
        audio_path:  audio file to transcribe
        language:    "hi"/"en" to force, or None to auto-detect from the audio
        model_size:  whisper model size
        transcriber: injection point for tests (defaults to speech_to_text.transcribe)

    Output:
        {
            "status": "complete" | "partial" | "unknown",
            "gloss_sequence": [{"gloss": str, "video": str}, ...],
            "unknown": [...],          # when status != "complete"
            "transcript": str,         # what the STT actually heard ("" if none)
            "detected_language": "hi" | "en" | None,
            "stt": {...}               # raw STT result, incl. `error` if it failed
        }

    If speech recognition is unavailable or fails, `status` is "unknown" with an
    empty sequence and "transcript" is "" — the response never invents words the
    user did not say.
    """
    stt_fn = transcriber or transcribe
    stt = stt_fn(audio_path, language=language, model_size=model_size)

    stt_record = {
        "engine": stt.get("engine"),
        "language": stt.get("language"),
        "language_probability": stt.get("language_probability"),
        "error": stt.get("error"),
    }

    text = (stt.get("text") or "").strip()
    detected_language = stt.get("language")

    if not text:
        # Nothing usable was heard (no engine, silent clip, or decode failure).
        reason = stt.get("error") or "No speech detected in the audio."
        return {
            "status": "unknown",
            "gloss_sequence": [],
            "unknown": [],
            "transcript": "",
            "detected_language": detected_language,
            "stt": stt_record,
            "error": reason,
        }

    # Reuse the exact same text pipeline as typed input, pinning the language the
    # STT detected so a Hindi transcript is never re-detected as English.
    result = translate(text, detected_language or "auto")

    return {
        **result,
        "transcript": text,
        "detected_language": detected_language,
        "stt": stt_record,
    }


def format_playback(gloss_sequence) -> str:
    """Human-readable playback plan, e.g. '1. HELLO -> assets/isl/Hello.mp4'."""
    if not gloss_sequence:
        return "(nothing to play)"
    lines = []
    for i, item in enumerate(gloss_sequence, 1):
        lines.append(f"{i}. {item['gloss']} -> {item['video']}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Transcribe speech and map it to ISL sign videos."
    )
    parser.add_argument("audio", help="path to an audio file (wav/mp3/m4a/...)")
    parser.add_argument(
        "language", nargs="?", choices=["hi", "en"], default=None,
        help="force a language instead of auto-detecting",
    )
    parser.add_argument(
        "--model", default=DEFAULT_MODEL_SIZE,
        help=f"whisper model size (default: {DEFAULT_MODEL_SIZE})",
    )
    args = parser.parse_args()

    result = speech_to_isl(args.audio, language=args.language, model_size=args.model)

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print()
    print(format_playback(result["gloss_sequence"]))

    # Distinct exit code for "no speech engine" so scripts can tell it apart
    # from "heard you, but the signs are missing".
    if result["stt"]["error"] and not result["transcript"]:
        return 3
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
