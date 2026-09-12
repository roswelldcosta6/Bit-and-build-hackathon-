"""
Weight Downloader for Sanket ISL Translator
Model: https://huggingface.co/ayush2635/sanket-isl-translator/blob/main/model_best.pth
"""

import os
import sys
import requests
from tqdm import tqdm

HUGGINGFACE_URL = "https://huggingface.co/ayush2635/sanket-isl-translator/resolve/main/model_best.pth"
WEIGHTS_DIR = os.path.join(os.path.dirname(__file__), "weights")
OUTPUT_PATH = os.path.join(WEIGHTS_DIR, "model_best.pth")


def download_weights(url: str = HUGGINGFACE_URL, dest: str = OUTPUT_PATH) -> str:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if os.path.exists(dest) and os.path.getsize(dest) > 1024 * 1024:
        print(f"[INFO] Weights already exist at: {dest} ({os.path.getsize(dest) / (1024 * 1024):.1f} MB)")
        return dest

    print(f"[INFO] Downloading model_best.pth from {url}...")
    response = requests.get(url, stream=True, allow_redirects=True, timeout=60)
    response.raise_for_status()

    total_size = int(response.headers.get("content-length", 0))
    block_size = 1024 * 1024  # 1MB

    with open(dest, "wb") as f, tqdm(
        desc="model_best.pth",
        total=total_size,
        unit="iB",
        unit_scale=True,
        unit_divisor=1024,
    ) as bar:
        for chunk in response.iter_content(chunk_size=block_size):
            if chunk:
                f.write(chunk)
                bar.update(len(chunk))

    print(f"[SUCCESS] Download completed: {dest}")
    return dest


if __name__ == "__main__":
    download_weights()
