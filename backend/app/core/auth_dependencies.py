"""Reusable auth/authorization dependencies.

`get_current_user` verifies the Firebase ID token in the Authorization header,
syncs/creates a local user row, and returns the local User. Tests override
`get_firebase_verifier` to bypass real token verification.

`verify_project_owner` resolves a project by id and ensures it belongs to the
current user. Returns 404 (not 403) on cross-user access so we never leak
existence of other users' projects.
"""

from __future__ import annotations

from fastapi import Depends, Path, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import not_found, unauthorized
from app.core.firebase import get_firebase_verifier
from app.core.security import extract_bearer_token
from app.models.project import Project
from app.models.user import User
from app.services.user_service import upsert_user_from_firebase


def get_current_user(
    request: Request,
    db: Session = Depends(get_db),
    verifier=Depends(get_firebase_verifier),
) -> User:
    token = extract_bearer_token(request)
    try:
        decoded = verifier(token)
    except ValueError as exc:
        raise unauthorized(f"Invalid Firebase token: {exc}")
    if not decoded.get("uid") and not decoded.get("sub"):
        raise unauthorized("Token missing uid")
    return upsert_user_from_firebase(db, decoded)


def require_authenticated_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_active:
        raise unauthorized("User account is inactive")
    return current_user


def require_admin_user(
    current_user: User = Depends(require_authenticated_user),
) -> User:
    if current_user.role != "admin":
        raise not_found()
    return current_user


def verify_project_owner(
    project_id: str = Path(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_authenticated_user),
) -> Project:
    project = db.query(Project).filter(Project.id == project_id).one_or_none()
    if project is None or project.user_id != current_user.id:
        # Do not leak existence of other users' projects.
        raise not_found("Project not found")
    return project
