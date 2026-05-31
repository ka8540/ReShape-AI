"""Gemini image generation with environment-driven model selection.

The model identifier is never hardcoded in callers or in the Flutter client.
Selection comes from `core.config.Settings` and falls back through the
preferred → fallback → legacy chain on availability/permission errors.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Iterable

from google import genai
from google.genai import errors as genai_errors

from app.core.config import Settings, get_settings

logger = logging.getLogger(__name__)

# Errors that mean "try the next model in the chain" rather than "give up".
_RETRYABLE_STATUS = {"NOT_FOUND", "PERMISSION_DENIED", "UNIMPLEMENTED", "FAILED_PRECONDITION"}
_RETRYABLE_HTTP = {403, 404, 501}


@dataclass
class ImageGenerationResult:
    image_bytes: bytes
    mime_type: str
    model_name: str
    prompt_version: str


@dataclass
class ImageGenerationFailure:
    error_code: str
    error_message: str
    attempts: list[tuple[str, str]]  # (model_name, error_message)


class AiImageService:
    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._client = genai.Client(api_key=self._settings.GEMINI_API_KEY)

    def generate(
        self,
        *,
        prompt: str,
        prompt_version: str,
        reference_image_bytes: bytes | None = None,
        reference_image_mime: str | None = None,
    ) -> ImageGenerationResult | ImageGenerationFailure:
        chain = self._settings.gemini_image_model_chain
        attempts: list[tuple[str, str]] = []

        for model_name in chain:
            try:
                result = self._generate_with_model(
                    model_name=model_name,
                    prompt=prompt,
                    reference_image_bytes=reference_image_bytes,
                    reference_image_mime=reference_image_mime,
                )
            except genai_errors.APIError as exc:
                if not self._is_retryable(exc):
                    logger.error(
                        "Gemini image generation failed permanently on %s: %s",
                        model_name,
                        exc,
                    )
                    return ImageGenerationFailure(
                        error_code=self._status_of(exc) or "API_ERROR",
                        error_message=str(exc),
                        attempts=attempts + [(model_name, str(exc))],
                    )
                logger.warning(
                    "Gemini model %s unavailable (%s); trying next in chain",
                    model_name,
                    exc,
                )
                attempts.append((model_name, str(exc)))
                continue

            if result is None:
                attempts.append((model_name, "no image in response"))
                logger.warning(
                    "Gemini model %s returned no image; trying next in chain",
                    model_name,
                )
                continue

            image_bytes, mime_type = result
            return ImageGenerationResult(
                image_bytes=image_bytes,
                mime_type=mime_type,
                model_name=model_name,
                prompt_version=prompt_version,
            )

        message = "All configured Gemini image models failed."
        logger.error("%s Attempts: %s", message, attempts)
        return ImageGenerationFailure(
            error_code="ALL_MODELS_FAILED",
            error_message=message,
            attempts=attempts,
        )

    def _generate_with_model(
        self,
        *,
        model_name: str,
        prompt: str,
        reference_image_bytes: bytes | None,
        reference_image_mime: str | None,
    ) -> tuple[bytes, str] | None:
        contents: list[object] = [prompt]
        if reference_image_bytes is not None:
            contents.append(
                genai.types.Part.from_bytes(
                    data=reference_image_bytes,
                    mime_type=reference_image_mime or "image/jpeg",
                )
            )

        response = self._client.models.generate_content(
            model=model_name,
            contents=contents,
        )
        return self._extract_image(response)

    @staticmethod
    def _extract_image(response: object) -> tuple[bytes, str] | None:
        candidates: Iterable = getattr(response, "candidates", []) or []
        for candidate in candidates:
            content = getattr(candidate, "content", None)
            for part in getattr(content, "parts", []) or []:
                inline = getattr(part, "inline_data", None)
                if inline and getattr(inline, "data", None):
                    return inline.data, getattr(inline, "mime_type", "image/png")
        return None

    @staticmethod
    def _is_retryable(exc: genai_errors.APIError) -> bool:
        status = AiImageService._status_of(exc)
        if status in _RETRYABLE_STATUS:
            return True
        code = getattr(exc, "code", None)
        return code in _RETRYABLE_HTTP

    @staticmethod
    def _status_of(exc: genai_errors.APIError) -> str | None:
        return getattr(exc, "status", None) or getattr(exc, "reason", None)
