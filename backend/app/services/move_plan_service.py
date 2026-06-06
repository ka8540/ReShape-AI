from __future__ import annotations

import json
import math

from pydantic import ValidationError

from app.models.detected_item import DetectedItem
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.schemas.move_plan import (
    MovePlanChecklistItem,
    MovePlanFixedItem,
    MovePlanFloorItem,
    MovePlanMovedItem,
    StructuredMovePlan,
)

FAILED_STATUS = "failed"
SUCCEEDED_STATUS = "succeeded"
PENDING_STATUS = "pending"

# Boxes smaller than this are invisible on a phone; clamp every floor item up to
# a usable minimum and keep it inside the room (x + width <= 100, y + height <= 100).
FLOOR_MIN_WIDTH = 4.0
FLOOR_MIN_HEIGHT = 3.0

# Categories that describe the room shell rather than a movable piece of
# furniture. The client renders these as edges/boundaries, not furniture boxes.
STRUCTURAL_CATEGORIES = {"wall", "window", "door"}


def build_prompt(project: Project, design: GeneratedDesign) -> str:
    items = [
        {
            "id": item.id,
            "name": item.name,
            "category": item.type,
            "fixed": item.fixed,
            "structural": item.structural,
        }
        for item in project.detected_items
    ]
    preferences = {
        "primary_goal": getattr(project.preference_set, "primary_goal", None),
        "style": getattr(project.preference_set, "style", None),
        "constraints_json": getattr(project.preference_set, "constraints_json", None),
    }
    return (
        "You are creating a practical final move plan for a room redesign app.\n"
        "Use the reference room image and selected generated design image.\n"
        "Return ONLY valid JSON, no markdown, with this exact shape:\n"
        "{\n"
        '  "room_summary": "Short description; say approximate if geometry is uncertain.",\n'
        '  "floor_plan": {"width": 100, "height": 100, "items": [\n'
        '    {"item_id": "detected-item-id", "name": "Item name", '
        '"category": "item-type", "x": 0, "y": 0, "width": 10, '
        '"height": 10, "rotation": 0, "status": "moved|fixed|structural|unchanged", '
        '"fixed": false}\n'
        "  ]},\n"
        '  "moved_items": [{"item_id": "detected-item-id", "name": "Item name", '
        '"from": "old area", "to": "new area", "reason": "why"}],\n'
        '  "fixed_items": [{"item_id": "detected-item-id", "name": "Item name", '
        '"reason": "why it stays fixed"}],\n'
        '  "checklist": [{"step": 1, "title": "Action", "details": "Practical detail"}]\n'
        "}\n\n"
        "Hard rules:\n"
        "- Return valid JSON only, no markdown.\n"
        "- Only include items from this detected_items array. Do not invent furniture.\n"
        "- floor_plan.items MUST include EVERY movable detected item, plus any "
        "structural items (window, door, wall) that are present.\n"
        "- Never return a floor plan that contains only a wall. If there is "
        "furniture, the furniture must be in floor_plan.items.\n"
        "- Structural or fixed items must not appear in moved_items and must not "
        "have status=moved. Keep fixed/structural items where they are.\n"
        "- Mark moved furniture with status \"moved\"; mark walls, windows and "
        "doors with status \"structural\".\n"
        "- Coordinates are normalized percentages from 0 to 100, where x and y are "
        "the TOP-LEFT corner of the box.\n"
        "- Give every furniture box a usable size (width >= 4, height >= 3) and keep "
        "x + width <= 100 and y + height <= 100.\n"
        "- Produce an approximate but useful top-down layout: do NOT stack every "
        "item in the center, and keep boxes visually separated.\n"
        "- Place window and door along the room edges (near x=0, x=100, y=0 or "
        "y=100), not in the middle. Represent a wall as the room boundary "
        "(x=0, y=0, width=100, height=100), not a small centered block.\n"
        "- Checklist steps must be specific to the moved items and selected design.\n"
        "- If geometry is approximate, say so in room_summary.\n\n"
        f"project_id: {project.id}\n"
        f"design_id: {design.id}\n"
        f"detected_items: {json.dumps(items)}\n"
        f"preferences: {json.dumps(preferences)}"
    )


def normalize_plan(raw_text: str, items: list[DetectedItem]) -> str:
    """Parse, validate, and normalize Gemini JSON against project items."""
    raw = _decode_json_text(raw_text)
    plan = StructuredMovePlan.model_validate(raw)
    by_id = {item.id: item for item in items}
    by_name = {item.name.strip().lower(): item for item in items}

    normalized_floor_items = [
        _normalize_floor_item(item, by_id, by_name)
        for item in plan.floor_plan.items
    ]
    normalized_moved = [
        _normalize_moved_item(item, by_id, by_name)
        for item in plan.moved_items
    ]
    moved_ids = {m.item_id for m in normalized_moved if m.item_id}
    # Repair: guarantee every movable detected item (especially anything in
    # moved_items) is present in the floor plan, even if the model omitted it or
    # returned a wall-only layout. Missing items get deterministic grid positions.
    normalized_floor_items = _repair_floor_items(
        normalized_floor_items, items, moved_ids
    )
    fixed_reason_by_id = {
        resolved.id: fixed.reason
        for fixed in plan.fixed_items
        if (resolved := _resolve_item(fixed.item_id, fixed.name, by_id, by_name))
    }
    normalized_fixed = [
        MovePlanFixedItem(
            item_id=item.id,
            name=item.name,
            reason=fixed_reason_by_id.get(
                item.id,
                "Structural item" if item.structural else "Marked fixed by the user",
            ),
        )
        for item in items
        if item.fixed or item.structural
    ]
    normalized_checklist = [
        MovePlanChecklistItem(
            step=index + 1,
            title=step.title,
            details=step.details,
        )
        for index, step in enumerate(plan.checklist)
    ]
    normalized = StructuredMovePlan(
        room_summary=plan.room_summary,
        floor_plan=plan.floor_plan.model_copy(update={"items": normalized_floor_items}),
        moved_items=normalized_moved,
        fixed_items=normalized_fixed,
        checklist=normalized_checklist,
    )
    return normalized.model_dump_json(by_alias=True)


def failure_plan_json(message: str) -> str:
    return json.dumps(
        {
            "layout_plan_status": FAILED_STATUS,
            "layout_plan_error": message,
        }
    )


def layout_plan_status(plan_json: str | None) -> str:
    if not plan_json:
        return PENDING_STATUS
    try:
        data = json.loads(plan_json)
    except json.JSONDecodeError:
        return FAILED_STATUS
    if data.get("layout_plan_status") == FAILED_STATUS:
        return FAILED_STATUS
    try:
        StructuredMovePlan.model_validate(data)
    except ValidationError:
        return FAILED_STATUS
    return SUCCEEDED_STATUS


def layout_plan_error(plan_json: str | None) -> str | None:
    if not plan_json:
        return None
    try:
        data = json.loads(plan_json)
    except json.JSONDecodeError:
        return "Structured move plan JSON is invalid."
    if data.get("layout_plan_status") == FAILED_STATUS:
        return str(data.get("layout_plan_error") or "Structured move plan failed.")
    try:
        StructuredMovePlan.model_validate(data)
    except ValidationError as exc:
        return str(exc)
    return None


def _decode_json_text(raw_text: str) -> object:
    text = raw_text.strip()
    if text.startswith("```"):
        text = text.removeprefix("```json").removeprefix("```").strip()
        if text.endswith("```"):
            text = text[:-3].strip()
    return json.loads(text)


def _normalize_floor_item(
    plan_item: MovePlanFloorItem,
    by_id: dict[str, DetectedItem],
    by_name: dict[str, DetectedItem],
) -> MovePlanFloorItem:
    item = _require_item(plan_item.item_id, plan_item.name, by_id, by_name)
    fixed = item.fixed or item.structural
    if fixed and plan_item.status == "moved":
        raise ValueError(f"Fixed item cannot be marked moved: {item.name}")
    status = "structural" if item.structural else "fixed" if item.fixed else plan_item.status
    x, y, width, height = _clamp_box(
        plan_item.x, plan_item.y, plan_item.width, plan_item.height
    )
    return plan_item.model_copy(
        update={
            "item_id": item.id,
            "name": item.name,
            "category": item.type,
            "status": status,
            "fixed": fixed,
            "x": x,
            "y": y,
            "width": width,
            "height": height,
        }
    )


def _clamp_box(
    x: float, y: float, width: float, height: float
) -> tuple[float, float, float, float]:
    """Force a normalized box to a visible size that stays inside the room."""
    width = min(max(width, FLOOR_MIN_WIDTH), 100.0)
    height = min(max(height, FLOOR_MIN_HEIGHT), 100.0)
    x = min(max(x, 0.0), 100.0 - width)
    y = min(max(y, 0.0), 100.0 - height)
    return x, y, width, height


def _repair_floor_items(
    floor_items: list[MovePlanFloorItem],
    items: list[DetectedItem],
    moved_ids: set[str],
) -> list[MovePlanFloorItem]:
    """Append any movable detected item the model left out of the floor plan,
    laying the missing items out on a simple grid so they render usefully.

    This is a deterministic local/dev repair, not invented data: every appended
    box corresponds to a real detected item the project already owns.
    """
    present_ids = {fi.item_id for fi in floor_items if fi.item_id}
    present_names = {fi.name.strip().lower() for fi in floor_items}
    missing = [
        item
        for item in items
        if not (item.fixed or item.structural)
        and item.id not in present_ids
        and item.name.strip().lower() not in present_names
    ]
    if not missing:
        return floor_items

    cols = max(1, math.ceil(math.sqrt(len(missing))))
    rows = max(1, math.ceil(len(missing) / cols))
    margin = 8.0
    cell_w = (100.0 - 2 * margin) / cols
    cell_h = (100.0 - 2 * margin) / rows
    box_w = max(FLOOR_MIN_WIDTH, cell_w * 0.7)
    box_h = max(FLOOR_MIN_HEIGHT, cell_h * 0.7)

    repaired = list(floor_items)
    for index, item in enumerate(missing):
        col = index % cols
        row = index // cols
        center_x = margin + cell_w * (col + 0.5)
        center_y = margin + cell_h * (row + 0.5)
        x, y, width, height = _clamp_box(
            center_x - box_w / 2, center_y - box_h / 2, box_w, box_h
        )
        repaired.append(
            MovePlanFloorItem(
                item_id=item.id,
                name=item.name,
                category=item.type,
                x=x,
                y=y,
                width=width,
                height=height,
                rotation=0,
                status="moved" if item.id in moved_ids else "unchanged",
                fixed=False,
            )
        )
    return repaired


def _normalize_moved_item(
    moved_item: MovePlanMovedItem,
    by_id: dict[str, DetectedItem],
    by_name: dict[str, DetectedItem],
) -> MovePlanMovedItem:
    item = _require_item(moved_item.item_id, moved_item.name, by_id, by_name)
    if item.fixed or item.structural:
        raise ValueError(f"Fixed item cannot be moved: {item.name}")
    return moved_item.model_copy(update={"item_id": item.id, "name": item.name})


def _require_item(
    item_id: str | None,
    name: str,
    by_id: dict[str, DetectedItem],
    by_name: dict[str, DetectedItem],
) -> DetectedItem:
    item = _resolve_item(item_id, name, by_id, by_name)
    if item is None:
        raise ValueError(f"Move plan included an item outside this project: {name}")
    return item


def _resolve_item(
    item_id: str | None,
    name: str,
    by_id: dict[str, DetectedItem],
    by_name: dict[str, DetectedItem],
) -> DetectedItem | None:
    if item_id and item_id in by_id:
        return by_id[item_id]
    return by_name.get(name.strip().lower())
