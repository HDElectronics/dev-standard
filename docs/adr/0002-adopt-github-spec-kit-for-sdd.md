---
status: proposed
date: 2026-10-18
decision-makers: Ibrahim Khadraoui
consulted: ""
informed: ""
---

# Adopt GitHub Spec Kit for spec-driven development

## Context and Problem Statement

The standard needs a spec-driven workflow. Should dev-standard define its own spec process and tooling, or adopt an existing one?

## Decision Drivers

* Rules should come from established standards, not be invented
* Agents already know widely used tools
* Our gates (brainstorm, approval, traceability) must still apply

## Considered Options

* GitHub Spec Kit used as is, with dev-standard template additions and hooks
* Our own spec templates and commands
* Kiro-style specs without tooling

## Decision Outcome

Chosen option: "GitHub Spec Kit used as is", because it gives the stages, commands and folder layout for free, and our hooks and template additions add the gates without forking it.

### Consequences

* Good, because Spec Kit upgrades come without rework
* Bad, because Spec Kit picks spec numbers by scanning `specs/`, which forced brainstorms to start in `brainstorms/<slug>/`
* Bad, because template additions must be merged by hand and are untested against current Spec Kit
