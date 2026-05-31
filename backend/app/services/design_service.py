from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.exceptions import not_found
from app.models.design_item_change import DesignItemChange
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.schemas.design import DesignCustomizeRequest
from app.services import r2_storage_service


def get_owned(db: Session, project: Project, design_id: str) -> GeneratedDesign:
    design = (
        db.query(GeneratedDesign)
        .filter(GeneratedDesign.id == design_id, GeneratedDesign.project_id == project.id)
        .one_or_none()
    )
    if design is None:
        raise not_found("Design not found")
    return design


def with_signed_urls(design: GeneratedDesign) -> dict:
    return {
        "output_read_url": (
            r2_storage_service.read_url(storage_key=design.output_image_key)
            if design.output_image_key
            else None
        ),
        "reference_read_url": (
            r2_storage_service.read_url(storage_key=design.reference_image_key)
            if design.reference_image_key
            else None
        ),
    }


def select(db: Session, project: Project, design_id: str) -> GeneratedDesign:
    target = get_owned(db, project, design_id)
    db.query(GeneratedDesign).filter(GeneratedDesign.project_id == project.id).update(
        {GeneratedDesign.is_selected: False}
    )
    target.is_selected = True
    db.commit()
    db.refresh(target)
    return target


def customize(
    db: Session,
    project: Project,
    design_id: str,
    payload: DesignCustomizeRequest,
) -> DesignItemChange:
    design = get_owned(db, project, design_id)
    change = DesignItemChange(
        design_id=design.id,
        detected_item_id=payload.detected_item_id,
        change_type=payload.change_type,
        change_payload_json=payload.change_payload_json,
    )
    db.add(change)
    db.commit()
    db.refresh(change)
    return change
