from pydantic import BaseModel


class GenerateLayoutsRequest(BaseModel):
    variants: int = 3
    reference_media_id: str | None = None


class GenerationStatus(BaseModel):
    project_id: str
    status: str  # queued | running | completed | failed
    designs_ready: int
    designs_requested: int
    # Per-status counts so the client can show truthful progress.
    total: int = 0
    queued: int = 0
    running: int = 0
    succeeded: int = 0
    failed: int = 0
    error_code: str | None = None
    error_message: str | None = None
