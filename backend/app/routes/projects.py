from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import require_authenticated_user, verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.models.user import User
from app.schemas.common import Status
from app.schemas.project import ProjectCreate, ProjectOut, ProjectUpdate
from app.services import project_service

router = APIRouter(prefix="/projects", tags=["projects"])


@router.post("", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
def create_project(
    payload: ProjectCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_authenticated_user),
) -> ProjectOut:
    project = project_service.create(db, user, payload)
    return ProjectOut.model_validate(project)


@router.get("", response_model=list[ProjectOut])
def list_projects(
    db: Session = Depends(get_db),
    user: User = Depends(require_authenticated_user),
) -> list[ProjectOut]:
    return [ProjectOut.model_validate(p) for p in project_service.list_for_user(db, user)]


@router.get("/{project_id}", response_model=ProjectOut)
def get_project(project: Project = Depends(verify_project_owner)) -> ProjectOut:
    return ProjectOut.model_validate(project)


@router.patch("/{project_id}", response_model=ProjectOut)
def update_project(
    payload: ProjectUpdate,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> ProjectOut:
    updated = project_service.update(db, project, payload)
    return ProjectOut.model_validate(updated)


@router.delete("/{project_id}", response_model=Status)
def delete_project(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> Status:
    project_service.delete(db, project)
    return Status(status="deleted")
