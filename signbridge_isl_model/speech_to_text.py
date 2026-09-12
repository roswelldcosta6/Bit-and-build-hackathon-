"""
speech_to_text.py — SignBridge speech input for the text -> ISL video pipeline.

Local, offline speech-to-text using faster-whisper. Hindi and English are both
supported; the language is auto-detected from the audio, so a single mic button
can serve both.

`faster-whisper` is an OPTIONAL dependency (it pulls in CTranslate2). This module
therefore imports it lazily and degrades honestly when it is absent:

    >>> transcribe("hello.wav")            # doctest: +SKIP
    {"text": "hello there", "language": "en", "engine": "faster-whisper", ...}

If the package is missing, `transcribe()` returns an empty transcript plus a
human-readable `error` explaining how to install it. It deliberately does NOT
return a canned/mock sentence — a fake transcript would silently send the user's
message to the wrong signs, which is worse than saying "no speech engine".

Install:
    pip install faster-whisper
"""

from __future__ import annotations

import os
import logging
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger("signbridge.stt")

# "small" is a good accuracy/speed default for Hindi + English on CPU.
# Override with SIGNBRIDGE_STT_MODEL=tiny|base|small|medium|large-v3
DEFAULT_MODEL_SIZE = os.environ.get("SIGNBRIDGE_STT_MODEL", "small")

ENGINE_NAME = "faster-whisper"

# Supported audio extensions (faster-whisper decodes via ffmpeg/PyAV).
SUPPORTED_AUDIO_EXTENSIONS = {
    ".wav", ".mp3", ".m4a", ".mp4", ".ogg", ".oga", ".flac", ".webm", ".aac", ".opus",
}

_model = None
_load_attempted = False
_load_error: Optional[str] = None

_INSTALL_HINT = (
    "faster-whisper is not installed, so speech input is unavailable. "
    "Install it with: pip install faster-whisper"
)


def is_available() -> bool:
    """True if faster-whisper can be imported (model may still need downloading)."""
    try:
        import faster_whisper  # noqa: F401
    except Exception:
        return False
    return True


def load_model(model_size: str = DEFAULT_MODEL_SIZE):
    """
    Lazily load and cache the Whisper model. Returns None if unavailable, and
    records why in `last_error()` so callers can surface a real reason instead
    of an empty string.
    """
    global _model, _load_attempted, _load_error

    if _model is not None or _load_attempted:
        return _model

    _load_attempted = True
    try:
        from faster_whisper import WhisperModel

        logger.info("Loading faster-whisper model %r...", model_size)
        # device="cpu" + int8 keeps this runnable on a laptop without a GPU.
        # Set SIGNBRIDGE_STT_DEVICE=cuda / SIGNBRIDGE_STT_COMPUTE=float16 to override.
        _model = WhisperModel(
            model_size,
            device=os.environ.get("SIGNBRIDGE_STT_DEVICE", "cpu"),
            compute_type=os.environ.get("SIGNBRIDGE_STT_COMPUTE", "int8"),
        )
        logger.info("faster-whisper model %r loaded.", model_size)
    except ImportError:
        _load_error = _INSTALL_HINT
        logger.warning(_INSTALL_HINT)
    except Exception as exc:  # model download failure, bad device, etc.
        _load_error = f"Could not load faster-whisper model {model_size!r}: {exc}"
        logger.warning(_load_error)

    return _model


def last_error() -> Optional[str]:
    """Why the last load attempt failed, if it did."""
    return _load_error


def transcribe(
    audio_path: str,
    language: Optional[str] = None,
    model_size: str = DEFAULT_MODEL_SIZE,
) -> Dict[str, Any]:
    """
    Transcribe an audio file.

    Input:
        audio_path: path to a .wav/.mp3/.m4a/... file
        language:   "hi" / "en" to force a language, or None to auto-detect
        model_size: whisper model size (default from SIGNBRIDGE_STT_MODEL)

    Output (always this shape — never raises for a missing engine or bad file):
        {
            "text": str,                 # "" when nothing could be transcribed
            "language": "hi"|"en"|None,  # detected (or requested) language
            "language_probability": float|None,
            "engine": "faster-whisper"|None,
            "error": str|None            # set when engine/file/decoding failed
        }
    """
    result: Dict[str, Any] = {
        "text": "",
        "language": language,
        "language_probability": None,
        "engine": None,
        "error": None,
    }

    path = Path(audio_path)
    if not path.is_file():
        result["error"] = f"Audio file not found: {audio_path}"
        return result

    if path.suffix.lower() not in SUPPORTED_AUDIO_EXTENSIONS:
        result["error"] = (
            f"Unsupported audio format {path.suffix!r}. Supported: "
            f"{', '.join(sorted(SUPPORTED_AUDIO_EXTENSIONS))}"
        )
        return result

    model = load_model(model_size)
    if model is None:
        result["error"] = _load_error or _INSTALL_HINT
        return result

    try:
        segments, info = model.transcribe(str(path), language=language, task="transcribe")
        text = " ".join(seg.text.strip() for seg in segments).strip()
        detected = getattr(info, "language", None)

        result["text"] = text
        result["language"] = _to_short_code(detected) or language
        result["language_probability"] = getattr(info, "language_probability", None)
        result["engine"] = ENGINE_NAME
        return result
    except Exception as exc:
        result["error"] = f"Transcription failed: {exc}"
        logger.error(result["error"])
        return result


def _to_short_code(language: Optional[str]) -> Optional[str]:
    """
    Normalize a Whisper language tag to the two codes this pipeline uses.
    Whisper already returns ISO-639-1 codes ('hi', 'en'), but be defensive
    about full names in case the engine or a newer version changes that.
    """
    if not language:
        return None
    tag = str(language).strip().lower()
    if tag.startswith("hi") or tag == "hindi":
        return "hi"
    if tag.startswith("en") or tag == "english":
        return "en"
    return None


def _reset_cache() -> None:
    """Test helper: forget the cached model so availability is re-evaluated."""
    global _model, _load_attempted, _load_error
    _model = None
    _load_attempted = False
    _load_error = None


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("usage: python3 speech_to_text.py <audio-file> [hi|en]")
        raise SystemExit(2)

    forced = sys.argv[2] if len(sys.argv) > 2 else None
    print(f"faster-whisper available: {is_available()}")
    print(transcribe(sys.argv[1], language=forced))
