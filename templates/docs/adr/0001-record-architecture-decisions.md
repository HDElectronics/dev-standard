---
status: proposed  # set to accepted by the decision-maker, not the agent (ADR-005)
date: {{DATE}}
decision-makers: {{NAMES}}
consulted: ""
informed: ""
---

# Record architecture decisions

## Context and Problem Statement

Decisions about this repository's architecture are made in chats, PR comments and
people's heads, and are lost when those move on. How should we keep a durable record that
people and coding agents can consult before changing the system?

## Decision Drivers

* Agents and new contributors need the reasons behind the current design.
* The record must live next to the code and be reviewed like code.
* Low effort: a decision should take minutes to record.

## Considered Options

* Architecture decision records in `docs/adr/`, MADR format
* A wiki page or document outside the repository
* No formal record (status quo)

## Decision Outcome

Chosen option: "Architecture decision records in `docs/adr/`, MADR format", because it keeps
decisions versioned with the code, reviewable in PRs, and readable by agents, as required by
dev-standard (DOC-003, ADR group).

### Consequences

* Good, because each decision has a permanent number that specs and code can cite.
* Good, because agents read accepted ADRs before proposing designs (ADR-008).
* Bad, because someone has to write and index each record (ADR-007).

### Confirmation

Code-owner review of `docs/adr/` (BRA-010) and the plan's "Related decisions" line.

## More Information

* Michael Nygard, [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
* [MADR](https://adr.github.io/madr/)
