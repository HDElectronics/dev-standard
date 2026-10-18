---
status: proposed
date: 2026-10-18
decision-makers: Ibrahim Khadraoui
consulted: ""
informed: ""
---

# Implement CI checks as one standard-library Python CLI

## Context and Problem Statement

Many rules need CI checks (SDD-001, SDD-003, BRN-001, ADR-007, PR-003, SEC-004). In what language and shape?

## Decision Drivers

* Runs in any CI image with no install step
* One place to read enforcement levels and waivers
* Testable

## Considered Options

* One Python 3.11+ stdlib-only script, `cli/dev-standard check`
* Separate shell scripts per check
* A Node package

## Decision Outcome

Chosen option: "One Python 3.11+ stdlib-only script", because Python is on every CI runner and in the default stack, and one entry point keeps level and waiver logic in one place.

### Consequences

* Good, because the hooks and the CLI share the same manifest semantics, covered by tests/
* Bad, because the hooks stay in bash, so the logic exists twice
