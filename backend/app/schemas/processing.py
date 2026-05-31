from pydantic import BaseModel


class ProcessingStatus(BaseModel):
    project_id: str
    status: str
    stage: str | None = None
    progress: float = 0.0
    error_code: str | None = None
    error_message: str | None = None
