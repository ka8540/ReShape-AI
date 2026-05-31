"""Firebase Admin SDK init + ID token verification.

Designed to be mockable: tests override `verify_id_token` via dependency
override on `get_firebase_verifier` rather than touching firebase_admin.
"""

from __future__ import annotations

import logging
import os
from typing import Any

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_initialized = False


def _ensure_initialized() -> None:
    global _initialized
    if _initialized:
        return
    settings = get_settings()
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:  # pragma: no cover - dev environments without firebase_admin
        logger.warning("firebase_admin is not installed; token verification disabled.")
        _initialized = True
        return

    if firebase_admin._apps:  # already initialised by host
        _initialized = True
        return

    cred_path = settings.FIREBASE_CREDENTIALS_PATH
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred, {"projectId": settings.FIREBASE_PROJECT_ID})
    else:
        logger.warning(
            "Firebase credentials not found at %s; initializing in app-default mode.",
            cred_path,
        )
        firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})
    _initialized = True


def verify_id_token(token: str) -> dict[str, Any]:
    """Verify a Firebase ID token. Raises ValueError on invalid token."""
    _ensure_initialized()
    try:
        from firebase_admin import auth as fb_auth
    except ImportError as exc:  # pragma: no cover
        raise RuntimeError("firebase_admin not installed") from exc

    try:
        return fb_auth.verify_id_token(token)
    except Exception as exc:  # firebase_admin raises various subclasses
        raise ValueError(str(exc)) from exc


def get_firebase_verifier():
    """FastAPI dependency hook so tests can override token verification."""
    return verify_id_token
