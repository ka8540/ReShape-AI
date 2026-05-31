from pydantic import BaseModel

from app.schemas.user import UserOut


class SessionResponse(BaseModel):
    user: UserOut
    app_metadata: dict = {}


class AuthHealth(BaseModel):
    firebase_configured: bool
    project_id_present: bool
