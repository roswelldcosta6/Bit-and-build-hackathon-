# Sanket — ISL Video-to-Text Translator

Deep learning pipeline for translating Indian Sign Language (ISL) videos into English text, powered by the pretrained model weights from HuggingFace:
👉 [ayush2635/sanket-isl-translator](https://huggingface.co/ayush2635/sanket-isl-translator)

---

## Architecture Overview

- **Vision Encoder**: `facebook/timesformer-base-finetuned-k400`
- **Pose / Skeleton Encoder**: Custom 2-layer `TransformerEncoder` processing 195 MediaPipe Holistic landmark coordinates per frame.
- **Cross-Modal Fusion**: `GatedCrossModalFusion` combining visual semantics and hand motion dynamics.
- **Language Decoder**: `t5-base` generating natural English sentences.
- **Dataset**: INCLUDE dataset (~4,284 videos across 250 ISL categories).

---

## Setup & Running

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Download Model Checkpoint (`model_best.pth`)
Run the automated downloader:
```bash
python download_weights.py
```
Or download manually from:
[https://huggingface.co/ayush2635/sanket-isl-translator/resolve/main/model_best.pth](https://huggingface.co/ayush2635/sanket-isl-translator/resolve/main/model_best.pth)
and place the file in `weights/model_best.pth`.

### 3. Translate a Video File (CLI)
```bash
python infer.py --video path/to/sample.mp4
```

### 4. Run the REST API Microservice
```bash
python server.py
```
API endpoint: `POST http://localhost:8001/translate-video`
Upload any `.mp4` video in the `file` multipart field.
