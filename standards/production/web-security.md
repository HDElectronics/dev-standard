---
id: WEB
title: Web security
version: 0.1.0
applies_to: deployed
based_on:
  - name: OWASP ASVS 5.0
    url: https://owasp.org/www-project-application-security-verification-standard/
  - name: OWASP Secure Headers Project
    url: https://owasp.org/www-project-secure-headers/
  - name: OWASP Cheat Sheet Series
    url: https://cheatsheetseries.owasp.org/
---

# Web security (WEB)

Transport, browser and injection defenses for anything reachable over HTTP. The OWASP Application Security Verification Standard (ASVS) is the yardstick: Level 1 for every deployed service, Level 2 for anything that stores personal data.

## Rules

### WEB-001 · MUST · Use TLS everywhere, with HSTS

Serve all traffic over HTTPS, redirect HTTP to HTTPS, and send `Strict-Transport-Security: max-age=31536000; includeSubDomains`. Internal service traffic is encrypted too, unless it stays on a private network recorded in the deploy-target ADR.

- **Why:** Without TLS, cookies and tokens travel in plaintext. HSTS stops downgrade attacks after the first visit.
- **Check:** ZAP baseline scan in CI against the staging URL. `testssl.sh` or the SSL Labs grade (A or better) recorded in the PRR.

### WEB-002 · MUST · Send the OWASP recommended security headers

Send at least: a `Content-Security-Policy` with no `unsafe-inline` for scripts, `X-Content-Type-Options: nosniff`, `frame-ancestors 'none'` (in the CSP) or a narrow allowlist, `Referrer-Policy: strict-origin-when-cross-origin`, and a restrictive `Permissions-Policy`.

- **Why:** These headers turn many XSS, clickjacking and data-leak bugs into non-exploitable ones.
- **Check:** ZAP baseline scan blocks on missing headers. A FastAPI middleware test asserts the headers on a sample response.

### WEB-003 · MUST · Use a CORS allowlist, never a wildcard with credentials

Configure CORS with an explicit list of origins per environment. Never combine `Access-Control-Allow-Origin: *` with credentials, and never reflect the request's `Origin` without checking it against the list. With the BFF pattern on the same site, CORS is usually not needed at all.

- **Why:** A permissive CORS policy lets any website make authenticated requests as your user.
- **Check:** Unit test of the CORS config: a request from an unlisted origin gets no `Access-Control-Allow-Origin`. Lint rule rejects `allow_origins=["*"]` together with `allow_credentials=True`.

### WEB-004 · MUST · Protect cookie-authenticated changes against CSRF

Every state-changing request authenticated by a cookie is protected by `SameSite` cookies plus either a synchronizer or double-submit token, or Fetch Metadata checks (reject cross-site `Sec-Fetch-Site` on unsafe methods).

- **Why:** `SameSite=Lax` alone still allows some cross-site requests (top-level `GET`, older browsers). A second layer closes them.
- **Check:** Integration test sends a `POST` with `Sec-Fetch-Site: cross-site` and no token, and expects `403`.

### WEB-005 · MUST · Parameterize queries and allowlist outbound requests

Database access uses SQLAlchemy bound parameters; never build SQL with string formatting. Outbound HTTP requests whose URL or host comes from user input go through an allowlist and refuse private, loopback and link-local addresses.

- **Why:** Injection and server-side request forgery (SSRF) remain in the OWASP Top 10 and give attackers database or internal network access.
- **Check:** Semgrep rules (SEC-006) for `text(f"...")`, `execute(f"...")` and `%`-formatted SQL. Unit test of the outbound client with `http://169.254.169.254/` and `http://localhost/` expects refusal.

### WEB-006 · MUST · Meet OWASP ASVS Level 1, and Level 2 with personal data

Every deployed service meets ASVS Level 1. Any service that stores personal data (DAT-001) meets Level 2. Record the verification in the PRR, one row per ASVS chapter, with evidence or a waiver.

- **Why:** ASVS is a complete, testable checklist; this pack covers the most common items but not all of them.
- **Check:** PRR section "ASVS" filled in, reviewed before launch (OPS-007).

## Reference

### Security headers middleware for FastAPI (example)

```python
# app/security_headers.py (example)
from starlette.middleware.base import BaseHTTPMiddleware

CSP = (
    "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; "
    "connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
)

HEADERS = {
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "Content-Security-Policy": CSP,
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
}


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        for name, value in HEADERS.items():
            response.headers.setdefault(name, value)
        return response
```

Set the same headers on the static frontend at the reverse proxy or CDN, since the SPA's HTML is usually not served by FastAPI.

### CORS (example)

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allowed_origins,  # e.g. ["https://app.example.com"]
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Content-Type", "Idempotency-Key", "X-CSRF-Token"],
)
```

### ZAP baseline scan in CI (example, GitHub Actions)

```yaml
- name: ZAP baseline scan
  uses: zaproxy/action-baseline@<pinned-sha>
  with:
    target: ${{ vars.STAGING_URL }}
    rules_file_name: .zap/rules.tsv
```

## Sources

- [OWASP ASVS 5.0](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [OWASP SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
- [OWASP Query Parameterization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Query_Parameterization_Cheat_Sheet.html)
- [OWASP ZAP baseline scan](https://www.zaproxy.org/docs/docker/baseline-scan/)
