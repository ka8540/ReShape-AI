"""Helpers around the HTTP Bearer scheme. Real token verification lives in
`core.firebase`; this module just normalises Authorization headers.
"""

from fastapi import Request

from app.core.exceptions import unauthorized


def extract_bearer_token(request: Request) -> str:
    header = request.headers.get("authorization") or request.headers.get("Authorization")
    if not header:
        raise unauthorized("Missing Authorization header")
    parts = header.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise unauthorized("Invalid Authorization header")
    return parts[1].strip()
