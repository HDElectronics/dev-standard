---
id: ERR
title: Errors and logging
version: 0.1.0
applies_to: all
based_on:
  - name: OWASP Logging Cheat Sheet
    url: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
---

# Errors and logging (ERR)

How code handles errors and what it writes to logs. HTTP error responses are covered by `API-003` (RFC 9457 problem details); tracing and log export by `OBS-001`.

## Rules

### ERR-001 · MUST NOT · Catch and ignore

Every caught error is handled (recovered from with a defined fallback), wrapped with context and re-raised, or re-raised as is. No empty `except`, no `except Exception: pass`, no `catch {}`.

- **Why:** Swallowed errors turn a clear failure into wrong data or a mystery later, far from the cause.
- **Check:** Python: ruff `BLE001` (blind except), `S110` (try-except-pass), `E722` (bare except). TypeScript: Biome `suspicious/noEmptyBlockStatements`. Block in CI.

```python
try:
    supplier_price = await supplier.fetch_price(sku)
except httpx.TimeoutException as exc:
    raise SupplierUnavailableError(sku=sku) from exc
```

### ERR-002 · MUST · Write structured logs without secrets or personal data

Logs are JSON with at least: timestamp, level, event name, trace ID, and service. Use event names, not sentences: `event="bom_import_completed"`. Never log passwords, tokens, session IDs, full card numbers or personal data (`DAT-005`).

- **Why:** Structured logs can be searched and aggregated. The trace ID links a log line to the request that produced it. Logged secrets and personal data turn logs into a breach.
- **Check:** Advisory for structure. The logger configuration redacts known sensitive keys; review checks new log calls.

### ERR-003 · SHOULD · Use typed errors at domain boundaries

Domain code raises specific error types (`CartLockedError`, `BomParseError`) or returns a Result type. A single handler at the edge maps them to responses.

- **Why:** Typed errors let callers handle specific cases and let the edge map each error to the right status code in one place.
- **Check:** Advisory.

## Reference

### Python: structlog JSON setup

```python
import logging
import structlog

REDACTED_KEYS = {"password", "token", "access_token", "refresh_token", "authorization", "cookie"}


def redact(_logger: object, _method: str, event_dict: dict[str, object]) -> dict[str, object]:
    for key in REDACTED_KEYS & event_dict.keys():
        event_dict[key] = "[redacted]"
    return event_dict


structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        redact,
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
)

log = structlog.get_logger()
log.info("bom_import_completed", lines=15, unmatched=2)
```

Bind the trace ID per request with `structlog.contextvars.bind_contextvars(trace_id=...)` in middleware; with OpenTelemetry (`OBS-001`), take it from the current span.

### FastAPI: mapping domain errors to problem details

Domain errors are mapped to RFC 9457 problem details in one exception handler. The response format itself is defined in `API-003`.

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()


class DomainError(Exception):
    type_uri = "https://errors.example.com/domain-error"
    title = "Domain error"
    status = 400


class CartLockedError(DomainError):
    type_uri = "https://errors.example.com/cart-locked"
    title = "Cart is locked for checkout"
    status = 409


@app.exception_handler(DomainError)
async def handle_domain_error(request: Request, exc: DomainError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status,
        media_type="application/problem+json",
        content={
            "type": exc.type_uri,
            "title": exc.title,
            "status": exc.status,
            "instance": str(request.url.path),
        },
    )
```

### Log levels

| Level | Use for |
|-------|---------|
| `error` | A request or job failed and needs attention |
| `warning` | Something unexpected that the code recovered from |
| `info` | Business events and lifecycle (started, completed) |
| `debug` | Detail for development; off in production |

## Sources

- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [structlog](https://www.structlog.org/)
- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457)
- [FastAPI: Handling errors](https://fastapi.tiangolo.com/tutorial/handling-errors/)
- [Ruff rules](https://docs.astral.sh/ruff/rules/)
