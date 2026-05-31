"""In-process token-bucket rate limiter. Swap for Redis in production."""

from __future__ import annotations

import threading
import time
from collections import defaultdict


class RateLimiter:
    def __init__(self, *, max_events: int, window_seconds: int) -> None:
        self._max = max_events
        self._window = window_seconds
        self._events: dict[str, list[float]] = defaultdict(list)
        self._lock = threading.Lock()

    def allow(self, key: str) -> bool:
        now = time.monotonic()
        with self._lock:
            recent = [t for t in self._events[key] if now - t < self._window]
            if len(recent) >= self._max:
                self._events[key] = recent
                return False
            recent.append(now)
            self._events[key] = recent
            return True


generation_limiter = RateLimiter(max_events=10, window_seconds=60 * 60)
