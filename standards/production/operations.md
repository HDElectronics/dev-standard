---
id: OPS
title: Delivery and operations
version: 0.1.0
applies_to: deployed
based_on:
  - name: SLSA
    url: https://slsa.dev/
  - name: CycloneDX
    url: https://cyclonedx.org/
  - name: Sigstore
    url: https://www.sigstore.dev/
  - name: DORA
    url: https://dora.dev/
  - name: OpenFeature
    url: https://openfeature.dev/
---

# Delivery and operations (OPS)

How code becomes a running, recoverable service. The deploy target is not decided yet, so every rule here works on any target: services ship as OCI images, run locally and on a single VPS with Docker Compose, and move to a PaaS, Cloud Run or Kubernetes without changes to the app.

## Rules

### OPS-001 · MUST · Choose the deploy target in an ADR and manage infrastructure as code

Before the first deploy, write an ADR that picks the deploy target (for example a VPS with Docker Compose, a PaaS, Cloud Run, or Kubernetes) with its trade-offs. All infrastructure is then described in code: OpenTofu or Terraform, or the platform's own config file (`compose.yaml`, `fly.toml`, Kubernetes manifests). No manual changes in web consoles.

- **Why:** Undocumented console changes cannot be reviewed, reproduced or rolled back.
- **Check:** CI fails the first deploy job if no ADR in `docs/adr/` has the tag `deploy-target`. `tofu plan` (or the platform's dry run) runs on PRs that touch `infra/`.

### OPS-002 · MUST · Build hardened, scanned container images

Images use a pinned, minimal base (by digest), a multi-stage build, a non-root user, and a read-only root filesystem where the app allows it. Trivy scans every image in CI and blocks on fixable `HIGH` or `CRITICAL` vulnerabilities.

- **Why:** Most image vulnerabilities come from unused packages in large base images. Running as root turns an app bug into a host compromise.
- **Check:** `hadolint` on the Dockerfile, a test asserting `USER` is not root, and `trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed`.

### OPS-003 · MUST · Ship an SBOM and provenance, and sign images

Every release produces a CycloneDX SBOM and build provenance, and the image is signed with cosign. Target SLSA Build Level 2: builds run on a hosted CI service, and the provenance is generated and signed by it.

- **Why:** When the next widespread vulnerability lands, the SBOM tells you in minutes which services are affected. Signatures prove the image came from your pipeline.
- **Check:** Release workflow runs `syft <image> -o cyclonedx-json`, `cosign sign`, and attaches provenance (for example `actions/attest-build-provenance`). The deploy step verifies the signature.

### OPS-004 · MUST · Deploy through staging with a tested one-command rollback

CI builds once, deploys the same image to staging, runs smoke tests, then promotes to production by canary or blue-green where the target supports it, or a rolling restart with health checks where it doesn't. Rollback to the previous image is one command, written in the runbook, and practiced.

- **Why:** Building once removes "works in staging" surprises. A rollback nobody has run fails when it matters.
- **Check:** The deploy workflow has separate staging and production jobs with a smoke test gate. The PRR links a rollback drill from the last 90 days.

### OPS-005 · MUST · Keep secrets in a secret manager

Secrets live in a secret manager (the platform's, a cloud KMS-backed store, or SOPS-encrypted files for a single VPS), are injected at runtime, and are rotated on a schedule and after any suspected leak. No secrets in images, repos, compose files or CI logs.

- **Why:** Secrets in images and repos leak through registries, forks and backups.
- **Check:** gitleaks (SEC-001) on the repo, Trivy secret scan on the image, and `compose.yaml` uses `${VAR}` or `secrets:` only.

### OPS-006 · MUST · Back up automatically and practice restores

Databases and object storage are backed up automatically, encrypted, following 3-2-1 (three copies, two media, one off-site). RPO and RTO are written in the PRR. Restore a backup into a scratch environment at least every quarter and record the result.

- **Why:** A backup that has never been restored is a hope, not a backup.
- **Check:** PRR links the backup config and the last restore drill; CI or a scheduled job runs the restore test where the platform allows it.

### OPS-007 · MUST · Pass the production readiness review before launch

Before the first launch, fill in `docs/prr.md` from `templates/prr.md`: every MUST rule in this pack checked with evidence or covered by a waiver. A human reviews and signs it.

- **Why:** The PRR catches the gaps that each individual PR looked fine without.
- **Check:** The production deploy job fails while `docs/prr.md` is missing or its status is not `approved`.

### OPS-008 · SHOULD · Ship risky changes behind flags and track DORA metrics

Put risky or partially finished changes behind feature flags through OpenFeature, so the flag provider can change. Track the four DORA metrics: deployment frequency, lead time for changes, change failure rate, and time to restore service.

- **Why:** Flags separate deploy from release, which makes small, frequent deploys safe. DORA metrics show whether delivery is improving.
- **Check:** advisory. Flags older than 90 days are listed by a scheduled job for removal.

## Reference

### Dockerfile for FastAPI with uv (example)

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.12-slim@sha256:<pinned-digest> AS build
COPY --from=ghcr.io/astral-sh/uv:<pinned-version> /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY src ./src
RUN uv sync --frozen --no-dev

FROM python:3.12-slim@sha256:<pinned-digest>
RUN useradd --create-home --uid 10001 app
WORKDIR /app
COPY --from=build --chown=app:app /app /app
ENV PATH="/app/.venv/bin:$PATH" PYTHONUNBUFFERED=1
USER app
EXPOSE 8000
HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/livez')"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--timeout-graceful-shutdown", "20"]
```

### Compose for local and single-VPS (example)

```yaml
# compose.yaml (example)
services:
  api:
    build: .
    env_file: .env            # local only; never committed
    read_only: true
    tmpfs: [/tmp]
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }
  db:
    image: postgres:<pinned-version>
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets: [db_password]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
  redis:
    image: redis:<pinned-version>
secrets:
  db_password:
    file: ./secrets/db_password   # SOPS-decrypted at deploy, git-ignored
```

### Release supply chain (example, GitHub Actions excerpt)

```yaml
- run: trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "$IMAGE"
- run: syft "$IMAGE" -o cyclonedx-json > sbom.cdx.json
- run: cosign sign --yes "$IMAGE@$DIGEST"
- uses: actions/attest-build-provenance@<pinned-sha>
  with:
    subject-name: ${{ env.IMAGE_NAME }}
    subject-digest: ${{ env.DIGEST }}
    push-to-registry: true
```

## Sources

- [SLSA specification](https://slsa.dev/spec/)
- [CycloneDX](https://cyclonedx.org/) · [Syft](https://github.com/anchore/syft)
- [Sigstore cosign](https://docs.sigstore.dev/)
- [Trivy](https://trivy.dev/) · [hadolint](https://github.com/hadolint/hadolint)
- [DORA metrics](https://dora.dev/guides/dora-metrics-four-keys/)
- [OpenFeature](https://openfeature.dev/)
- [Google SRE book: Release Engineering](https://sre.google/sre-book/release-engineering/)
