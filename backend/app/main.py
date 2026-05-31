import logging

from fastapi import FastAPI

from app.core.database import Base, engine
from app.routes import (
    auth,
    designs,
    feedback,
    final_plan,
    generation,
    health,
    items,
    media,
    preferences,
    processing,
    projects,
    users,
)

# Import models so SQLAlchemy registers them before create_all.
from app.models import *  # noqa: F401,F403

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="ReSpace AI Backend", version="0.2.0")


@app.on_event("startup")
def _create_tables() -> None:
    # Lightweight bootstrap for local/dev. Production uses Alembic migrations.
    Base.metadata.create_all(bind=engine)


app.include_router(health.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(projects.router)
app.include_router(media.router)
app.include_router(processing.router)
app.include_router(items.router)
app.include_router(preferences.router)
app.include_router(generation.router)
app.include_router(designs.router)
app.include_router(final_plan.router)
app.include_router(feedback.router)
