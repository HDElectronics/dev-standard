---
id: PROD
title: Production pack
version: 0.1.0
applies_to: deployed
based_on:
  - name: Google SRE books (production readiness review)
    url: https://sre.google/books/
  - name: OWASP ASVS 5.0
    url: https://owasp.org/www-project-application-security-verification-standard/
  - name: The Twelve-Factor App
    url: https://12factor.net/
---

# Production pack

Rules for any service that will be deployed and reached by real users. The pack applies when `.dev-standard.json` sets `"deployed": true`. It adds runtime rules on top of the security baseline (SEC), which applies to every repo.

## Groups

| Prefix | File | Covers |
|--------|------|--------|
| AUTH | [auth.md](auth.md) | Authentication, sessions, tokens, authorization |
| ABU | [abuse.md](abuse.md) | Rate limits, request limits, brute-force protection |
| API | [api.md](api.md) | Resource design, contracts, errors, pagination, idempotency |
| WEB | [web-security.md](web-security.md) | TLS, headers, CORS, CSRF, injection, SSRF |
| REL | [reliability.md](reliability.md) | Twelve-factor, health, timeouts, retries, databases, scaling |
| OBS | [observability.md](observability.md) | OpenTelemetry, SLOs, alerts, runbooks |
| OPS | [operations.md](operations.md) | Deploy target, images, supply chain, secrets, backups |
| DAT | [data.md](data.md) | Data classes, encryption, retention, user rights |

## Decided defaults

These defaults hold unless an ADR in `docs/adr/` says otherwise.

| Concern | Default | Alternatives (need an ADR) |
|---------|---------|----------------------------|
| Backend | FastAPI, Python 3.12+, Pydantic v2, SQLAlchemy 2 + Alembic, managed with uv | — |
| Identity provider | Keycloak (free, open source, CNCF project, one Docker container) | Zitadel, Authentik, a managed free tier |
| Browser auth pattern | FastAPI as backend-for-frontend: runs the OIDC code flow, sets an HttpOnly session cookie | — |
| Service-to-service auth | JWT access tokens validated against Keycloak's JWKS | mTLS inside a mesh |
| Rate limit store | Redis | — |
| Packaging | One OCI image per service, Dockerfile + `compose.yaml` | — |
| Deploy target | **Not decided.** Container-first, so a VPS, a PaaS, Cloud Run or Kubernetes all work. OPS-001 requires the ADR before the first deploy. | — |
| Telemetry | OpenTelemetry SDK, OTLP export | — |

## Production readiness review

Before the first launch, and before any launch that changes the architecture, the project fills in `templates/prr.md` (copied to `docs/prr.md`). Modeled on Google SRE's production readiness review, it is a checklist of every MUST rule in this pack. Each row is either checked with evidence (a link to a test, config or dashboard) or covered by a waiver in `.dev-standard.json`. OPS-007 makes passing it a launch gate.

## Sources

- [Google SRE books](https://sre.google/books/)
- [OWASP ASVS 5.0](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP API Security Top 10](https://owasp.org/API-Security/)
- [The Twelve-Factor App](https://12factor.net/)
