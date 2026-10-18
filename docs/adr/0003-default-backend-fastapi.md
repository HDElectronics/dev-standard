---
status: proposed
date: 2026-10-18
decision-makers: Ibrahim Khadraoui
consulted: ""
informed: ""
---

# Default backend stack: FastAPI

## Context and Problem Statement

Profiles need one default backend so rules, configs and examples are concrete. Which one?

## Decision Drivers

* The owner's preference
* Typed, OpenAPI-first APIs (API-001)
* Mature tooling: uv, ruff, pyright, pytest

## Considered Options

* FastAPI (Python 3.12+, Pydantic v2, SQLAlchemy 2, Alembic)
* TypeScript (Hono or Fastify) sharing Zod schemas with React

## Decision Outcome

Chosen option: "FastAPI", because the owner chose it, and FastAPI generates the OpenAPI schema that the React client is generated from (UI-005).

### Consequences

* Good, because one contract (OpenAPI) links backend and frontend
* Bad, because validation schemas are not shared directly with React; the generated client and CI diff replace that
