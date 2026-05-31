from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.feedback import Feedback
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.schemas.feedback import FeedbackCreate
from app.services.design_service import get_owned as get_owned_design


def create(
    db: Session, project: Project, design_id: str, payload: FeedbackCreate
) -> Feedback:
    design = get_owned_design(db, project, design_id)
    entry = Feedback(
        design_id=design.id,
        rating=payload.rating,
        sentiment=payload.sentiment,
        comment=payload.comment,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def list_for_project(db: Session, project: Project) -> list[Feedback]:
    return (
        db.query(Feedback)
        .join(GeneratedDesign, GeneratedDesign.id == Feedback.design_id)
        .filter(GeneratedDesign.project_id == project.id)
        .order_by(Feedback.created_at.desc())
        .all()
    )
