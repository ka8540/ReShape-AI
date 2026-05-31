from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.design import DesignCustomizeRequest, DesignOut, DesignWithUrls
from app.services import design_service, generation_service

router = APIRouter(prefix="/projects/{project_id}/designs", tags=["designs"])


@router.get("", response_model=list[DesignOut])
def list_designs(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> list[DesignOut]:
    return [DesignOut.model_validate(d) for d in generation_service.list_designs(db, project)]


@router.get("/{design_id}", response_model=DesignWithUrls)
def get_design(
    design_id: str,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> DesignWithUrls:
    design = design_service.get_owned(db, project, design_id)
    base = DesignOut.model_validate(design).model_dump()
    return DesignWithUrls(**base, **design_service.with_signed_urls(design))


@router.post("/{design_id}/select", response_model=DesignOut)
def select(
    design_id: str,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> DesignOut:
    return DesignOut.model_validate(design_service.select(db, project, design_id))


@router.post("/{design_id}/customize", response_model=DesignOut)
def customize(
    design_id: str,
    payload: DesignCustomizeRequest,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> DesignOut:
    design_service.customize(db, project, design_id, payload)
    design = design_service.get_owned(db, project, design_id)
    return DesignOut.model_validate(design)
