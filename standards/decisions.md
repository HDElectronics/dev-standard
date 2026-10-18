---
id: ADR
title: Architecture decision records
version: 0.1.0
applies_to: all
based_on:
  - name: Michael Nygard, "Documenting Architecture Decisions"
    url: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
  - name: MADR 4
    url: https://adr.github.io/madr/
  - name: ADR GitHub organization
    url: https://adr.github.io/
  - name: Google Cloud, "Architecture decision records overview"
    url: https://cloud.google.com/architecture/architecture-decision-records
  - name: AWS Prescriptive Guidance, "ADR process"
    url: https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html
---

# Architecture decision records (ADR)

The repo keeps a permanent archive of its significant decisions: what was decided, which
options were considered, and why. Each decision is one short Markdown file in `docs/adr/`,
written in MADR format, and never rewritten once accepted. Later decisions supersede earlier
ones and link back to them, so the archive reads as a history.

The archive has two parts:

| Record | Where | Holds |
|--------|-------|-------|
| ADR | `docs/adr/NNNN-slug.md` | Architecture and technology decisions for the whole repo |
| Brainstorm record | `specs/NNN-slug/brainstorm.md` (`BRN`) | The product direction chosen for one feature, with rejected options |

`DOC-003` requires ADRs; this group says when and how to write them.

## Rules

### ADR-001 · MUST · Write an ADR for every architecturally significant decision

A decision needs an ADR when it is hard to reverse or shapes the system beyond one feature:
choosing a framework, database, auth provider, hosting target or message broker; a public API
shape; a cross-cutting pattern (errors, auth flow, tenancy); adding a major dependency
(`SEC-004`); and any deviation that the standard says needs an ADR (`UI-002`, `AUTH-001`,
`OPS-001`).

- **Why:** These decisions outlive the people and the chat sessions that made them. Without a record, later contributors and agents repeat the debate or undo the decision by accident.
- **Check:** advisory. The `plan.md` cross-cutting section lists the ADRs the design needs; the reviewer subagent flags new infrastructure or dependencies without one.

### ADR-002 · MUST · Use MADR, one decision per file, numbers never reused

Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-slug.md`, where `NNNN` is the next free
number and the slug names the decision (`0004-use-keycloak-for-auth`). One file records one
decision. Numbers are never reused, even for rejected ADRs.

- **Why:** A stable number gives every decision a permanent ID that specs, code comments and other ADRs can cite.
- **Check:** `dev-standard check adr` rejects bad file names and duplicate numbers.

### ADR-003 · MUST · Compare at least two options, including the status quo

The ADR lists the decision drivers, at least two considered options (one of them keeping
things as they are, where that's possible), the pros and cons of each, and the consequences
of the chosen option, good and bad.

- **Why:** A decision with only one option is a description, not a decision. The bad consequences are what a later reader most needs.
- **Check:** advisory. The reviewer subagent checks the sections are filled.

### ADR-004 · MUST · Follow the status lifecycle; accepted ADRs are immutable

Status moves `proposed` → `accepted` or `rejected`. Later it can become `deprecated` or
`superseded by ADR-NNNN`. Once an ADR is accepted, its content doesn't change. To change the
decision, write a new ADR that supersedes it, and edit the old one only to set its status to
`superseded by ADR-NNNN`.

- **Why:** Nygard's original point: the record shows what was believed at the time. Editing an accepted ADR erases why the code looks the way it does.
- **Check:** code-owner review of `docs/adr/` (`BRA-010`). `dev-standard check adr` validates statuses and that a superseding ADR exists.

### ADR-005 · MUST NOT · Let the agent accept its own ADR

The agent drafts ADRs with `status: proposed` and may recommend an option. You set
`status: accepted` (or `rejected`) and fill in `decision-makers`.

- **Why:** Like the brainstorm decision (`BRN-004`) and spec approval (`SDD-001`), the decision belongs to a person who is accountable for it.
- **Check:** `guard-approvals.sh` blocks the agent from writing `status: accepted` into `docs/adr/*.md`; `no-bypass.sh` blocks doing it through a shell command.

### ADR-006 · MUST · Land the ADR with, or before, the change it decides

An ADR merges in the spec PR (when `plan.md` depends on it) or in the same PR as the change.
The plan links its ADRs, and each ADR links the spec or issue that raised it.

- **Why:** A decision recorded after the fact gets rationalized to match the code. Linking both ways lets readers move from code to reason and back.
- **Check:** advisory. `PR-003` template asks for linked ADRs.

### ADR-007 · MUST · Keep the decision log index current

`docs/adr/README.md` lists every ADR with its number, title, status and date. The PR that adds
an ADR or changes a status updates the index.

- **Why:** The index is how people and agents find a decision without opening every file.
- **Check:** `dev-standard check adr` compares the index with the files: missing rows, stale statuses, rows without a file.

### ADR-008 · MUST · Read the relevant accepted ADRs before proposing a design

Before writing a plan, brainstorm options or an ADR, the agent searches `docs/adr/` for
accepted decisions in the same area. It never proposes a design that contradicts an accepted
ADR without also proposing a superseding ADR.

- **Why:** The archive is only useful if it is consulted. This makes past decisions binding until someone deliberately changes them.
- **Check:** advisory. `plan.md` has a "Related decisions" line; the reviewer subagent checks it.

### ADR-009 · SHOULD · Keep existing decision records where they are

When a repo already records decisions (another folder such as `doc/adr` or
`docs/decisions`, Nygard format, or a design-doc wiki), keep them and their numbering. New
ADRs continue in the same place, and the index links any older records outside it.

- **Why:** Moving or renumbering an archive breaks every link to it (`INS-003`, `INS-010`).
- **Check:** advisory. Recorded in the adoption report.

## Reference

### Frontmatter (MADR 4)

```yaml
---
status: proposed   # proposed | rejected | accepted | deprecated | superseded by ADR-NNNN
date: 2026-10-18
decision-makers: Ibrahim
consulted: ""
informed: ""
---
```

### Index format (`docs/adr/README.md`)

```markdown
| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | accepted | 2026-10-18 |
| [0002](0002-use-fastapi-for-backend.md) | Use FastAPI for the backend | accepted | 2026-10-18 |
| [0003](0003-use-keycloak-for-auth.md) | Use Keycloak for authentication | proposed | 2026-10-18 |
```

### Typical first ADRs for a dev-standard repo

1. Record architecture decisions (this process).
2. Backend framework (default FastAPI).
3. Frontend build (default Vite; Next.js only for SEO).
4. Auth provider (default Keycloak).
5. Deploy target (required before the first deploy, `OPS-001`).
6. Agent identity and branch protection setup (`BRA-009`).

## Sources

- [Michael Nygard: Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [MADR](https://adr.github.io/madr/)
- [adr.github.io](https://adr.github.io/)
- [Google Cloud: Architecture decision records overview](https://cloud.google.com/architecture/architecture-decision-records)
- [AWS: ADR process](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html)
