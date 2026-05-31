from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel

MediaKind = Literal["image", "video"]


class UploadUrlRequest(BaseModel):
    file_name: str = Field(..., min_length=1, max_length=255)
    mime_type: str
    file_size: int = Field(..., gt=0)
    media_kind: MediaKind


class UploadUrlResponse(BaseModel):
    media_id: str
    upload_url: str
    storage_key: str
    expires_in: int


class CompleteUploadRequest(BaseModel):
    media_id: str


class MediaAssetOut(ORMModel):
    id: str
    project_id: str
    media_kind: str
    file_name: str
    mime_type: str
    file_size: int
    upload_status: str
    created_at: datetime


class ReadUrlResponse(BaseModel):
    read_url: str
    expires_in: int
