from pydantic import BaseModel, Field


class VoiceTranscriptionResponse(BaseModel):
    transcript: str
    confidence: float | None = None


class VoiceSynthesisRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
