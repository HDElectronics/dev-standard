<!--
  dev-standard PR template (PR-001 to PR-006). Title: a Conventional Commit line, e.g.
  feat(cart): match pasted BOM lines by SKU
  CI rejects the PR if a required section below is empty. Write "n/a" with a reason where a section does not apply.
-->

## What and why

<!-- What changed, why, and what a future reader needs to know. Self-contained: don't rely on the issue link alone. -->

## Spec

<!-- e.g. 013-faster-restock · tasks T012–T013 · FR-001, FR-002. For fix/ and chore/ branches, link the issue. -->

## How I tested

<!-- Commands you ran and their results. Paste the summary lines, not "tests pass". -->

## Risk and rollback

<!-- What could break, who is affected, and how to undo it. -->

## Follow-ups (out of scope)

<!-- Things you noticed but did not change (AGT-005). -->

## Self-review

- [ ] One concern; refactors are in a separate PR (PR-004)
- [ ] Tests ship in this PR and reference requirement IDs (PR-005, SDD-003)
- [ ] Format, lint, typecheck and tests pass locally (AGT-003)
- [ ] No test assertion was weakened, or the reason is stated above (AGT-004)
- [ ] Docs, ADRs and changelog updated where behavior changed (DOC-003, DOC-007)
- [ ] No accepted ADR contradicted; new decisions have a proposed ADR (ADR-001, ADR-008)
- [ ] Rebased on the latest `main` (BRA-005)
- [ ] No secrets, personal data or debug output added (SEC-001, DAT-005)
- [ ] Reviewed by the `standard-reviewer` subagent; blocking findings resolved
