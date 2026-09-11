# 🤟 SignBridge Backend API Service
> Owned by: **Person 3 (Backend + NLP Engineer)**

This FastAPI microservice powers **Mode B (Speak → Sign Avatar)**, handles bilingual speech-to-text (Whisper), maps English and Hindi natural language into ISL grammatical gloss tokens (SOV order, WH-question end position), provides the 60+ sign vocabulary registry, and acts as cloud fallback inference for **Mode A (Sign → Speak)**.

---

## 🚀 Quickstart (Local Development)

### 1. Set Up Environment
```bash
cd backend
python -m venv .venv
source .venv/bin/activate    # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Run Server
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive Swagger API docs available immediately at: **`http://localhost:8000/docs`**

---

## 🧪 Run Automated Tests
```bash
pytest tests/test_endpoints.py -v
```

---

## 📡 API Endpoints Reference

### 1. Health Check
- **`GET /health`**
- Verifies server status and supported languages.
```json
{
  "status": "healthy",
  "service": "signbridge-backend",
  "version": "1.0.0",
  "supported_languages": ["en", "hi"],
  "total_signs": 62
}
```

---

### 2. ISL Vocabulary Registry
- **`GET /vocabulary`**
- Returns the complete list of 60+ supported ISL signs, categories, English/Hindi labels, and matching video animation filenames for Person 4's `AvatarPlayer` widget.
```json
{
  "total": 62,
  "categories": ["Banking", "Education", "Emergency", "Greetings", "Hospital", "Needs", "People", "Pronouns", "Questions", "Time", "Verbs"],
  "vocabulary": [
    {
      "clip_id": 1,
      "gloss": "HELP",
      "en": "Help",
      "hi": "मदद",
      "category": "Emergency",
      "video_file": "HELP.mp4"
    },
    {
      "clip_id": 2,
      "gloss": "DOCTOR",
      "en": "Doctor",
      "hi": "डॉक्टर",
      "category": "Hospital",
      "video_file": "DOCTOR.mp4"
    }
  ]
}
```

---

### 3. Text to ISL Gloss Mapping (Mode B)
- **`POST /text-to-isl`**
- Translates plain English or Hindi text into ISL SOV glosses and animation sequence clip IDs.

**Request:**
```bash
curl -X POST "http://localhost:8000/text-to-isl" \
     -H "Content-Type: application/json" \
     -d '{"text": "Where is the hospital?"}'
```

**Response:**
```json
{
  "original_text": "Where is the hospital?",
  "detected_lang": "en",
  "glosses": [
    "HOSPITAL",
    "WHERE"
  ],
  "clip_ids": [
    3,
    33
  ],
  "video_filenames": [
    "HOSPITAL.mp4",
    "WHERE.mp4"
  ],
  "subtitle": "Hospital Where",
  "grammar_applied": [
    "WH_QUESTION_FINAL"
  ]
}
```

---

### 4. Speech to ISL Gloss Mapping (Mode B)
- **`POST /speech-to-isl`**
- Ingests audio recording (`multipart/form-data`), transcribes via Whisper (auto-detects Hindi or English), and returns the sequential ISL gloss animation manifest.

**Request:**
```bash
curl -X POST "http://localhost:8000/speech-to-isl" \
     -F "audio=@recording.wav"
```

---

### 5. Mode A Cloud Fallback Gesture Prediction
- **`POST /predict`**
- Takes 30 frames x 63 coordinates `[[x1,y1,z1...], ...]` and returns classified sign.
```json
{
  "sign_label": "HELP",
  "label_en": "Help",
  "label_hi": "मदद",
  "confidence": 0.91,
  "is_stable": true
}
```

---

### 6. Session History
- **`GET /history/{session_id}`** — Retrieve past translations
- **`POST /history`** — Manually record a translated item

---

## 🐳 Docker Deployment

```bash
docker build -t signbridge-backend .
docker run -p 8000:8000 signbridge-backend
```
Deploy to Railway.app or Render by selecting Dockerfile deployment from your GitHub repo.
