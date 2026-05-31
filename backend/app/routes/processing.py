from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.processing import ProcessingStatus
from app.services import processing_service

router = APIRouter(prefix="/projects/{project_id}", tags=["processing"])


@router.get("/processing-status", response_model=ProcessingStatus)
def get_status(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> ProcessingStatus:
    return ProcessingStatus(**processing_service.status(db, project))


@router.post("/retry-processing", response_model=ProcessingStatus)
def retry(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> ProcessingStatus:
    return ProcessingStatus(**processing_service.retry(db, project))
