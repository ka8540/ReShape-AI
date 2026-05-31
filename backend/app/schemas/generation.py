from pydantic import BaseModel


class GenerateLayoutsRequest(BaseModel):
    variants: int = 3
    reference_media_id: str | None = None


class GenerationStatus(BaseModel):
    project_id: str
    status: str
    designs_ready: int
    designs_requested: int
    error_code: str | None = None
    error_message: str | None = None
