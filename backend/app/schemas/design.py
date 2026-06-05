from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class DesignOut(ORMModel):
    id: str
    project_id: str
    model_name: str | None
    prompt_version: str | None
    generation_status: str
    is_selected: bool
    error_code: str | None
    error_message: str | None
    created_at: datetime


class DesignWithUrls(DesignOut):
    output_read_url: str | None = None
    reference_read_url: str | None = None
    layout_plan_json: str | None = None
    layout_plan_status: str | None = None
    layout_plan_error: str | None = None


class DesignCustomizeRequest(BaseModel):
    change_type: str
    change_payload_json: str | None = None
    detected_item_id: str | None = None
