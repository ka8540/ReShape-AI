from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.common import Status
from app.schemas.item import DetectedItemCreate, DetectedItemOut, DetectedItemUpdate
from app.services import item_service

router = APIRouter(prefix="/projects/{project_id}/items", tags=["items"])


@router.get("", response_model=list[DetectedItemOut])
def list_items(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> list[DetectedItemOut]:
    return [DetectedItemOut.model_validate(i) for i in item_service.list_for_project(db, project)]


@router.post("", response_model=DetectedItemOut, status_code=status.HTTP_201_CREATED)
def add_item(
    payload: DetectedItemCreate,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> DetectedItemOut:
    return DetectedItemOut.model_validate(item_service.create(db, project, payload))


@router.patch("/{item_id}", response_model=DetectedItemOut)
def patch_item(
    item_id: str,
    payload: DetectedItemUpdate,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> DetectedItemOut:
    return DetectedItemOut.model_validate(
        item_service.update(db, project, item_id, payload)
    )


@router.delete("/{item_id}", response_model=Status)
def delete_item(
    item_id: str,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> Status:
    item_service.delete(db, project, item_id)
    return Status(status="deleted")
