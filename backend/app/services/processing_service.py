from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.project import Project


def status(db: Session, project: Project) -> dict:
    return {
        "project_id": project.id,
        "status": project.status,
        "stage": None,
        "progress": 0.0,
        "error_code": None,
        "error_message": None,
    }


def retry(db: Session, project: Project) -> dict:
    project.status = "processing"
    db.commit()
    return status(db, project)
