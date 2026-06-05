"""Tests for the layout generation pipeline + designs contract.

Generation runs inline in tests (APP_ENV=local). Gemini and R2 are mocked by the
autouse `offline_generation` fixture in conftest; individual tests override those
mocks to exercise success / specific failures. No real Gemini calls are made.
"""

from __future__ import annotations

import json
import time

import pytest

from app.models.detected_item import DetectedItem
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


def _add_item(
    db_session,
    project_id,
    name,
    type_,
    *,
    fixed=False,
    structural=False,
):
    item = DetectedItem(
        project_id=project_id,
        name=name,
        type=type_,
        confidence=0.9,
        fixed=fixed,
        structural=structural,
    )
    db_session.add(item)
    db_session.commit()
    db_session.refresh(item)
    return item


def _plan_json(*, sofa_id: str, window_id: str | None = None) -> str:
    fixed_items = []
    floor_items = [
        {
            "item_id": sofa_id,
            "name": "Sofa",
            "category": "sofa",
            "x": 12,
            "y": 58,
            "width": 34,
            "height": 12,
            "rotation": 0,
            "status": "moved",
            "fixed": False,
        }
    ]
    if window_id:
        floor_items.append(
            {
                "item_id": window_id,
                "name": "Window",
                "category": "window",
                "x": 45,
                "y": 0,
                "width": 20,
                "height": 2,
                "rotation": 0,
                "status": "structural",
                "fixed": True,
            }
        )
        fixed_items.append(
            {"item_id": window_id, "name": "Window", "reason": "structural item"}
        )
    return json.dumps(
        {
            "room_summary": "Approximate top-down plan based on the selected design.",
            "floor_plan": {"width": 100, "height": 100, "items": floor_items},
            "moved_items": [
                {
                    "item_id": sofa_id,
                    "name": "Sofa",
                    "from": "left wall",
                    "to": "opposite wall",
                    "reason": "opens a clearer walkway",
                }
            ],
            "fixed_items": fixed_items,
            "checklist": [
                {
                    "step": 1,
                    "title": "Move the sofa",
                    "details": "Keep clear of fixed structural items.",
                }
            ],
        }
    )


def _run_inline_synchronously(monkeypatch, db_session):
    monkeypatch.setattr(
        generation_service,
        "start_inline_generation_job",
        lambda design_ids: generation_service.run_generation_job(
            list(design_ids),
            db=db_session,
        ),
    )


def test_inline_mode_returns_quickly_and_schedules_background_job(
    client,
    auth_as,
    monkeypatch,
):
    headers = auth_as("t-inline", uid="inline")
    pid = _project(client, headers)
    started: list[list[str]] = []

    monkeypatch.setattr(
        generation_service,
        "start_inline_generation_job",
        lambda design_ids: started.append(list(design_ids)),
    )

    start = time.monotonic()
    res = client.post(
        f"/projects/{pid}/generate-layouts", json={"variants": 2}, headers=headers
    )
    elapsed = time.monotonic() - start

    assert res.status_code == 202
    assert elapsed < 0.5
    assert res.json()["status"] == "running"
    assert started and len(started[0]) == 2

    designs = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert len(designs) == 2
    assert all(d["generation_status"] == "queued" for d in designs)


def test_generation_status_reports_queued_while_background_job_active(
    client,
    auth_as,
    monkeypatch,
):
    headers = auth_as("t-status-queued", uid="status-queued")
    pid = _project(client, headers)
    started: list[list[str]] = []

    monkeypatch.setattr(
        generation_service,
        "start_inline_generation_job",
        lambda design_ids: started.append(list(design_ids)),
    )

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 2}, headers=headers)
    status = client.get(f"/projects/{pid}/generation-status", headers=headers).json()

    assert started and len(started[0]) == 2
    assert status["status"] == "running"
    assert status["total"] == 2
    assert status["queued"] == 2


def test_missing_reference_marks_design_failed(client, db_session, auth_as, monkeypatch):
    _run_inline_synchronously(monkeypatch, db_session)
    headers = auth_as("t-noref", uid="noref")
    pid = _project(client, headers)  # no media uploaded

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    designs = client.get(f"/projects/{pid}/designs", headers=headers).json()
    assert len(designs) == 1
    assert designs[0]["generation_status"] == "failed"
    assert designs[0]["error_code"] == "NO_REFERENCE"
    assert "No reference room image" in designs[0]["error_message"]


def test_gemini_auth_failure_is_surfaced(client, db_session, auth_as, monkeypatch):
    _run_inline_synchronously(monkeypatch, db_session)
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
    _run_inline_synchronously(monkeypatch, db_session)
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
    _run_inline_synchronously(monkeypatch, db_session)
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

    status = client.get(f"/projects/{pid}/generation-status", headers=headers).json()
    assert status["status"] == "completed"
    assert status["succeeded"] == 1
    assert status["failed"] == 0


def test_successful_generation_stores_structured_layout_plan(
    client, db_session, auth_as, monkeypatch
):
    _run_inline_synchronously(monkeypatch, db_session)
    headers = auth_as("t-plan", uid="plan")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)
    sofa = _add_item(db_session, pid, "Sofa", "sofa")
    window = _add_item(db_session, pid, "Window", "window", fixed=True, structural=True)

    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate",
        lambda self, *, prompt, prompt_version, **kwargs: ai_image_service.ImageGenerationResult(
            image_bytes=b"PNGDATA",
            mime_type="image/png",
            model_name="gemini-3.1-flash-image",
            prompt_version=prompt_version,
        ),
    )
    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate_structured_move_plan",
        lambda self, **kwargs: ai_image_service.StructuredMovePlanResult(
            raw_json=_plan_json(sofa_id=sofa.id, window_id=window.id),
            model_name="gemini-2.5-flash",
        ),
    )

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]
    plan = json.loads(design["layout_plan_json"])

    assert design["generation_status"] == "succeeded"
    assert design["layout_plan_status"] == "succeeded"
    assert design["layout_plan_error"] is None
    assert plan["floor_plan"]["items"][0]["item_id"] == sofa.id
    assert plan["moved_items"][0]["name"] == "Sofa"
    assert plan["fixed_items"][0]["item_id"] == window.id


def test_invalid_gemini_json_marks_layout_plan_failed_but_keeps_image(
    client, db_session, auth_as, monkeypatch
):
    _run_inline_synchronously(monkeypatch, db_session)
    headers = auth_as("t-bad-plan", uid="bad-plan")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)
    _add_item(db_session, pid, "Chair", "chair")

    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate",
        lambda self, *, prompt, prompt_version, **kwargs: ai_image_service.ImageGenerationResult(
            image_bytes=b"PNGDATA",
            mime_type="image/png",
            model_name="gemini-3.1-flash-image",
            prompt_version=prompt_version,
        ),
    )
    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate_structured_move_plan",
        lambda self, **kwargs: ai_image_service.StructuredMovePlanResult(
            raw_json="not json",
            model_name="gemini-2.5-flash",
        ),
    )

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]

    assert design["generation_status"] == "succeeded"
    assert design["output_read_url"]
    assert design["layout_plan_status"] == "failed"
    assert "Structured move plan could not be generated" in design["layout_plan_error"]


def test_design_detail_returns_structured_plan_json(client, db_session, auth_as):
    headers = auth_as("t-detail-plan", uid="detail-plan")
    pid = _project(client, headers)
    sofa = _add_item(db_session, pid, "Sofa", "sofa")
    design = _add_design(
        db_session,
        pid,
        generation_status="succeeded",
        output_image_key=f"{pid}/designs/out.png",
        layout_plan_json=_plan_json(sofa_id=sofa.id),
    )

    body = client.get(f"/projects/{pid}/designs/{design.id}", headers=headers).json()
    assert body["layout_plan_status"] == "succeeded"
    assert json.loads(body["layout_plan_json"])["moved_items"][0]["item_id"] == sofa.id


def test_final_plan_returns_selected_design_and_structured_plan(
    client, db_session, auth_as
):
    headers = auth_as("t-final-plan", uid="final-plan")
    pid = _project(client, headers)
    sofa = _add_item(db_session, pid, "Sofa", "sofa")
    design = _add_design(
        db_session,
        pid,
        generation_status="succeeded",
        output_image_key=f"{pid}/designs/out.png",
        reference_image_key=f"{pid}/image/room.jpg",
        layout_plan_json=_plan_json(sofa_id=sofa.id),
    )

    created = client.post(
        f"/projects/{pid}/final-plan",
        json={"selected_design_id": design.id, "plan_json": json.dumps({"fake": True})},
        headers=headers,
    )
    assert created.status_code == 201
    body = client.get(f"/projects/{pid}/final-plan", headers=headers).json()

    assert body["selected_design_id"] == design.id
    assert body["selected_design_output_read_url"]
    assert body["selected_design_reference_read_url"]
    assert body["layout_plan_status"] == "succeeded"
    assert json.loads(body["layout_plan_json"])["moved_items"][0]["item_id"] == sofa.id
    assert "fake" not in body["layout_plan_json"]


def test_fixed_items_are_not_marked_as_moved(client, db_session, auth_as, monkeypatch):
    _run_inline_synchronously(monkeypatch, db_session)
    headers = auth_as("t-fixed-plan", uid="fixed-plan")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)
    window = _add_item(db_session, pid, "Window", "window", fixed=True, structural=True)

    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate",
        lambda self, *, prompt, prompt_version, **kwargs: ai_image_service.ImageGenerationResult(
            image_bytes=b"PNGDATA",
            mime_type="image/png",
            model_name="gemini-3.1-flash-image",
            prompt_version=prompt_version,
        ),
    )
    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate_structured_move_plan",
        lambda self, **kwargs: ai_image_service.StructuredMovePlanResult(
            raw_json=_plan_json(sofa_id=window.id),
            model_name="gemini-2.5-flash",
        ),
    )

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]

    assert design["generation_status"] == "succeeded"
    assert design["layout_plan_status"] == "failed"
    assert "Fixed item cannot be marked moved" in design["layout_plan_error"]


def test_floor_plan_rejects_items_outside_current_project(
    client, db_session, auth_as, monkeypatch
):
    _run_inline_synchronously(monkeypatch, db_session)
    headers = auth_as("t-unknown-plan", uid="unknown-plan")
    pid = _project(client, headers)
    _add_reference_image(db_session, monkeypatch, pid)
    _add_item(db_session, pid, "Chair", "chair")

    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate",
        lambda self, *, prompt, prompt_version, **kwargs: ai_image_service.ImageGenerationResult(
            image_bytes=b"PNGDATA",
            mime_type="image/png",
            model_name="gemini-3.1-flash-image",
            prompt_version=prompt_version,
        ),
    )
    monkeypatch.setattr(
        ai_image_service.AiImageService,
        "generate_structured_move_plan",
        lambda self, **kwargs: ai_image_service.StructuredMovePlanResult(
            raw_json=_plan_json(sofa_id="not-a-project-item"),
            model_name="gemini-2.5-flash",
        ),
    )

    client.post(f"/projects/{pid}/generate-layouts", json={"variants": 1}, headers=headers)
    design = client.get(f"/projects/{pid}/designs", headers=headers).json()[0]

    assert design["layout_plan_status"] == "failed"
    assert "outside this project" in design["layout_plan_error"]


def test_generation_status_failed_when_all_failed(
    client,
    db_session,
    auth_as,
    monkeypatch,
):
    _run_inline_synchronously(monkeypatch, db_session)
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


def test_regenerate_replaces_batch_no_pileup(
    client,
    db_session,
    auth_as,
    monkeypatch,
):
    _run_inline_synchronously(monkeypatch, db_session)
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


def test_cross_user_final_plan_access_returns_404(client, db_session, auth_as):
    alice = auth_as("t-final-alice", uid="final-alice", email="a@example.com")
    pid = _project(client, alice)
    sofa = _add_item(db_session, pid, "Sofa", "sofa")
    design = _add_design(
        db_session,
        pid,
        generation_status="succeeded",
        output_image_key=f"{pid}/designs/out.png",
        layout_plan_json=_plan_json(sofa_id=sofa.id),
    )
    assert (
        client.post(
            f"/projects/{pid}/final-plan",
            json={"selected_design_id": design.id},
            headers=alice,
        ).status_code
        == 201
    )

    bob = auth_as("t-final-bob", uid="final-bob", email="b@example.com")
    assert client.get(f"/projects/{pid}/final-plan", headers=bob).status_code == 404
