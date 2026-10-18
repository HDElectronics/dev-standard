# Runbook: {{ALERT_NAME}}

<!--
  dev-standard runbook template (OBS-004). Destination: docs/runbooks/<alert-name>.md.
  Every alert links its runbook. Write for someone paged at 3 a.m. who has never seen this service.
-->

| | |
|---|---|
| Service | {{SERVICE_NAME}} |
| Alert | `{{ALERT_NAME}}` |
| Severity | page / ticket |
| SLO | {{SLO, e.g. 99.5% of GET /v1/carts under 300 ms over 28 days}} |
| Owner | {{TEAM_OR_PERSON}} |
| Last reviewed | {{DATE}} |

## Alert

What fires this alert, in one sentence, and the exact condition:

```
{{alert expression, e.g. error-budget burn rate > 14.4 over 1 h and 5 m windows}}
```

## Impact

Who is affected and how, when this alert is real. What users see.

## Diagnosis

1. Open the dashboard: {{DASHBOARD_URL}}
2. Check the golden signals (latency, traffic, errors, saturation) for the time of the alert.
3. Check recent deploys and flag changes: {{COMMAND_OR_URL}}
4. Check dependencies: {{DATABASE, CACHE, QUEUE, OIDC PROVIDER}} health.
5. Find failing requests by trace: {{QUERY}}

Common causes:

| Symptom | Likely cause | Go to |
|---------|--------------|-------|
| {{Errors started right after a deploy}} | {{Bad release}} | Mitigation 1 |
| {{Latency up, database CPU at 100%}} | {{Missing index or traffic spike}} | Mitigation 2 |

## Mitigation

Stop the user impact first; find the root cause later.

1. **Roll back the last release:** `{{ROLLBACK_COMMAND}}`
2. **Shed load or disable the feature:** `{{FLAG_OR_COMMAND}}`
3. **Scale out:** `{{SCALE_COMMAND}}`

After mitigating, confirm the alert clears and the SLI recovers on the dashboard.

## Escalation

| When | Who | How |
|------|-----|-----|
| Not mitigated in {{30}} minutes | {{NAME_OR_ROTATION}} | {{CHANNEL}} |
| Data loss or security incident suspected | {{NAME}} | {{CHANNEL}} |

## After the incident

Open a postmortem (OBS-005) if users were affected. Link it here.
