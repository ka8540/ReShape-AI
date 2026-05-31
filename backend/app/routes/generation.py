from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import require_authenticated_user, verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.models.user import User
from app.schemas.generation import GenerateLayoutsRequest, GenerationStatus
from app.services import generation_service

router = APIRouter(prefix="/projects/{project_id}", tags=["generation"])


@router.post(
    "/generate-layouts",
    response_model=GenerationStatus,
    status_code=status.HTTP_202_ACCEPTED,
)
def generate_layouts(
    payload: GenerateLayoutsRequest,
    project: Project = Depends(verify_project_owner),
    user: User = Depends(require_authenticated_user),
    db: Session = Depends(get_db),
) -> GenerationStatus:
    generation_service.request_generation(
        db,
        user=user,
        project=project,
        variants=payload.variants,
        reference_media_id=payload.reference_media_id,
    )
    return GenerationStatus(**generation_service.status(db, project))


@router.get("/generation-status", response_model=GenerationStatus)
def generation_status(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> GenerationStatus:
    return GenerationStatus(**generation_service.status(db, project))
