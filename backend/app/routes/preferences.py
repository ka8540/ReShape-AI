from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth_dependencies import verify_project_owner
from app.core.database import get_db
from app.models.project import Project
from app.schemas.preference import PreferenceOut, PreferencePut
from app.services import preference_service

router = APIRouter(prefix="/projects/{project_id}/preferences", tags=["preferences"])


@router.get("", response_model=PreferenceOut)
def get_preferences(
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> PreferenceOut:
    pref = preference_service.get(db, project)
    if pref is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No preferences set")
    return PreferenceOut.model_validate(pref)


@router.put("", response_model=PreferenceOut)
def put_preferences(
    payload: PreferencePut,
    project: Project = Depends(verify_project_owner),
    db: Session = Depends(get_db),
) -> PreferenceOut:
    return PreferenceOut.model_validate(preference_service.put(db, project, payload))
