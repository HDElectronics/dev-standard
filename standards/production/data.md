---
id: DAT
title: Data and privacy
version: 0.1.0
applies_to: deployed
based_on:
  - name: OWASP ASVS 5.0 (data protection chapters)
    url: https://owasp.org/www-project-application-security-verification-standard/
  - name: GDPR
    url: https://eur-lex.europa.eu/eli/reg/2016/679/oj
  - name: Local data protection law
---

# Data and privacy (DAT)

What data a service holds, how it is protected, how long it is kept, and how users get it back or removed. GDPR is the reference when EU residents are users; apply the local data protection law of every country you serve as well, and record which laws apply in the PRR.

## Rules

### DAT-001 · MUST · Classify every stored field

`data-model.md` in the spec folder classifies every field as `public`, `internal`, `personal` or `sensitive`. Personal data identifies a person (name, email, IP address). Sensitive data is personal data whose leak causes serious harm (government IDs, health, payment details, precise location, credentials).

- **Why:** You cannot protect, retain or delete data correctly without knowing what it is.
- **Check:** `/speckit.analyze` and the reviewer flag new model fields missing from `data-model.md`. A CI script compares SQLAlchemy model columns with the classification table and fails on unclassified columns.

### DAT-002 · MUST · Encrypt in transit, at rest, and per field for sensitive data

All data is encrypted in transit (WEB-001) and at rest (disk or managed database encryption). Sensitive fields also get application-level encryption with keys held in the secret manager (OPS-005), or are not stored at all. Payment card data stays with the payment provider.

- **Why:** Disk encryption does not help against a stolen database dump or an over-broad query. Field encryption does.
- **Check:** PRR records the at-rest encryption setting. A unit test asserts that sensitive columns are stored as ciphertext (the raw column value differs from the input).

### DAT-003 · MUST · Set and enforce a retention period per data class

Each data class and each table with personal data has a retention period, written in `data-model.md`. A scheduled job deletes or anonymizes data past its period, including in logs and analytics. Backups expire on the same schedule.

- **Why:** Data you no longer hold cannot leak. GDPR's storage-limitation principle requires it.
- **Check:** The retention job exists, has tests, and its last successful run is visible in monitoring. PRR lists the periods.

### DAT-004 · MUST · Let users export and delete their data where the law requires

Where GDPR or local law applies, users can export their personal data in a machine-readable format and request deletion. Deletion covers the primary database, caches, search indexes and third-party processors, within the legal deadline (one month under GDPR).

- **Why:** These are legal rights, and handling them by hand does not scale or get audited.
- **Check:** Integration test creates a user with data in every store, runs export and delete, and asserts the export is complete and every store is empty afterwards.

### DAT-005 · MUST NOT · Log personal data, tokens or secrets

Logs, traces and error reports never contain personal data, tokens, passwords or secrets. The logger redacts a known list of field names, and request and response bodies are not logged by default.

- **Why:** Logs are copied widely, kept long, and readable by many people, which makes them the most common source of data leaks.
- **Check:** structlog processor that redacts keys such as `password`, `token`, `authorization`, `cookie`, `email`, with a unit test. Semgrep rule flags logging of `request.body` and `Authorization` headers.

## Reference

### Classification table in data-model.md (example)

```markdown
## Data classification

| Table.column | Class | Retention | Notes |
|--------------|-------|-----------|-------|
| users.id | internal | account lifetime | |
| users.email | personal | account lifetime + 30 days | login identifier |
| users.phone | personal | account lifetime + 30 days | |
| orders.shipping_address | personal | 10 years | tax law |
| orders.total | internal | 10 years | |
| payment_tokens.token | sensitive | until card removed | provider token, field-encrypted |
| audit_log.ip | personal | 1 year | security (AUTH-008) |
```

### Redacting logger (example, structlog)

```python
# app/logging.py (example)
import structlog

REDACTED_KEYS = {"password", "token", "access_token", "refresh_token",
                 "authorization", "cookie", "set-cookie", "email", "phone"}


def redact(_, __, event_dict: dict) -> dict:
    for key in list(event_dict):
        if key.lower() in REDACTED_KEYS:
            event_dict[key] = "[REDACTED]"
    return event_dict


structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        redact,
        structlog.processors.JSONRenderer(),
    ]
)
```

## Sources

- [OWASP ASVS 5.0](https://owasp.org/www-project-application-security-verification-standard/)
- [GDPR (Regulation (EU) 2016/679)](https://eur-lex.europa.eu/eli/reg/2016/679/oj)
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
