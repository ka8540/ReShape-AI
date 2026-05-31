from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.exceptions import bad_request
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.models.user import User
from app.services import prompt_builder
from app.services.rate_limit_service import generation_limiter


def request_generation(
    db: Session,
    *,
    user: User,
    project: Project,
    variants: int,
    reference_media_id: str | None,
) -> list[GeneratedDesign]:
    if variants < 1 or variants > 6:
        raise bad_request("variants must be between 1 and 6")

    if not generation_limiter.allow(user.id):
        raise bad_request("Generation rate limit exceeded; try again later")

    # Build prompt server-side so Flutter never sees it.
    items = [item.name for item in project.detected_items]
    style = getattr(project.preference_set, "style", None) if project.preference_set else None
    prompt = (
        prompt_builder.build_reshuffle_prompt(items=items, style=style)
        if project.mode == "reshuffle"
        else prompt_builder.build_redesign_prompt(items=items, style=style)
    )
    designs: list[GeneratedDesign] = []
    for _ in range(variants):
        design = GeneratedDesign(
            project_id=project.id,
            prompt_version=prompt_builder.PROMPT_VERSION,
            generation_status="queued",
            reference_image_key=None,
        )
        db.add(design)
        designs.append(design)
    db.commit()
    for design in designs:
        db.refresh(design)

    from app.workers.image_generation_worker import enqueue_generation

    for design in designs:
        enqueue_generation(
            design_id=design.id,
            prompt=prompt,
            reference_media_id=reference_media_id,
        )
    project.status = "processing"
    db.commit()
    return designs


def list_designs(db: Session, project: Project) -> list[GeneratedDesign]:
    return (
        db.query(GeneratedDesign)
        .filter(GeneratedDesign.project_id == project.id)
        .order_by(GeneratedDesign.created_at.desc())
        .all()
    )


def status(db: Session, project: Project) -> dict:
    designs = list_designs(db, project)
    ready = sum(1 for d in designs if d.generation_status == "succeeded")
    failed = [d for d in designs if d.generation_status == "failed"]
    return {
        "project_id": project.id,
        "status": "succeeded" if designs and ready == len(designs) else project.status,
        "designs_ready": ready,
        "designs_requested": len(designs),
        "error_code": failed[0].error_code if failed else None,
        "error_message": failed[0].error_message if failed else None,
    }
