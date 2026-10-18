---
id: SDD
title: Spec-driven development
version: 0.1.0
applies_to: all
based_on:
  - name: GitHub Spec Kit
    url: https://github.com/github/spec-kit
  - name: EARS (Easy Approach to Requirements Syntax)
    url: https://alistairmavin.com/ears/
  - name: Design docs at Google
    url: https://www.industrialempathy.com/posts/design-docs-at-google/
---

# Spec-driven development (SDD)

The second diamond of the workflow: specify, plan and build the direction chosen in the brainstorm (`BRN`). dev-standard uses [GitHub Spec Kit](https://github.com/github/spec-kit) as is, for its commands and folder layout. It adds three things on top: EARS for requirements, Google design-doc sections in `plan.md`, and gates enforced by hooks.

## Rules

### SDD-001 · MUST · No source edits on a feature branch until the spec is approved

On a feature branch named `NNN-slug` (Spec Kit's convention), source files are not edited until `specs/NNN-slug/spec.md` contains `**Status**: Approved`. You set that status after Clarify; the agent does not.

- **Why:** Approval is the point where you confirm the agent understood the problem. Code before that point is often thrown away.
- **Check:** `require-spec.sh` (PreToolUse hook) blocks edits under `src/` and exits with code 2 and the message `SDD-001: spec NNN is not approved.` In CI, `dev-standard check spec` blocks PRs that change source files from a `NNN-` branch whose spec is not approved.

### SDD-002 · MUST · Write functional requirements in EARS

Each functional requirement uses one of the five EARS patterns (see Reference), for example `WHEN <trigger> THE SYSTEM SHALL <response>`.

- **Why:** EARS removes the most common ambiguities in natural-language requirements (missing trigger, missing actor, vague response) and makes each requirement directly testable.
- **Check:** Advisory. `/speckit.analyze` and the reviewer check requirement wording; a CI lint for the `SHALL` keyword can be added later.

### SDD-003 · MUST · Reference every requirement ID in at least one test

Requirement IDs are `FR-NNN` inside a spec. Tests reference them qualified by the spec number, as `013/FR-002`, in the test name, a marker or a docstring.

- **Why:** The reference makes the traceability table in `tasks.md` checkable and shows which requirements have no test.
- **Check:** `dev-standard check trace` lists the FR IDs of every spec with `**Status**: Implemented` that no test file references, so setting a spec to Implemented (Verify) fails until each requirement has a test.

```python
@pytest.mark.req("013/FR-002")
def test_unmatched_line_lists_three_suggestions() -> None: ...
```

```ts
it("lists up to 3 suggestions for an unmatched line [013/FR-002]", () => { ... });
```

### SDD-004 · MUST · Include Google design-doc sections in plan.md

`plan.md` keeps Spec Kit's sections and adds: context and scope, goals and non-goals, design, alternatives considered, and cross-cutting concerns (security, abuse, privacy, observability).

- **Why:** Spec Kit's plan focuses on technical context and structure. The design-doc sections force the trade-offs and the "why not the other way" into writing before code.
- **Check:** Advisory. The plan template contains the sections; review checks they are filled.

### SDD-005 · MUST · Pass /speckit.analyze before implementation

Run `/speckit.analyze` after `/speckit.tasks`. Implementation starts only when it reports no critical issues.

- **Why:** Analyze cross-checks spec, plan and tasks for gaps and contradictions, such as a requirement with no task or a task with no requirement.
- **Check:** Advisory. The PR description states the analyze result.

### SDD-006 · MUST · Send scope changes back through Clarify

If implementation shows that the spec is wrong or incomplete, stop, update `spec.md`, set `**Status**: Draft`, run `/speckit.clarify`, and get approval again.

- **Why:** Silent scope changes make the spec stop describing the code, and the next reader trusts a wrong document.
- **Check:** The SDD-001 hook blocks further source edits once the status is back to Draft.

### SDD-007 · SHOULD · Keep a spec to about two pages

A spec that grows past about two pages is split into several specs, each with its own number and branch.

- **Why:** Large specs produce large PRs (`PR-002`) and long-lived branches (`GIT-004`).
- **Check:** Advisory.

## Reference

### Stages and commands

| # | Stage | Command | Output | Gate |
|---|-------|---------|--------|------|
| 00 | Constitution (once per repo) | `/speckit.constitution` | `.specify/memory/constitution.md`, generated from the MUST rules of the selected groups | |
| 05 | Specify | `/speckit.specify` with `brainstorms/<slug>/brainstorm.md` as input | `specs/NNN-slug/`; the agent then runs `git mv brainstorms/<slug>/brainstorm.* specs/NNN-slug/` and writes `spec.md` with user stories, EARS requirements, non-goals from `brainstorm.md` | |
| 06 | Clarify | `/speckit.clarify` | Open questions answered, `**Status**: Approved` set by you | Yes |
| 07 | Plan | `/speckit.plan` | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` | |
| 08 | Tasks | `/speckit.tasks` | `tasks.md`, one PR per task, `[P]` marks tasks that can run in parallel | |
| 09 | Analyze | `/speckit.analyze` | Consistency report | |
| 10 | Implement | `/speckit.implement` | Code, test first, one task per `NNN-tTTT-slug` branch (`BRA-002`) | |
| 11 | Verify | CI | Every FR has a passing test; production pack checks pass | Yes |
| 12 | Close | | `**Status**: Implemented`, changelog entry, ADRs linked | |

Stages 01 to 04 are the brainstorm (`BRN`).

Branches follow trunk-based development ([branching.md](branching.md)): Spec Kit's `NNN-slug` branch carries only the documents (brainstorm, spec, plan, tasks, proposed ADRs) and merges to `main` once the spec is approved and `/speckit.analyze` passes (`BRA-004`). Each task then gets its own branch `NNN-tTTT-slug` from the latest `main`, so `require-spec.sh` finds the approved spec there. Plans read and link the accepted ADRs they rely on (`ADR-008`).

### Folder layout

Before Specify, the brainstorm lives outside `specs/`, because Spec Kit picks the next spec number by scanning `specs/`:

```text
brainstorms/faster-restock/
├── brainstorm.html     # created by /brainstorm <slug> "problem"
└── brainstorm.md       # saved by you from the board's export
```

Right after `/speckit.specify` creates the spec folder, and before `spec.md` is edited, the agent moves both files:

```bash
git mv brainstorms/faster-restock/brainstorm.* specs/013-faster-restock/
```

The `BRN-001` hook checks that `specs/NNN-*/brainstorm.md` has `status: decided` before it allows edits to `spec.md`. Final layout:

```text
specs/013-faster-restock/
├── brainstorm.html     # interactive board (BRN), moved from brainstorms/<slug>/
├── brainstorm.md       # decision record exported from the board
├── spec.md             # /speckit.specify
├── plan.md             # /speckit.plan
├── research.md
├── data-model.md       # includes data classes (DAT-001)
├── contracts/          # OpenAPI 3.1 files (API-001)
├── quickstart.md
└── tasks.md            # /speckit.tasks
```

### Status line

`spec.md` carries Spec Kit's status line. Allowed values:

```markdown
**Status**: Draft | Approved | Implemented | Superseded
```

The hooks match `**Status**: Approved` case-insensitively.

### EARS patterns

| Pattern | Template | Example |
|---------|----------|---------|
| Ubiquitous | THE SYSTEM SHALL `<response>` | THE SYSTEM SHALL store prices in minor currency units. |
| Event-driven | WHEN `<trigger>` THE SYSTEM SHALL `<response>` | WHEN a buyer submits a pasted list THE SYSTEM SHALL match each line by SKU or MPN. |
| State-driven | WHILE `<state>` THE SYSTEM SHALL `<response>` | WHILE the cart is locked for checkout THE SYSTEM SHALL reject edits with 409. |
| Unwanted behavior | IF `<condition>` THEN THE SYSTEM SHALL `<response>` | IF a line matches no product THEN THE SYSTEM SHALL list it with up to 3 suggestions. |
| Optional feature | WHERE `<feature is included>` THE SYSTEM SHALL `<response>` | WHERE the KiCad import is enabled THE SYSTEM SHALL accept BOM CSV files. |

Patterns can be combined, for example `WHILE <state>, WHEN <trigger> THE SYSTEM SHALL <response>`.

### Template additions

dev-standard's templates in `templates/.specify/templates/` are additions to Spec Kit's templates, not replacements. Spec Kit's commands depend on the sections and placeholders in its own templates. At install time, merge our sections into the templates that `specify init` created, and keep every Spec Kit section.

| Template | dev-standard adds |
|----------|-------------------|
| `spec-template.md` | `**Input**: specs/NNN-slug/brainstorm.md (BRN-<slug>)`, requirements in EARS, non-goals from rejected options |
| `plan-template.md` | Context and scope; goals and non-goals; design (API, data, indexes); alternatives considered; cross-cutting concerns; rollout and rollback |
| `tasks-template.md` | Requirement IDs per task; traceability table (FR to test) |

### plan.md design-doc sections

```markdown
## Context and scope
## Goals and non-goals
## Design
### API      → contracts/<name>.yaml (OpenAPI 3.1)
### Data     → data-model.md, with data classes
### Indexes  → every query path names its index (REL-005)
## Alternatives considered
## Cross-cutting concerns
- Security: ASVS level, object-level authorization
- Abuse: rate limits per endpoint
- Privacy: personal fields, retention
- Observability: SLOs, spans, alerts
## Rollout and rollback
```

### Traceability table in tasks.md

```markdown
## Traceability
| Requirement | Task  | Test                                                 |
|-------------|-------|------------------------------------------------------|
| 013/FR-001  | T003  | tests/test_bom_import.py::test_matches_by_sku        |
| 013/FR-002  | T004  | tests/test_bom_import.py::test_unmatched_suggestions |
```

## Sources

- [GitHub Spec Kit](https://github.com/github/spec-kit)
- [Alistair Mavin: EARS](https://alistairmavin.com/ears/)
- [Malte Ubl: Design Docs at Google](https://www.industrialempathy.com/posts/design-docs-at-google/)
