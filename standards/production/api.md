---
id: API
title: API design
version: 0.1.0
applies_to: deployed
based_on:
  - name: Google API Improvement Proposals (AIP)
    url: https://google.aip.dev/
  - name: OpenAPI 3.1
    url: https://spec.openapis.org/oas/v3.1.0
  - name: RFC 9457 (Problem Details for HTTP APIs)
    url: https://www.rfc-editor.org/rfc/rfc9457
  - name: OWASP API Security Top 10
    url: https://owasp.org/API-Security/
---

# API design (API)

HTTP APIs follow Google's resource-oriented design from the AIPs, expressed in OpenAPI 3.1. FastAPI generates the OpenAPI document from Pydantic models; the contract in the spec folder is the design, and a CI check keeps code and contract in line.

## Rules

### API-001 · MUST · Design the contract first

Every new or changed endpoint is described in an OpenAPI 3.1 file in `specs/NNN-slug/contracts/` and reviewed with `plan.md` before implementation starts.

- **Why:** Reviewing a contract is cheap; changing a shipped API is expensive. The contract also drives the generated frontend client (UI-005).
- **Check:** CI exports FastAPI's `openapi.json` and diffs it against the contract with `oasdiff`. Breaking differences fail; additive differences that are not in the contract warn.

### API-002 · MUST · Use resource-oriented design per Google AIP

Model the API as resources with plural nouns (`/v1/orders/{order_id}/lines`) and the standard methods Get, List, Create, Update, Delete (AIP-131 to AIP-135), mapped to `GET`, `GET`, `POST`, `PATCH`, `DELETE`. Use custom methods (AIP-136, `POST /v1/carts/current:importBom`) only when no standard method fits.

- **Why:** A predictable shape means clients and agents can guess endpoints correctly, and it maps cleanly onto authorization checks per resource.
- **Check:** Spectral ruleset in `profiles/python-api/.spectral.yaml` lints the contract for plural path segments, no verbs in paths outside `:customMethod`, and standard method shapes.

### API-003 · MUST · Return RFC 9457 problem details

Errors use `application/problem+json` with `type`, `title`, `status`, `detail` and `instance`. `type` is a stable URI per error kind, documented in the API reference. Never return stack traces or internal messages.

- **Why:** One error format lets clients handle errors generically, and a stable `type` lets them branch on the kind of error without parsing text.
- **Check:** Contract test: every non-2xx response in the OpenAPI document references the shared `Problem` schema. Integration test triggers `404`, `422` and `500` and validates the body.

### API-004 · MUST · Paginate lists with page tokens and a maximum size

List methods accept `page_size` and `page_token` and return `next_page_token` (AIP-158). The token is opaque to clients. The server enforces a maximum page size and a default.

- **Why:** Offset pagination gets slow and returns duplicates when data changes. Unbounded lists are a denial-of-service vector (ABU-004).
- **Check:** Spectral rule: every List operation has `page_size` and `page_token` parameters and a `next_page_token` field. Integration test asks for `page_size=100000` and gets at most the maximum.

### API-005 · MUST · Accept an Idempotency-Key on retried unsafe operations

Operations that clients may retry and that must not run twice, such as creating orders and payments, accept an `Idempotency-Key` header. The server stores the key with the result for at least 24 hours and replays the stored response on a repeat. Reuse of a key with a different body returns `422`.

- **Why:** Networks fail after the server has acted. Without a key, a retry creates a duplicate order or a double charge.
- **Check:** Contract lists the header on the operation. Integration test sends the same request twice with one key and asserts one record created and identical responses.

### API-006 · MUST · Version in the path and announce deprecations

Put the major version in the path (`/v1`). A breaking change ships as a new version. The old version keeps working through a deprecation window announced with the `Deprecation` and `Sunset` headers and in the changelog.

- **Why:** Clients you don't control, such as mobile apps and partners, cannot upgrade on your schedule.
- **Check:** `oasdiff breaking` against the last released contract fails the PR unless the path version changes. The deprecation window is recorded in the ADR.

## Reference

### Resource layout (example)

| Method | HTTP | Path |
|--------|------|------|
| Get | `GET` | `/v1/orders/{order_id}` |
| List | `GET` | `/v1/orders?page_size=50&page_token=...` |
| Create | `POST` | `/v1/orders` |
| Update | `PATCH` | `/v1/orders/{order_id}` |
| Delete | `DELETE` | `/v1/orders/{order_id}` |
| Custom | `POST` | `/v1/carts/current:importBom` |

### Problem details in FastAPI (example)

```python
# app/errors.py (example)
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

PROBLEM_BASE = "https://errors.example.com"


class AppError(Exception):
    def __init__(self, status: int, kind: str, title: str, detail: str | None = None):
        self.status, self.kind, self.title, self.detail = status, kind, title, detail


def problem_response(status: int, type_: str, title: str, detail: str | None = None,
                     instance: str | None = None, headers: dict | None = None) -> JSONResponse:
    body = {"type": type_, "title": title, "status": status}
    if detail:
        body["detail"] = detail
    if instance:
        body["instance"] = instance
    return JSONResponse(body, status_code=status, headers=headers,
                        media_type="application/problem+json")


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def on_app_error(request: Request, exc: AppError):
        return problem_response(exc.status, f"{PROBLEM_BASE}/{exc.kind}", exc.title,
                                exc.detail, str(request.url.path))
```

### Pagination (example)

```python
from pydantic import BaseModel, Field

MAX_PAGE_SIZE = 100
DEFAULT_PAGE_SIZE = 25


class ListOrdersParams(BaseModel):
    page_size: int = Field(DEFAULT_PAGE_SIZE, ge=1)
    page_token: str | None = None

    def effective_page_size(self) -> int:
        return min(self.page_size, MAX_PAGE_SIZE)


class ListOrdersResponse(BaseModel):
    orders: list["Order"]
    next_page_token: str | None = None
```

Encode the page token as a signed or encrypted cursor (for example the last seen `(created_at, id)`), so clients cannot forge or depend on its contents.

## Sources

- [Google AIP-121 Resource-oriented design](https://google.aip.dev/121)
- [Google AIP-131 to AIP-136 standard and custom methods](https://google.aip.dev/131)
- [Google AIP-158 Pagination](https://google.aip.dev/158)
- [RFC 9457 Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457)
- [IETF draft: The Idempotency-Key HTTP header](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)
- [RFC 8594 The Sunset HTTP header](https://www.rfc-editor.org/rfc/rfc8594)
- [oasdiff](https://github.com/oasdiff/oasdiff) · [Spectral](https://github.com/stoplightio/spectral)
