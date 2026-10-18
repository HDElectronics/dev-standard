<!--
  dev-standard adoption report. The installing agent writes this file in Phase 1-3 of
  .dev-standard/INSTALL.md and changes nothing else until the user approves Section 5.
-->
# dev-standard adoption report

- **Repository**: {{REPO_NAME}}
- **dev-standard version**: {{VERSION}}
- **Date**: {{DATE}}
- **Prepared by**: {{AGENT}} for {{USER}}
- **Status**: Proposed  <!-- Proposed | Approved | Applied -->

## 1. What this repo is today

| Area | Found | Evidence |
|------|-------|----------|
| Languages and versions | | `pyproject.toml`, `package.json`, … |
| Frameworks | | |
| Package managers | | |
| Formatters and linters | | config files |
| Type checking | | |
| Tests and coverage | | test command, current coverage |
| CI | | workflow files |
| Commit style | | sample of last 50 subjects: N of 50 are Conventional Commits |
| Branch protection | | `gh api repos/{owner}/{repo}/rulesets`, `.../branches/main/protection` |
| Agent identity | | does the agent push as you, a bot account or a GitHub App? (BRA-009) |
| Decision records | | `docs/adr/`, `doc/adr/`, `docs/decisions/`, design docs |
| Branch naming | | `git branch -r` |
| PR template, review rules | | |
| Docs layout, ADRs | | |
| Agent instructions | | `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md` |
| Specs or design docs | | |
| Deployment | | Dockerfile, compose, IaC, hosting config |
| Security tooling | | secret scanning, dependency updates, SAST |

### Conventions this repo already follows

List each existing convention that an agent must keep, with evidence. These go into the
"Repo-specific conventions" block of `AGENTS.md`.

- …

## 2. Proposed profiles

| Setting | Proposal | Why |
|---------|----------|-----|
| Profiles | `base`, … | |
| `deployed` | true / false | |
| Packs | | |
| `paths.source` | | |
| `checks.fast` | | must pass today on a clean checkout |
| `checks.full` | | |

## 3. Rule-by-rule assessment

One row per rule group in the selected profiles. Status values:
**Compliant** (already true), **Adopt** (cheap, no conflict), **Conflict** (repo does it
differently), **Migrate** (large change, needs its own plan), **N/A**.

| Group | Status | Notes | Proposed level |
|-------|--------|-------|----------------|
| AGT | | | block |
| BRN | | | block |
| SDD | | | block |
| NAM | | | warn |
| STY | | | warn |
| GIT | | | block |
| BRA | | current protection on `main`: … | block |
| PR | | | warn |
| REV | | | advisory |
| DOC | | | warn |
| ADR | | existing decision records: … | advisory |
| TST | | | warn |
| SEC | | | warn |
| ERR | | | warn |

## 4. Conflicts and proposed waivers

For each conflict: what the repo does, what the standard says, and the option you recommend.

| Rule | Repo does | Standard says | Options | Recommendation |
|------|-----------|---------------|---------|----------------|
| | | | keep (waiver) · new code only · migrate | |

Waivers to add to `.dev-standard.json` once approved:

```json
[
  { "rule": "NAM-001", "scope": "legacy/", "reason": "…", "approved_by": "{{USER}}", "expires": "YYYY-MM-DD", "plan": "…" }
]
```

## 5. Rollout plan

Each step is one commit, Conventional Commits format, on branch `chore/adopt-dev-standard`.

1. `docs: add dev-standard adoption report`: this file only.
2. `chore: add dev-standard agent instructions`: `AGENTS.md` block, `CLAUDE.md`, `.dev-standard.json`.
3. `chore: add spec-driven workflow`: Spec Kit, template additions, constitution, commands, PR and ADR templates.
4. `chore: add dev-standard agent hooks`: `.claude/settings.json` merge.
5. `chore: add local checks in warn mode`: profile configs merged, git hooks installed.
6. `ci: add dev-standard checks`: on changed files only, warn first.
7. `chore: add branch protection rulesets`: `.github/rulesets/`, `CODEOWNERS`. You apply them on GitHub (admin action).
8. Separate PRs, later: any reformat, rename or migration listed in Section 4.

## 6. Questions for you

1. …

## 7. Approval

- [ ] I approve Sections 2 to 5. Approved by: ______ Date: ______
