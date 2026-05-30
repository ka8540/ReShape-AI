# ReSpace AI Backend Placeholder

Backend implementation is intentionally deferred for Phase 1.

The planned MVP backend should be a Python FastAPI modular monolith with:

- PostgreSQL as the system of record.
- SQLAlchemy or SQLModel plus Alembic migrations.
- Redis plus Celery or Dramatiq workers.
- Cloudflare R2 private bucket storage with signed upload/read URLs.
- REST API only.

Planned modules:

- `auth`
- `projects`
- `media`
- `processing`
- `items`
- `preferences`
- `generation`
- `final_plan`
- `workers`
- `storage/r2`

The future trustworthy pipeline is:

`video upload -> frame extraction -> item detection -> user correction -> layout generation -> saved final plan`
