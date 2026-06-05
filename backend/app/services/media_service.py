from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.exceptions import bad_request, not_found
from app.models.media_asset import MediaAsset
from app.models.project import Project
from app.schemas.media import UploadUrlRequest
from app.services import r2_storage_service


def _validate(req: UploadUrlRequest) -> None:
    settings = get_settings()
    if req.media_kind == "image":
        if req.mime_type not in settings.ALLOWED_IMAGE_MIME:
            raise bad_request(f"Unsupported image type: {req.mime_type}")
        if req.file_size > settings.MAX_IMAGE_BYTES:
            raise bad_request("Image exceeds size limit")
    elif req.media_kind == "video":
        if req.mime_type not in settings.ALLOWED_VIDEO_MIME:
            raise bad_request(f"Unsupported video type: {req.mime_type}")
        if req.file_size > settings.MAX_VIDEO_BYTES:
            raise bad_request("Video exceeds size limit")
    else:  # pragma: no cover - pydantic Literal guards this
        raise bad_request("Invalid media_kind")


def create_upload(
    db: Session, project: Project, req: UploadUrlRequest
) -> tuple[MediaAsset, str]:
    _validate(req)
    storage_key = r2_storage_service.build_storage_key(
        user_id=project.user_id,
        project_id=project.id,
        kind=req.media_kind,
        file_name=req.file_name,
    )
    asset = MediaAsset(
        project_id=project.id,
        media_kind=req.media_kind,
        file_name=req.file_name,
        mime_type=req.mime_type,
        file_size=req.file_size,
        storage_key=storage_key,
        upload_status="pending",
    )
    db.add(asset)
    db.commit()
    db.refresh(asset)
    url = r2_storage_service.upload_url(
        storage_key=storage_key, content_type=req.mime_type
    )
    return asset, url


def complete_upload(db: Session, project: Project, media_id: str) -> MediaAsset:
    asset = (
        db.query(MediaAsset)
        .filter(MediaAsset.id == media_id, MediaAsset.project_id == project.id)
        .one_or_none()
    )
    if asset is None:
        raise not_found("Media not found")
    asset.upload_status = "uploaded"
    db.commit()
    db.refresh(asset)

    # Kick off detection. In local/dev this synthesises reviewable DetectedItem
    # rows synchronously (real object detection is still a TODO); otherwise it
    # hands off to the async worker pipeline. Imported here to avoid a circular
    # import at module load time.
    from app.services import detection_service

    detection_service.run_detection(db, project, asset)
    return asset


def list_for_project(db: Session, project: Project) -> list[MediaAsset]:
    return (
        db.query(MediaAsset)
        .filter(MediaAsset.project_id == project.id)
        .order_by(MediaAsset.created_at.desc())
        .all()
    )


def get_owned(db: Session, project: Project, media_id: str) -> MediaAsset:
    asset = (
        db.query(MediaAsset)
        .filter(MediaAsset.id == media_id, MediaAsset.project_id == project.id)
        .one_or_none()
    )
    if asset is None:
        raise not_found("Media not found")
    return asset


def delete(db: Session, asset: MediaAsset) -> None:
    db.delete(asset)
    db.commit()
