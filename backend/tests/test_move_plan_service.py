"""Unit tests for structured move-plan normalization, clamping and repair.

These exercise `move_plan_service` directly with lightweight detected-item
stand-ins (duck-typed; no DB needed) so the floor-plan guarantees are pinned
down independently of Gemini.
"""

from __future__ import annotations

import json
from types import SimpleNamespace

import pytest

from app.services import move_plan_service


def _item(id_, name, type_, *, fixed=False, structural=False):
    return SimpleNamespace(
        id=id_,
        name=name,
        type=type_,
        fixed=fixed,
        structural=structural,
    )


def _floor_item(name, item_id, category, x, y, w, h, status="moved", fixed=False):
    return {
        "item_id": item_id,
        "name": name,
        "category": category,
        "x": x,
        "y": y,
        "width": w,
        "height": h,
        "rotation": 0,
        "status": status,
        "fixed": fixed,
    }


def _raw_plan(floor_items, *, moved=None, fixed=None):
    return json.dumps(
        {
            "room_summary": "Approximate layout.",
            "floor_plan": {"width": 100, "height": 100, "items": floor_items},
            "moved_items": moved or [],
            "fixed_items": fixed or [],
            "checklist": [{"step": 1, "title": "Do it", "details": "Details."}],
        }
    )


def test_floor_items_are_clamped_to_visible_in_bounds_coordinates():
    items = [_item("i1", "Sofa", "sofa")]
    raw = _raw_plan(
        [_floor_item("Sofa", "i1", "sofa", x=80, y=90, w=100, h=100)]
    )

    plan = json.loads(move_plan_service.normalize_plan(raw, items))
    sofa = plan["floor_plan"]["items"][0]

    assert sofa["width"] >= move_plan_service.FLOOR_MIN_WIDTH
    assert sofa["height"] >= move_plan_service.FLOOR_MIN_HEIGHT
    assert sofa["x"] + sofa["width"] <= 100.0
    assert sofa["y"] + sofa["height"] <= 100.0


def test_tiny_or_zero_boxes_are_grown_to_minimum():
    items = [_item("i1", "Floor lamp", "lamp")]
    raw = _raw_plan([_floor_item("Floor lamp", "i1", "lamp", x=10, y=10, w=0, h=0)])

    plan = json.loads(move_plan_service.normalize_plan(raw, items))
    lamp = plan["floor_plan"]["items"][0]

    assert lamp["width"] >= move_plan_service.FLOOR_MIN_WIDTH
    assert lamp["height"] >= move_plan_service.FLOOR_MIN_HEIGHT


def test_wall_only_response_is_repaired_from_detected_furniture():
    items = [
        _item("sofa", "Sofa", "sofa"),
        _item("rug", "Rug", "rug"),
        _item("wall", "Wall", "wall", structural=True),
    ]
    # Model returned only the wall, omitting all furniture.
    raw = _raw_plan(
        [_floor_item("Wall", "wall", "wall", 0, 0, 100, 100, status="structural", fixed=True)]
    )

    plan = json.loads(move_plan_service.normalize_plan(raw, items))
    names = {fi["name"] for fi in plan["floor_plan"]["items"]}

    assert {"Sofa", "Rug"}.issubset(names)
    # Repaired boxes are real items, laid out apart (not all stacked in the centre).
    furniture = [
        fi for fi in plan["floor_plan"]["items"] if fi["name"] in {"Sofa", "Rug"}
    ]
    assert len({(fi["x"], fi["y"]) for fi in furniture}) == len(furniture)
    for fi in furniture:
        assert fi["x"] + fi["width"] <= 100.0
        assert fi["y"] + fi["height"] <= 100.0


def test_moved_items_also_appear_in_floor_plan():
    items = [_item("sofa", "Sofa", "sofa")]
    raw = _raw_plan(
        # Floor plan omits the sofa, but moved_items references it.
        [],
        moved=[
            {
                "item_id": "sofa",
                "name": "Sofa",
                "from": "left",
                "to": "centre",
                "reason": "flow",
            }
        ],
    )

    plan = json.loads(move_plan_service.normalize_plan(raw, items))
    moved_names = {m["name"] for m in plan["moved_items"]}
    floor_names = {fi["name"] for fi in plan["floor_plan"]["items"]}

    assert "Sofa" in moved_names
    assert moved_names.issubset(floor_names)


def test_structural_item_cannot_be_marked_moved():
    items = [_item("win", "Window", "window", structural=True)]
    raw = _raw_plan(
        [_floor_item("Window", "win", "window", 10, 0, 60, 8, status="moved")]
    )

    with pytest.raises(Exception):
        move_plan_service.normalize_plan(raw, items)


def test_structural_items_keep_structural_status_not_moved():
    items = [
        _item("sofa", "Sofa", "sofa"),
        _item("win", "Window", "window", structural=True),
    ]
    raw = _raw_plan(
        [
            _floor_item("Sofa", "sofa", "sofa", 20, 60, 40, 20, status="moved"),
            _floor_item("Window", "win", "window", 10, 0, 60, 8, status="structural", fixed=True),
        ]
    )

    plan = json.loads(move_plan_service.normalize_plan(raw, items))
    by_name = {fi["name"]: fi for fi in plan["floor_plan"]["items"]}

    assert by_name["Window"]["status"] == "structural"
    assert by_name["Window"]["fixed"] is True
    assert by_name["Sofa"]["status"] == "moved"


def test_normalized_plan_exposes_full_structure():
    items = [_item("sofa", "Sofa", "sofa")]
    raw = _raw_plan(
        [_floor_item("Sofa", "sofa", "sofa", 20, 60, 40, 20)],
        moved=[
            {
                "item_id": "sofa",
                "name": "Sofa",
                "from": "left",
                "to": "centre",
                "reason": "flow",
            }
        ],
    )

    plan = json.loads(move_plan_service.normalize_plan(raw, items))

    assert set(plan).issuperset(
        {"room_summary", "floor_plan", "moved_items", "fixed_items", "checklist"}
    )
    assert "items" in plan["floor_plan"]
    assert move_plan_service.layout_plan_status(json.dumps(plan)) == "succeeded"
