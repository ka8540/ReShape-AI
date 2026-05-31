from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.project import Project
from app.models.user import User
from app.schemas.project import ProjectCreate, ProjectUpdate


def create(db: Session, user: User, payload: ProjectCreate) -> Project:
    project = Project(
        user_id=user.id,
        name=payload.name,
        room=payload.room,
        mode=payload.mode,
        notes=payload.notes,
    )
    db.add(project)
    db.commit()
    db.refresh(project)
    return project


def list_for_user(db: Session, user: User) -> list[Project]:
    return (
        db.query(Project)
        .filter(Project.user_id == user.id)
        .order_by(Project.created_at.desc())
        .all()
    )


def update(db: Session, project: Project, payload: ProjectUpdate) -> Project:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(project, field, value)
    db.commit()
    db.refresh(project)
    return project


def delete(db: Session, project: Project) -> None:
    db.delete(project)
    db.commit()
