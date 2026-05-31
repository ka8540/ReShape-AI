"""Video → frame extraction worker (stub)."""

from __future__ import annotations

import logging

from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


def enqueue_frame_extraction(media_asset_id: str) -> None:
    if celery_app is None:
        logger.info("[stub] frame extraction for media_asset=%s", media_asset_id)
        return
    extract_frames.delay(media_asset_id)


if celery_app is not None:  # pragma: no cover - requires celery

    @celery_app.task(name="workers.extract_frames")
    def extract_frames(media_asset_id: str) -> None:
        logger.info("Extracting frames for media_asset=%s", media_asset_id)
        # TODO: ffmpeg-python frame extraction → store frames in R2 → write
        # ExtractedFrame rows.
