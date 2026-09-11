import pytest
from fastapi.testclient import TestClient
import sys
import os

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from gloss_mapper import text_to_isl_gloss, detect_language

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "en" in data["supported_languages"]
    assert "hi" in data["supported_languages"]
    assert data["total_signs"] >= 50


def test_vocabulary():
    response = client.get("/vocabulary")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 50
    assert "Emergency" in data["categories"]
    assert "Hospital" in data["categories"]
    assert len(data["vocabulary"]) == data["total"]
    # Check that HELP has clip_id 1
    help_item = next(item for item in data["vocabulary"] if item["gloss"] == "HELP")
    assert help_item["clip_id"] == 1
    assert help_item["video_file"] == "HELP.mp4"


def test_text_to_isl_english_question():
    response = client.post("/text-to-isl", json={"text": "Where is the hospital?"})
    assert response.status_code == 200
    data = response.json()
    assert data["detected_lang"] == "en"
    assert "HOSPITAL" in data["glosses"]
    assert data["glosses"][-1] == "WHERE"  # ISL rule: WH-question at end
    assert len(data["clip_ids"]) == len(data["glosses"])


def test_text_to_isl_hindi_request():
    response = client.post("/text-to-isl", json={"text": "मुझे डॉक्टर चाहिए"})
    assert response.status_code == 200
    data = response.json()
    assert data["detected_lang"] == "hi"
    assert "DOCTOR" in data["glosses"]
    assert len(data["clip_ids"]) > 0


def test_text_to_isl_hindi_question():
    response = client.post("/text-to-isl", json={"text": "पानी कहाँ है?"})
    assert response.status_code == 200
    data = response.json()
    assert data["detected_lang"] == "hi"
    assert "WATER" in data["glosses"]
    assert data["glosses"][-1] == "WHERE"  # ISL rule: WH-word at the end


def test_predict_fallback():
    dummy_keypoints = [[0.5] * 63] * 30
    response = client.post("/predict", json={"keypoints": dummy_keypoints})
    assert response.status_code == 200
    data = response.json()
    assert "sign_label" in data
    assert "label_en" in data
    assert "label_hi" in data
    assert data["confidence"] > 0.7


def test_history_flow():
    # Submit text to ISL with custom session
    client.post("/text-to-isl?session_id=test-session-123", json={"text": "Thank you doctor"})
    
    # Fetch session history
    hist_resp = client.get("/history/test-session-123")
    assert hist_resp.status_code == 200
    hist_data = hist_resp.json()
    assert hist_data["session_id"] == "test-session-123"
    assert hist_data["count"] >= 1
    assert "DOCTOR" in hist_data["items"][0]["glosses"]


def test_avatar_preview():
    response = client.get("/avatar-preview")
    assert response.status_code == 200
    assert "Three.js" in response.text
    assert "SignBridge Humanoid" in response.text


def test_avatar_poses():
    response = client.get("/avatar/poses/DOCTOR")
    assert response.status_code == 200
    data = response.json()
    assert data["gloss"] == "DOCTOR"
    assert data["fps"] == 30
    assert data["frame_count"] > 0
    first_frame = data["frames"][0]
    assert "joints" in first_frame
    assert "right_wrist" in first_frame["joints"]
    assert len(first_frame["joints"]["right_wrist"]) == 3  # [x, y, z]


def test_text_to_isl_humanoid_animation_sequence():
    response = client.post("/text-to-isl", json={"text": "Where is the hospital?"})
    assert response.status_code == 200
    data = response.json()
    assert "animation_sequence" in data
    assert len(data["animation_sequence"]) == len(data["glosses"])
    first_action = data["animation_sequence"][0]
    assert first_action["gloss"] == "HOSPITAL"
    assert "animation_trigger" in first_action
    assert first_action["duration_ms"] > 0
    assert "/avatar/poses/HOSPITAL" in first_action["pose_endpoint"]


def test_speech_to_isl_upload():
    import io
    fake_wav_bytes = b"RIFF....WAVEfmt ...." + (b"\x00" * 100)
    response = client.post(
        "/speech-to-isl",
        files={"audio": ("test_recording.wav", io.BytesIO(fake_wav_bytes), "audio/wav")},
    )
    assert response.status_code == 200
    data = response.json()
    assert "glosses" in data
    assert "animation_sequence" in data
    assert len(data["animation_sequence"]) > 0


def test_predict_empty_keypoints_returns_400():
    response = client.post("/predict", json={"keypoints": []})
    assert response.status_code == 400


def test_bigram_phrases_map_to_single_gloss():
    result = text_to_isl_gloss("Thank you doctor")
    assert result["glosses"][0] == "THANK_YOU"  # bigram 'thank you' -> one sign
    assert "YOU" not in result["glosses"]
    assert "DOCTOR" in result["glosses"]


def test_please_is_kept_as_sign():
    result = text_to_isl_gloss("Water please")
    assert "PLEASE" in result["glosses"]  # PLEASE has its own sign, must not be dropped
    assert "WATER" in result["glosses"]


def test_stt_sanitizes_unsafe_filename():
    from whisper_stt import transcribe_audio_bytes

    backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    result = transcribe_audio_bytes(b"RIFF....", filename="../../evil.exe")
    # Must still return a result (mock mode) without writing outside temp_audio/
    assert "text" in result
    assert not os.path.exists(os.path.join(backend_dir, "evil.exe"))
    temp_audio_dir = os.path.join(backend_dir, "temp_audio")
    if os.path.exists(temp_audio_dir):
        leftovers = [f for f in os.listdir(temp_audio_dir) if "evil" in f]
        assert leftovers == []


def test_stt_empty_audio_returns_empty_text():
    from whisper_stt import transcribe_audio_bytes

    result = transcribe_audio_bytes(b"")
    assert result["text"] == ""
    assert result["confidence"] == 0.0
