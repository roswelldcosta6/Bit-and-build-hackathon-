# ml/ — Person 1 (ML Engineer)

## Testing `model_best.pth` (sign → text model)

The checkpoint is a 433M-param PyTorch state dict. Architecture (recovered from
tensor names/shapes — every weight matched):

| Module | Structure | Input |
|---|---|---|
| `video_encoder` | 12-layer ViT with per-frame CLS + temporal attention (TimeSformer-style) | 8 frames × 3×224×224 |
| `pose_encoder` | Linear(195→768) + 2× TransformerEncoderLayer | 8 frames × 195 keypoints (33 pose×4 + 21 hand×3, MediaPipe order) |
| `fusion` | gated multimodal fusion (`visual_gate`, `pose_gate`, `out_proj`) | two 768-d vectors |
| `dim_mapper` | Linear(768→768) | fused vector |
| `text_decoder` | HuggingFace **T5-base** encoder+decoder + lm_head (vocab 32128) | 768-d memory |

All 281 encoder/fusion tensors load with zero unexpected keys; the 260
`text_decoder.*` tensors match `t5-base` exactly.

### Run it

```bash
# from the repo root, using the backend venv (torch + transformers installed)
cd ml
../backend/.venv/Scripts/python.exe test_model.py                    # random-input smoke test
../backend/.venv/Scripts/python.exe test_model.py path/to/model_best.pth
../backend/.venv/Scripts/python.exe test_model.py model.pth --video f1.jpg f2.jpg ...   # up to 8 frames
../backend/.venv/Scripts/python.exe test_model.py model.pth --npz landmarks.npz        # (T,195) keypoints
```

Smoke output on random weights is gibberish — that is expected. With real
frames (`--video`) you get the model's actual translation.

### What this proves / what is still missing

- ✔ Checkpoint is intact and loadable; forward pass runs end-to-end (CPU).
- ✔ Exact inference contract for P2: video `(B, 8, 3, 224, 224)` normalized to
  [-1, 1] + pose `(B, 8, 195)`.
- ✘ `test_model.py` reconstructs the architecture from shapes; operations are
  inferred (gated mean fusion, mean pooling) and may differ from P1's training
  code. **Get P1's training repo** (`model.py` + config) to guarantee faithful
  outputs.
- ✘ For the app: export to TFLite (int8) or ONNX is still pending — a 433M /
  1.4GB model cannot ship on-device, so Mode A needs the backend `/predict`
  fallback or a distilled model.
