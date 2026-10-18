---
id: REL
title: Scaling and reliability
version: 0.1.0
applies_to: deployed
based_on:
  - name: The Twelve-Factor App
    url: https://12factor.net/
  - name: Google SRE books
    url: https://sre.google/books/
  - name: Amazon Builders' Library
    url: https://aws.amazon.com/builders-library/
  - name: RFC 9111 (HTTP Caching)
    url: https://www.rfc-editor.org/rfc/rfc9111
---

# Scaling and reliability (REL)

How a service stays up under load and when its dependencies fail. Services are built as stateless containers so they can scale horizontally on whatever deploy target the OPS-001 ADR picks.

## Rules

### REL-001 · MUST · Follow the Twelve-Factor App

Read config from the environment (pydantic-settings), keep processes stateless (sessions and caches in Redis, files in object storage), log to stdout, start fast, and shut down gracefully on `SIGTERM` by finishing in-flight requests.

- **Why:** Stateless processes can be restarted, moved and multiplied by any orchestrator without losing data.
- **Check:** Test that the app starts with only environment variables set. CI starts the container, sends `SIGTERM` during a slow request, and asserts the request completes and the exit code is `0`.

### REL-002 · MUST · Expose /livez and /readyz

`/livez` returns `200` when the process is alive and does not touch dependencies. `/readyz` returns `200` only when the service can serve traffic: database and Redis reachable, migrations applied. The orchestrator uses `/livez` for restarts and `/readyz` for routing.

- **Why:** A liveness check that touches the database restarts every replica when the database blips, which turns a small outage into a large one.
- **Check:** Integration test stops Redis and asserts `/livez` = `200`, `/readyz` = `503`. The Dockerfile or compose file declares a healthcheck.

### REL-003 · MUST · Set timeouts on every call, retry with backoff and jitter

Every network call (HTTP, database, Redis, queue) has a timeout. Retry only idempotent calls, at most 3 times, with capped exponential backoff and full jitter. Wrap dependencies that fail often in a circuit breaker.

- **Why:** A call without a timeout can hold a worker forever. Retries without jitter synchronize clients into waves that keep a recovering service down.
- **Check:** Semgrep rule flags `httpx.AsyncClient()` and `httpx.get()` without `timeout=`. Database engine created with `pool_timeout` and a `statement_timeout`. Unit test of the retry helper asserts jittered delays.

### REL-004 · MUST · Pool connections and migrate with expand and contract

Use SQLAlchemy's connection pool with explicit `pool_size` and `max_overflow`. Every schema change is an Alembic migration in the same PR as the code. Breaking changes use expand and contract: add the new column, deploy code that writes both, backfill, switch reads, and remove the old column in a later release.

- **Why:** During a rolling deploy, old and new code run against the same database. A migration that only fits the new code takes the old code down.
- **Check:** CI runs `alembic upgrade head` then `alembic check` (no pending model changes) on a fresh database. A migration lint (for example `squawk` on generated SQL) flags column drops and renames without a prior expand step.

### REL-005 · MUST · Name the index for every query path

`plan.md` lists each new query path with the index that serves it. No query reads an unbounded number of rows: lists paginate (API-004), batch jobs process in chunks.

- **Why:** Missing indexes are the most common reason a service that was fast in testing falls over with real data.
- **Check:** advisory in review, plus an integration test with `EXPLAIN` on the main queries asserting no sequential scan on large tables.

### REL-006 · SHOULD · Move slow or bursty work to a queue

Work that takes longer than about a second, calls slow third parties, or arrives in bursts (emails, imports, exports) runs as a background job with retries and a dead-letter queue. Jobs are idempotent.

- **Why:** Doing slow work inside a request ties up workers and makes latency depend on the slowest dependency.
- **Check:** advisory. p95 request latency in OBS dashboards shows outliers.

### REL-007 · SHOULD · Give every cache a TTL and an owner

Each cache has an explicit TTL and a named owner responsible for invalidation, written in `plan.md`. HTTP responses set `Cache-Control` and `ETag` per RFC 9111 where they can be cached.

- **Why:** Caches without a TTL serve stale data forever; caches without an owner never get invalidated on writes.
- **Check:** advisory. Review checks the plan's cache table.

### REL-008 · MUST · Load test against the SLO before launch

Before the first launch and before expected traffic peaks, run a k6 load test at the expected peak plus margin (default 2×) and compare p95 latency and error rate against the SLO (OBS-002).

- **Why:** Capacity limits are found either by a load test or by users.
- **Check:** `tests/load/*.js` k6 scripts with thresholds; results linked in the PRR. A short k6 smoke run in CI on staging.

### REL-009 · SHOULD · Autoscale on saturation and degrade before failing

Scale horizontally on saturation signals (CPU, concurrency, queue depth). Under overload, shed low-priority work and turn off non-essential features before the core path fails.

- **Why:** A service that degrades gracefully keeps its most important function working during a spike.
- **Check:** advisory. Documented in the deploy-target ADR and the runbook.

## Reference

### Health endpoints (example)

```python
# app/health.py (example)
from fastapi import APIRouter, Response, status
from sqlalchemy import text

from app.db import engine
from app.redis import redis

router = APIRouter()


@router.get("/livez", include_in_schema=False)
async def livez() -> dict:
    return {"status": "ok"}  # no dependency calls (REL-002)


@router.get("/readyz", include_in_schema=False)
async def readyz(response: Response) -> dict:
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        await redis.ping()
    except Exception:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "unavailable"}
    return {"status": "ok"}
```

### Timeouts and pool settings (example)

```python
import httpx
from sqlalchemy.ext.asyncio import create_async_engine

HTTP_TIMEOUT = httpx.Timeout(connect=2.0, read=5.0, write=5.0, pool=2.0)
supplier_client = httpx.AsyncClient(timeout=HTTP_TIMEOUT)

engine = create_async_engine(
    settings.database_url,
    pool_size=10,
    max_overflow=5,
    pool_timeout=5,
    pool_pre_ping=True,
    connect_args={"server_settings": {"statement_timeout": "5000"}},  # asyncpg, ms
)
```

### Retry with full jitter (example)

```python
import asyncio
import random

BASE_DELAY_S = 0.2
MAX_DELAY_S = 5.0
MAX_ATTEMPTS = 3


async def retry_idempotent(call):
    for attempt in range(MAX_ATTEMPTS):
        try:
            return await call()
        except (httpx.TransportError, httpx.HTTPStatusError) as exc:
            if attempt == MAX_ATTEMPTS - 1 or not _is_retryable(exc):
                raise
            await asyncio.sleep(random.uniform(0, min(MAX_DELAY_S, BASE_DELAY_S * 2**attempt)))
```

Libraries such as `tenacity` (`wait_random_exponential`) implement the same policy.

### Graceful shutdown

Uvicorn handles `SIGTERM` by stopping new connections and waiting for in-flight requests; set `--timeout-graceful-shutdown` below the orchestrator's kill timeout (for example 20 s against a 30 s grace period).

## Sources

- [The Twelve-Factor App](https://12factor.net/)
- [Google SRE book: Handling Overload, Addressing Cascading Failures](https://sre.google/sre-book/table-of-contents/)
- [Amazon Builders' Library: Timeouts, retries, and backoff with jitter](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/)
- [Amazon Builders' Library: Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/)
- [RFC 9111 HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
- [Alembic](https://alembic.sqlalchemy.org/) · [k6](https://grafana.com/docs/k6/latest/)
