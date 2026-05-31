from datetime import datetime

from pydantic import BaseModel, EmailStr

from app.schemas.common import ORMModel


class UserOut(ORMModel):
    id: str
    firebase_uid: str
    email: EmailStr | None = None
    display_name: str | None = None
    photo_url: str | None = None
    provider: str | None = None
    role: str
    is_active: bool
    created_at: datetime
    last_login_at: datetime | None = None


class UserUpdate(BaseModel):
    display_name: str | None = None


class ProjectsSummary(BaseModel):
    total_projects: int
    processing_projects: int
    completed_projects: int
    failed_projects: int
    generated_design_count: int
