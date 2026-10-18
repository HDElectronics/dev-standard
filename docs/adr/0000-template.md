---
# MADR 4 template: https://adr.github.io/madr/
# File name: docs/adr/NNNN-short-title.md (NAM-007, ADR-002). Rules: DOC-003, standards/decisions.md.
# The agent drafts with status: proposed. Only the decision-maker sets accepted (ADR-005).
status: proposed  # proposed | rejected | accepted | deprecated | superseded by ADR-NNNN
date: {{DATE}}
decision-makers: {{NAMES}}
consulted: {{NAMES}}
informed: {{NAMES}}
---

# {{Short title: the problem solved and the solution chosen}}

## Context and Problem Statement

{{Two or three sentences describing the context and the problem. Phrase it as a question if that helps. Link the spec or issue.}}

## Decision Drivers

* {{Driver, e.g. a force or a concern}}
* {{Driver}}

## Considered Options

* {{Option 1}}
* {{Option 2}}
* {{Option 3}}

## Decision Outcome

Chosen option: "{{Option 1}}", because {{justification: it meets driver X, it is the only option that ..., it comes out best overall}}.

### Consequences

* Good, because {{positive consequence}}
* Bad, because {{negative consequence}}

### Confirmation

{{How compliance with this decision is checked: a lint rule, a test, a review item.}}

## Pros and Cons of the Options

### {{Option 1}}

* Good, because {{argument}}
* Neutral, because {{argument}}
* Bad, because {{argument}}

### {{Option 2}}

* Good, because {{argument}}
* Bad, because {{argument}}

## More Information

{{Links to related ADRs, specs and discussions. When this decision should be revisited.}}
