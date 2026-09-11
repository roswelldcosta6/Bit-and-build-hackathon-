# SignBridge Flutter App

The mobile client for SignBridge's bilingual Indian Sign Language experience.

## What is implemented

- Accessible splash, home, Mode A, Mode B, history, and settings screens.
- Mode B text and microphone input connected to `POST /text-to-isl` and `POST /speech-to-isl`.
- A native skeletal `AvatarPlayer` that fetches the backend's 30 FPS joint poses from `/avatar/poses/{gloss}` and plays each action in sequence. This replaces the original PRD's MP4 clip strategy.
- A graceful local avatar preview when the backend is not reachable, so the UI remains demonstrable.
- Light/dark mode, scalable text, and English/Hindi/both speech preferences.

## Run locally

Start the backend first:

```powershell
cd backend
python -m uvicorn main:app --reload
```

Then run the app from `app/`:

```powershell
flutter pub get
flutter run
```

The default endpoint is `http://10.0.2.2:8000`, which is Android Emulator's route to the host machine. Update `AppSettings.apiBaseUrl` for a physical phone or hosted backend.

## Verification

```powershell
flutter analyze
flutter test
```
