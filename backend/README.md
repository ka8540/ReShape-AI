# ReSpace AI Backend

Phase 1 backend implementation plan. The backend is a Python FastAPI modular
monolith. Flutter never calls Gemini directly and never holds the API key.

## Stack

- FastAPI (REST only).
- PostgreSQL via SQLAlchemy/SQLModel + Alembic.
- Redis + Celery/Dramatiq workers.
- Cloudflare R2 (private bucket; backend issues signed upload/read URLs).

## Planned modules

`auth`, `projects`, `media`, `processing`, `items`, `preferences`,
`generation`, `final_plan`, `workers`, `storage/r2`.

## Pipeline

`video upload -> frame extraction -> item detection -> user correction ->
layout generation -> saved final plan`

Image uploads skip frame extraction. Video uploads go through frame
extraction. Generated images are written back to R2; Flutter renders them
through signed R2 URLs.

## Gemini image model selection

Google rotates Gemini image models often, so the model identifier is
environment-driven. The backend never hardcodes a model name and the Flutter
client never sees one (unless the backend explicitly exposes it through an
admin/debug endpoint).

Configured in `.env` (see `.env.example`):

```
GEMINI_IMAGE_MODEL=gemini-3.1-flash-image-preview
GEMINI_IMAGE_FALLBACK_MODEL=gemini-3-pro-image-preview
GEMINI_IMAGE_LEGACY_MODEL=gemini-2.5-flash-image
```

- `gemini-3.1-flash-image-preview` — preferred current model.
- `gemini-3-pro-image-preview` — fallback for higher fidelity or
  compatibility testing.
- `gemini-2.5-flash-image` — legacy fallback, kept only in case the newer
  models are unavailable.

`app/services/ai_image_service.py` walks the chain in order. If a request
fails because the model is unavailable, unsupported, or permission-denied,
the failure is logged and the next model is tried. Failures are never
silently hidden. The model that actually produced the image is persisted on
the row.

## Generated design metadata

Each row in `generated_designs` stores:

- `model_name` — the model that actually produced the image.
- `prompt_version` — version tag of the prompt template used.
- `reference_image_key` — R2 key of the input/reference image.
- `output_image_key` — R2 key of the generated output image.
- `layout_plan_json` — structured layout plan returned alongside the image.
- `generation_status` — `succeeded` / `failed`.
- `error_code` / `error_message` — populated when every model in the chain
  fails.
- `created_at`.

## Invariants

- FastAPI is the only thing that calls Gemini.
- `GEMINI_API_KEY` stays backend-only.
- R2 bucket is private; access is always via signed URLs.
- Media uploads accept both images and videos; the processing pipeline
  branches on type.
