# 🤟 SignBridge — Real-Time Indian Sign Language Translation

> **Breaking barriers, one sign at a time.**
> Bidirectional (English + Hindi) two-way communication platform for Deaf and Hard-of-Hearing users.

---

## 🎯 Architecture Overview

| Mode | Direction | Pipeline |
|------|-----------|----------|
| 🟢 **Mode A: Sign → Speak** | ISL gesture → text + speech | Camera → MediaPipe keypoints → TFLite → EN/HI text → TTS |
| 🔵 **Mode B: Speak → Sign** | Speech/text → ISL avatar | Mic/text → Whisper STT → Gloss Mapper NLP → 3D avatar |

---

## 📁 Monorepo Structure

```
Bit-and-build-hackathon-/
├── app/                      # Flutter Mobile Application (Cross-platform Android / iOS)
│   ├── android/              # Android native project and Gradle build configs
│   ├── ios/                  # iOS native project
│   ├── lib/                  # Flutter Dart source code
│   │   ├── models/           # Data models (SignResult, etc.)
│   │   ├── screens/          # UI Screens (Home, Mode A, Mode B, History, Settings)
│   │   ├── services/         # Hardware & ML Services (Camera, TFLite, TTS, API)
│   │   ├── state/            # Riverpod state management
│   │   └── widgets/          # Reusable UI components
│   ├── assets/               # Models (model.tflite), bilingual labels, clips
│   └── pubspec.yaml          # Flutter package dependencies
│
├── backend/                  # FastAPI Python Backend Services
│   ├── main.py               # REST API endpoints & server setup
│   ├── whisper_stt.py        # Speech-to-Text inference pipeline
│   ├── gloss_mapper.py       # English/Hindi to ISL gloss grammar rules
│   ├── avatar_engine.py      # 3D skeletal avatar motion engine
│   ├── vocabulary.py         # ISL vocabulary and dictionary definitions
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile            # Container deployment configuration
│
├── .gitignore                # Comprehensive Git ignore rules
└── README.md                 # Project documentation
```

---

## 🚀 Quickstart Guide

### 1. Backend Setup (FastAPI & Whisper)

```bash
cd backend
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Run test suite:
```bash
pytest tests/test_endpoints.py -v
```

Full API documentation: [`backend/README.md`](backend/README.md)

---

### 2. Mobile App Setup (Flutter)

```bash
cd app
flutter pub get
flutter run
```

To run directly on a connected physical Android device:
```bash
flutter run -d <your-device-id>
```

---

## 🔗 Team Handoff Points

- **P1 → P3:** `model.tflite` + `labels_bilingual.json` land in `ml/models/`; `/predict` swaps the mock heuristic for real inference.
- **P3 → P2:** Deployed base URL + Postman collection; `POST /speech-to-isl`, `POST /text-to-isl`, `GET /vocabulary`.
- **P3 → P4:** `GET /vocabulary` returns every gloss with `clip_id` + `video_file` for the `AvatarPlayer` widget; `GET /avatar-preview` shows a live 3D WebGL avatar visualizer.
