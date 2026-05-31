from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy.orm import Session

from app.models.detected_item import DetectedItem  # noqa: F401 (used elsewhere)
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.models.user import User


def _provider_from_firebase(decoded: dict[str, Any]) -> str | None:
    fb = decoded.get("firebase") or {}
    return fb.get("sign_in_provider") or decoded.get("provider")


def upsert_user_from_firebase(db: Session, decoded: dict[str, Any]) -> User:
    uid = decoded.get("uid") or decoded.get("sub")
    if not uid:
        raise ValueError("Token missing uid/sub")

    user = db.query(User).filter(User.firebase_uid == uid).one_or_none()
    now = datetime.now(timezone.utc)

    if user is None:
        user = User(
            firebase_uid=uid,
            email=decoded.get("email"),
            display_name=decoded.get("name"),
            photo_url=decoded.get("picture"),
            provider=_provider_from_firebase(decoded),
            role="user",
            is_active=True,
            last_login_at=now,
        )
        db.add(user)
    else:
        # Keep profile fields fresh; never accept role here.
        if decoded.get("email") and user.email != decoded["email"]:
            user.email = decoded["email"]
        if decoded.get("name"):
            user.display_name = decoded["name"]
        if decoded.get("picture"):
            user.photo_url = decoded["picture"]
        provider = _provider_from_firebase(decoded)
        if provider:
            user.provider = provider
        user.last_login_at = now

    db.commit()
    db.refresh(user)
    return user


def update_profile(db: Session, user: User, display_name: str | None) -> User:
    if display_name is not None:
        user.display_name = display_name
    db.commit()
    db.refresh(user)
    return user


def soft_delete(db: Session, user: User) -> None:
    user.is_active = False
    db.commit()


def projects_summary(db: Session, user: User) -> dict[str, int]:
    base = db.query(Project).filter(Project.user_id == user.id)
    total = base.count()
    processing = base.filter(Project.status == "processing").count()
    completed = base.filter(Project.status == "completed").count()
    failed = base.filter(Project.status == "failed").count()
    designs = (
        db.query(GeneratedDesign)
        .join(Project, Project.id == GeneratedDesign.project_id)
        .filter(Project.user_id == user.id)
        .count()
    )
    return {
        "total_projects": total,
        "processing_projects": processing,
        "completed_projects": completed,
        "failed_projects": failed,
        "generated_design_count": designs,
    }
