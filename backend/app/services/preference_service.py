from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.preference_set import PreferenceSet
from app.models.project import Project
from app.schemas.preference import PreferencePut


def get(db: Session, project: Project) -> PreferenceSet | None:
    return (
        db.query(PreferenceSet)
        .filter(PreferenceSet.project_id == project.id)
        .one_or_none()
    )


def put(db: Session, project: Project, payload: PreferencePut) -> PreferenceSet:
    pref = get(db, project)
    if pref is None:
        pref = PreferenceSet(project_id=project.id)
        db.add(pref)
    pref.primary_goal = payload.primary_goal
    pref.style = payload.style
    pref.constraints_json = payload.constraints_json
    db.commit()
    db.refresh(pref)
    return pref
