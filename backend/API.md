# ReSpace AI — HTTP API

All endpoints except `GET /health*` and `GET /auth/health` require
`Authorization: Bearer <firebase_id_token>`. The backend resolves the user
from the token; clients never send a `user_id`.

Cross-user access to a project-scoped resource returns **404**, never 403,
so existence of other users' data is not leaked.

## Endpoint catalogue

| Module      | Method | Path                                                | Auth |
|-------------|--------|-----------------------------------------------------|------|
| health      | GET    | `/health`                                           | —    |
| health      | GET    | `/health/ready`                                     | —    |
| auth        | POST   | `/auth/session`                                     | ✅   |
| auth        | GET    | `/auth/me`                                          | ✅   |
| auth        | POST   | `/auth/logout`                                      | ✅   |
| auth        | GET    | `/auth/health`                                      | —    |
| users       | GET    | `/users/me`                                         | ✅   |
| users       | PATCH  | `/users/me`                                         | ✅   |
| users       | DELETE | `/users/me`                                         | ✅   |
| users       | GET    | `/users/me/projects-summary`                        | ✅   |
| projects    | POST   | `/projects`                                         | ✅   |
| projects    | GET    | `/projects`                                         | ✅   |
| projects    | GET    | `/projects/{project_id}`                            | ✅ + owner |
| projects    | PATCH  | `/projects/{project_id}`                            | ✅ + owner |
| projects    | DELETE | `/projects/{project_id}`                            | ✅ + owner |
| media       | POST   | `/projects/{project_id}/media/upload-url`           | ✅ + owner |
| media       | POST   | `/projects/{project_id}/media/complete`             | ✅ + owner |
| media       | GET    | `/projects/{project_id}/media`                      | ✅ + owner |
| media       | GET    | `/projects/{project_id}/media/{media_id}/read-url`  | ✅ + owner |
| media       | DELETE | `/projects/{project_id}/media/{media_id}`           | ✅ + owner |
| processing  | GET    | `/projects/{project_id}/processing-status`          | ✅ + owner |
| processing  | POST   | `/projects/{project_id}/retry-processing`           | ✅ + owner |
| items       | GET    | `/projects/{project_id}/items`                      | ✅ + owner |
| items       | POST   | `/projects/{project_id}/items`                      | ✅ + owner |
| items       | PATCH  | `/projects/{project_id}/items/{item_id}`            | ✅ + owner |
| items       | DELETE | `/projects/{project_id}/items/{item_id}`            | ✅ + owner |
| preferences | GET    | `/projects/{project_id}/preferences`                | ✅ + owner |
| preferences | PUT    | `/projects/{project_id}/preferences`                | ✅ + owner |
| generation  | POST   | `/projects/{project_id}/generate-layouts`           | ✅ + owner |
| generation  | GET    | `/projects/{project_id}/generation-status`          | ✅ + owner |
| designs     | GET    | `/projects/{project_id}/designs`                    | ✅ + owner |
| designs     | GET    | `/projects/{project_id}/designs/{design_id}`        | ✅ + owner |
| designs     | POST   | `/projects/{project_id}/designs/{design_id}/select` | ✅ + owner |
| designs     | POST   | `/projects/{project_id}/designs/{design_id}/customize` | ✅ + owner |
| final_plan  | POST   | `/projects/{project_id}/final-plan`                 | ✅ + owner |
| final_plan  | GET    | `/projects/{project_id}/final-plan`                 | ✅ + owner |
| final_plan  | POST   | `/projects/{project_id}/final-plan/export`          | ✅ + owner |
| feedback    | POST   | `/projects/{project_id}/designs/{design_id}/feedback` | ✅ + owner |
| feedback    | GET    | `/projects/{project_id}/feedback`                   | ✅ + owner |

## Examples

### `POST /auth/session`

Creates or updates the local user from the Firebase token and returns the
profile + app metadata.

```http
POST /auth/session
Authorization: Bearer <firebase_id_token>
```

```json
{
  "user": {
    "id": "9b1c…",
    "firebase_uid": "abc123",
    "email": "maya@example.com",
    "display_name": "Maya Chen",
    "photo_url": "https://…",
    "provider": "google.com",
    "role": "user",
    "is_active": true,
    "created_at": "2026-05-31T02:14:00Z",
    "last_login_at": "2026-05-31T02:14:00Z"
  },
  "app_metadata": { "role": "user", "is_active": true }
}
```

### `GET /users/me`

Returns the current local user.

### `POST /projects`

```json
{ "name": "Living room", "room": "living", "mode": "reshuffle" }
```

→ `201` with the new `ProjectOut`.

### `POST /projects/{project_id}/media/upload-url`

```json
{
  "file_name": "room.mov",
  "mime_type": "video/quicktime",
  "file_size": 24000000,
  "media_kind": "video"
}
```

→
```json
{
  "media_id": "…",
  "upload_url": "https://<r2-endpoint>/…?X-Amz-Signature=…",
  "storage_key": "users/<user>/projects/<project>/video/room.mov",
  "expires_in": 3600
}
```

Allowed image types: `image/jpeg`, `image/png`, `image/webp`, `image/heic`.
Allowed video types: `video/mp4`, `video/quicktime`. Image cap 15 MB, video
cap 250 MB.

### `POST /projects/{project_id}/media/complete`

```json
{ "media_id": "…" }
```

Branches on `media_kind`: image → image-processing worker, video → video
frame-extraction worker.

### `GET /projects/{project_id}/processing-status`

```json
{
  "project_id": "…",
  "status": "processing",
  "stage": "detection",
  "progress": 0.42,
  "error_code": null,
  "error_message": null
}
```

### `POST /projects/{project_id}/generate-layouts`

```json
{ "variants": 3, "reference_media_id": "<optional>" }
```

→ `202` with `GenerationStatus`. Generation is queued; check
`/generation-status` for progress.

### `GET /projects/{project_id}/designs`

Returns the generated designs for the project. Each design carries the
actual `model_name` Gemini used (one of the env-configured chain), the
`prompt_version`, status, and any error info.
