# 🤟 SignBridge — Real-Time Indian Sign Language Translation

> **Breaking barriers, one sign at a time.**
> Hackathon monorepo — see the full PRD for the complete product spec.

A bilingual (English + Hindi) two-way communication bridge for Deaf and hard-of-hearing users:

| Mode | Direction | Pipeline |
|------|-----------|----------|
| 🟢 **A: Sign → Speak** | ISL gesture → text + speech | Camera → MediaPipe keypoints → TFLite → EN/HI text → TTS |
| 🔵 **B: Speak → Sign** | Speech/text → ISL avatar | Mic/text → Whisper STT → Gloss Mapper NLP → 3D avatar |

## 📁 Repository Structure

```
signbridge/
├── backend/          ← 🟢 Person 3 (Backend + NLP) — FastAPI, Whisper STT, ISL gloss mapper, avatar engine
├── ml/               ← 🔴 Person 1 (ML) — dataset prep, training, TFLite export
└── app/              ← 🟡 P2 (core engine) + 🔵 P4 (UI) — Flutter app
```

## 🚀 Backend Quickstart (Person 3 — currently implemented)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload        # http://localhost:8000/docs
```

Run the test suite:

```bash
pytest tests/test_endpoints.py -v
```

Full API documentation: [`backend/README.md`](backend/README.md)

## 🔗 Team Handoff Points

- **P1 → P3:** `model.tflite` + `labels_bilingual.json` land in `ml/models/`; `/predict` swaps the mock heuristic for real inference.
- **P3 → P2:** Deployed base URL + Postman collection; `POST /speech-to-isl`, `POST /text-to-isl`, `GET /vocabulary`.
- **P3 → P4:** `GET /vocabulary` returns every gloss with `clip_id` + `video_file` for the `AvatarPlayer` widget; `GET /avatar-preview` shows a live 3D WebGL avatar visualizer.
