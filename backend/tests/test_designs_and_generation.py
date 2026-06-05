"""Tests for the generation → designs → select flow backing the Results screen.

Generation itself is intentionally NOT faked: request_generation creates
GeneratedDesign rows and hands off to the async worker. These tests verify the
contract the Flutter Results screen relies on (designs list, signed read URL on
the detail endpoint, select persistence, ownership 404).
"""

from __future__ import annotations

import pytest

from app.models.generated_design import GeneratedDesign


def _project(client, headers, name="Living room"):
    res = client.post("/projects", json={"name": name}, headers=headers)
    assert res.status_code == 201
    return res.json()["id"]


@pytest.fixture()
def no_broker(monkeypatch):
    """Avoid touching Redis/Celery when calling generate-layouts."""
    import app.workers.image_generation_worker as worker

    monkeypatch.setattr(worker, "enqueue_generation", lambda **kwargs: None)
    return worker


def _add_design(db_session, project_id, **kwargs):
    design = GeneratedDesign(project_id=project_id, **kwargs)
    db_session.add(design)
    db_session.commit()
    db_session.refresh(design)
    return design


def test_generation_creates_designs(client, auth_as, no_broker):
    headers = auth_as("t-gen", uid="gen")
    pid = _project(client, headers)

    res = client.post(
        f"/projects/{pid}/generate-layouts",
        json={"variants": 2},
        headers=headers,
    )
    assert res.status_code == 202

    designs = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert len(designs) == 2
    # Freshly requested designs are queued; no image yet (honest, not faked).
    assert all(d["generation_status"] == "queued" for d in designs)


def test_design_detail_returns_signed_read_url(client, db_session, auth_as):
    headers = auth_as("t-url", uid="url")
    pid = _project(client, headers)
    design = _add_design(
        db_session,
        pid,
        generation_status="succeeded",
        output_image_key=f"{pid}/designs/out.png",
        model_name="test-model",
    )

    res = client.get(f"/projects/{pid}/designs/{design.id}", headers=headers)
    assert res.status_code == 200
    body = res.json()
    assert body["generation_status"] == "succeeded"
    # A signed read URL is present so the client can render the image.
    assert body["output_read_url"]


def test_select_persists_is_selected(client, db_session, auth_as):
    headers = auth_as("t-sel", uid="sel")
    pid = _project(client, headers)
    d1 = _add_design(db_session, pid, generation_status="succeeded")
    d2 = _add_design(db_session, pid, generation_status="succeeded")

    res = client.post(f"/projects/{pid}/designs/{d1.id}/select", headers=headers)
    assert res.status_code == 200
    assert res.json()["is_selected"] is True

    listed = {d["id"]: d for d in client.get(f"/projects/{pid}/designs", headers=headers).json()}
    assert listed[d1.id]["is_selected"] is True
    assert listed[d2.id]["is_selected"] is False

    # Selecting the other one flips the flag exclusively.
    client.post(f"/projects/{pid}/designs/{d2.id}/select", headers=headers)
    listed = {d["id"]: d for d in client.get(f"/projects/{pid}/designs", headers=headers).json()}
    assert listed[d1.id]["is_selected"] is False
    assert listed[d2.id]["is_selected"] is True


def test_cross_user_design_access_returns_404(client, db_session, auth_as):
    alice = auth_as("t-alice", uid="alice", email="a@example.com")
    pid = _project(client, alice)
    design = _add_design(db_session, pid, generation_status="succeeded")

    bob = auth_as("t-bob", uid="bob", email="b@example.com")
    # Detail and select on someone else's design look like 404, not 403.
    assert client.get(f"/projects/{pid}/designs/{design.id}", headers=bob).status_code == 404
    assert (
        client.post(f"/projects/{pid}/designs/{design.id}/select", headers=bob).status_code
        == 404
    )
