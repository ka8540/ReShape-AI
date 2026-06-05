from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    APP_ENV: str = "local"

    # MVP object detection is not implemented yet. When enabled, /media/complete
    # synthesises a small set of DetectedItem rows so the review flow is usable
    # locally. Never fakes silently in production: it only runs when explicitly
    # turned on OR when APP_ENV == "local" (see mock_detection_enabled).
    USE_MOCK_DETECTION: bool = False

    # Firebase Authentication (verified server-side).
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_CREDENTIALS_PATH: str = "./firebase-service-account.json"

    # How layout generation runs:
    #   inline   = run synchronously in the API process (good for local/dev)
    #   celery   = enqueue a Celery task (production; needs a running worker)
    #   disabled = reject generation requests with a clear 503
    # Empty string -> inline in local, celery otherwise (see generation_mode).
    GENERATION_EXECUTION_MODE: str = ""

    # Gemini image generation — env-driven so Google's rolling releases never
    # require a code change. Defaults are current image-capable model ids;
    # the fallback chain is tried in order on availability/permission errors.
    GEMINI_API_KEY: str = Field(default="", description="Google AI Studio API key.")
    GEMINI_IMAGE_MODEL: str = "gemini-3.1-flash-image"
    GEMINI_IMAGE_FALLBACK_MODEL: str = "gemini-3.1-flash-image-preview"
    GEMINI_IMAGE_LEGACY_MODEL: str = "gemini-2.5-flash-image"
    GEMINI_TEXT_MODEL: str = "gemini-2.5-flash"

    # Cloudflare R2 (private bucket; backend issues signed URLs).
    R2_ACCOUNT_ID: str = ""
    R2_ACCESS_KEY_ID: str = ""
    R2_SECRET_ACCESS_KEY: str = ""
    R2_BUCKET_NAME: str = "respace-media"
    R2_ENDPOINT_URL: str = ""

    DATABASE_URL: str = "sqlite:///./respace.db"
    REDIS_URL: str = "redis://localhost:6379/0"

    # Upload limits.
    MAX_IMAGE_BYTES: int = 15 * 1024 * 1024
    MAX_VIDEO_BYTES: int = 250 * 1024 * 1024
    ALLOWED_IMAGE_MIME: tuple[str, ...] = (
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/heic",
    )
    ALLOWED_VIDEO_MIME: tuple[str, ...] = (
        "video/mp4",
        "video/quicktime",
    )

    @property
    def generation_mode(self) -> str:
        """Resolved generation execution mode. Defaults to inline locally so the
        MVP works without a Celery worker, and celery everywhere else."""
        explicit = (self.GENERATION_EXECUTION_MODE or "").strip().lower()
        if explicit in ("inline", "celery", "disabled"):
            return explicit
        return "inline" if self.APP_ENV == "local" else "celery"

    @property
    def mock_detection_enabled(self) -> bool:
        """Run the synthetic fallback detector when explicitly enabled, or in
        local dev. Production (APP_ENV != "local") must opt in via
        USE_MOCK_DETECTION, so it never fabricates items silently."""
        return self.USE_MOCK_DETECTION or self.APP_ENV == "local"

    @property
    def gemini_image_model_chain(self) -> list[str]:
        ordered = [
            self.GEMINI_IMAGE_MODEL,
            self.GEMINI_IMAGE_FALLBACK_MODEL,
            self.GEMINI_IMAGE_LEGACY_MODEL,
        ]
        seen: set[str] = set()
        out: list[str] = []
        for name in ordered:
            if name and name not in seen:
                seen.add(name)
                out.append(name)
        return out


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
