"""
Tests for the speech front-end. Run: python3 test_speech_to_isl.py

These deliberately do NOT require faster-whisper (or a model download): the
transcriber is injectable, and the "engine is missing" path is tested for what
it must never do — invent a transcript.
"""

import os
import tempfile

from speech_to_text import (
    SUPPORTED_AUDIO_EXTENSIONS,
    is_available,
    transcribe,
    _to_short_code,
)
from speech_to_isl import speech_to_isl, format_playback


def _fake(text, language, engine="fake-stt", error=None):
    """Build an injectable transcriber returning a fixed transcript."""
    def _transcriber(audio_path, language=None, model_size=None):
        return {
            "text": text,
            "language": language,
            "language_probability": 0.99 if text else None,
            "engine": engine,
            "error": error,
        }
    return _transcriber


def _temp_audio(suffix=".wav", data=b"\x00" * 64):
    fd, path = tempfile.mkstemp(suffix=suffix)
    with os.fdopen(fd, "wb") as f:
        f.write(data)
    return path


# --------------------------------------------------------------------------
# STT module: failure modes must be honest, never fabricated
# --------------------------------------------------------------------------

def test_missing_file_reports_error_and_empty_text():
    result = transcribe("definitely-not-here-12345.wav")
    assert result["text"] == ""
    assert result["engine"] is None
    assert result["error"], "a missing file must explain itself"


def test_unsupported_format_is_rejected():
    path = _temp_audio(suffix=".txt")
    try:
        result = transcribe(path)
        assert result["text"] == ""
        assert result["error"] and "Unsupported" in result["error"]
    finally:
        os.remove(path)


def test_transcribe_result_shape_is_stable():
    path = _temp_audio()
    try:
        result = transcribe(path)
        assert set(result) == {
            "text", "language", "language_probability", "engine", "error",
        }
        # Either the engine ran, or it explained why it could not. Never both
        # silently empty, and never a canned sentence.
        if result["engine"] is None:
            assert result["text"] == ""
            assert result["error"]
    finally:
        os.remove(path)


def test_engine_absent_is_never_covered_by_a_mock_transcript():
    path = _temp_audio()
    try:
        result = transcribe(path)
        if not is_available():
            assert result["text"] == ""
            assert result["error"] and "faster-whisper" in result["error"]
    finally:
        os.remove(path)


def test_supported_extensions_cover_common_recorder_output():
    for ext in (".wav", ".mp3", ".m4a", ".ogg", ".flac", ".webm"):
        assert ext in SUPPORTED_AUDIO_EXTENSIONS


def test_language_tag_normalization():
    assert _to_short_code("hi") == "hi"
    assert _to_short_code("Hindi") == "hi"
    assert _to_short_code("hi-IN") == "hi"
    assert _to_short_code("en") == "en"
    assert _to_short_code("English") == "en"
    assert _to_short_code(None) is None
    assert _to_short_code("fr") is None  # unsupported -> don't pretend it's English


# --------------------------------------------------------------------------
# Full speech -> ISL pipeline
# --------------------------------------------------------------------------

def test_speech_to_isl_english():
    result = speech_to_isl("clip.wav", transcriber=_fake("Thank you", "en"))
    assert result["status"] == "complete"
    assert [g["gloss"] for g in result["gloss_sequence"]] == ["THANK_YOU"]
    assert result["transcript"] == "Thank you"
    assert result["detected_language"] == "en"


def test_speech_to_isl_hindi_reuses_the_text_pipeline():
    result = speech_to_isl("clip.wav", transcriber=_fake("घर कहाँ है", "hi"))
    assert result["status"] == "complete"
    assert [g["gloss"] for g in result["gloss_sequence"]] == ["WHERE", "HOME"]
    assert result["detected_language"] == "hi"


def test_speech_to_isl_reports_unknown_words_from_speech():
    result = speech_to_isl("clip.wav", transcriber=_fake("I need water", "en"))
    assert result["status"] == "partial"
    assert set(result["unknown"]) == {"need", "water"}


def test_silent_audio_is_unknown_and_never_invented():
    result = speech_to_isl(
        "clip.wav", transcriber=_fake("", None, engine=None, error="no engine")
    )
    assert result["status"] == "unknown"
    assert result["gloss_sequence"] == []
    assert result["transcript"] == ""
    assert result["error"] == "no engine"
    assert result["stt"]["engine"] is None


def test_speech_to_isl_gloss_sequence_carries_video_paths():
    result = speech_to_isl("clip.wav", transcriber=_fake("Hello", "en"))
    for item in result["gloss_sequence"]:
        assert item["video"].startswith("assets/isl/")
        assert item["video"].endswith(".mp4")


def test_format_playback():
    assert format_playback([]) == "(nothing to play)"
    plan = format_playback([
        {"gloss": "WHERE", "video": "assets/isl/Where.mp4"},
        {"gloss": "HOME", "video": "assets/isl/Home.mp4"},
    ])
    assert "1. WHERE -> assets/isl/Where.mp4" in plan
    assert "2. HOME -> assets/isl/Home.mp4" in plan


if __name__ == "__main__":
    tests = [v for k, v in list(globals().items()) if k.startswith("test_")]
    passed = 0
    for t in tests:
        t()
        passed += 1
        print(f"PASS: {t.__name__}")
    print(f"\n{passed}/{len(tests)} tests passed.")
