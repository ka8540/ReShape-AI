# ReSpace AI Backend

Python FastAPI modular monolith. Authenticated with Firebase. Cloudflare R2
for private media. Gemini for image generation. The Flutter client never
calls Gemini, never holds the API key, never holds the R2 secret, and never
reads from a public R2 URL.

## Layout

```
backend/
  app/
    main.py              # FastAPI bootstrap, mounts routers
    core/                # config, db, firebase, auth deps, exceptions, security
    routes/              # one file per service; thin handlers
    services/            # business logic (no FastAPI types)
    models/              # SQLAlchemy ORM
    schemas/             # Pydantic request/response contracts
    workers/             # Celery app + worker stubs (video/image/generation)
    prompts/             # Gemini prompt templates
  alembic/               # migrations (Alembic + env.py wired to models)
  tests/                 # pytest, Firebase verifier mocked via DI override
  requirements.txt
  .env.example
  README.md
  API.md
```

## Setup

1. `python3 -m venv .venv && source .venv/bin/activate`
2. `pip install -r requirements.txt`
3. `cp .env.example .env` and fill in real values
4. Drop your Firebase service-account JSON at the path named in
   `FIREBASE_CREDENTIALS_PATH` (default `./firebase-service-account.json`).
   **Do not commit it** — `.gitignore` excludes the file.
5. Run the API: `uvicorn app.main:app --reload`
6. Run a worker: `celery -A app.workers.celery_app.celery_app worker -l info`
7. Migrations: `alembic upgrade head`

For local-only quick start, the app falls back to a SQLite file
(`./respace.db`) so you can boot without Postgres.

## Environment

See [.env.example](./.env.example). Highlights:

- `FIREBASE_PROJECT_ID`, `FIREBASE_CREDENTIALS_PATH` — Firebase Admin SDK
  initialisation. Service-account JSON stays local and gitignored.
- `GEMINI_API_KEY` plus the three model slots (`GEMINI_IMAGE_MODEL`,
  `GEMINI_IMAGE_FALLBACK_MODEL`, `GEMINI_IMAGE_LEGACY_MODEL`). The model
  name is never hardcoded and never exposed to Flutter.
- `R2_*` — Cloudflare R2 credentials. The bucket is **private**; backend
  always issues short-lived signed upload/read URLs.

## Authentication

Authentication is Firebase. Flutter signs in (Google OAuth via Firebase Auth),
gets a Firebase ID token, and sends it to the backend on every protected
request:

```
Authorization: Bearer <firebase_id_token>
```

The backend dependency [`get_current_user`](app/core/auth_dependencies.py)
verifies the token with the Firebase Admin SDK, extracts the Firebase UID,
email, name, photo and provider, and upserts a local `users` row. The
Firebase UID is **never** the primary key — local id is a UUID, and
`firebase_uid` is a unique indexed column. Routes never accept a `user_id`
from the client body for ownership decisions.

### Authorization

Every project-scoped route depends on `verify_project_owner`, which:

1. Resolves the current user from the Firebase token.
2. Loads the project by `project_id`.
3. Returns **404** (not 403) on cross-user access — we don't leak existence
   of other users' projects.

Media, items, designs, final plan, and feedback routes nest under
`/projects/{project_id}/...`, so the same dependency enforces ownership for
every child resource.

## Gemini image model selection

`app/services/ai_image_service.py` walks the env-configured chain:

1. `GEMINI_IMAGE_MODEL` (preferred — currently `gemini-3.1-flash-image-preview`)
2. `GEMINI_IMAGE_FALLBACK_MODEL` (`gemini-3-pro-image-preview`)
3. `GEMINI_IMAGE_LEGACY_MODEL` (`gemini-2.5-flash-image`)

On `NOT_FOUND` / `PERMISSION_DENIED` / `UNIMPLEMENTED` / 403 / 404 / 501 the
service falls through to the next model. Permanent failures are logged and
recorded on `generated_designs` as `error_code` + `error_message`. The
model that actually produced the image is persisted as `model_name`.

## R2 storage

`r2_storage_service` builds storage keys server-side:
`users/{user_id}/projects/{project_id}/{kind}/{file_name}`. Clients never
supply storage keys directly — the upload-URL endpoint creates the media row
and signs a PUT URL bound to that key.

## Media upload flow

1. `POST /projects/{project_id}/media/upload-url` with `media_kind=image|video`
   → backend creates `MediaAsset` row and returns a presigned PUT URL.
2. Flutter PUTs the bytes to R2 directly.
3. `POST /projects/{project_id}/media/complete` → backend marks the asset
   `uploaded` and dispatches the right worker:
   - `media_kind=image` → `image_processing_worker` (no frame extraction).
   - `media_kind=video` → `video_processing_worker` (frame extraction).
4. `GET /projects/{project_id}/media/{media_id}/read-url` returns a signed
   GET URL when the client needs to display the asset.

## Example authenticated call

```bash
curl -X POST http://localhost:8000/auth/session \
  -H "Authorization: Bearer $FIREBASE_ID_TOKEN"
```

## Running tests

```
pip install -r requirements.txt
pytest
```

Tests override the Firebase verifier dependency to bypass real token
verification and run against SQLite. They cover:

- 401 on protected endpoints with no/invalid token
- `POST /auth/session` creates a local user
- `GET /users/me` returns the current user
- Cross-user project access returns 404
- Image vs. video upload URL endpoints both succeed
- Unsupported media types return 400
- Generation requires project ownership

## API reference

See [API.md](./API.md).
