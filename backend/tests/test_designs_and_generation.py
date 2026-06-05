"""Tests for the layout generation pipeline + designs contract.

Generation runs inline in tests (APP_ENV=local). Gemini and R2 are mocked by the
autouse `offline_generation` fixture in conftest; individual tests override those
mocks to exercise success / specific failures. No real Gemini calls are made.
"""

from __future__ import annotations

import pytest

from app.models.generated_design import GeneratedDesign
from app.models.media_asset import MediaAsset
from app.services import ai_image_service, generation_service, r2_storage_service


def _project(client, headers, name="Living room"):
    res = client.post("/projects", json={"name": name}, headers=headers)
    assert res.status_code == 201
    return res.json()["id"]


def _add_reference_image(db_session, monkeypatch, project_id):
    """Give the project an uploaded image and make R2 return bytes for it."""
    asset = MediaAsset(
        project_id=project_id,
        media_kind="image",
        file_name="room.jpg",
        mime_type="image/jpeg",
        file_size=2048,
        storage_key=f"{project_id}/image/room.jpg",
        upload_status="uploaded",
    )
    db_session.add(asset)
    db_session.commit()
    monkeypatch.setattr(
        r2_storage_service, "get_object", lambda *, storage_key: b"reference-bytes"
    )


def _add_design(db_session, project_id, **kwargs):
    design = GeneratedDesign(project_id=project_id, **kwargs)
    db_session.add(design)
    db_session.commit()
    db_session.refresh(design)
    return design


def test_inline_mode_calls_shared_generation_job(client, auth_as, monkeypatch):
    calls: list[list[str]] = []
    real = generation_service.run_generation_job

    def _spy(design_ids, db=None):
        calls.append(list(design_ids))
        return real(design_ids, db=db)

    monkeypatch.setattr(generation_service, "run_generation_job", _spy)

    headers = auth_as("t-inline", uid="inline")
    pid = _project(client, headers)
    res = client.post(
        f"/projects/{pid}/generate-layouts", json={"variants": 2}, headers=headers
    )
    assert res.status_code == 202
    assert calls and len(calls[0]) == 2  # inline ran the shared job for 2 designs
    # Inline ran -> nothing left "queued".
    designs = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert all(d["generation_status"] != "queued" for d in designs)


def test_missing_reference_marks_design_failed(client, auth_as):
    headers = auth_as("t-noref", uid="noref")
    pid = _project(client, headers)  # no media uploaded

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    designs = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert len(designs) == 1
    assert designs[0]["generation_status"] == "failed"
    assert designs[0]["error_code"] == "NO_REFERENCE"
    assert "No reference room image" in designs[0]["error_message"]


def test_gemini_auth_failure_is_surfaced(client, db_session, auth_as, monkeypatch):
    headers = auth_as("t-auth", uid="auth")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)

    def _auth_fail(self, *, prompt, prompt_version, **kwargs):
        return ai_image_service.ImageGenerationFailure(
            error_code="PERMISSION_DENIED",
            error_message="403 PERMISSION_DENIED: API key not valid",
            attempts=[("gemini-3.1-flash-image", "403 permission denied")],
        )

    monkeypatch.setattr(ai_image_service.AiImageService, "generate", _auth_fail)

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]
    assert design["generation_status"] == "failed"
    assert design["error_code"] == "GEMINI_AUTH_FAILED"
    assert "valid Google AI Studio API key" in design["error_message"]


def test_gemini_quota_failure_is_surfaced(client, db_session, auth_as, monkeypatch):
    headers = auth_as("t-quota", uid="quota")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)

    def _quota_fail(self, *, prompt, prompt_version, **kwargs):
        return ai_image_service.ImageGenerationFailure(
            error_code="RESOURCE_EXHAUSTED",
            error_message="429 RESOURCE_EXHAUSTED. You exceeded your current quota",
            attempts=[("gemini-3.1-flash-image", "429 RESOURCE_EXHAUSTED")],
        )

    monkeypatch.setattr(ai_image_service.AiImageService, "generate", _quota_fail)

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]
    assert design["generation_status"] == "failed"
    assert design["error_code"] == "GEMINI_QUOTA_EXCEEDED"
    assert "quota" in design["error_message"].lower()


def test_successful_generation_uploads_and_saves_key(
    client, db_session, auth_as, monkeypatch
):
    headers = auth_as("t-ok", uid="ok")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)

    def _ok(self, *, prompt, prompt_version, **kwargs):
        return ai_image_service.ImageGenerationResult(
            image_bytes=b"PNGDATA",
            mime_type="image/png",
            model_name="gemini-3.1-flash-image",
            prompt_version=prompt_version,
        )

    monkeypatch.setattr(ai_image_service.AiImageService, "generate", _ok)

    uploaded: list[bytes] = []
    monkeypatch.setattr(
        r2_storage_service,
        "put_object",
        lambda *, storage_key, data, content_type: uploaded.append(data) or True,
    )

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]

    assert design["generation_status"] == "succeeded"
    assert design["model_name"] == "gemini-3.1-flash-image"
    assert design["output_read_url"]  # signed URL present
    assert uploaded == [b"PNGDATA"]  # output image uploaded to R2


def test_generation_status_failed_when_all_failed(client, auth_as):
    headers = auth_as("t-stat", uid="stat")
    pid = _project(client, headers)  # no reference -> all fail

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 2}, headers=headers)
    status = client.get(f"/projects/{pid}/generation-status", headers=headers).json()
    assert status["status"] == "failed"
    assert status["total"] == 2
    assert status["failed"] == 2
    assert status["succeeded"] == 0
    assert status["error_message"]


def test_designs_list_returns_output_read_url(client, db_session, auth_as):
    headers = auth_as("t-list", uid="list")
    pid = _project(client, headers)
    _add_design(
        db_session,
        pid,
        generation_status="succeeded",
        output_image_key=f"{pid}/designs/out.png",
    )
    designs = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert designs[0]["output_read_url"]
    assert designs[0]["generation_status"] == "succeeded"


def test_regenerate_replaces_batch_no_pileup(client, auth_as):
    headers = auth_as("t-regen", uid="regen")
    pid = _project(client, headers)

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 2}, headers=headers)
    first = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert len(first) == 2

    # Regenerate -> fresh batch, not 4 rows.
    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 2}, headers=headers)
    second = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert len(second) == 2
    assert {d["id"] for d in first}.isdisjoint({d["id"] for d in second})


def test_cross_user_access_returns_404(client, db_session, auth_as):
    alice = auth_as("t-alice", uid="alice", email="a@example.com")
    pid = _project(client, alice)
    design = _add_design(db_session, pid, generation_status="succeeded")

    bob = auth_as("t-bob", uid="bob", email="b@example.com")
    assert client.get(f"/projects/{pid}/designs/{design.id}", headers=bob).status_code == 404
    assert (
        client.post(f"/projects/{pid}/designs/{design.id}/select", headers=bob).status_code
        == 404
    )
    assert (
        client.post(
            f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=bob
        ).status_code
        == 404
    )
