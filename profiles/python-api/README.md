# Profile: python-api

For FastAPI backends. Python 3.12 or later, managed with [uv](https://docs.astral.sh/uv/).

## Stack

| Concern | Tool |
|---------|------|
| Framework | FastAPI, Pydantic v2, pydantic-settings |
| Database | SQLAlchemy 2, Alembic migrations (REL-004) |
| Format, lint | ruff (STY-001, NAM-001, STY-003) |
| Types | pyright strict (STY-002) |
| Tests | pytest, pytest-cov, httpx, diff-cover (TST-002, TST-003) |
| Auth | Keycloak (OIDC) with the API as backend-for-frontend; see `standards/production/auth.md` |
| Telemetry | OpenTelemetry (OBS-001), when `deployed: true` |

## New project

```bash
uv init --app --python 3.12
uv add "fastapi[standard]" pydantic-settings sqlalchemy alembic
uv add --dev ruff pyright pytest pytest-cov diff-cover httpx
```

Then merge `pyproject.fragment.toml` into `pyproject.toml`.

## Existing project

Merge `pyproject.fragment.toml` table by table (profiles/README.md). If the repo uses mypy, black or flake8, keep them during install and record the difference in the adoption report.

## Commands

```bash
uv run fastapi dev app/main.py                 # run locally
uv run ruff format . && uv run ruff check .    # format and lint
uv run pyright                                 # type check
uv run pytest -m small                         # fast suite (checks.fast)
uv run pytest --cov --cov-report=xml           # full suite with coverage
uv run diff-cover coverage.xml --compare-branch=origin/main --fail-under=80   # TST-003
```

A good `checks.fast` value for `.dev-standard.json`:

```bash
uv run ruff format --check . && uv run ruff check . && uv run pyright && uv run pytest -m small -q
```

## Layout

Feature folders, matching the frontend's `src/features/` (UI-006).

```
app/
├── main.py              # create_app(): routers, middleware, exception handlers
├── core/
│   ├── config.py        # Settings(BaseSettings), env prefix APP_ (NAM-007, REL-001)
│   ├── security.py      # OIDC login, session cookie, current_user dependency
│   ├── errors.py        # RFC 9457 problem details handlers (API-003)
│   └── telemetry.py     # OpenTelemetry setup (OBS-001)
├── db/
│   └── session.py       # engine, pooled sessions (REL-004)
├── <feature>/
│   ├── router.py        # HTTP layer only
│   ├── schemas.py       # Pydantic request and response models (SEC-003)
│   ├── service.py       # business logic, no FastAPI imports (STY-006)
│   ├── repository.py    # database access, parameterized queries (WEB-005)
│   └── models.py        # SQLAlchemy models
└── health.py            # /livez and /readyz (REL-002)
migrations/              # Alembic
tests/
├── small/               # @pytest.mark.small
├── medium/
└── large/
```

## API types for the frontend

FastAPI serves its OpenAPI 3.1 schema at `/openapi.json`. The `react-web` profile generates TypeScript types from it (UI-005). Keep response models explicit (`response_model=` or return annotations) so the schema is complete. For contract-first work (API-001), the spec's `contracts/*.yaml` is the source and a contract test checks the running app against it.
