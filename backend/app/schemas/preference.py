from pydantic import BaseModel

from app.schemas.common import ORMModel


class PreferencePut(BaseModel):
    primary_goal: str | None = None
    style: str | None = None
    constraints_json: str | None = None


class PreferenceOut(ORMModel):
    id: str
    project_id: str
    primary_goal: str | None
    style: str | None
    constraints_json: str | None
