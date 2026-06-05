"""Tests for the photo → detection → review-items flow.

Covers the bug where an image upload completed but produced zero DetectedItem
rows. With APP_ENV=local (the test default) the synthetic fallback detector
runs on /media/complete.
"""

from __future__ import annotations


def _create_project(client, headers, name="Living room"):
    res = client.post("/projects", json={"name": name}, headers=headers)
    assert res.status_code == 201
    return res.json()["id"]


def _upload_and_complete_image(client, headers, project_id):
    up = client.post(
        f"/projects/{project_id}/media/upload-url",
        json={
            "file_name": "living_room.jpg",
            "mime_type": "image/jpeg",
            "file_size": 2048,
            "media_kind": "image",
        },
        headers=headers,
    )
    assert up.status_code == 201
    media_id = up.json()["media_id"]
    done = client.post(
        f"/projects/{project_id}/media/complete",
        json={"media_id": media_id},
        headers=headers,
    )
    assert done.status_code == 200
    return done.json()


def test_image_complete_creates_detected_items(client, auth_as):
    headers = auth_as("t-alice", uid="alice")
    pid = _create_project(client, headers)
    _upload_and_complete_image(client, headers, pid)

    items = client.get(f"/projects/{pid}/items", headers=headers).json()
    assert len(items) > 0, "image processing should create reviewable items"

    names = {i["name"].lower() for i in items}
    assert "sofa" in names  # representative furniture item
    # Structural items are flagged and fixed so layouts never move them.
    structural = [i for i in items if i["structural"]]
    assert structural, "expected at least one structural item (window/door/wall)"
    assert all(i["fixed"] for i in structural)
    # Detected (not user-added) items.
    assert all(i["added_by_user"] is False for i in items)


def test_processing_status_becomes_awaiting_review(client, auth_as):
    headers = auth_as("t-amy", uid="amy")
    pid = _create_project(client, headers)
    _upload_and_complete_image(client, headers, pid)

    status = client.get(f"/projects/{pid}/processing-status", headers=headers).json()
    assert status["status"] == "awaiting_user_review"


def test_complete_is_idempotent_no_duplicate_items(client, auth_as):
    headers = auth_as("t-ida", uid="ida")
    pid = _create_project(client, headers)
    first = _upload_and_complete_image(client, headers, pid)
    count_after_first = len(client.get(f"/projects/{pid}/items", headers=headers).json())

    # Re-complete the same asset; fallback must not duplicate items.
    media_id = first["id"]
    again = client.post(
        f"/projects/{pid}/media/complete",
        json={"media_id": media_id},
        headers=headers,
    )
    assert again.status_code == 200
    count_after_second = len(
        client.get(f"/projects/{pid}/items", headers=headers).json()
    )
    assert count_after_second == count_after_first


def test_delete_item_removes_it(client, auth_as):
    headers = auth_as("t-bob", uid="bob")
    pid = _create_project(client, headers)
    _upload_and_complete_image(client, headers, pid)

    items = client.get(f"/projects/{pid}/items", headers=headers).json()
    target = items[0]["id"]
    before = len(items)

    res = client.delete(f"/projects/{pid}/items/{target}", headers=headers)
    assert res.status_code == 200
    assert res.json()["status"] == "deleted"

    after = client.get(f"/projects/{pid}/items", headers=headers).json()
    assert len(after) == before - 1
    assert target not in {i["id"] for i in after}


def test_cross_user_delete_returns_404(client, auth_as):
    alice = auth_as("t-alice", uid="alice", email="a@example.com")
    pid = _create_project(client, alice)
    _upload_and_complete_image(client, alice, pid)
    item_id = client.get(f"/projects/{pid}/items", headers=alice).json()[0]["id"]

    bob = auth_as("t-bob", uid="bob", email="b@example.com")
    res = client.delete(f"/projects/{pid}/items/{item_id}", headers=bob)
    # Not 403 — we never leak existence of another user's data.
    assert res.status_code == 404
    # The item is still there for the real owner.
    assert item_id in {
        i["id"] for i in client.get(f"/projects/{pid}/items", headers=alice).json()
    }


def test_manual_add_item_appears_in_list(client, auth_as):
    headers = auth_as("t-cara", uid="cara")
    pid = _create_project(client, headers)

    created = client.post(
        f"/projects/{pid}/items",
        json={"name": "Beanbag", "type": "chair"},
        headers=headers,
    )
    assert created.status_code == 201
    body = created.json()
    assert body["added_by_user"] is True

    listed = client.get(f"/projects/{pid}/items", headers=headers).json()
    assert body["id"] in {i["id"] for i in listed}


def test_patch_item_fixed_toggle(client, auth_as):
    headers = auth_as("t-dee", uid="dee")
    pid = _create_project(client, headers)
    _upload_and_complete_image(client, headers, pid)

    movable = next(
        i for i in client.get(f"/projects/{pid}/items", headers=headers).json()
        if not i["fixed"]
    )
    res = client.patch(
        f"/projects/{pid}/items/{movable['id']}",
        json={"fixed": True},
        headers=headers,
    )
    assert res.status_code == 200
    assert res.json()["fixed"] is True


def test_real_detection_path_creates_no_items_when_mock_disabled(
    client, auth_as, monkeypatch
):
    """When mock detection is off (prod-like), /media/complete must NOT
    fabricate items — it hands off to the async worker (still a stub)."""
    from app.core.config import get_settings
    from app.services import detection_service

    settings = get_settings()
    monkeypatch.setattr(settings, "USE_MOCK_DETECTION", False)
    monkeypatch.setattr(settings, "APP_ENV", "production")

    calls: list[str] = []
    monkeypatch.setattr(
        detection_service,
        "enqueue_image_analysis",
        lambda media_asset_id: calls.append(media_asset_id),
    )

    headers = auth_as("t-eve", uid="eve")
    pid = _create_project(client, headers)
    _upload_and_complete_image(client, headers, pid)

    items = client.get(f"/projects/{pid}/items", headers=headers).json()
    assert items == []  # no synthetic items in production-like mode
    assert calls, "real path should dispatch the async image-analysis worker"

    status = client.get(f"/projects/{pid}/processing-status", headers=headers).json()
    assert status["status"] == "processing"
