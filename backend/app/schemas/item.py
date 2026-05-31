from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class DetectedItemCreate(BaseModel):
    name: str
    type: str
    fixed: bool = False
    structural: bool = False


class DetectedItemUpdate(BaseModel):
    name: str | None = None
    type: str | None = None
    fixed: bool | None = None


class DetectedItemOut(ORMModel):
    id: str
    project_id: str
    name: str
    type: str
    confidence: float
    fixed: bool
    structural: bool
    added_by_user: bool
    created_at: datetime
