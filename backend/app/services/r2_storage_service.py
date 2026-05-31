"""Cloudflare R2 access. Backend issues signed upload/read URLs; the bucket
stays private. Storage keys are derived server-side from user/project ids so
clients cannot inject arbitrary paths.
"""

from __future__ import annotations

import logging
from functools import lru_cache
from typing import Any

from app.core.config import get_settings

logger = logging.getLogger(__name__)

DEFAULT_EXPIRES = 3600


@lru_cache(maxsize=1)
def _client() -> Any:
    try:
        import boto3
        from botocore.client import Config
    except ImportError:  # pragma: no cover
        logger.warning("boto3 not installed; R2 signed URLs disabled.")
        return None

    settings = get_settings()
    if not (settings.R2_ACCESS_KEY_ID and settings.R2_SECRET_ACCESS_KEY and settings.R2_ENDPOINT_URL):
        return None
    return boto3.client(
        "s3",
        endpoint_url=settings.R2_ENDPOINT_URL,
        aws_access_key_id=settings.R2_ACCESS_KEY_ID,
        aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
        config=Config(signature_version="s3v4"),
    )


def build_storage_key(
    *, user_id: str, project_id: str, kind: str, file_name: str
) -> str:
    safe_name = file_name.replace("/", "_").replace("\\", "_")
    return f"users/{user_id}/projects/{project_id}/{kind}/{safe_name}"


def upload_url(
    *, storage_key: str, content_type: str, expires_in: int = DEFAULT_EXPIRES
) -> str:
    client = _client()
    settings = get_settings()
    if client is None:
        return f"mock://upload/{storage_key}"
    return client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.R2_BUCKET_NAME,
            "Key": storage_key,
            "ContentType": content_type,
        },
        ExpiresIn=expires_in,
    )


def read_url(*, storage_key: str, expires_in: int = DEFAULT_EXPIRES) -> str:
    client = _client()
    settings = get_settings()
    if client is None:
        return f"mock://read/{storage_key}"
    return client.generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.R2_BUCKET_NAME, "Key": storage_key},
        ExpiresIn=expires_in,
    )


def put_object(*, storage_key: str, data: bytes, content_type: str) -> None:
    client = _client()
    settings = get_settings()
    if client is None:
        logger.info("R2 not configured; skipping put_object for %s", storage_key)
        return
    client.put_object(
        Bucket=settings.R2_BUCKET_NAME,
        Key=storage_key,
        Body=data,
        ContentType=content_type,
    )
