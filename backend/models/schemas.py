from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(..., json_schema_extra={"example": "healthy"})
    service: str = Field(..., json_schema_extra={"example": "signbridge-backend"})
    version: str = Field(..., json_schema_extra={"example": "1.0.0"})
    supported_languages: List[str] = Field(default=["en", "hi"])
    total_signs: int = Field(..., json_schema_extra={"example": 65})


class TextToISLRequest(BaseModel):
    text: str = Field(..., description="Text in English or Hindi to translate to ISL", json_schema_extra={"example": "Where is the hospital?"})
    lang: Optional[str] = Field(default=None, description="Optional ISO code 'en' or 'hi'. If omitted, auto-detected.")


class ISLGlossResponse(BaseModel):
    original_text: str
    detected_lang: str
    glosses: List[str]
    clip_ids: List[int]
    video_filenames: List[str]
    subtitle: str
    grammar_applied: List[str]


class PredictRequest(BaseModel):
    # Mode A cloud fallback: 30 frames x 63 landmarks (21 hand coords x,y,z)
    keypoints: List[List[float]] = Field(..., description="Normalized keypoints buffer: 30 frames x 63 coordinates")


class PredictResponse(BaseModel):
    sign_label: str
    label_en: str
    label_hi: str
    confidence: float
    is_stable: bool


class HistoryItem(BaseModel):
    id: Optional[str] = None
    timestamp: str
    mode: str = Field(..., description="'MODE_A' or 'MODE_B'")
    input_content: str
    output_content: str
    detected_lang: Optional[str] = None
    glosses: Optional[List[str]] = None


class HistoryListResponse(BaseModel):
    session_id: str
    count: int
    items: List[HistoryItem]


class VocabularyItem(BaseModel):
    clip_id: int
    gloss: str
    en: str
    hi: str
    category: str
    video_file: str


class VocabularyResponse(BaseModel):
    total: int
    categories: List[str]
    vocabulary: List[VocabularyItem]
