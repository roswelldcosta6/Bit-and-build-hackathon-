from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(..., json_schema_extra={"example": "healthy"})
    service: str = Field(..., json_schema_extra={"example": "signbridge-backend"})
    version: str = Field(..., json_schema_extra={"example": "1.0.0"})
    avatar_engine: str = Field(default="3D_HUMANOID_SKELETAL", json_schema_extra={"example": "3D_HUMANOID_SKELETAL"})
    supported_languages: List[str] = Field(default=["en", "hi"])
    total_signs: int = Field(..., json_schema_extra={"example": 65})


class AvatarAnimationAction(BaseModel):
    gloss: str
    animation_trigger: str
    duration_ms: int
    blend_transition_ms: int = 250
    hand_target: str = "BOTH_HANDS"  # "RIGHT_HAND", "LEFT_HAND", "BOTH_HANDS"
    facial_expression: str = "NEUTRAL"  # "NEUTRAL", "QUESTIONING", "CONCERNED", "SMILE"
    pose_endpoint: str


class TextToISLRequest(BaseModel):
    text: str = Field(..., description="Text in English or Hindi to translate to ISL", json_schema_extra={"example": "Where is the hospital?"})
    lang: Optional[str] = Field(default=None, description="Optional ISO code 'en' or 'hi'. If omitted, auto-detected.")


class ISLGlossResponse(BaseModel):
    original_text: str
    detected_lang: str
    glosses: List[str]
    # Humanoid 3D Avatar Animation Data
    animation_sequence: List[AvatarAnimationAction]
    total_duration_ms: int
    # Backward compatibility
    clip_ids: List[int]
    video_filenames: List[str]
    subtitle: str
    grammar_applied: List[str]


class SkeletalJointFrame(BaseModel):
    frame_index: int
    time_ms: float
    joints: Dict[str, List[float]]  # joint_name -> [x, y, z]


class SkeletalPoseResponse(BaseModel):
    gloss: str
    fps: int = 30
    frame_count: int
    duration_ms: int
    hand_target: str
    facial_expression: str
    frames: List[SkeletalJointFrame]


class PredictRequest(BaseModel):
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
    animation_trigger: str
    hand_target: str
    facial_expression: str
    duration_ms: int
    video_file: str


class VocabularyResponse(BaseModel):
    total: int
    categories: List[str]
    vocabulary: List[VocabularyItem]
