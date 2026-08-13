"""In-memory sliding-window rate limiter for auth endpoints.

Per-process only: suitable for single-worker deployments. If the app runs
behind multiple uvicorn workers or processes, replace this with a shared
store (e.g. Redis).
"""

import threading
import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request, status

_lock = threading.Lock()
_hits: dict[str, deque[float]] = defaultdict(deque)


def allow(key: str, max_requests: int, window_seconds: float) -> bool:
    """Record a hit for ``key`` and return True if within the limit."""
    now = time.monotonic()
    with _lock:
        bucket = _hits[key]
        cutoff = now - window_seconds
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()
        if len(bucket) >= max_requests:
            return False
        bucket.append(now)
        return True


def reset() -> None:
    """Clear all recorded hits (used by tests)."""
    with _lock:
        _hits.clear()


def rate_limit(max_requests: int, window_seconds: float):
    """FastAPI dependency factory keyed by client IP + request path."""

    async def dependency(request: Request) -> None:
        ip = request.client.host if request.client else "unknown"
        if not allow(f"{ip}:{request.url.path}", max_requests, window_seconds):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests, please try again later",
            )

    return dependency
