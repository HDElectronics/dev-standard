---
id: OBS
title: Observability
version: 0.1.0
applies_to: deployed
based_on:
  - name: OpenTelemetry
    url: https://opentelemetry.io/
  - name: W3C Trace Context
    url: https://www.w3.org/TR/trace-context/
  - name: "Google SRE books: SLOs, alerting, golden signals"
    url: https://sre.google/books/
---

# Observability (OBS)

You need to know a service is broken before users tell you, and to find out why quickly. Telemetry uses OpenTelemetry so the backend (Grafana stack, SigNoz, a cloud vendor) can change without touching code. Reliability targets follow Google SRE practice: SLOs and error budgets, alerts on symptoms.

## Rules

### OBS-001 · MUST · Instrument with OpenTelemetry and propagate trace context

Emit traces, metrics and logs with the OpenTelemetry SDK and export over OTLP. Propagate W3C Trace Context (`traceparent`) across every HTTP call and queue message. Every log line carries `trace_id` and `span_id`.

- **Why:** One standard keeps the vendor swappable, and shared trace IDs let you jump from a log line to the full request.
- **Check:** Integration test: a request with a `traceparent` header produces log lines containing the same trace ID. Startup fails if `OTEL_EXPORTER_OTLP_ENDPOINT` is unset outside local mode.

### OBS-002 · MUST · Define SLOs and alert on error-budget burn

Each user-facing endpoint group has an availability SLO and a latency SLO (for example 99.5% of requests succeed, 95% complete under 300 ms, over 28 days), recorded in `docs/slo.md`. Alerts fire on error-budget burn rate (multi-window, multi-burn-rate), not on CPU, memory or single errors.

- **Why:** Cause-based alerts page people for things users never notice and miss the things they do. Burn-rate alerts page only when the SLO is at risk.
- **Check:** `docs/slo.md` exists and is referenced in the PRR. Alert rules are committed as code (`infra/alerts/`) and reviewed.

### OBS-003 · MUST · Show the four golden signals

Each service has a dashboard with latency (p50, p95, p99), traffic (requests per second), errors (rate and ratio), and saturation (CPU, memory, connection pool, queue depth).

- **Why:** These four signals answer "is it broken, and is it about to be" for almost any service.
- **Check:** Dashboard committed as code (`infra/dashboards/`) and linked in the PRR.

### OBS-004 · MUST · Link a runbook from every alert

Every alert has a runbook in `docs/runbooks/` (from `templates/runbook.md`) with what the alert means, how to confirm it, how to mitigate it, and who to escalate to. The alert's annotations link to it.

- **Why:** At 3 a.m. the person paged is not the person who wrote the alert.
- **Check:** CI script parses `infra/alerts/` and fails if an alert lacks a `runbook_url` annotation or the linked file is missing.

### OBS-005 · SHOULD · Write a blameless postmortem for user-facing incidents

After every incident that users noticed, write a blameless postmortem within five working days: timeline, impact, root causes, what went well, and action items with owners. Store it in `docs/postmortems/`.

- **Why:** Incidents repeat unless the system, not the person, changes.
- **Check:** advisory.

## Reference

### OpenTelemetry for FastAPI (example)

Packages: `opentelemetry-sdk`, `opentelemetry-exporter-otlp`, `opentelemetry-instrumentation-fastapi`, `opentelemetry-instrumentation-sqlalchemy`, `opentelemetry-instrumentation-httpx`.

```python
# app/telemetry.py (example)
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor


def setup_telemetry(app, engine, service_name: str) -> None:
    provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))  # reads OTEL_EXPORTER_OTLP_ENDPOINT
    trace.set_tracer_provider(provider)

    FastAPIInstrumentor.instrument_app(app, excluded_urls="livez,readyz")
    SQLAlchemyInstrumentor().instrument(engine=engine.sync_engine)
    HTTPXClientInstrumentor().instrument()
```

The zero-code alternative is `opentelemetry-instrument uvicorn app.main:app`, configured through `OTEL_*` environment variables.

### SLO file (example)

```markdown
# docs/slo.md

| Endpoint group | SLI | Target | Window |
|----------------|-----|--------|--------|
| Checkout API   | Share of non-5xx responses | 99.5% | 28 days |
| Checkout API   | Share of responses under 300 ms | 95% | 28 days |
| Catalog reads  | Share of non-5xx responses | 99.9% | 28 days |
```

### Burn-rate alert (example, Prometheus rule)

```yaml
- alert: CheckoutErrorBudgetFastBurn
  expr: |
    (sum(rate(http_server_errors_total{route=~"/v1/orders.*"}[1h]))
      / sum(rate(http_server_requests_total{route=~"/v1/orders.*"}[1h]))) > (14.4 * 0.005)
    and
    (sum(rate(http_server_errors_total{route=~"/v1/orders.*"}[5m]))
      / sum(rate(http_server_requests_total{route=~"/v1/orders.*"}[5m]))) > (14.4 * 0.005)
  labels: { severity: page }
  annotations:
    runbook_url: https://github.com/org/repo/blob/main/docs/runbooks/checkout-errors.md
```

Metric names depend on your exporter; the 14.4× factor over 1 h and 5 min is the SRE Workbook's fast-burn page for a 28 to 30 day window.

## Sources

- [OpenTelemetry Python](https://opentelemetry.io/docs/languages/python/)
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
- [Google SRE book: Monitoring Distributed Systems (golden signals)](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Google SRE Workbook: Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- [Google SRE book: Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
