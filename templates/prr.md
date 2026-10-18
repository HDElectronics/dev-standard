# Production readiness review: {{SERVICE_NAME}}

<!--
  dev-standard production readiness review (OPS-007), modeled on Google SRE's PRR.
  Destination: docs/prr.md. Required before the first production launch of a service with deployed: true,
  and again after a major architecture change.
  For each row: Status is pass, fail, n/a or waived. Evidence is a link (test, dashboard, config file, ADR)
  or a one-line note. "n/a" needs a reason. "waived" needs a waiver in .dev-standard.json.
  Launch requires every MUST row to be pass, n/a or waived.
-->

| | |
|---|---|
| Service | {{SERVICE_NAME}} |
| Reviewer | {{REVIEWER}} |
| Date | {{DATE}} |
| dev-standard | {{VERSION}} |
| Result | pending / approved / blocked |

## Authentication and authorization (AUTH)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| AUTH-001 | Auth uses the OIDC provider or a maintained library; no custom crypto | | | |
| AUTH-002 | Authorization code + PKCE, exact redirect URIs, no implicit or password grant | | | |
| AUTH-003 | Passwords (if any) hashed with Argon2id; NIST 800-63B length and breach checks | | | |
| AUTH-004 | Session cookies HttpOnly, Secure, SameSite; ID rotated at login; timeouts set | | | |
| AUTH-005 | Access tokens ≤ 15 min; refresh rotation with reuse detection; JWT validation per RFC 8725 | | | |
| AUTH-006 | Server-side, deny-by-default authorization with object-level checks; tests prove it | | | |
| AUTH-007 | MFA required for admin and staff accounts | | | |
| AUTH-008 | Security events written to the audit log | | | |

## Rate limiting and abuse (ABU)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| ABU-001 | Every public endpoint limited per IP and per user, shared store | | | |
| ABU-002 | Strict limits and backoff on login, signup, reset, OTP | | | |
| ABU-003 | `429` with `Retry-After` and RateLimit headers; integration test | | | |
| ABU-004 | Body, upload, page size and query time limits | | | |
| ABU-005 | CDN or WAF in front of the origin (SHOULD) | | | |

## API design (API)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| API-001 | OpenAPI 3.1 contract in `specs/*/contracts/`, matches the running service | | | |
| API-002 | Resource-oriented design, standard methods | | | |
| API-003 | Errors are RFC 9457 problem details | | | |
| API-004 | List endpoints paginate with page tokens and a max page size | | | |
| API-005 | Retried unsafe operations accept `Idempotency-Key` | | | |
| API-006 | Versioned path; deprecation policy with `Sunset` header | | | |

## Web security (WEB)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| WEB-001 | TLS everywhere; HSTS | | | |
| WEB-002 | Security headers; ZAP baseline scan clean | | | |
| WEB-003 | CORS allowlist per environment | | | |
| WEB-004 | CSRF protection for cookie-authenticated writes | | | |
| WEB-005 | Parameterized queries; SSRF allowlist | | | |
| WEB-006 | ASVS level met (L1, or L2 with personal data) | | | |

## Scaling and reliability (REL)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| REL-001 | Twelve-factor: env config, stateless, stdout logs, graceful SIGTERM | | | |
| REL-002 | `/livez` and `/readyz` wired to the platform | | | |
| REL-003 | Timeouts on every outbound call; safe retries; circuit breakers | | | |
| REL-004 | Pooled connections; versioned expand/contract migrations | | | |
| REL-005 | Every query path indexed; no unbounded queries | | | |
| REL-006 | Background work on a queue with DLQ (SHOULD) | | | |
| REL-007 | Caches have TTL and invalidation owner (SHOULD) | | | |
| REL-008 | k6 load test result against the SLO | | | |
| REL-009 | Autoscaling and load shedding plan (SHOULD) | | | |

## Observability (OBS)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| OBS-001 | OpenTelemetry traces, metrics, logs; trace context propagated | | | |
| OBS-002 | SLOs per user-facing endpoint; burn-rate alerts | | | |
| OBS-003 | Golden-signal dashboard | | | |
| OBS-004 | Every alert links a runbook | | | |
| OBS-005 | Postmortem process agreed (SHOULD) | | | |

## Delivery and operations (OPS)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| OPS-001 | Infrastructure as code; no console changes | | | |
| OPS-002 | Pinned minimal image, non-root, Trivy clean on high and critical | | | |
| OPS-003 | SBOM, provenance and signed images | | | |
| OPS-004 | Staging, canary or blue-green; rollback tested (link the drill) | | | |
| OPS-005 | Secrets from a secret manager; rotation schedule | | | |
| OPS-006 | Encrypted 3-2-1 backups; restore drill done; RPO and RTO written | | | |
| OPS-008 | Feature flags for risky changes; DORA metrics tracked (SHOULD) | | | |

## Data and privacy (DAT)

| Rule | Check | Status | Owner | Evidence |
|------|-------|--------|-------|----------|
| DAT-001 | Every field classified in `data-model.md` | | | |
| DAT-002 | Encryption in transit and at rest; field-level for sensitive data | | | |
| DAT-003 | Retention per data class, enforced by a job | | | |
| DAT-004 | User data export and deletion where the law requires it | | | |
| DAT-005 | Logger redacts personal data, tokens and secrets | | | |

## Launch decision

- Blocking items: {{LIST}}
- Accepted risks, with waiver IDs: {{LIST}}
- Next review date: {{DATE}}
