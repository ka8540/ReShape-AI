from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class FeedbackCreate(BaseModel):
    rating: int | None = Field(default=None, ge=1, le=5)
    sentiment: str | None = None
    comment: str | None = None


class FeedbackOut(ORMModel):
    id: str
    design_id: str
    rating: int | None
    sentiment: str | None
    comment: str | None
    created_at: datetime
