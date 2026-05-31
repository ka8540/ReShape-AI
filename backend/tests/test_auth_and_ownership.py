from __future__ import annotations


def test_health_is_public(client):
    assert client.get("/health").status_code == 200


def test_protected_endpoint_requires_auth(client):
    assert client.get("/users/me").status_code == 401
    assert client.get("/projects").status_code == 401


def test_invalid_token_returns_401(client, auth_as):
    auth_as("good-token", uid="alice")
    res = client.get("/users/me", headers={"Authorization": "Bearer not-the-good-one"})
    assert res.status_code == 401


def test_session_creates_local_user(client, auth_as):
    headers = auth_as("t-alice", uid="firebase-alice", email="alice@example.com", name="Alice")
    res = client.post("/auth/session", headers=headers)
    assert res.status_code == 200
    body = res.json()
    assert body["user"]["firebase_uid"] == "firebase-alice"
    assert body["user"]["email"] == "alice@example.com"
    assert body["app_metadata"]["role"] == "user"


def test_users_me_returns_current_user(client, auth_as):
    headers = auth_as("t-bob", uid="firebase-bob", email="bob@example.com", name="Bob")
    res = client.get("/users/me", headers=headers)
    assert res.status_code == 200
    assert res.json()["email"] == "bob@example.com"


def test_user_cannot_access_other_users_project(client, auth_as):
    alice = auth_as("t-alice", uid="alice", email="a@example.com")
    created = client.post("/projects", json={"name": "Alice room"}, headers=alice)
    assert created.status_code == 201
    project_id = created.json()["id"]

    bob = auth_as("t-bob", uid="bob", email="b@example.com")
    res = client.get(f"/projects/{project_id}", headers=bob)
    # Cross-user access must look like "not found", not "forbidden", so we
    # don't leak existence of other users' projects.
    assert res.status_code == 404

    res = client.patch(
        f"/projects/{project_id}", json={"name": "hack"}, headers=bob
    )
    assert res.status_code == 404


def test_image_upload_url_branches_from_video(client, auth_as):
    headers = auth_as("t-carol", uid="carol")
    created = client.post("/projects", json={"name": "Loft"}, headers=headers).json()
    project_id = created["id"]

    img = client.post(
        f"/projects/{project_id}/media/upload-url",
        json={
            "file_name": "room.jpg",
            "mime_type": "image/jpeg",
            "file_size": 1024,
            "media_kind": "image",
        },
        headers=headers,
    )
    assert img.status_code == 201
    assert "upload_url" in img.json()

    vid = client.post(
        f"/projects/{project_id}/media/upload-url",
        json={
            "file_name": "room.mov",
            "mime_type": "video/quicktime",
            "file_size": 5_000_000,
            "media_kind": "video",
        },
        headers=headers,
    )
    assert vid.status_code == 201


def test_rejects_unsupported_image_mime(client, auth_as):
    headers = auth_as("t-dan", uid="dan")
    pid = client.post("/projects", json={"name": "X"}, headers=headers).json()["id"]
    res = client.post(
        f"/projects/{pid}/media/upload-url",
        json={
            "file_name": "x.bmp",
            "mime_type": "image/bmp",
            "file_size": 1024,
            "media_kind": "image",
        },
        headers=headers,
    )
    assert res.status_code == 400


def test_generation_endpoint_requires_owner(client, auth_as):
    alice = auth_as("t-alice", uid="alice", email="g-alice@example.com")
    pid = client.post("/projects", json={"name": "X"}, headers=alice).json()["id"]
    bob = auth_as("t-bob", uid="bob", email="g-bob@example.com")
    res = client.post(
        f"/projects/{pid}/generate-layouts",
        json={"variants": 1},
        headers=bob,
    )
    assert res.status_code == 404

    res = client.post(
        f"/projects/{pid}/generate-layouts",
        json={"variants": 1},
        headers=alice,
    )
    assert res.status_code == 202
