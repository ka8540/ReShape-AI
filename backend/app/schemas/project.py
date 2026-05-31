from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class ProjectCreate(BaseModel):
    name: str
    room: str | None = None
    mode: str = "reshuffle"
    notes: str | None = None


class ProjectUpdate(BaseModel):
    name: str | None = None
    room: str | None = None
    mode: str | None = None
    status: str | None = None
    notes: str | None = None


class ProjectOut(ORMModel):
    id: str
    user_id: str
    name: str
    room: str | None
    mode: str
    status: str
    notes: str | None
    created_at: datetime
    updated_at: datetime
