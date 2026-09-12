"""
FastAPI Microservice for Sanket ISL Video-to-Text Translation
Exposes REST endpoints for mobile app and web clients.
"""

import os
import shutil
import tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from infer import VideoToTextTranslator

app = FastAPI(
    title="Sanket ISL Video-to-Text Translation API",
    description="Translates Indian Sign Language video clips into fluent English text.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

translator = VideoToTextTranslator()


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "sanket-video-to-text",
        "weights_present": os.path.exists(translator.weights_path),
    }


@app.post("/translate-video")
async def translate_video_endpoint(file: UploadFile = File(...)):
    """
    Upload an MP4 / WebM / AVI video file to receive the translated ISL sentence.
    """
    if not file.filename.lower().endswith((".mp4", ".avi", ".mov", ".webm")):
        raise HTTPException(status_code=400, detail="Invalid video format. Please upload MP4, WebM, or MOV.")

    suffix = os.path.splitext(file.filename)[1]
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name

    try:
        result = translator.translate_video(tmp_path)
        return result
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8001, reload=True)
