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

    # Firebase Authentication (verified server-side).
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_CREDENTIALS_PATH: str = "./firebase-service-account.json"

    # Gemini image generation — env-driven so Google's rolling releases never
    # require a code change.
    GEMINI_API_KEY: str = Field(default="", description="Google AI Studio API key.")
    GEMINI_IMAGE_MODEL: str = "gemini-3.1-flash-image-preview"
    GEMINI_IMAGE_FALLBACK_MODEL: str = "gemini-3-pro-image-preview"
    GEMINI_IMAGE_LEGACY_MODEL: str = "gemini-2.5-flash-image"

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
