<!--
  dev-standard ADDITIONS to Spec Kit's spec template.
  Merge these into the .specify/templates/spec-template.md that `specify init` generated.
  Keep every Spec Kit section, heading and [PLACEHOLDER] as is; Spec Kit's commands depend on them.
  Add the lines and sections below in the places indicated. Rules: BRN-005, SDD-001, SDD-002, SDD-003.
-->

<!-- 1. Header block: keep Spec Kit's lines, make sure these three exist. -->
**Feature Branch**: `[###-feature-name]`
**Status**: Draft
**Input**: specs/###-feature-name/brainstorm.md (BRN-[slug], option #[N])

<!--
  The brainstorm starts in brainstorms/<slug>/. Right after Spec Kit creates specs/###-feature-name/,
  run `git mv brainstorms/<slug>/brainstorm.* specs/###-feature-name/` before editing this file.
-->

<!--
  Status values: Draft → Approved → Implemented (or Superseded).
  Only the user changes Draft to Approved (SDD-001). The require-spec hook reads this exact line.
-->

<!-- 2. In Spec Kit's "Functional Requirements" section, write each requirement in EARS form (SDD-002). -->

### Functional Requirements

<!--
  EARS patterns (https://alistairmavin.com/ears/):
    Ubiquitous:    THE SYSTEM SHALL <response>.
    Event-driven:  WHEN <trigger>, THE SYSTEM SHALL <response>.
    State-driven:  WHILE <state>, THE SYSTEM SHALL <response>.
    Unwanted:      IF <condition>, THEN THE SYSTEM SHALL <response>.
    Optional:      WHERE <feature is included>, THE SYSTEM SHALL <response>.
  One requirement per ID. Each ID is referenced by at least one test name or tag, e.g. `test_fr_001_...`
  or `it("[###/FR-001] ...")` (SDD-003).
-->

- **FR-001**: WHEN [trigger], THE SYSTEM SHALL [response].
- **FR-002**: IF [unwanted condition], THEN THE SYSTEM SHALL [response].

<!-- 3. Add this section after Spec Kit's requirements and success criteria. -->

## Non-goals

<!-- Copy each rejected option from brainstorm.md with its reason (BRN-005). Add any other explicit exclusions. -->

- [Rejected option] (BRN-###, option #[N]: [reason])

## Traceability

<!-- Filled during /speckit.implement and checked at Verify. -->

| Requirement | Test |
|-------------|------|
| FR-001 | [file › test name] |
