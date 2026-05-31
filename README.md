# ReShape AI

AI-powered mobile room reshuffle and redesign assistant built with Flutter, FastAPI, Cloudflare R2, Firebase Auth, and Gemini image generation.

**Project status:** Active development — MVP build.

---

## 1. Overview

ReShape AI helps people rearrange a room they already own. The user records a short video (or uploads a photo) of their space, the backend detects furniture and structural elements, the user confirms what's movable vs. fixed, and Gemini produces a small set of photo-real preview images of the same room re-laid-out using only the items the user already has. The final reshuffle plan is saved with a structured layout and a generated preview.

**Who it's for.** Renters and homeowners who want a better room without buying new furniture, plus a fast way to see what a reshuffle would actually look like before lifting anything.

**Problem it solves.** Generic interior-design apps either ignore what you already own, or require precise measurements. ReShape AI works from a quick video, respects fixed pieces, and shows the result.

**MVP focus.**

- Mobile-first Flutter app.
- "Reshuffle existing room" path end-to-end.
- Backend that owns Gemini and R2 — clients never touch either directly.
- Firebase Auth (Google OAuth) for identity.

**Not in MVP.**

- Full "redesign" mode (new furniture, shopping flows).
- Product recommendations / marketplace / affiliate links.
- AR or 3D scene editor.
- CAD-level measurements; the app explicitly does not claim exact dimensions.

---

## 2. Current MVP Scope

| Area | Status |
|---|---|
| Flutter mobile UI (Welcome → Home → Capture → Upload → Processing → Review → Preferences → Results → Layout detail → Final plan) | Implemented (mock-data driven for the design pass) |
| Bottom-tab navigation via `StatefulShellRoute.indexedStack` | Implemented |
| Reshuffle flow screens | Implemented |
| Redesign mode | Coming-soon screen only |
| Image upload support (backend) | Implemented |
| Video upload support (backend) | Implemented |
| Firebase Auth + Google OAuth (Flutter) | Scaffolded (`AuthService`, `LoginScreen`, Dio interceptor); not wired into router by default so mock flow still boots |
| Firebase ID-token verification (backend) | Implemented |
| User / project / media / item / preference / generation / design / final-plan / feedback APIs | Implemented |
| R2 signed upload + read URLs | Implemented (mock URLs when R2 env vars are unset) |
| Gemini image generation service with model fallback chain | Implemented |
| Async worker pipeline (Celery + video / image / generation worker stubs) | Scaffolded (tasks dispatched when Celery is configured; no-op stubs otherwise) |
| Generated-design metadata (`model_name`, `prompt_version`, `error_code`, …) | Implemented |
| Backend tests for auth + ownership | Implemented (9 passing) |

---

## 3. Tech Stack

### Frontend (mobile/)

| Tech | Purpose |
|---|---|
| Flutter, Dart | App framework |
| Riverpod | State management |
| GoRouter | Navigation (with `StatefulShellRoute.indexedStack` for tabs) |
| Dio | HTTP client with Bearer-token interceptor |
| firebase_core, firebase_auth | Identity |
| google_sign_in | Google OAuth provider for Firebase |
| flutter_secure_storage | Token / secret storage |
| image_picker, camera, video_player | Capture + preview |
| cached_network_image | Remote image display |
| google_fonts | Typography |

### Backend (backend/)

| Tech | Purpose |
|---|---|
| Python 3.11+, FastAPI | API |
| Pydantic v2 + pydantic-settings | Schemas + env config |
| SQLAlchemy 2.x | ORM |
| Alembic | Migrations |
| PostgreSQL (SQLite fallback for local dev) | System of record |
| Redis | Queue / cache (planned for rate-limit too) |
| Celery | Background workers (scaffolded) |
| Firebase Admin SDK | ID-token verification |
| boto3 | Cloudflare R2 (S3-compatible) signed URLs |
| google-genai | Gemini image generation |
| Pillow, OpenCV, ffmpeg-python | Image/video processing (planned in workers) |
| pytest, httpx | Tests |

### Infrastructure

Cloudflare R2 (private bucket) · Firebase Authentication / Google OAuth · PostgreSQL · Redis · Gemini image generation.

---

## 4. Repository Structure

```text
ReShape-AI/
├── mobile/                     # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                # router, app shell
│   │   ├── screens/            # screens.dart (all flow screens), login_screen.dart
│   │   ├── widgets/            # design_system.dart, room_art.dart
│   │   ├── services/           # api_client.dart, auth_service.dart, future_mobile_stack.dart
│   │   ├── state/              # project_state.dart (Riverpod)
│   │   ├── data/               # mock_data.dart, models.dart
│   │   └── theme/              # colors.dart, typography.dart
│   ├── ios/  android/  web/  macos/  linux/  windows/
│   └── pubspec.yaml
├── backend/                    # FastAPI modular monolith
│   ├── app/
│   │   ├── main.py             # mounts all routers
│   │   ├── core/               # config, database, firebase, auth_dependencies, security, exceptions
│   │   ├── routes/             # health, auth, users, projects, media, processing,
│   │   │                       # items, preferences, generation, designs, final_plan, feedback
│   │   ├── services/           # auth, user, project, media, processing, item, preference,
│   │   │                       # generation, design, final_plan, feedback, r2_storage,
│   │   │                       # ai_image_service, prompt_builder, rate_limit_service
│   │   ├── models/             # SQLAlchemy ORM
│   │   ├── schemas/            # Pydantic request/response contracts
│   │   ├── workers/            # celery_app + video / image / generation worker stubs
│   │   └── prompts/            # reshuffle_preview_prompt.txt, redesign_preview_prompt.txt
│   ├── alembic/                # env.py wired to models; versions/
│   ├── tests/                  # pytest; Firebase verifier mocked via dependency override
│   ├── requirements.txt
│   ├── alembic.ini
│   ├── .env.example
│   ├── API.md                  # endpoint catalogue + examples
│   └── README.md               # backend-specific notes
├── docs/                       # PRD, TRD, app-flow PDFs, design-handoff-notes.md
├── design-handoff/             # original Claude design handoff (HTML/CSS reference)
├── .gitignore
└── README.md                   # this file
```

---

## 5. High-Level Architecture

The Flutter app talks **only** to the FastAPI backend. The backend owns every secret: Gemini API key, R2 access keys, Firebase Admin credentials. Media never flows through FastAPI — clients upload/download directly from R2 with short-lived signed URLs the backend issues.

```mermaid
flowchart TD
    User[User] --> Flutter[Flutter Mobile App]
    Flutter --> Firebase[Firebase Auth / Google OAuth]
    Flutter --> API[FastAPI Backend]

    API --> Auth[Firebase Admin Token Verification]
    API --> DB[(PostgreSQL)]
    API --> Redis[(Redis Queue)]
    API --> R2[(Cloudflare R2 Private Bucket)]

    Redis --> Worker[Background Worker]
    Worker --> R2
    Worker --> Gemini[Gemini Image Generation API]
    Worker --> DB

    API --> Flutter
```

**Boundaries.**

- Flutter holds only the Firebase ID token (short-lived, refreshed automatically).
- FastAPI verifies every protected call with the Firebase Admin SDK.
- All project-scoped routes enforce ownership via a reusable dependency (`verify_project_owner`) which returns `404` on cross-user access so existence of other users' data is not leaked.
- Storage keys are server-built (`users/<uid>/projects/<pid>/<kind>/<file>`); clients cannot inject arbitrary paths.

---

## 6. End-to-End Product Workflow

1. User opens app and signs in with Google (Firebase Auth).
2. Flutter calls `POST /auth/session` with the Firebase ID token; backend upserts a local `users` row and returns the profile.
3. User creates a project (`POST /projects`).
4. User chooses image or video. Flutter calls `POST /projects/{id}/media/upload-url`.
5. Backend creates a `MediaAsset` row and returns a presigned PUT URL.
6. Flutter PUTs the file directly to R2.
7. Flutter calls `POST /projects/{id}/media/complete`.
8. Backend dispatches the right worker:
   - **Image path:** validate + use as reference frame.
   - **Video path:** download → extract frames → pick best reference frames.
9. Worker writes `DetectedItem` rows; user reviews + corrects (`GET/POST/PATCH /projects/{id}/items`).
10. User marks items movable vs fixed and sets reshuffle preferences (`PUT /projects/{id}/preferences`).
11. Backend builds a structured layout plan + Gemini prompt server-side.
12. User triggers generation (`POST /projects/{id}/generate-layouts`).
13. Worker calls Gemini, walking the model fallback chain on transient errors.
14. Generated images are saved to R2; `model_name`, `prompt_version`, status, error code/message are persisted on `generated_designs`.
15. Flutter polls `GET /projects/{id}/generation-status` and lists `/designs` — each design carries a signed read URL when fetched individually.
16. User selects a design and saves the final plan (`POST /projects/{id}/final-plan`); optional `POST /final-plan/export`.

```mermaid
sequenceDiagram
    actor U as User
    participant F as Flutter App
    participant FB as Firebase Auth
    participant API as FastAPI Backend
    participant R2 as Cloudflare R2
    participant Q as Redis Queue
    participant W as Worker
    participant G as Gemini API
    participant DB as PostgreSQL

    U->>F: Sign in with Google
    F->>FB: Authenticate
    FB-->>F: Firebase ID Token
    F->>API: Create project (Bearer token)
    API->>FB: Verify token
    API->>DB: Create project
    DB-->>API: Project created
    API-->>F: Project response

    F->>API: Request signed upload URL
    API->>R2: Generate signed upload URL
    API->>DB: Create media record
    API-->>F: Signed upload URL

    F->>R2: Upload image/video directly
    F->>API: Mark upload complete
    API->>Q: Queue processing job

    Q->>W: Start processing
    alt Video Upload
        W->>R2: Download video
        W->>W: Extract / select frames
        W->>R2: Store frames
    else Image Upload
        W->>R2: Download image
        W->>W: Validate / normalize
    end
    W->>DB: Save detected items / status

    F->>API: Poll processing status
    API-->>F: awaiting_user_review

    U->>F: Correct items / pick preferences
    F->>API: Save items + preferences
    F->>API: Generate layouts
    API->>Q: Queue generation job

    Q->>W: Start generation
    W->>DB: Load project / items / preferences
    W->>G: Generate reshuffle preview
    G-->>W: Generated image bytes
    W->>R2: Save generated images
    W->>DB: Save generated design metadata

    F->>API: Poll generation status
    API-->>F: completed
    F->>API: Fetch designs
    API->>R2: Generate signed read URLs
    API-->>F: Preview designs
    U->>F: Select final design
    F->>API: Save final plan
```

---

## 7. Backend Architecture

Strict separation of concerns:

- **`routes/`** — only HTTP request/response wiring. No DB calls, no business logic.
- **`services/`** — business logic, framework-free (FastAPI types do not leak in).
- **`models/`** — SQLAlchemy ORM tables. Internal UUID primary keys; `firebase_uid` is a unique indexed column on `users`, never the PK.
- **`schemas/`** — Pydantic request/response contracts. One module per service.
- **`workers/`** — Celery app + per-domain task modules (video frame extraction, image analysis, image generation). Workers stay decoupled from the request path.
- **`core/config.py`** — pydantic-settings loaded from env; exposes a `gemini_image_model_chain` property that de-dupes the fallback chain.
- **`core/auth_dependencies.py`** — reusable FastAPI dependencies: `get_current_user`, `require_authenticated_user`, `require_admin_user`, `verify_project_owner`.
- **`core/firebase.py`** — Firebase Admin init + `verify_id_token`. Tests override `get_firebase_verifier` via FastAPI DI rather than touching firebase_admin itself.
- **`services/r2_storage_service.py`** — signed URLs and storage-key construction. Falls back to mock URLs if R2 env vars are absent (handy for local dev).
- **`services/ai_image_service.py`** — Gemini calls with the env-driven fallback chain (preferred → fallback → legacy). Persists which model actually produced the image.
- **`services/prompt_builder.py`** — loads `prompts/*.txt`; stamps `PROMPT_VERSION` on every generation so we can A/B prompt revisions.
- **`services/rate_limit_service.py`** — in-process token-bucket; swap for Redis in production.

---

## 8. API Overview

Full catalogue with auth annotations: [`backend/API.md`](backend/API.md). Summary:

| Module | Endpoints | Auth |
|---|---|---|
| Health | `GET /health`, `GET /health/ready` | public |
| Auth | `POST /auth/session`, `GET /auth/me`, `POST /auth/logout`, `GET /auth/health` | bearer (except `auth/health`) |
| Users | `GET/PATCH/DELETE /users/me`, `GET /users/me/projects-summary` | bearer |
| Projects | `POST /projects`, `GET /projects`, `GET/PATCH/DELETE /projects/{id}` | bearer + owner on `/{id}` routes |
| Media | `POST /projects/{id}/media/upload-url`, `POST /projects/{id}/media/complete`, `GET /projects/{id}/media`, `GET /projects/{id}/media/{media_id}/read-url`, `DELETE /projects/{id}/media/{media_id}` | bearer + owner |
| Processing | `GET /projects/{id}/processing-status`, `POST /projects/{id}/retry-processing` | bearer + owner |
| Items | `GET/POST /projects/{id}/items`, `PATCH/DELETE /projects/{id}/items/{item_id}` | bearer + owner |
| Preferences | `GET/PUT /projects/{id}/preferences` | bearer + owner |
| Generation | `POST /projects/{id}/generate-layouts`, `GET /projects/{id}/generation-status` | bearer + owner |
| Designs | `GET /projects/{id}/designs`, `GET /projects/{id}/designs/{design_id}`, `POST /projects/{id}/designs/{design_id}/select`, `POST /projects/{id}/designs/{design_id}/customize` | bearer + owner |
| Final Plan | `POST /projects/{id}/final-plan`, `GET /projects/{id}/final-plan`, `POST /projects/{id}/final-plan/export` | bearer + owner |
| Feedback | `POST /projects/{id}/designs/{design_id}/feedback`, `GET /projects/{id}/feedback` | bearer + owner |

Cross-user access on any `/{id}` route returns **404 Not Found**, not 403, by design.

---

## 9. Authentication and Authorization

- Identity provider: **Firebase Authentication**. Flutter signs in with Google through Firebase (Google OAuth).
- Flutter sends the Firebase ID token on every protected call:

  ```http
  Authorization: Bearer <firebase_id_token>
  ```

- FastAPI verifies the token with the Firebase Admin SDK in `app/core/firebase.py`, extracts `uid` / email / name / picture / provider, and upserts a local `users` row (`upsert_user_from_firebase`).
- **Backend never trusts a `user_id` from the client body.** The Firebase UID is the only source of truth for ownership.
- Every project-scoped route uses `verify_project_owner`. If the project doesn't exist *or* belongs to another user, it returns `404`. This is intentional — never leak existence of other users' data.
- Role gate: `require_admin_user` for any future admin endpoints; ordinary users see `404` on those.

---

## 10. Media Upload Flow

### Image

1. Flutter `POST /projects/{id}/media/upload-url` with `media_kind=image`.
2. Backend validates MIME + size, creates `MediaAsset`, returns presigned PUT URL.
3. Flutter PUTs the file to R2.
4. Flutter `POST /projects/{id}/media/complete` → backend marks asset uploaded and dispatches the image-processing worker (**no frame extraction**).

### Video

Same as above with `media_kind=video`. On complete, the **video-processing worker** is dispatched for frame extraction and best-frame selection.

### Allowed types / limits (configurable in `app/core/config.py`)

| Kind | MIME types | Max size |
|---|---|---|
| Image | `image/jpeg`, `image/png`, `image/webp`, `image/heic` | 15 MB |
| Video | `video/mp4`, `video/quicktime` | 250 MB (guideline: 30–60 s) |

Storage keys are built server-side: `users/<user_id>/projects/<project_id>/<kind>/<file_name>`. Clients can't supply arbitrary keys.

---

## 11. Gemini Image Generation Flow

- The Gemini API key lives only on the backend (`GEMINI_API_KEY`). Flutter never calls Gemini.
- The backend builds the prompt from a versioned template (`prompts/*.txt`) and the user's items + preferences.
- A structured layout plan is the source of truth; the generated image is a preview.
- The output is saved to R2; metadata (including the actual `model_name` used) is saved to PostgreSQL on `generated_designs`.

### Model selection (env-driven, never hardcoded)

```env
GEMINI_IMAGE_MODEL=gemini-3.1-flash-image-preview
GEMINI_IMAGE_FALLBACK_MODEL=gemini-3-pro-image-preview
GEMINI_IMAGE_LEGACY_MODEL=gemini-2.5-flash-image
```

`AiImageService` walks the chain in order. On `NOT_FOUND` / `PERMISSION_DENIED` / `UNIMPLEMENTED` / HTTP 403 / 404 / 501 it falls through to the next model. Permanent failures are logged and persisted as `error_code` + `error_message` — never silently hidden.

---

## 12. Environment Variables

### Backend (`backend/.env`)

```env
APP_ENV=local
DATABASE_URL=postgresql://user:password@host:5432/respace
REDIS_URL=redis://localhost:6379/0

FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CREDENTIALS_PATH=./firebase-service-account.json

GEMINI_API_KEY=your_google_ai_studio_key
GEMINI_IMAGE_MODEL=gemini-3.1-flash-image-preview
GEMINI_IMAGE_FALLBACK_MODEL=gemini-3-pro-image-preview
GEMINI_IMAGE_LEGACY_MODEL=gemini-2.5-flash-image

R2_ACCOUNT_ID=your_cloudflare_account_id
R2_ACCESS_KEY_ID=your_r2_access_key
R2_SECRET_ACCESS_KEY=your_r2_secret_key
R2_BUCKET_NAME=respace-media
R2_ENDPOINT_URL=https://<account_id>.r2.cloudflarestorage.com
```

If `DATABASE_URL` is omitted the backend falls back to a local SQLite file so you can boot without Postgres. If R2 vars are omitted, `r2_storage_service` returns mock URLs (useful for tests and offline dev).

### Mobile (`--dart-define`)

| Variable | Default |
|---|---|
| `API_BASE_URL` | `http://localhost:8000` |

> **Never commit real `.env` files or `firebase-service-account.json`.** They're covered by `.gitignore`.

---

## 13. Local Development Setup

### Prerequisites

- Flutter SDK (3.41+) and Dart
- Python 3.11+
- PostgreSQL (or skip and use the SQLite fallback for prototyping)
- Redis (only required when running workers)
- A Firebase project with Google sign-in enabled + service-account JSON
- A Cloudflare R2 private bucket and API token
- A Gemini API key
- Git

### Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env       # then fill in real values
uvicorn app.main:app --reload
```

### Database migrations

```bash
cd backend
alembic upgrade head
```

(`app.main` also auto-creates tables on startup for local convenience; production should rely on Alembic.)

### Worker

```bash
cd backend
celery -A app.workers.celery_app.celery_app worker --loglevel=info
```

If Celery isn't running, queue calls degrade to in-process logs so the API still responds.

### Mobile

```bash
cd mobile
flutter pub get
# Design-pass (mock data, no Firebase, no backend required):
flutter run --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Real backend:
flutter run --debug \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=ENABLE_FIREBASE=true
```

Three compile-time flags drive runtime behaviour (`mobile/lib/services/api_config.dart`):

| Flag | Default | Effect |
|---|---|---|
| `API_BASE_URL` | `http://127.0.0.1:8000` | Base URL for the FastAPI backend. |
| `USE_MOCK_DATA` | `true` | When true, screens read the in-memory mock state. When false, project list / create / media calls hit the backend. |
| `ENABLE_FIREBASE` | `false` | When true, `Firebase.initializeApp()` runs at startup and the router redirects unauthenticated users to `/login`. |

### Firebase setup

1. Create a Firebase project; enable Google sign-in under **Authentication → Sign-in method**.
2. Add Android and iOS apps to the project.
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the standard Flutter locations. Do **not** commit them.
4. Generate a service-account key from **Project settings → Service accounts** and save it as `backend/firebase-service-account.json`. Do **not** commit it (`.gitignore` blocks it).
5. To wire login into the Flutter router, initialise Firebase in `lib/main.dart` (`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`) and route to `LoginScreen` when unauthenticated. By default the app boots straight into the mock flow.

### Cloudflare R2 setup

1. Create a private bucket (e.g. `respace-media`).
2. Create an R2 API token with object read/write.
3. Set the five `R2_*` env vars on the backend.

### Gemini setup

1. Create a key at Google AI Studio.
2. Set `GEMINI_API_KEY` and the three `GEMINI_IMAGE_MODEL*` vars on the backend.

---

## 14. Running the Full Stack Locally

1. Start PostgreSQL and Redis (skip if you're fine with SQLite + in-process queue stubs).
2. `uvicorn app.main:app --reload` in `backend/`.
3. `celery -A app.workers.celery_app.celery_app worker -l info` in `backend/`.
4. `flutter run` in `mobile/`.
5. Sign in with Google (Firebase).
6. Create a project, upload an image or video, poll status, review items, generate designs, save final plan.

---

## 15. Testing

### Backend

```bash
cd backend
pytest
```

The current suite (`tests/test_auth_and_ownership.py`) covers:

- 401 on protected endpoints with no/invalid token
- `POST /auth/session` creates the local user
- `GET /users/me` returns current user
- Cross-user project access returns **404**
- Image vs. video upload URL endpoints both succeed
- Unsupported MIME → 400
- Generation requires project ownership

Firebase verification is mocked via FastAPI dependency override; SQLite is used as the test DB.

### Mobile

```bash
cd mobile
flutter analyze
flutter test
```

`flutter test` currently only contains the default scaffold widget test; more tests TODO once the API client is wired into screens.

---

## 16. Contribution Guide

### Branching

Work on `feature/...`, `fix/...`, `refactor/...`, or `docs/...` branches off `main`. Open PRs into `main`.

### Commit style

Conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`. Keep subjects short; explain the *why* in the body when it isn't obvious.

### Adding a backend route

1. Add the SQLAlchemy model in `app/models/` (if a new table is needed).
2. Add Pydantic schemas in `app/schemas/<module>.py`.
3. Put business logic in `app/services/<module>_service.py`. Services don't import FastAPI.
4. Add a thin route module in `app/routes/<module>.py` that calls the service.
5. If the route is project-scoped, depend on `verify_project_owner` so ownership is enforced uniformly.
6. Register the router in `app/main.py`.
7. Add a test that hits the new endpoint via `TestClient` with the `auth_as` fixture.

### Adding a Flutter screen

1. Build the screen in `mobile/lib/screens/` and re-use widgets from `lib/widgets/design_system.dart`.
2. Add a route in `lib/app/router.dart`. Use `NoTransitionPage` for tab-shell pages; default transitions for detail/flow pages.
3. State goes through Riverpod providers in `lib/state/`.
4. API calls use `apiClientProvider` from `lib/services/api_client.dart` — the Dio interceptor attaches the Firebase ID token automatically.

### PR checklist

- [ ] No secrets committed (`.env`, service-account JSON, R2 keys, Gemini key).
- [ ] `flutter analyze` clean for any Flutter changes.
- [ ] `pytest` green for any backend changes.
- [ ] README / `backend/API.md` updated when API contracts change.
- [ ] Screenshots or screen recordings attached for UI changes.
- [ ] New project-scoped endpoints use `verify_project_owner`.

---

## 17. Security Notes

- Firebase ID tokens are verified server-side on every protected request.
- The backend never trusts a `user_id` from the client body; the Firebase UID is the source of truth.
- Cross-user reads of project resources return **404** so existence isn't leaked.
- The Cloudflare R2 bucket is private; clients access it only via short-lived signed URLs the backend issues.
- The Gemini API key never leaves the backend.
- A simple in-process rate limiter caps generation requests per user (10/hour by default); production should swap this for a Redis-backed limiter.
- `.env`, `*.pem`, `*.key`, and `backend/firebase-service-account.json` are all in `.gitignore`.

---

## 18. Roadmap

**Phase 1 — Mobile UI** ✅
Flutter design pass, mock data, full reshuffle flow shell, bottom-tab navigation.

**Phase 2 — Backend foundation** ✅
Modular FastAPI monolith, Firebase Auth, user / project / media / items / preferences / generation / designs / final-plan / feedback routes, services + schemas + models.

**Phase 3 — Real media pipeline** 🔜
Wire workers up to actual video frame extraction (ffmpeg-python) and image normalisation (Pillow + OpenCV). Persist `ExtractedFrame` rows. Replace the in-process generation queue with Celery in production.

**Phase 4 — Real generation loop** 🔜
End-to-end Gemini calls with reference frames, signed read URLs surfaced into Flutter, design selection persisted as `FinalPlan`.

**Phase 5 — Polish** 🔜
Feedback collection, Redis-backed rate limits, admin endpoints, observability.

**Future**
Redesign mode (new furniture, shopping flows), product recommendations + marketplace, AR / 3D editor, measurement calibration with a reference object.

---

## 19. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `401 Invalid Firebase token` | Token expired or wrong project. Sign out + back in. Confirm `FIREBASE_PROJECT_ID` matches the Firebase project that issued the token. |
| `400 Unsupported image type` | MIME not in `ALLOWED_IMAGE_MIME`. Re-encode to JPEG/PNG/WebP or extend the allow-list in `core/config.py`. |
| R2 PUT returns 403 / SignatureDoesNotMatch | Wrong `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` or the bucket name/endpoint doesn't match the credentials. |
| `ALL_MODELS_FAILED` on generation | The current `GEMINI_IMAGE_MODEL` and both fallbacks rejected the call. Try `gemini-2.5-flash-image` as `GEMINI_IMAGE_MODEL` and check API key permissions. |
| Worker doesn't pick up jobs | Celery isn't running, or `REDIS_URL` is wrong. With Celery off, enqueue calls fall back to in-process logs (visible in API logs). |
| `psycopg2.OperationalError` | Postgres not running or `DATABASE_URL` mistyped. Switch to the SQLite fallback by setting `DATABASE_URL=sqlite:///./respace.db`. |
| Flutter iOS build: `Command CodeSign failed` "detritus not allowed" | Extended attributes on the build artifacts. Run `xattr -cr mobile/` and `flutter clean`, then `flutter run` again. |
| Android Gradle plugin / Firebase mismatch | Re-run `flutterfire configure`; ensure `google-services.json` matches your Firebase Android app. |
| CORS / wrong base URL | Pass `--dart-define=API_BASE_URL=...` when running Flutter, and confirm the backend is reachable from your device/emulator. |

---

## 20. Glossary

- **Project** — a single room reshuffle session owned by one user.
- **MediaAsset** — an uploaded image or video tied to a project; stored in R2, indexed in Postgres.
- **ExtractedFrame** — a still pulled from a video by the worker; one of these becomes the reference frame for generation.
- **DetectedItem** — furniture / structural item detected (or added by the user) inside a project. `fixed=true` means layouts must not move it.
- **PreferenceSet** — per-project preferences (primary goal, style, structured constraints) that feed the prompt builder.
- **GeneratedDesign** — one Gemini output for a project, with `model_name`, `prompt_version`, `output_image_key`, `generation_status`, optional `error_code` / `error_message`, and a `is_selected` flag.
- **DesignItemChange** — a per-item edit (move / rotate / swap) the user applies on top of a generated design.
- **FinalPlan** — the design the user committed to, plus optional export status.
- **Feedback** — rating / sentiment / comment on a generated design.
- **R2 signed URL** — a short-lived presigned URL issued by the backend so clients can PUT or GET an R2 object without ever holding R2 credentials.
- **Firebase ID token** — short-lived JWT issued by Firebase Auth after Google sign-in; sent as `Authorization: Bearer …`.
- **Reference frame** — the still image (uploaded directly, or selected from a video) used as visual context for Gemini generation.
- **Layout plan** — structured JSON describing item positions/rotations; the source of truth for what the room looks like.

---

## 21. Project Status

Active development — MVP build. Mobile UI and backend scaffolding are in; the real media-processing and generation pipelines are next. See the [Roadmap](#18-roadmap) for what's wired up vs. planned.

---

### Further reading

- [`backend/API.md`](backend/API.md) — full endpoint catalogue with request/response examples.
- [`backend/README.md`](backend/README.md) — backend-specific setup notes.
- [`docs/`](docs/) — PRD, TRD, app-flow PDF, design-handoff notes.
