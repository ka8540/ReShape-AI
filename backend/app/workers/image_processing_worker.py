"""Image → detection worker (stub). Skips video frame extraction."""

from __future__ import annotations

import logging

from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


def enqueue_image_analysis(media_asset_id: str) -> None:
    if celery_app is None:
        logger.info("[stub] image analysis for media_asset=%s", media_asset_id)
        return
    analyse_image.delay(media_asset_id)


if celery_app is not None:  # pragma: no cover - requires celery

    @celery_app.task(name="workers.analyse_image")
    def analyse_image(media_asset_id: str) -> None:
        logger.info("Analysing image for media_asset=%s", media_asset_id)
        # TODO: object detection / scene parsing → DetectedItem rows.
