"""Image generation worker.

The real work lives in `generation_service.run_generation_job`. This module only
bridges Celery to it: `enqueue_generation_batch` dispatches the task (production),
and the task body calls the same shared function the inline path uses.
"""

from __future__ import annotations

import logging

from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


def enqueue_generation_batch(design_ids: list[str]) -> None:
    """Dispatch a generation batch to Celery.

    Raises if Celery is unavailable so the caller (generation_service) can fall
    back to inline execution in local/dev.
    """
    if celery_app is None:
        raise RuntimeError("Celery is not available")
    run_generation_task.delay(design_ids)


if celery_app is not None:  # pragma: no cover - requires celery

    @celery_app.task(name="workers.run_generation")
    def run_generation_task(design_ids: list[str]) -> None:
        from app.services.generation_service import run_generation_job

        run_generation_job(design_ids)
