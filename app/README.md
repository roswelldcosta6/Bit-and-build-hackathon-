# 🤟 SignBridge — Flutter App
> Owned by: **Person 2 (App Core Engineer)**

This is the Flutter app for SignBridge — the real-time Indian Sign Language translation mobile app.

---

## 📁 Person 2's File Ownership

```
app/
├── lib/
│   ├── main.dart                  ← App entry point, Riverpod + theme
│   ├── router.dart                ← go_router navigation config
│   ├── theme.dart                 ← Dark/light theme + accessible design
│   │
│   ├── models/                    ← Data models
│   │   ├── sign_result.dart       ← SignResult, PredictResponse, ISLGlossResponse, HistoryItem
│   │   └── models.dart            ← Re-export
│   │
│   ├── services/                  ← 🔑 Person 2 owns this folder
│   │   ├── camera_service.dart    ← Camera pipeline + MediaPipe keypoint extraction
│   │   ├── tflite_service.dart    ← TFLite inference engine + sliding window + debounce
│   │   ├── tts_service.dart       ← Bilingual TTS (en-IN + hi-IN)
│   │   └── api_service.dart       ← Dio HTTP client for all backend endpoints
│   │
│   ├── state/                     ← 🔑 Person 2 owns this folder
│   │   ├── sign_provider.dart     ← Riverpod provider for Mode A (sign recognition pipeline)
│   │   └── avatar_provider.dart   ← Riverpod provider for Mode B (avatar animation state)
│   │
│   ├── screens/                   ← 🔵 P4 owns screen UI; P2 provides functional skeleton
│   │   ├── home_screen.dart
│   │   ├── mode_a_screen.dart     ← Camera + sign result + sentence builder + confidence
│   │   ├── mode_b_screen.dart     ← Mic/text input + avatar area + gloss display
│   │   ├── history_screen.dart
│   │   └── settings_screen.dart
│   │
│   └── widgets/                   ← 🔵 P4 owns widget polish; P2 provides functional widgets
│       ├── camera_view.dart       ← Live camera preview (mirrored front camera)
│       └── sign_result_card.dart  ← Bilingual sign result display
│
└── pubspec.yaml                   ← All dependencies configured
```

---

## 🚀 Setup Instructions

### 1. Create the Flutter project
```bash
# On your machine with Flutter installed:
flutter create signbridge
cd signbridge
```

### 2. Copy Person 2's files
Replace the generated `lib/` folder and `pubspec.yaml` with the files from this directory:
```bash
cp -r path/to/this/app/lib/* lib/
cp path/to/this/app/pubspec.yaml pubspec.yaml
```

### 3. Create required asset directories
```bash
mkdir -p assets/clips
mkdir -p assets/fonts
```

### 4. Add model files (from Person 1)
```bash
# Drop these into assets/:
cp path/to/ml/models/model.tflite assets/
cp path/to/ml/models/labels_bilingual.json assets/
```

### 5. Add font files
```bash
# Download Noto Sans Devanagari and place in assets/fonts/
# https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari
```

### 6. Install dependencies
```bash
flutter pub get
```

### 7. Run
```bash
flutter run
```

---

## 🏗️ Architecture Overview

### Mode A Pipeline (Sign → Speak)
```
Camera (30fps) 
  → CameraService.extractKeypoints() [MediaPipe Pose]
  → TfliteService.addFrame() [sliding window of 30 frames]
  → SignResult { labelEn, labelHi, confidence }
  → TtsService.speakSign() [bilingual TTS]
  → ApiService.addHistoryEntry() [log to backend]
```

### Mode B Pipeline (Speak → Sign)
```
Mic recording / Text input
  → ApiService.speechToISL() or ApiService.textToISL()
  → ISLGlossResponse { glosses, clip_ids, subtitle }
  → P4's AvatarPlayer plays clip sequence
```

### State Management (Riverpod)
- `signRecognitionProvider` — Mode A state (camera, inference, sentence building)
- `avatarProvider` — Mode B state (speech/text → gloss → avatar)
- `cameraServiceProvider` — Shared camera instance
- `tfliteServiceProvider` — Shared TFLite model instance
- `apiServiceProvider` — Shared API client (base URL configurable)
- `ttsServiceProvider` — Shared TTS engine

---

## 🔗 Integration Points

| Who | Delivers To | What |
|-----|------------|------|
| 🔴 P1 | → P2 | `model.tflite` + `labels_bilingual.json` into `assets/` |
| 🟢 P3 | → P2 | Base URL + Postman collection after Railway deployment |
| 🟡 P2 | → P4 | `CameraView` widget, `SignResultCard` widget, all services |
| 🟡 P2 | → P4 | Riverpod providers for Mode A + Mode B state |

---

## ⚠️ Known Limitations
- MediaPipe pose detection extracts 21 key landmarks (not full 21 hand landmarks per hand). If P1's model expects different input format, `CameraService.extractKeypoints()` needs adjustment.
- TTS voices depend on device — some Android devices may not have `hi-IN` voice installed.
- Mode B audio recording uses `record` plugin — requires Android RECORD_AUDIO permission (already in pubspec docs).
- Camera preview is mirrored for front camera — if orientation is wrong, check `CameraView` FittedBox.
