from pydantic import BaseModel

from app.schemas.common import ORMModel


class FinalPlanCreate(BaseModel):
    selected_design_id: str
    plan_json: str | None = None


class FinalPlanOut(ORMModel):
    id: str
    project_id: str
    selected_design_id: str | None
    plan_json: str | None
    export_status: str
    export_url: str | None


class FinalPlanExportRequest(BaseModel):
    format: str = "pdf"
