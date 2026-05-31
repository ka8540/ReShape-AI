from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.exceptions import bad_request, not_found
from app.models.final_plan import FinalPlan
from app.models.generated_design import GeneratedDesign
from app.models.project import Project
from app.schemas.final_plan import FinalPlanCreate


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
    plan.plan_json = payload.plan_json
    db.commit()
    db.refresh(plan)
    return plan


def request_export(db: Session, project: Project, fmt: str) -> FinalPlan:
    plan = get(db, project)
    if plan is None:
        raise not_found("Final plan not set")
    plan.export_status = "queued"
    db.commit()
    db.refresh(plan)
    return plan
