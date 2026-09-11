"""
SignBridge Backend API Service
Author: Person 3 (Backend + NLP Engineer)
Framework: FastAPI
"""

import time
import uuid
from typing import Dict, List, Optional
from datetime import datetime, timezone

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models.schemas import (
    HealthResponse,
    TextToISLRequest,
    ISLGlossResponse,
    PredictRequest,
    PredictResponse,
    HistoryItem,
    HistoryListResponse,
    VocabularyItem,
    VocabularyResponse,
)
from vocabulary import get_all_vocabulary, get_sign_metadata
from gloss_mapper import text_to_isl_gloss
from whisper_stt import transcribe_audio_bytes

# Initialize FastAPI App
app = FastAPI(
    title="SignBridge Real-Time ISL Translation API",
    description="Backend microservice providing bilingual Speech-to-ISL, Text-to-ISL gloss mapping, vocabulary registry, and cloud fallback gesture inference.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Enable CORS for Flutter Mobile, Web, and Desktop Clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-Memory History Storage (can be linked to MongoDB Atlas)
_HISTORY_STORE: Dict[str, List[HistoryItem]] = {}


@app.get("/health", response_model=HealthResponse, tags=["System"])
def health_check():
    """Returns the operational status of the SignBridge backend."""
    vocab = get_all_vocabulary()
    return HealthResponse(
        status="healthy",
        service="signbridge-backend",
        version="1.0.0",
        supported_languages=["en", "hi"],
        total_signs=len(vocab),
    )


@app.get("/vocabulary", response_model=VocabularyResponse, tags=["ISL Knowledge Base"])
def get_vocabulary():
    """Fetches the complete bilingual vocabulary mapping with avatar clip metadata."""
    vocab = get_all_vocabulary()
    categories = sorted(list(set(item["category"] for item in vocab)))
    vocab_items = [VocabularyItem(**item) for item in vocab]
    return VocabularyResponse(
        total=len(vocab_items),
        categories=categories,
        vocabulary=vocab_items,
    )


@app.post("/text-to-isl", response_model=ISLGlossResponse, tags=["Mode B: Speak/Text -> Sign"])
def convert_text_to_isl(payload: TextToISLRequest, session_id: Optional[str] = "default"):
    """
    Translates English or Hindi plain text to an ordered ISL gloss sequence
    with corresponding video animation clip IDs.
    """
    if not payload.text.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Text field cannot be empty",
        )

    result = text_to_isl_gloss(payload.text, explicit_lang=payload.lang)

    # Save to history
    item = HistoryItem(
        id=str(uuid.uuid4())[:8],
        timestamp=datetime.now(timezone.utc).isoformat(),
        mode="MODE_B",
        input_content=payload.text,
        output_content=" -> ".join(result["glosses"]),
        detected_lang=result["detected_lang"],
        glosses=result["glosses"],
    )
    if session_id not in _HISTORY_STORE:
        _HISTORY_STORE[session_id] = []
    _HISTORY_STORE[session_id].append(item)

    return ISLGlossResponse(**result)


@app.post("/speech-to-isl", response_model=ISLGlossResponse, tags=["Mode B: Speak/Text -> Sign"])
async def convert_speech_to_isl(
    audio: UploadFile = File(...),
    session_id: Optional[str] = Form("default"),
):
    """
    Ingests spoken audio (.wav, .mp3, .m4a), transcribes via Whisper (auto-detecting Hindi or English),
    and maps the transcribed text to ISL glosses and animation clip IDs.
    """
    content = await audio.read()
    if len(content) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded audio file is empty",
        )

    stt_result = transcribe_audio_bytes(content, filename=audio.filename or "audio.wav")
    text = stt_result.get("text", "")
    detected_lang = stt_result.get("lang", "en")

    if not text:
        text = "Help"

    # Pass transcribed text through the ISL Gloss Mapper
    isl_result = text_to_isl_gloss(text, explicit_lang=detected_lang)

    # Save to history
    item = HistoryItem(
        id=str(uuid.uuid4())[:8],
        timestamp=datetime.now(timezone.utc).isoformat(),
        mode="MODE_B",
        input_content=f"[Audio: {text}]",
        output_content=" -> ".join(isl_result["glosses"]),
        detected_lang=detected_lang,
        glosses=isl_result["glosses"],
    )
    if session_id not in _HISTORY_STORE:
        _HISTORY_STORE[session_id] = []
    _HISTORY_STORE[session_id].append(item)

    return ISLGlossResponse(**isl_result)


@app.post("/predict", response_model=PredictResponse, tags=["Mode A: Sign -> Speak (Cloud Fallback)"])
def predict_gesture(payload: PredictRequest):
    """
    Cloud fallback inference for Mode A when on-device inference is unavailable.
    Takes 30 frames x 63 coordinates and returns the classified sign with confidence.
    """
    frames = payload.keypoints
    if not frames:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Keypoints buffer cannot be empty",
        )

    # Heuristic & mock fallback classifier for demonstration
    # In production, this loads Person 1's model weights
    sample_first = frames[0] if len(frames) > 0 else []
    
    # Calculate simple variance across frames to simulate dynamic gesture recognition
    avg_val = sum(sample_first) / len(sample_first) if sample_first else 0.5
    
    if avg_val > 0.6:
        label = "HELP"
    elif avg_val > 0.4:
        label = "DOCTOR"
    elif avg_val > 0.2:
        label = "WATER"
    else:
        label = "HELLO"

    meta = get_sign_metadata(label) or {"en": label, "hi": label}

    return PredictResponse(
        sign_label=label,
        label_en=meta.get("en", label),
        label_hi=meta.get("hi", label),
        confidence=0.91,
        is_stable=True,
    )


@app.get("/history/{session_id}", response_model=HistoryListResponse, tags=["Session History"])
def get_session_history(session_id: str):
    """Retrieves chronological translation items for a session."""
    items = _HISTORY_STORE.get(session_id, [])
    return HistoryListResponse(
        session_id=session_id,
        count=len(items),
        items=items,
    )


@app.post("/history", response_model=HistoryItem, tags=["Session History"])
def add_history_entry(item: HistoryItem, session_id: Optional[str] = "default"):
    """Manually logs a translation record (e.g. from on-device Mode A)."""
    if not item.id:
        item.id = str(uuid.uuid4())[:8]
    if session_id not in _HISTORY_STORE:
        _HISTORY_STORE[session_id] = []
    _HISTORY_STORE[session_id].append(item)
    return item


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
