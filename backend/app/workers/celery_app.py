"""Celery app factory. Workers stay decoupled from FastAPI request flow."""

from __future__ import annotations

import logging

from app.core.config import get_settings

logger = logging.getLogger(__name__)

try:
    from celery import Celery
except ImportError:  # pragma: no cover
    Celery = None  # type: ignore[assignment]


def create_celery():
    if Celery is None:
        logger.warning("celery is not installed; using in-process stub.")
        return None
    settings = get_settings()
    return Celery(
        "respace",
        broker=settings.REDIS_URL,
        backend=settings.REDIS_URL,
        include=[
            "app.workers.video_processing_worker",
            "app.workers.image_processing_worker",
            "app.workers.image_generation_worker",
        ],
    )


celery_app = create_celery()
