"""Image generation worker: calls Gemini through AiImageService and writes
output to R2.
"""

from __future__ import annotations

import logging

from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


def enqueue_generation(
    *, design_id: str, prompt: str, reference_media_id: str | None
) -> None:
    if celery_app is None:
        logger.info(
            "[stub] generation queued design=%s reference=%s",
            design_id,
            reference_media_id,
        )
        return
    run_generation.delay(design_id, prompt, reference_media_id)


if celery_app is not None:  # pragma: no cover - requires celery

    @celery_app.task(name="workers.run_generation")
    def run_generation(
        design_id: str, prompt: str, reference_media_id: str | None
    ) -> None:
        from app.core.database import SessionLocal
        from app.models.generated_design import GeneratedDesign
        from app.services import r2_storage_service
        from app.services.ai_image_service import (
            AiImageService,
            ImageGenerationFailure,
            ImageGenerationResult,
        )
        from app.services.prompt_builder import PROMPT_VERSION

        db = SessionLocal()
        try:
            design = db.get(GeneratedDesign, design_id)
            if design is None:
                logger.error("design %s missing", design_id)
                return
            result = AiImageService().generate(
                prompt=prompt, prompt_version=PROMPT_VERSION
            )
            if isinstance(result, ImageGenerationFailure):
                design.generation_status = "failed"
                design.error_code = result.error_code
                design.error_message = result.error_message
                db.commit()
                return
            assert isinstance(result, ImageGenerationResult)
            storage_key = f"{design.project_id}/designs/{design.id}.png"
            r2_storage_service.put_object(
                storage_key=storage_key,
                data=result.image_bytes,
                content_type=result.mime_type,
            )
            design.output_image_key = storage_key
            design.model_name = result.model_name
            design.prompt_version = result.prompt_version
            design.generation_status = "succeeded"
            db.commit()
        finally:
            db.close()
