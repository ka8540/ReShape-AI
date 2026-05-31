from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.exceptions import not_found
from app.models.detected_item import DetectedItem
from app.models.project import Project
from app.schemas.item import DetectedItemCreate, DetectedItemUpdate


def list_for_project(db: Session, project: Project) -> list[DetectedItem]:
    return (
        db.query(DetectedItem)
        .filter(DetectedItem.project_id == project.id)
        .order_by(DetectedItem.created_at.asc())
        .all()
    )


def create(db: Session, project: Project, payload: DetectedItemCreate) -> DetectedItem:
    item = DetectedItem(
        project_id=project.id,
        name=payload.name,
        type=payload.type,
        fixed=payload.fixed,
        structural=payload.structural,
        added_by_user=True,
        confidence=1.0,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def _get_owned(db: Session, project: Project, item_id: str) -> DetectedItem:
    item = (
        db.query(DetectedItem)
        .filter(DetectedItem.id == item_id, DetectedItem.project_id == project.id)
        .one_or_none()
    )
    if item is None:
        raise not_found("Item not found")
    return item


def update(
    db: Session, project: Project, item_id: str, payload: DetectedItemUpdate
) -> DetectedItem:
    item = _get_owned(db, project, item_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return item


def delete(db: Session, project: Project, item_id: str) -> None:
    item = _get_owned(db, project, item_id)
    db.delete(item)
    db.commit()
