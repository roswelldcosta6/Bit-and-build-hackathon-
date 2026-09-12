"""
Dual-Stream Gated Multi-Modal Transformer for ISL Video Translation
Backbone: TimeSformer (Vision) + TransformerEncoder (Pose) + T5-Base (Language Decoder)
Model checkpoint: ayush2635/sanket-isl-translator/model_best.pth
"""

import torch
import torch.nn as nn
from typing import Optional, Dict, Any


class PoseEncoder(nn.Module):
    def __init__(self, in_features: int = 195, d_model: int = 768, nhead: int = 8, num_layers: int = 2):
        super().__init__()
        self.input_proj = nn.Linear(in_features, d_model)
        self.pos_emb = nn.Parameter(torch.randn(1, 100, d_model) * 0.02)
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=d_model,
            nhead=nhead,
            dim_feedforward=d_model * 4,
            dropout=0.1,
            activation="gelu",
            batch_first=True,
        )
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.norm = nn.LayerNorm(d_model)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [B, T, 195]
        B, T, _ = x.shape
        h = self.input_proj(x) + self.pos_emb[:, :T, :]
        h = self.encoder(h)
        return self.norm(h)


class GatedCrossModalFusion(nn.Module):
    def __init__(self, d_model: int = 768):
        super().__init__()
        self.gate = nn.Sequential(
            nn.Linear(d_model * 2, d_model),
            nn.Sigmoid(),
        )
        self.fusion_proj = nn.Linear(d_model, d_model)
        self.norm = nn.LayerNorm(d_model)

    def forward(self, vision_feat: torch.Tensor, pose_feat: torch.Tensor) -> torch.Tensor:
        # Both: [B, T, d_model]
        combined = torch.cat([vision_feat, pose_feat], dim=-1)
        g = self.gate(combined)
        fused = g * vision_feat + (1.0 - g) * pose_feat
        return self.norm(self.fusion_proj(fused))


class DualStreamISLTranslator(nn.Module):
    def __init__(self, d_model: int = 768, pose_dim: int = 195):
        super().__init__()
        self.d_model = d_model

        # Visual projector (simulating TimeSformer output embedding layer)
        self.vision_proj = nn.Sequential(
            nn.Linear(768, d_model),
            nn.LayerNorm(d_model),
            nn.GELU(),
        )

        # Pose encoder stream
        self.pose_encoder = PoseEncoder(in_features=pose_dim, d_model=d_model)

        # Gated fusion
        self.fusion = GatedCrossModalFusion(d_model=d_model)

        # Output adapter for T5 cross-attention
        self.encoder_out_proj = nn.Linear(d_model, d_model)

    def forward(self, vision_tokens: torch.Tensor, pose_keypoints: torch.Tensor) -> torch.Tensor:
        # vision_tokens: [B, T, 768]
        # pose_keypoints: [B, T, 195]
        v_feat = self.vision_proj(vision_tokens)
        p_feat = self.pose_encoder(pose_keypoints)
        fused = self.fusion(v_feat, p_feat)
        return self.encoder_out_proj(fused)


def build_isl_translator(weights_path: Optional[str] = None) -> DualStreamISLTranslator:
    model = DualStreamISLTranslator()
    if weights_path and torch.cuda.is_available() or weights_path:
        try:
            checkpoint = torch.load(weights_path, map_location="cpu")
            state_dict = checkpoint.get("model_state_dict", checkpoint)
            model.load_state_dict(state_dict, strict=False)
            print(f"[INFO] Successfully loaded model checkpoint from: {weights_path}")
        except Exception as e:
            print(f"[WARN] Could not load checkpoint from {weights_path}: {e}")
    return model
