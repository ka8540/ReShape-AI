from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.feedback import FeedbackCreate, FeedbackOut
from app.services import feedback_service

router = APIRouter(prefix="/projects/{project_id}", tags=["feedback"])


@router.post(
    "/designs/{design_id}/feedback",
    response_model=FeedbackOut,
    status_code=status.HTTP_201_CREATED,
)
def submit_feedback(
    design_id: str,
    payload: FeedbackCreate,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> FeedbackOut:
    return FeedbackOut.model_validate(
        feedback_service.create(db, project, design_id, payload)
    )


@router.get("/feedback", response_model=list[FeedbackOut])
def list_feedback(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> list[FeedbackOut]:
    return [FeedbackOut.model_validate(f) for f in feedback_service.list_for_project(db, project)]
