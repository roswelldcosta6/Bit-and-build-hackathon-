"""
Test harness for P1's `model_best.pth` (SignBridge sign -> text model).

The checkpoint is a 433M-param state dict. Its tensor names/shapes define the
architecture:

  video_encoder  : 12-layer ViT/TimeSformer-style encoder
                   (8 frames x 224x224, patch 16, CLS token, temporal attention)
  pose_encoder   : fc_in(195 -> 768) + 2x nn.TransformerEncoderLayer
                   (195 = 33 pose x 4 + 21 hand x 3 MediaPipe keypoints)
  fusion         : gated multimodal fusion (visual_gate, pose_gate, out_proj)
  dim_mapper     : Linear(768 -> 768)
  text_decoder   : HuggingFace T5-base encoder+decoder (vocab 32128) + lm_head

Usage:
    python test_model.py                       # random-weight smoke test
    python test_model.py path/to/model_best.pth
    python test_model.py model.pth --video frame1.jpg frame2.jpg ... (up to 8)
    python test_model.py model.pth --npz landmarks.npz              # 195-dim keypoints
"""
import argparse
import sys
from pathlib import Path

import torch
import torch.nn as nn

CKPT_DEFAULT = r"C:/Users/rebel/Downloads/model_best.pth"
D_MODEL = 768
NUM_FRAMES = 8
POSE_DIM = 195


# ---------------------------------------------------------------------------
# Architecture reconstruction (matches the checkpoint's keys/shapes exactly)
# ---------------------------------------------------------------------------
class VideoEmbeddings(nn.Module):
    def __init__(self):
        super().__init__()
        self.cls_token = nn.Parameter(torch.zeros(1, 1, D_MODEL))
        self.position_embeddings = nn.Parameter(torch.zeros(1, 197, D_MODEL))
        self.time_embeddings = nn.Parameter(torch.zeros(1, NUM_FRAMES, D_MODEL))
        self.patch_embeddings = nn.Module()
        self.patch_embeddings.projection = nn.Conv2d(3, D_MODEL, kernel_size=16, stride=16)

    def forward(self, x):  # x: (B, T=8, 3, 224, 224)
        b, t = x.shape[:2]
        patches = self.patch_embeddings.projection(x.flatten(0, 1))  # (B*T, 768, 14, 14)
        patches = patches.flatten(2).transpose(1, 2)                 # (B*T, 196, 768)
        patches = patches.view(b, t, 196, D_MODEL)
        patches = patches + self.time_embeddings[:, :t].unsqueeze(2)  # per-frame time emb
        cls = self.cls_token.expand(b, t, -1, -1)                    # (B, T, 1, 768)
        seq = torch.cat([cls, patches], dim=2)                       # (B, T, 197, 768)
        return seq + self.position_embeddings[:, None, :]            # shared spatial pos


class AttentionBlock(nn.Module):
    """ViT-style pre-norm block with fused QKV, matching checkpoint names."""

    def __init__(self):
        super().__init__()
        self.attention = nn.Module()
        self.attention.attention = nn.Module()
        self.attention.attention.qkv = nn.Linear(D_MODEL, D_MODEL * 3)
        self.attention.output = nn.Module()
        self.attention.output.dense = nn.Linear(D_MODEL, D_MODEL)
        self.intermediate = nn.Module()
        self.intermediate.dense = nn.Linear(D_MODEL, D_MODEL * 4)
        self.output = nn.Module()
        self.output.dense = nn.Linear(D_MODEL * 4, D_MODEL)
        self.layernorm_before = nn.LayerNorm(D_MODEL)
        self.layernorm_after = nn.LayerNorm(D_MODEL)

    def forward(self, x):
        h = self.layernorm_before(x)
        qkv = self.attention.attention.qkv(h)
        q, k, v = qkv.chunk(3, dim=-1)
        attn = nn.functional.scaled_dot_product_attention(q, k, v)
        x = x + self.attention.output.dense(attn)
        h = self.layernorm_after(x)
        h = self.output.dense(nn.functional.gelu(self.intermediate.dense(h)))
        return x + h


class TemporalAttention(nn.Module):
    def __init__(self):
        super().__init__()
        self.attention = nn.Module()
        self.attention.qkv = nn.Linear(D_MODEL, D_MODEL * 3)
        self.output = nn.Module()
        self.output.dense = nn.Linear(D_MODEL, D_MODEL)

    def forward(self, x):  # (B, T, 768)
        qkv = self.attention.qkv(x)
        q, k, v = qkv.chunk(3, dim=-1)
        attn = nn.functional.scaled_dot_product_attention(q, k, v)
        return self.output.dense(attn)


class VideoEncoderLayer(nn.Module):
    def __init__(self):
        super().__init__()
        self.attention = AttentionBlock().attention
        self.intermediate = AttentionBlock().intermediate
        self.output = AttentionBlock().output
        self.layernorm_before = nn.LayerNorm(D_MODEL)
        self.layernorm_after = nn.LayerNorm(D_MODEL)
        self.temporal_attention = TemporalAttention()
        self.temporal_layernorm = nn.LayerNorm(D_MODEL)
        self.temporal_dense = nn.Linear(D_MODEL, D_MODEL)

    def spatial_pass(self, x):  # (B*T, 197, 768)
        h = self.layernorm_before(x)
        qkv = self.attention.attention.qkv(h)
        q, k, v = qkv.chunk(3, dim=-1)
        attn = nn.functional.scaled_dot_product_attention(q, k, v)
        x = x + self.attention.output.dense(attn)
        h = self.layernorm_after(x)
        return x + self.output.dense(nn.functional.gelu(self.intermediate.dense(h)))

    def forward(self, x):  # (B, T, 197, 768)
        b, t, n, d = x.shape
        x = self.spatial_pass(x.flatten(0, 1)).view(b, t, n, d)
        cls, patches = x[:, :, :1], x[:, :, 1:]
        patches = patches + self.temporal_attention(
            self.temporal_layernorm(patches.transpose(1, 2)).transpose(1, 2)
        )
        patches = patches + self.temporal_dense(patches)
        return torch.cat([cls, patches], dim=2)


class VideoEncoder(nn.Module):
    def __init__(self, num_layers=12):
        super().__init__()
        self.embeddings = VideoEmbeddings()
        self.encoder = nn.Module()
        self.encoder.layer = nn.ModuleList([VideoEncoderLayer() for _ in range(num_layers)])
        self.layernorm = nn.LayerNorm(D_MODEL)

    def forward(self, x):
        h = self.embeddings(x)                       # (B, T, 197, 768)
        for layer in self.encoder.layer:
            h = layer(h)
        return self.layernorm(h.mean(dim=1).mean(dim=1))  # (B, 768) simple pool


class PoseEncoder(nn.Module):
    def __init__(self, num_layers=2):
        super().__init__()
        self.fc_in = nn.Linear(POSE_DIM, D_MODEL)
        self.transformer = nn.Module()
        self.transformer.layers = nn.ModuleList(
            [nn.TransformerEncoderLayer(
                D_MODEL, 12, 2048, 0.1, batch_first=True
            ) for _ in range(num_layers)]
        )

    def forward(self, keypoints):  # (B, T, 195)
        h = self.fc_in(keypoints)
        for layer in self.transformer.layers:
            h = layer(h)
        return h.mean(dim=1)  # (B, 768)


class Fusion(nn.Module):
    def __init__(self):
        super().__init__()
        self.visual_gate = nn.Linear(D_MODEL * 2, D_MODEL)
        self.pose_gate = nn.Linear(D_MODEL * 2, D_MODEL)
        self.out_proj = nn.Linear(D_MODEL * 2, D_MODEL)
        self.sigmoid = torch.sigmoid

    def forward(self, visual, pose):
        pair = torch.cat([visual, pose], dim=-1)
        fused = self.out_proj(
            torch.cat([visual * self.sigmoid(self.visual_gate(pair)),
                       pose * self.sigmoid(self.pose_gate(pair))], dim=-1)
        )
        return fused


class SignBridgeModel(nn.Module):
    def __init__(self):
        super().__init__()
        self.video_encoder = VideoEncoder()
        self.pose_encoder = PoseEncoder()
        self.fusion = Fusion()
        self.dim_mapper = nn.Linear(D_MODEL, D_MODEL)


# ---------------------------------------------------------------------------
# Checkpoint loading
# ---------------------------------------------------------------------------
def load_checkpoint(path: str) -> SignBridgeModel:
    print(f"Loading {path} ...")
    state = torch.load(path, map_location="cpu", weights_only=True)
    if not isinstance(state, dict) or not all(
        isinstance(v, torch.Tensor) for v in state.values()
    ):
        for k in ("state_dict", "model", "model_state_dict"):
            if k in state:
                state = state[k]
                break

    model = SignBridgeModel()
    # text_decoder -> HuggingFace T5-base
    from transformers import T5ForConditionalGeneration
    t5 = T5ForConditionalGeneration.from_pretrained("t5-base")
    missing, unexpected = t5.load_state_dict(extract_t5(state), strict=False)
    missing = [m for m in missing if "relative_position" not in m]
    if missing or unexpected:
        print(f"  T5 load: missing={len(missing)} unexpected={len(unexpected)}")
        if missing:
            print("   e.g.", missing[:4])
        if unexpected:
            print("   e.g.", unexpected[:4])
    else:
        print("  T5 text decoder: all weights matched exactly")
    model.text_decoder = t5

    custom = {k: v for k, v in state.items() if not k.startswith("text_decoder.")}
    result = model.load_state_dict(custom, strict=False)
    # T5 params are 'missing' from the custom dict by design (loaded above).
    real_missing = [k for k in result.missing_keys if not k.startswith("text_decoder")]
    print(f"  encoders/fusion: matched={len(custom)} missing={len(real_missing)} "
          f"unexpected={len(result.unexpected_keys)}")
    if real_missing:
        print("   e.g.", real_missing[:5])
    if result.unexpected_keys:
        print("   e.g.", result.unexpected_keys[:5])
    model.eval()
    print(f"Loaded {sum(p.numel() for p in model.parameters())/1e6:.0f}M params")
    return model


def extract_t5(state):
    """text_decoder.* keys (minus the bare T5 wrapper) -> T5 state dict."""
    t5_sd = {}
    for k, v in state.items():
        if k.startswith("text_decoder."):
            t5_sd[k[len("text_decoder."):]] = v
    return t5_sd


# ---------------------------------------------------------------------------
# Smoke tests
# ---------------------------------------------------------------------------
@torch.no_grad()
def run_smoke(model, frames=None, pose=None):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = model.to(device)
    b = 1
    if frames is None:
        frames = torch.randn(b, NUM_FRAMES, 3, 224, 224, device=device)
    if pose is None:
        pose = torch.randn(b, NUM_FRAMES, POSE_DIM, device=device)

    print(f"\nRunning inference on {device} ...")
    visual = model.video_encoder(frames)
    pose_feat = model.pose_encoder(pose)
    fused = model.dim_mapper(model.fusion(visual, pose_feat))

    # T5: feed fused vector as encoder outputs, greedy-decode
    dec = model.text_decoder
    enc_out = dec.get_encoder()(inputs_embeds=fused.unsqueeze(1))
    ys = torch.tensor([[dec.config.decoder_start_token_id]], device=device)
    out_tokens = []
    for _ in range(20):
        logits = dec(decoder_input_ids=ys, encoder_outputs=enc_out).logits
        nxt = logits[:, -1].argmax(-1)
        tok = int(nxt)
        if tok == dec.config.eos_token_id:
            break
        out_tokens.append(tok)
        ys = torch.cat([ys, nxt.unsqueeze(0)], dim=1)

    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained("t5-base")
    text = tok.decode(out_tokens, skip_special_tokens=True)
    print("  visual feature:", tuple(visual.shape))
    print("  pose feature:  ", tuple(pose_feat.shape))
    print("  fused feature: ", tuple(fused.shape))
    print(f"  generated text: {text!r}")
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint", nargs="?", default=CKPT_DEFAULT)
    ap.add_argument("--video", nargs="*", help="up to 8 image frames (jpg/png)")
    ap.add_argument("--npz", help=".npz with (T, 195) pose keypoints array")
    args = ap.parse_args()

    model = load_checkpoint(args.checkpoint)

    frames = pose = None
    if args.video:
        from PIL import Image
        import numpy as np
        imgs = [Image.open(p).convert("RGB").resize((224, 224)) for p in args.video[:8]]
        while len(imgs) < NUM_FRAMES:
            imgs.append(imgs[-1])
        frames = torch.stack([torch.from_numpy(np.array(i)).permute(2, 0, 1) for i in imgs])
        frames = frames.float() / 255.0
        frames = (frames - 0.5) / 0.5
        frames = frames.unsqueeze(0)
    if args.npz:
        import numpy as np
        arr = np.load(args.npz)
        key = next(k for k in arr.files if arr[k].ndim == 2 and arr[k].shape[-1] == POSE_DIM)
        seq = arr[key][:NUM_FRAMES]
        pose = torch.from_numpy(seq).float().unsqueeze(0)

    run_smoke(model, frames, pose)


if __name__ == "__main__":
    main()
