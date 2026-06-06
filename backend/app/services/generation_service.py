"""Layout generation orchestration.

Generation can run inline (synchronously in the API process) or via Celery.
The actual work lives in `run_generation_job`, which both the inline path and
the Celery task call, so behaviour is identical regardless of mode.

Nothing here fakes a result: if there's no reference image, the API key is
missing, or Gemini rejects the request, the design is marked `failed` with a
clear error that the client can show.
"""

from __future__ import annotations

import logging
from collections.abc import Callable
from threading import Thread

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import SessionLocal
from app.core.exceptions import bad_request, service_unavailable
from app.models.generated_design import GeneratedDesign
from app.models.media_asset import MediaAsset
from app.models.project import Project
from app.models.user import User
from app.services import move_plan_service, prompt_builder, r2_storage_service
from app.services.ai_image_service import (
    AiImageService,
    ImageGenerationFailure,
    ImageGenerationResult,
)
from app.services.prompt_builder import PROMPT_VERSION
from app.services.rate_limit_service import generation_limiter

logger = logging.getLogger(__name__)


def start_inline_generation_job(design_ids: list[str]) -> None:
    thread = Thread(
        target=run_generation_job,
        args=(list(design_ids),),
        daemon=True,
        name=f"layout-generation-{design_ids[0] if design_ids else 'empty'}",
    )
    thread.start()


def request_generation(
    db: Session,
    *,
    user: User,
    project: Project,
    variants: int,
    reference_media_id: str | None,
    schedule_inline_job: Callable[[list[str]], None] | None = None,
) -> list[GeneratedDesign]:
    settings = get_settings()
    mode = settings.generation_mode

    if mode == "disabled":
        raise service_unavailable(
            "Layout generation is disabled on this server "
            "(GENERATION_EXECUTION_MODE=disabled)."
        )
    if variants < 1 or variants > 6:
        raise bad_request("variants must be between 1 and 6")
    if not generation_limiter.allow(user.id):
        raise bad_request("Generation rate limit exceeded; try again later")

    # Regenerate cleanly: drop the previous batch so taps never pile up an
    # ever-growing list of stale queued/failed rows.
    db.query(GeneratedDesign).filter(
        GeneratedDesign.project_id == project.id
    ).delete()
    db.commit()

    designs = [
        GeneratedDesign(
            project_id=project.id,
            prompt_version=PROMPT_VERSION,
            generation_status="queued",
        )
        for _ in range(variants)
    ]
    db.add_all(designs)
    db.commit()
    for design in designs:
        db.refresh(design)
    design_ids = [d.id for d in designs]

    project.status = "processing"
    db.commit()

    if mode == "celery":
        try:
            from app.workers.image_generation_worker import enqueue_generation_batch

            enqueue_generation_batch(design_ids)
            logger.info("Enqueued generation batch %s via Celery", design_ids)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Celery enqueue failed: %s", exc)
            if settings.APP_ENV == "local" and schedule_inline_job is not None:
                logger.info("Falling back to background inline generation (local).")
                schedule_inline_job(design_ids)
            elif settings.APP_ENV == "local":
                logger.info("Falling back to inline generation (local, blocking caller).")
                run_generation_job(design_ids, db=db)
            else:
                _fail_designs(
                    db,
                    designs,
                    "ENQUEUE_FAILED",
                    "Could not queue the generation job. Try again later.",
                )
    else:  # inline
        if schedule_inline_job is not None:
            logger.info("Scheduling background inline generation for %s", design_ids)
            schedule_inline_job(design_ids)
        else:
            logger.info("Running generation inline for %s", design_ids)
            run_generation_job(design_ids, db=db)

    return list_designs(db, project)


def run_generation_job(design_ids: list[str], db: Session | None = None) -> None:
    """Generate images for the given designs. Shared by the inline path (passes
    the request's session) and the Celery task (opens its own session)."""
    owns_session = db is None
    if db is None:
        db = SessionLocal()
    try:
        designs = (
            db.query(GeneratedDesign)
            .filter(GeneratedDesign.id.in_(design_ids))
            .all()
        )
        if not designs:
            logger.warning("run_generation_job: no designs for %s", design_ids)
            return
        project = db.get(Project, designs[0].project_id)
        settings = get_settings()

        for design in designs:
            design.generation_status = "running"
        db.commit()

        if not settings.GEMINI_API_KEY:
            _fail_designs(db, designs, "MISSING_API_KEY", "GEMINI_API_KEY is missing.")
            return

        reference = _load_reference_image(db, project)
        if reference is None:
            _fail_designs(
                db,
                designs,
                "NO_REFERENCE",
                "No reference room image available for generation.",
            )
            return

        ref_bytes, ref_mime, ref_key = reference
        prompt = _build_prompt(project)
        service = AiImageService(settings)

        for design in designs:
            result = service.generate(
                prompt=prompt,
                prompt_version=PROMPT_VERSION,
                reference_image_bytes=ref_bytes,
                reference_image_mime=ref_mime,
            )
            if isinstance(result, ImageGenerationFailure):
                code, message = _friendly_failure(result)
                design.generation_status = "failed"
                design.error_code = code
                design.error_message = message
                logger.warning(
                    "Generation failed design=%s code=%s msg=%s attempts=%s",
                    design.id,
                    code,
                    message,
                    result.attempts,
                )
                db.commit()
                continue

            assert isinstance(result, ImageGenerationResult)
            storage_key = f"{project.id}/designs/{design.id}.png"
            stored = r2_storage_service.put_object(
                storage_key=storage_key,
                data=result.image_bytes,
                content_type=result.mime_type,
            )
            if not stored:
                design.generation_status = "failed"
                design.error_code = "STORAGE_UNAVAILABLE"
                design.error_message = (
                    "Generated image could not be stored (R2 not configured)."
                )
                logger.error("R2 not configured; cannot store design %s", design.id)
                db.commit()
                continue

            design.output_image_key = storage_key
            design.reference_image_key = ref_key
            design.model_name = result.model_name
            design.prompt_version = result.prompt_version
            design.layout_plan_json = _generate_structured_move_plan(
                service=service,
                project=project,
                design=design,
                reference_image_bytes=ref_bytes,
                reference_image_mime=ref_mime,
                generated_image_bytes=result.image_bytes,
                generated_image_mime=result.mime_type,
            )
            design.generation_status = "succeeded"
            design.error_code = None
            design.error_message = None
            logger.info(
                "Generation succeeded design=%s model=%s",
                design.id,
                result.model_name,
            )
            db.commit()
    finally:
        if owns_session:
            db.close()


def _load_reference_image(db: Session, project: Project) -> tuple[bytes, str, str] | None:
    asset = (
        db.query(MediaAsset)
        .filter(
            MediaAsset.project_id == project.id,
            MediaAsset.media_kind == "image",
            MediaAsset.upload_status == "uploaded",
        )
        .order_by(MediaAsset.created_at.desc())
        .first()
    )
    if asset is None:
        return None
    data = r2_storage_service.get_object(storage_key=asset.storage_key)
    if not data:
        return None
    return data, asset.mime_type or "image/jpeg", asset.storage_key


def _generate_structured_move_plan(
    *,
    service: AiImageService,
    project: Project,
    design: GeneratedDesign,
    reference_image_bytes: bytes,
    reference_image_mime: str,
    generated_image_bytes: bytes,
    generated_image_mime: str,
) -> str:
    prompt = move_plan_service.build_prompt(project, design)
    result = service.generate_structured_move_plan(
        prompt=prompt,
        reference_image_bytes=reference_image_bytes,
        reference_image_mime=reference_image_mime,
        generated_image_bytes=generated_image_bytes,
        generated_image_mime=generated_image_mime,
    )
    if isinstance(result, ImageGenerationFailure):
        _, message = _friendly_failure(result)
        logger.warning("Structured move plan failed design=%s: %s", design.id, message)
        return move_plan_service.failure_plan_json(message)
    try:
        return move_plan_service.normalize_plan(
            result.raw_json,
            list(project.detected_items),
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("Structured move plan JSON invalid design=%s: %s", design.id, exc)
        return move_plan_service.failure_plan_json(
            f"Structured move plan could not be generated: {exc}"
        )


def _build_prompt(project: Project) -> str:
    preference_set = project.preference_set
    style = getattr(preference_set, "style", None) if preference_set else None

    if project.mode == "reshuffle":
        # The strict reshuffle template is self-contained: it carries the
        # same-room / same-viewpoint / no-new-items rules and the per-item
        # fixed/structural breakdown, so no extra constraint block is appended.
        prompt_items = [
            prompt_builder.PromptItem(
                name=item.name,
                fixed=item.fixed,
                structural=item.structural,
            )
            for item in project.detected_items
        ]
        return prompt_builder.build_reshuffle_prompt(
            items=prompt_items,
            style=style,
            primary_goal=getattr(preference_set, "primary_goal", None),
            room_type=getattr(preference_set, "room_type", None),
        )

    names = [item.name for item in project.detected_items]
    fixed = [i.name for i in project.detected_items if i.fixed or i.structural]
    base = prompt_builder.build_redesign_prompt(items=names, style=style)
    fixed_line = (
        f"Keep these fixed/structural items exactly where they are: {', '.join(fixed)}.\n"
        if fixed
        else ""
    )
    constraints = (
        "\n\nIMPORTANT CONSTRAINTS:\n"
        "- This must be the SAME room shown in the provided reference photo.\n"
        "- Keep the walls, windows, doors, flooring and overall structure identical.\n"
        "- Only rearrange the movable furniture the user already owns.\n"
        f"{fixed_line}"
        "- Do not add new furniture unless explicitly requested.\n"
        "- Produce a single photo-realistic image of the reshuffled room from the "
        "same camera viewpoint as the reference photo."
    )
    return base + constraints


def _friendly_failure(result: ImageGenerationFailure) -> tuple[str, str]:
    code = result.error_code or "GENERATION_FAILED"
    blob = " ".join(
        [result.error_message or ""] + [f"{m}:{e}" for m, e in result.attempts]
    ).lower()
    if (
        code in ("UNAUTHENTICATED", "PERMISSION_DENIED")
        or "unauthenticated" in blob
        or "api key not valid" in blob
        or "api_key_invalid" in blob
        or "permission" in blob
        or " 401" in blob
        or " 403" in blob
    ):
        return (
            "GEMINI_AUTH_FAILED",
            "Gemini authentication failed. Use a valid Google AI Studio API key.",
        )
    if (
        code in ("NOT_FOUND", "ALL_MODELS_FAILED")
        or "not found" in blob
        or "not_found" in blob
        or " 404" in blob
    ):
        return (
            "GEMINI_MODEL_NOT_FOUND",
            "Configured Gemini image model was not found or is not enabled for this key.",
        )
    if (
        code == "RESOURCE_EXHAUSTED"
        or " 429" in blob
        or "resource_exhausted" in blob
        or "quota" in blob
    ):
        return (
            "GEMINI_QUOTA_EXCEEDED",
            "Gemini quota exceeded for this API key. Check your Google AI "
            "Studio plan/billing or try again later.",
        )
    if code == "SDK_UNAVAILABLE":
        return (
            "GEMINI_SDK_UNAVAILABLE",
            "Gemini SDK (google-genai) is not installed on the server.",
        )
    return code, result.error_message or "Image generation failed."


def _fail_designs(
    db: Session, designs: list[GeneratedDesign], code: str, message: str
) -> None:
    for design in designs:
        design.generation_status = "failed"
        design.error_code = code
        design.error_message = message
    db.commit()
    logger.warning("Marked %d designs failed: %s — %s", len(designs), code, message)


def list_designs(db: Session, project: Project) -> list[GeneratedDesign]:
    return (
        db.query(GeneratedDesign)
        .filter(GeneratedDesign.project_id == project.id)
        .order_by(GeneratedDesign.created_at.desc())
        .all()
    )


def status(db: Session, project: Project) -> dict:
    designs = list_designs(db, project)
    total = len(designs)
    counts = {"queued": 0, "running": 0, "succeeded": 0, "failed": 0}
    for d in designs:
        counts[d.generation_status] = counts.get(d.generation_status, 0) + 1
    pending = counts["queued"] + counts["running"] + counts.get("pending", 0)

    if total == 0:
        normalized = "queued"
    elif pending > 0:
        normalized = "running"
    elif counts["succeeded"] > 0:
        normalized = "completed"
    elif counts["failed"] > 0:
        normalized = "failed"
    else:
        normalized = project.status

    failed = [d for d in designs if d.generation_status == "failed"]
    return {
        "project_id": project.id,
        "status": normalized,
        "designs_ready": counts["succeeded"],
        "designs_requested": total,
        "total": total,
        "queued": counts["queued"],
        "running": counts["running"],
        "succeeded": counts["succeeded"],
        "failed": counts["failed"],
        "error_code": failed[-1].error_code if failed else None,
        "error_message": failed[-1].error_message if failed else None,
    }
