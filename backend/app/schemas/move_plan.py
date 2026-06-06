from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


PlanItemStatus = Literal["moved", "fixed", "structural", "unchanged"]


class MovePlanFloorItem(BaseModel):
    item_id: str | None = None
    name: str
    category: str
    x: float = Field(..., ge=0, le=100)
    y: float = Field(..., ge=0, le=100)
    # Accept 0 here; the service clamps to a visually usable minimum so a weak
    # model response never produces an invisible (zero-area) box.
    width: float = Field(..., ge=0, le=100)
    height: float = Field(..., ge=0, le=100)
    rotation: float = 0
    status: PlanItemStatus = "unchanged"
    fixed: bool = False


class MovePlanFloorPlan(BaseModel):
    width: float = Field(100, gt=0, le=100)
    height: float = Field(100, gt=0, le=100)
    items: list[MovePlanFloorItem] = Field(default_factory=list)


class MovePlanMovedItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    item_id: str | None = None
    name: str
    from_: str = Field(..., alias="from")
    to: str
    reason: str


class MovePlanFixedItem(BaseModel):
    item_id: str | None = None
    name: str
    reason: str


class MovePlanChecklistItem(BaseModel):
    step: int = Field(..., ge=1)
    title: str
    details: str


class StructuredMovePlan(BaseModel):
    room_summary: str
    floor_plan: MovePlanFloorPlan
    moved_items: list[MovePlanMovedItem] = Field(default_factory=list)
    fixed_items: list[MovePlanFixedItem] = Field(default_factory=list)
    checklist: list[MovePlanChecklistItem] = Field(default_factory=list)
