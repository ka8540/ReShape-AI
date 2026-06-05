from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.final_plan import FinalPlanCreate, FinalPlanExportRequest, FinalPlanOut
from app.services import final_plan_service

router = APIRouter(prefix="/projects/{project_id}/final-plan", tags=["final_plan"])


@router.post("", response_model=FinalPlanOut, status_code=status.HTTP_201_CREATED)
def create_final_plan(
    payload: FinalPlanCreate,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> FinalPlanOut:
    plan = final_plan_service.create_or_update(db, project, payload)
    return final_plan_service.to_out(db, plan)


@router.get("", response_model=FinalPlanOut)
def get_final_plan(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> FinalPlanOut:
    plan = final_plan_service.get(db, project)
    if plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No final plan set")
    return final_plan_service.to_out(db, plan)


@router.post("/export", response_model=FinalPlanOut, status_code=status.HTTP_202_ACCEPTED)
def export_final_plan(
    payload: FinalPlanExportRequest,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> FinalPlanOut:
    plan = final_plan_service.request_export(db, project, payload.format)
    return final_plan_service.to_out(db, plan)
