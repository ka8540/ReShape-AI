from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import require_authenticated_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.common import Status
from app.schemas.user import ProjectsSummary, UserOut, UserUpdate
from app.services import user_service

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserOut)
def get_me(user: User = Depends(require_authenticated_user)) -> UserOut:
    return UserOut.model_validate(user)


@router.patch("/me", response_model=UserOut)
def update_me(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_authenticated_user),
) -> UserOut:
    updated = user_service.update_profile(db, user, payload.display_name)
    return UserOut.model_validate(updated)


@router.delete("/me", status_code=status.HTTP_200_OK, response_model=Status)
def delete_me(
    db: Session = Depends(get_db),
    user: User = Depends(require_authenticated_user),
) -> Status:
    user_service.soft_delete(db, user)
    return Status(status="deleted")


@router.get("/me/projects-summary", response_model=ProjectsSummary)
def projects_summary(
    db: Session = Depends(get_db),
    user: User = Depends(require_authenticated_user),
) -> ProjectsSummary:
    return ProjectsSummary(**user_service.projects_summary(db, user))
