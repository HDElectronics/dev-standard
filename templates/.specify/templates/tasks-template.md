<!--
  dev-standard ADDITIONS to Spec Kit's tasks template.
  Merge these into the .specify/templates/tasks-template.md that `specify init` generated.
  Keep Spec Kit's phases, task format and placeholders. Add the rules and columns below.
  Rules: SDD-003, PR-002, PR-004, PR-005, TST-001.
-->

## dev-standard task rules

- Format stays Spec Kit's: `- [ ] T001 [P] [US1] Description with exact file path`.
  - `[P]`: can run in parallel with other `[P]` tasks (different files, no dependency).
  - `[US1]`: the user story the task belongs to.
- Every task ends with the requirement IDs it covers: `→ FR-001, FR-002`. Setup tasks write `→ setup`.
- Each task fits one pull request: about 100 changed lines, one concern, tests included (PR-002, PR-004, PR-005).
- Test tasks come before the implementation tasks they cover, and must fail first (TST-001).
- A refactor needed by a feature is its own task, ordered before the feature task.

## Example

```markdown
## Phase 3: User Story 1 - Paste a BOM (Priority: P1)

- [ ] T010 [P] [US1] Contract test for POST /v1/carts/{id}:importLines in tests/contract/test_import_lines.py → FR-001
- [ ] T011 [P] [US1] Unit tests for line parser in tests/unit/test_line_parser.py → FR-001, FR-002
- [ ] T012 [US1] Line parser in app/cart/line_parser.py → FR-001, FR-002
- [ ] T013 [US1] Import endpoint in app/cart/router.py → FR-001
```

## Traceability check

Before `/speckit.implement` finishes, every FR in `spec.md` appears after `→` in at least one task, and every task's tests reference those IDs.
