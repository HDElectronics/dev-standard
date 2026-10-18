---
id: PR
title: Pull requests
version: 0.1.0
applies_to: all
based_on:
  - name: Google Engineering Practices, Small CLs
    url: https://google.github.io/eng-practices/review/developer/small-cls.html
  - name: Google Engineering Practices, Writing good CL descriptions
    url: https://google.github.io/eng-practices/review/developer/cl-descriptions.html
---

# Pull requests (PR)

How to shape and describe a pull request. Google calls a change a CL (changelist); its guidance on small CLs and CL descriptions applies directly to PRs.

## Rules

### PR-001 · MUST · Title the PR as a Conventional Commit line

The PR title follows `GIT-001`: `type(scope): imperative summary`. With squash merge, the title becomes the commit on `main`.

- **Why:** The title is what release tooling and `git log` see.
- **Check:** CI PR-title lint (commitlint against the title). Blocks.

### PR-002 · SHOULD · Keep a PR around 100 changed lines

Google: "100 lines is usually a reasonable size for a CL, and 1000 lines is usually too large." Aim for about 100. A PR over 1000 changed lines needs a stated reason in the description. Lockfiles, generated code and snapshots don't count.

- **Why:** Small PRs are reviewed faster and more thoroughly, are less likely to hide bugs, are easier to roll back, and merge with fewer conflicts.
- **Check:** CI size check warns above 400 lines and requires a "Why this is large" note above 1000, excluding lockfiles and generated paths.

### PR-003 · MUST · Fill in the description template

Every section of `.github/pull_request_template.md` is filled in: what and why, spec and tasks, how you tested, risk and rollback, follow-ups. The first line of "What and why" is a short summary that stands alone; the rest gives the context a future reader needs (Google CL description guide).

- **Why:** The description is the reviewer's map and the permanent record of the change. "Fix bug" tells neither anything.
- **Check:** `dev-standard check pr` in CI blocks when a template heading is missing or a section is empty. The `/pr` command fills the template from the spec and tasks.

### PR-004 · MUST · Make one self-contained change

A PR does one thing. Refactors go in their own PR, before or after the feature. Each PR leaves the system working.

- **Why:** Google's small-CL guidance: separating refactors from behavior changes makes both easy to review and to revert.
- **Check:** Advisory. The reviewer flags unrelated changes (`REV-002`).

### PR-005 · MUST · Ship tests in the same PR as the code

New or changed behavior arrives with its tests in the same PR.

- **Why:** A PR without tests cannot show it works, and "tests in a follow-up" often never happens.
- **Check:** Diff coverage on changed lines (`TST-003`) blocks in CI.

### PR-006 · MUST · Open as draft until green; squash merge and delete the branch

Open the PR as a draft. Mark it ready for review when CI is green and you have reviewed your own diff. Merge with squash, then delete the branch.

- **Why:** Reviewers' time goes to changes that already pass the machines. Squash merges keep `main` at one commit per PR.
- **Check:** Branch protection allows squash merge only and requires status checks. Automatic branch deletion is enabled in repository settings.

## Reference

### Description template

```markdown
## What and why
<One-line summary that stands alone.>
<What changed, why, and what a future reader needs to know.>

## Spec
013-faster-restock · tasks T003–T004 · 013/FR-001, 013/FR-002

## How I tested
<Commands run and their results.>

## Risk and rollback
<What could break, how you would notice, how to roll back.>

## Follow-ups (out of scope)
- 
```

### Splitting a large change

Google lists these ways to split a CL:

- **Stack:** a sequence of small PRs, each building on the previous one.
- **By layer:** for example, the API contract first, then the backend, then the UI.
- **By file group:** changes that need different reviewers go in different PRs.
- **Refactor first:** a behavior-neutral refactor PR, then a small feature PR.

### Self-review before marking ready

- [ ] Title follows Conventional Commits.
- [ ] Diff contains only the current task.
- [ ] Formatter, linter, type checker and tests pass locally.
- [ ] Every requirement in scope has a test that references its ID.
- [ ] Docs and changelog updated, or the description says why not.

## Sources

- [Google: Small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html)
- [Google: Writing good CL descriptions](https://google.github.io/eng-practices/review/developer/cl-descriptions.html)
- [GitHub: Creating a pull request template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
