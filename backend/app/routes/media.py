from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.common import Status
from app.schemas.media import (
    CompleteUploadRequest,
    MediaAssetOut,
    ReadUrlResponse,
    UploadUrlRequest,
    UploadUrlResponse,
)
from app.services import media_service, r2_storage_service

router = APIRouter(prefix="/projects/{project_id}/media", tags=["media"])


@router.post("/upload-url", response_model=UploadUrlResponse, status_code=status.HTTP_201_CREATED)
def create_upload_url(
    payload: UploadUrlRequest,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> UploadUrlResponse:
    asset, url = media_service.create_upload(db, project, payload)
    return UploadUrlResponse(
        media_id=asset.id,
        upload_url=url,
        storage_key=asset.storage_key,
        expires_in=r2_storage_service.DEFAULT_EXPIRES,
    )


@router.post("/complete", response_model=MediaAssetOut)
def complete_upload(
    payload: CompleteUploadRequest,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> MediaAssetOut:
    asset = media_service.complete_upload(db, project, payload.media_id)
    return MediaAssetOut.model_validate(asset)


@router.get("", response_model=list[MediaAssetOut])
def list_media(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> list[MediaAssetOut]:
    return [
        MediaAssetOut.model_validate(a)
        for a in media_service.list_for_project(db, project)
    ]


@router.get("/{media_id}/read-url", response_model=ReadUrlResponse)
def get_read_url(
    media_id: str,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> ReadUrlResponse:
    asset = media_service.get_owned(db, project, media_id)
    return ReadUrlResponse(
        read_url=r2_storage_service.read_url(storage_key=asset.storage_key),
        expires_in=r2_storage_service.DEFAULT_EXPIRES,
    )


@router.delete("/{media_id}", response_model=Status)
def delete_media(
    media_id: str,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> Status:
    asset = media_service.get_owned(db, project, media_id)
    media_service.delete(db, asset)
    return Status(status="deleted")
