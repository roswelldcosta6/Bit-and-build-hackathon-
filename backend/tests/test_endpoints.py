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
