from fastapi import APIRouter, Depends

from app.core.auth_dependencies import require_authenticated_user
from app.models.user import User
from app.schemas.auth import AuthHealth, SessionResponse
from app.schemas.common import Status
from app.schemas.user import UserOut
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/session", response_model=SessionResponse)
def create_session(user: User = Depends(require_authenticated_user)) -> SessionResponse:
    return SessionResponse(
        user=UserOut.model_validate(user),
        app_metadata=auth_service.app_metadata(user),
    )


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(require_authenticated_user)) -> UserOut:
    return UserOut.model_validate(user)


@router.post("/logout", response_model=Status)
def logout(_user: User = Depends(require_authenticated_user)) -> Status:
    # Firebase sign-out happens on the client; no server-side revocation here.
    return Status(status="ok")


@router.get("/health", response_model=AuthHealth)
def auth_health() -> AuthHealth:
    return AuthHealth(**auth_service.auth_health())
