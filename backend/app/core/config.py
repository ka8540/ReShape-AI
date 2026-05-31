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

    # Gemini image generation. Model names are environment-driven so Google's
    # rolling Gemini image releases never require a code change.
    GEMINI_API_KEY: str = Field(..., description="Google AI Studio API key.")
    GEMINI_IMAGE_MODEL: str = "gemini-3.1-flash-image-preview"
    GEMINI_IMAGE_FALLBACK_MODEL: str = "gemini-3-pro-image-preview"
    GEMINI_IMAGE_LEGACY_MODEL: str = "gemini-2.5-flash-image"

    # Cloudflare R2 (private bucket; backend issues signed URLs).
    R2_ACCOUNT_ID: str
    R2_ACCESS_KEY_ID: str
    R2_SECRET_ACCESS_KEY: str
    R2_BUCKET_NAME: str = "respace-media"
    R2_ENDPOINT_URL: str

    DATABASE_URL: str
    REDIS_URL: str = "redis://localhost:6379/0"

    @property
    def gemini_image_model_chain(self) -> list[str]:
        """Ordered list of models to try, with duplicates removed."""
        ordered = [
            self.GEMINI_IMAGE_MODEL,
            self.GEMINI_IMAGE_FALLBACK_MODEL,
            self.GEMINI_IMAGE_LEGACY_MODEL,
        ]
        seen: set[str] = set()
        chain: list[str] = []
        for name in ordered:
            if name and name not in seen:
                seen.add(name)
                chain.append(name)
        return chain


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
