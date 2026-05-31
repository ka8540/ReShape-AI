"""Auth-specific orchestration: session creation, health, etc."""

from __future__ import annotations

import os

from app.core.config import get_settings


def auth_health() -> dict[str, bool]:
    settings = get_settings()
    return {
        "firebase_configured": bool(
            settings.FIREBASE_PROJECT_ID
            and settings.FIREBASE_CREDENTIALS_PATH
            and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH)
        ),
        "project_id_present": bool(settings.FIREBASE_PROJECT_ID),
    }


def app_metadata(user) -> dict:
    return {"role": user.role, "is_active": user.is_active}
