---
id: GIT
title: Commits and branches
version: 0.1.0
applies_to: all
based_on:
  - name: Conventional Commits 1.0.0
    url: https://www.conventionalcommits.org/en/v1.0.0/
  - name: Semantic Versioning 2.0.0
    url: https://semver.org/
  - name: Google Engineering Practices, Writing good CL descriptions
    url: https://google.github.io/eng-practices/review/developer/cl-descriptions.html
---

# Commits and branches (GIT)

Commit messages follow Conventional Commits so that versions and changelogs can be generated. The message body follows Google's guidance for change descriptions, so each commit explains itself to a future reader. Branches are short-lived and merged into `main`.

## Rules

### GIT-001 · MUST · Use Conventional Commits

The subject line is `type(scope): imperative summary`, 72 characters or fewer, no trailing period. The scope is optional. Types map to SemVer bumps (see Reference).

- **Why:** A machine-readable subject lets tools compute the next version and write the changelog (`DOC-005`). The imperative mood ("add", not "added") matches what git itself writes.
- **Check:** commitlint with `@commitlint/config-conventional` in the `commit-msg` hook (lefthook). CI lints the PR title, which becomes the squash commit (`PR-001`).

### GIT-002 · MUST · Explain what and why in the body; put references in the footer

When the change is not obvious from the subject, the body says what changed and why, so it stands on its own for a reader who has no other context. The footer carries `Refs:` and `BREAKING CHANGE:`.

- **Why:** Google's CL description guide: the description becomes a permanent record that future readers search when they wonder why code is the way it is.
- **Check:** commitlint enforces the blank line before body and footer. Content is advisory.

### GIT-003 · SHOULD · Make one logical change per commit, and keep every commit buildable

- **Why:** Small, buildable commits make `git bisect` and `git revert` work.
- **Check:** Advisory. Squash merges (`PR-006`) make the PR the unit on `main`.

### GIT-004 · MUST · Work trunk-based with short-lived branches

Branch off `main`, merge back within 3 days. The full branching model, branch names and server-side protection are in [branching.md](branching.md) (`BRA`).

- **Why:** Long-lived branches drift and produce large, risky merges. Short branches keep PRs small (`PR-002`).
- **Check:** Advisory. A scheduled CI job can list branches older than 3 days.

### GIT-005 · MUST NOT · Commit to or force-push main

All changes reach `main` through a PR.

- **Why:** `main` is the shared history and the deploy source. Direct commits skip review and CI; force pushes rewrite what others have built on.
- **Check:** The `main` ruleset (`BRA-007`: require PR, require status checks, block force pushes). `no-bypass.sh` blocks `git push --force` to `main` from the agent.

## Reference

### Types and version bumps

| Type | Use for | SemVer bump |
|------|---------|-------------|
| `feat` | A new user-visible feature | minor |
| `fix` | A bug fix | patch |
| `perf` | A performance improvement | patch |
| `refactor` | Code change that neither fixes a bug nor adds a feature | none |
| `docs` | Documentation only | none |
| `test` | Adding or fixing tests | none |
| `build` | Build system or dependencies | none |
| `ci` | CI configuration | none |
| `chore` | Other maintenance | none |
| `revert` | Reverts a previous commit | depends on the reverted change |
| any type with `!` or a `BREAKING CHANGE:` footer | An incompatible API change | major |

Before 1.0.0, release tools commonly treat breaking changes as minor bumps; check your release tool's configuration.

### Example

```text
feat(cart): match pasted BOM lines by SKU or MPN

Buyers re-searched every part for repeat orders. Matching
runs server side so the same parser serves the API and the
page, and unmatched lines come back with suggestions.

Refs: 013/FR-001, 013/FR-002
```

### commitlint configuration

```js
// commitlint.config.mjs
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "header-max-length": [2, "always", 72],
  },
};
```

### Branch protection on main

See [branching.md](branching.md) (`BRA-007` to `BRA-012`) and the ruleset files in `templates/.github/rulesets/`.

## Sources

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [Google: Writing good CL descriptions](https://google.github.io/eng-practices/review/developer/cl-descriptions.html)
- [commitlint](https://commitlint.js.org/)
- [Trunk-based development](https://trunkbaseddevelopment.com/)
