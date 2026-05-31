from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

# Use an isolated SQLite DB and dummy creds before app modules import settings.
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_respace.db")
os.environ.setdefault("FIREBASE_PROJECT_ID", "test-project")
os.environ.setdefault("FIREBASE_CREDENTIALS_PATH", "./does-not-exist.json")
os.environ.setdefault("GEMINI_API_KEY", "test-key")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402

from app.core import database  # noqa: E402
from app.core.firebase import get_firebase_verifier  # noqa: E402
from app.main import app  # noqa: E402
from app.models import *  # noqa: F401,F403,E402


@pytest.fixture()
def db_engine(tmp_path):
    url = f"sqlite:///{tmp_path}/test.db"
    engine = create_engine(url, connect_args={"check_same_thread": False}, future=True)
    database.Base.metadata.create_all(bind=engine)
    return engine


@pytest.fixture()
def db_session(db_engine):
    SessionLocal = sessionmaker(bind=db_engine, autoflush=False, autocommit=False, future=True)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture()
def client(db_engine, monkeypatch):
    SessionLocal = sessionmaker(bind=db_engine, autoflush=False, autocommit=False, future=True)

    def override_get_db():
        db = SessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[database.get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.pop(database.get_db, None)


def _fake_verifier(token_to_decoded: dict[str, dict]):
    def verify(token: str):
        decoded = token_to_decoded.get(token)
        if decoded is None:
            raise ValueError("invalid token")
        return decoded

    return verify


@pytest.fixture()
def auth_as(client):
    """Returns a helper that authenticates the test client as a Firebase user."""

    tokens: dict[str, dict] = {}

    def setup(token: str, uid: str, email: str | None = "user@example.com", name: str = "Test"):
        tokens[token] = {
            "uid": uid,
            "email": email,
            "name": name,
            "picture": None,
            "firebase": {"sign_in_provider": "google.com"},
        }
        app.dependency_overrides[get_firebase_verifier] = lambda: _fake_verifier(tokens)
        return {"Authorization": f"Bearer {token}"}

    yield setup
    app.dependency_overrides.pop(get_firebase_verifier, None)
