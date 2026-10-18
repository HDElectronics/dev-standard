<!--
  dev-standard ADDITIONS to Spec Kit's plan template.
  Merge these into the .specify/templates/plan-template.md that `specify init` generated.
  Keep every Spec Kit section (Summary, Technical Context, Constitution Check, Project Structure, ...)
  and its placeholders. Add the sections below after "Technical Context". Rules: SDD-004, API-001, REL-005.
  Section structure follows "Design Docs at Google": https://www.industrialempathy.com/posts/design-docs-at-google/
-->

## Context and scope

[What exists today and the part of the system this change touches. Link the spec and brainstorm record. A C4 context or container diagram in Mermaid when more than one service is involved (DOC-006).]

## Goals and non-goals

**Goals**
- [Measurable outcome, usually from the spec's success criteria]

**Non-goals**
- [Copied from the spec's Non-goals]

## Design

### Overview
[The approach in a few paragraphs. Focus on trade-offs, not on code.]

### API
[Endpoints or interfaces. For HTTP APIs, the contract is `contracts/<name>.yaml` (OpenAPI 3.1) and is reviewed with this plan (API-001).]

### Data
[Schema changes, in `data-model.md`. Every field has a data class: public, internal, personal or sensitive (DAT-001). Migrations follow expand and contract (REL-004).]

### Query paths and indexes
| Query | Index | Expected rows |
|-------|-------|---------------|
| [e.g. orders by user, newest first] | [e.g. `orders(user_id, created_at desc)`] | [bounded by page size] |

## Related decisions

<!-- ADR-008: accepted ADRs this plan relies on, and new ADRs it proposes (status: proposed). -->
- Relies on: [ADR-NNNN title](../../docs/adr/NNNN-slug.md)
- Proposes: [ADR-NNNN title](../../docs/adr/NNNN-slug.md)

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| [Option] | [Reason] |

## Cross-cutting concerns

<!-- Answer every line. Write "n/a" with a reason when something does not apply. -->

- [ ] **Security**: ASVS level [1 or 2] (WEB-006). New trust boundaries and how input is validated (SEC-003).
- [ ] **Authorization**: who may call each operation; object-level ownership checks (AUTH-006).
- [ ] **Abuse**: rate limit per endpoint, per IP and per user (ABU-001, ABU-002); size and page limits (ABU-004).
- [ ] **Privacy**: personal and sensitive fields touched, retention, export and deletion (DAT-001 to DAT-004).
- [ ] **Reliability**: timeouts, retries, idempotency keys for retried writes (REL-003, API-005).
- [ ] **Observability**: SLO for each new user-facing endpoint, spans, metrics, alerts and runbooks (OBS-002, OBS-004).
- [ ] **Performance**: frontend Core Web Vitals impact (UI-008), load test needed (REL-008).
- [ ] **Accessibility**: new UI meets WCAG 2.2 AA (UI-007).

## Rollout and rollback

- **Rollout**: [feature flag, canary, migration order]
- **Rollback**: [exact steps or command; what happens to data written by the new version]
- **Launch gate**: [PRR items this change must satisfy, if deployed]
