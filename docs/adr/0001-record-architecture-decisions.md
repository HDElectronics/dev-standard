---
status: proposed
date: 2026-10-18
decision-makers: Ibrahim Khadraoui
consulted: ""
informed: ""
---

# Record architecture decisions

## Context and Problem Statement

Decisions about dev-standard were made in a chat session and would be lost with it. How do we keep them where people and agents can find and cite them?

## Decision Drivers

* The standard requires ADRs of adopting repos (DOC-003, ADR group), so it should follow its own rule
* Records must be versioned and reviewed with the repo

## Considered Options

* ADRs in `docs/adr/`, MADR 4
* Notes in the README
* No record (status quo)

## Decision Outcome

Chosen option: "ADRs in `docs/adr/`, MADR 4", because it is the format the standard asks of every adopting repo, and `dev-standard check adr` validates it.

### Consequences

* Good, because each decision below has a permanent number
* Bad, because the index must be kept in sync (ADR-007)
