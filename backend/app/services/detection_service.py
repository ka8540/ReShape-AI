"""Item detection orchestration for an uploaded media asset.

Real object detection / scene parsing is NOT implemented yet. Until it lands,
local/dev environments use a synthetic fallback detector so the review flow is
usable end-to-end. The fallback is gated by ``Settings.mock_detection_enabled``
and every run is logged so it is never mistaken for real detection.
"""

from __future__ import annotations

import logging

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.detected_item import DetectedItem
from app.models.media_asset import MediaAsset
from app.models.project import Project
from app.services import item_service
from app.workers.image_processing_worker import enqueue_image_analysis
from app.workers.video_processing_worker import enqueue_frame_extraction

logger = logging.getLogger(__name__)

# Project status the UI waits for before it fetches items for review.
STATUS_AWAITING_REVIEW = "awaiting_user_review"
STATUS_PROCESSING = "processing"

# (name, type, confidence, fixed, structural)
# Types intentionally match the Flutter `itemIcons` keys so each item renders
# with the right glyph. Structural pieces are marked fixed so layouts never
# move them.
_FALLBACK_LIVING_ROOM: list[tuple[str, str, float, bool, bool]] = [
    ("Sofa", "sofa", 0.94, False, False),
    ("Coffee table", "table", 0.88, False, False),
    ("TV stand", "tv", 0.83, False, False),
    ("Armchair", "chair", 0.79, False, False),
    ("Rug", "rug", 0.72, False, False),
    ("Floor lamp", "lamp", 0.61, False, False),
    ("Window", "window", 0.90, True, True),
    ("Door", "door", 0.92, True, True),
    ("Wall", "wall", 0.95, True, True),
]


def run_detection(db: Session, project: Project, asset: MediaAsset) -> None:
    """Entry point called from media_service.complete_upload.

    Either synthesises fallback items (local/dev) or hands off to the async
    worker pipeline (which is still a stub — real detection is a TODO).
    """
    settings = get_settings()

    if settings.mock_detection_enabled:
        existing = item_service.list_for_project(db, project)
        if existing:
            logger.info(
                "[detection] FALLBACK skipped: project=%s already has %d items",
                project.id,
                len(existing),
            )
        else:
            created = _create_fallback_items(db, project)
            logger.info(
                "[detection] FALLBACK mock detection ran (USE_MOCK_DETECTION=%s, "
                "APP_ENV=%s): created %d synthetic items for project=%s media=%s "
                "kind=%s — NOT real AI detection",
                settings.USE_MOCK_DETECTION,
                settings.APP_ENV,
                len(created),
                project.id,
                asset.id,
                asset.media_kind,
            )
        project.status = STATUS_AWAITING_REVIEW
        db.commit()
        return

    # Real path: hand off to the async workers. These are still stubs that do
    # not yet produce DetectedItem rows, so be explicit about it in the logs.
    logger.info(
        "[detection] REAL detection path for project=%s media=%s kind=%s "
        "(mock disabled) — dispatching async worker; detection not yet "
        "implemented, so no items will appear until it is",
        project.id,
        asset.id,
        asset.media_kind,
    )
    project.status = STATUS_PROCESSING
    db.commit()
    if asset.media_kind == "video":
        enqueue_frame_extraction(asset.id)
    else:
        enqueue_image_analysis(asset.id)


def _create_fallback_items(db: Session, project: Project) -> list[DetectedItem]:
    rows: list[DetectedItem] = []
    for name, type_, confidence, fixed, structural in _FALLBACK_LIVING_ROOM:
        item = DetectedItem(
            project_id=project.id,
            name=name,
            type=type_,
            confidence=confidence,
            fixed=fixed,
            structural=structural,
            added_by_user=False,
        )
        db.add(item)
        rows.append(item)
    db.flush()
    return rows
