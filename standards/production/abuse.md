---
id: ABU
title: Rate limiting and abuse
version: 0.1.0
applies_to: deployed
based_on:
  - name: "OWASP API Security Top 10: API4:2023 Unrestricted Resource Consumption"
    url: https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/
  - name: RFC 6585 (429 Too Many Requests)
    url: https://www.rfc-editor.org/rfc/rfc6585
  - name: IETF RateLimit header fields draft
    url: https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/
---

# Rate limiting and abuse (ABU)

Every public service is a target for scraping, credential stuffing and accidental overload. Limits live in two places: the reverse proxy (coarse, per IP, cheap) and the application (precise, per user or API key, shared through Redis).

## Rules

### ABU-001 · MUST · Rate limit every public endpoint per client and per user

Every public endpoint has a limit per client IP and, once authenticated, per user or API key. Use a token bucket or sliding window kept in a shared store (Redis), never in process memory.

- **Why:** In-memory counters reset on restart and multiply by the number of replicas, so the real limit is unknown.
- **Check:** Integration test sends limit+1 requests and expects `429`. A route test fails if a route has neither a limit decorator nor an explicit exemption.

### ABU-002 · MUST · Apply strict limits and lockout to auth routes

Login, signup, password reset, MFA and OTP routes get much stricter limits, counted both per account and per IP. Repeated failures trigger exponential backoff on that account. With Keycloak, enable its brute-force detection; for app-owned auth routes, apply the same in the app.

- **Why:** These routes are the target of credential stuffing and enumeration. Per-account counting stops distributed attacks that rotate IPs.
- **Check:** Keycloak realm export has `bruteForceProtected: true`. Integration test: 6 failed logins in a minute on one account return `429` even from different IPs.

### ABU-003 · MUST · Return 429 with Retry-After

Over-limit requests get `429 Too Many Requests` with a `Retry-After` header, and an RFC 9457 problem body (API-003). Responses also send the IETF `RateLimit` and `RateLimit-Policy` headers so clients can slow down before they hit the limit.

- **Why:** Well-behaved clients and SDKs back off correctly only when told when to retry.
- **Check:** Same integration test as ABU-001 asserts `Retry-After` and the problem `type`.

### ABU-004 · MUST · Limit request size, uploads, page size and query time

Set maximum sizes for request bodies and uploads (with an allowlist of content types checked by content, not just extension), a maximum page size for lists (API-004), and a statement timeout for database queries.

- **Why:** Unbounded inputs let one request exhaust memory, disk or database time (OWASP API4).
- **Check:** Reverse proxy config (`client_max_body_size` or equivalent) committed in `infra/`. Integration tests send an oversized body (`413`) and `page_size=100000` (clamped or `400`). Database URL or session sets `statement_timeout`.

### ABU-005 · SHOULD · Put a CDN or WAF in front, with CAPTCHA only after failures

Place a CDN or web application firewall in front of the origin to absorb volumetric traffic. Show a CAPTCHA only after repeated failures, not to every user.

- **Why:** The app cannot defend itself against traffic that saturates its network. CAPTCHA for everyone hurts conversion and accessibility.
- **Check:** advisory. Recorded in the deploy-target ADR and the PRR.

## Reference

### Default limits

Starting points; tune them from real traffic.

| Route class | Per IP | Per user / key |
|-------------|--------|----------------|
| Public read | 300 / min | 600 / min |
| Writes | 60 / min | 120 / min |
| Login, reset, OTP | 10 / min | 5 / min, backoff after 5 failures |
| Signup | 5 / hour | — |
| Expensive (search, export, import) | 20 / min | 30 / min |

### FastAPI with slowapi and Redis (example)

```python
# app/limits.py (example)
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings


def client_key(request) -> str:
    user = getattr(request.state, "user_id", None)
    return f"user:{user}" if user else f"ip:{get_remote_address(request)}"


limiter = Limiter(
    key_func=client_key,
    storage_uri=settings.redis_url,      # shared store, not memory (ABU-001)
    headers_enabled=True,                # emits rate limit and Retry-After headers
    default_limits=["300/minute"],
)
```

```python
# app/main.py (example)
from fastapi import FastAPI, Request
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.limits import limiter
from app.errors import problem_response

app = FastAPI()
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)


@app.exception_handler(RateLimitExceeded)
async def on_rate_limited(request: Request, exc: RateLimitExceeded):
    return problem_response(
        status=429,
        type_="https://errors.example.com/rate-limited",
        title="Too many requests",
        headers={"Retry-After": "60"},
    )
```

```python
# app/routes/auth.py (example)
@router.post("/password-reset")
@limiter.limit("5/minute")
async def request_password_reset(request: Request, body: ResetRequest): ...
```

`get_remote_address` reads the socket address. Behind a proxy, run Uvicorn with `--proxy-headers` and `--forwarded-allow-ips` set to the proxy's address so the real client IP is used, and never trust `X-Forwarded-For` from the open internet.

### Reverse proxy limit (example, nginx)

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
client_max_body_size 5m;

server {
  location /api/ {
    limit_req zone=api burst=20 nodelay;
    limit_req_status 429;
    proxy_pass http://api:8000;
  }
}
```

## Sources

- [OWASP API4:2023 Unrestricted Resource Consumption](https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/)
- [OWASP Credential Stuffing Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Credential_Stuffing_Prevention_Cheat_Sheet.html)
- [RFC 6585: 429 Too Many Requests](https://www.rfc-editor.org/rfc/rfc6585)
- [IETF draft: RateLimit header fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/)
- [slowapi](https://github.com/laurentS/slowapi)
