from __future__ import annotations

import json

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
        "- Only include items from this detected_items array. Do not invent furniture.\n"
        "- Structural or fixed items must not appear in moved_items and must not have status=moved.\n"
        "- Coordinates are normalized percentages from 0 to 100.\n"
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
    return plan_item.model_copy(
        update={
            "item_id": item.id,
            "name": item.name,
            "category": item.type,
            "status": status,
            "fixed": fixed,
        }
    )


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
