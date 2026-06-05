from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.exceptions import bad_request, not_found
from app.models.final_plan import FinalPlan
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.schemas.final_plan import FinalPlanCreate, FinalPlanOut
from app.services import move_plan_service, r2_storage_service


def get(db: Session, project: Project) -> FinalPlan | None:
    return db.query(FinalPlan).filter(FinalPlan.project_id == project.id).one_or_none()


def create_or_update(
    db: Session, project: Project, payload: FinalPlanCreate
) -> FinalPlan:
    design = (
        db.query(GeneratedDesign)
        .filter(
            GeneratedDesign.id == payload.selected_design_id,
            GeneratedDesign.project_id == project.id,
        )
        .one_or_none()
    )
    if design is None:
        raise bad_request("selected_design_id must belong to this project")
    plan = get(db, project)
    if plan is None:
        plan = FinalPlan(project_id=project.id)
        db.add(plan)
    plan.selected_design_id = design.id
    plan.plan_json = design.layout_plan_json
    db.commit()
    db.refresh(plan)
    return plan


def to_out(db: Session, plan: FinalPlan) -> FinalPlanOut:
    design = None
    if plan.selected_design_id:
        design = db.get(GeneratedDesign, plan.selected_design_id)
    plan_json = plan.plan_json or (design.layout_plan_json if design else None)
    return FinalPlanOut(
        id=plan.id,
        project_id=plan.project_id,
        selected_design_id=plan.selected_design_id,
        plan_json=plan.plan_json,
        layout_plan_json=plan_json,
        layout_plan_status=move_plan_service.layout_plan_status(plan_json),
        layout_plan_error=move_plan_service.layout_plan_error(plan_json),
        selected_design_output_read_url=(
            r2_storage_service.read_url(storage_key=design.output_image_key)
            if design and design.output_image_key
            else None
        ),
        selected_design_reference_read_url=(
            r2_storage_service.read_url(storage_key=design.reference_image_key)
            if design and design.reference_image_key
            else None
        ),
        export_status=plan.export_status,
        export_url=plan.export_url,
    )


def request_export(db: Session, project: Project, fmt: str) -> FinalPlan:
    plan = get(db, project)
    if plan is None:
        raise not_found("Final plan not set")
    plan.export_status = "queued"
    db.commit()
    db.refresh(plan)
    return plan
