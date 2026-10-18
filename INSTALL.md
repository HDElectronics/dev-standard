# Installing dev-standard

This file is a runbook for a coding agent. A person adds dev-standard to their repository and
says to their agent:

> Install dev-standard: follow `.dev-standard/INSTALL.md`.

The agent then works through the phases below in order. The rules behind each step are in
[standards/installation.md](standards/installation.md) (`INS-*`).

**Agent: three rules hold for the whole install.**

1. Phases 1 to 3 are read-only, apart from writing the adoption report (INS-001).
2. Stop at the end of Phase 3 and wait for the user's approval (INS-002).
3. Never overwrite or delete an existing file. Merge into it (INS-003).

---

## Phase 0 · Add dev-standard to the repo (done by the person, or by the agent when asked)

Pin a release tag (INS-009).

```bash
git submodule add <DEV_STANDARD_GIT_URL> .dev-standard
git -C .dev-standard checkout v0.1.0
git add .gitmodules .dev-standard
```

If the repo can't use submodules, copy a release into `.dev-standard/` instead and note the
version in the adoption report.

Then the agent:

1. Confirms the working tree is clean (`git status --porcelain` prints nothing). If it isn't,
   stop and ask the user to commit or stash.
2. Creates the branch `chore/adopt-dev-standard` from the default branch.
3. Reads `.dev-standard/README.md`, `.dev-standard/standards/README.md` and
   `.dev-standard/standards/installation.md`.

## Phase 1 · Discover (read-only)

Build a factual picture of the repo. Record each finding with its evidence (file path or
command output) in Section 1 of
[`templates/docs/dev-standard/adoption-report.md`](templates/docs/dev-standard/adoption-report.md),
copied to `docs/dev-standard/adoption-report.md`.

| Look for | How |
|----------|-----|
| Is the repo new? | `git rev-list --count HEAD`, number of source files. Fewer than about 10 commits and no app code means greenfield; see the shortcut below. |
| Languages, frameworks, versions | `pyproject.toml`, `requirements*.txt`, `package.json`, `tsconfig.json`, `CMakeLists.txt`, `Makefile`, `go.mod` |
| Package managers | lockfiles: `uv.lock`, `poetry.lock`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock` |
| Formatters, linters, type checkers | `[tool.ruff]`, `[tool.black]`, `[tool.mypy]`, `[tool.pyright]`, `.eslintrc*`, `eslint.config.*`, `biome.json`, `.prettierrc*`, `.clang-format` |
| Git hooks | `.pre-commit-config.yaml`, `lefthook.yml`, `.husky/` |
| Tests | test folders, the test command, current coverage if a report exists |
| CI | `.github/workflows/`, `.gitlab-ci.yml`, other CI files |
| Commit and branch style | `git log -50 --format=%s`; count Conventional Commits. `git branch -r` |
| PR and review | `.github/pull_request_template.md`, `CODEOWNERS` |
| Branching and protection | `git branch -r`, release tags. With `gh` and access: `gh api repos/{owner}/{repo}/rulesets` and `gh api repos/{owner}/{repo}/branches/main/protection`. Note whether the agent pushes as the user or as its own identity (BRA-009). |
| Decision records | `docs/adr/`, `doc/adr/`, `docs/decisions/`, design docs or wiki links. Read the accepted ones: they constrain what you propose (ADR-008). |
| Docs | `README.md`, `docs/`, ADR folders, `CHANGELOG.md` |
| Agent instructions | `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.cursorrules`, `.cursor/rules/`, `.github/copilot-instructions.md` |
| Existing specs | `.specify/`, `specs/`, design docs |
| Deployment | `Dockerfile`, `compose.yaml`, IaC (`*.tf`), Kubernetes manifests, PaaS config |
| Security tooling | secret scanning, Dependabot or Renovate, CodeQL or Semgrep |
| Conventions in the code | Sample 10 to 20 representative files: file naming, casing, error handling, logging, folder layout |

Also list the conventions the repo clearly follows, even where they differ from
dev-standard. These become the "Repo-specific conventions" block in `AGENTS.md`, so future
agents keep them.

**Greenfield shortcut.** For a new repo, skip the rule-by-rule assessment in Phase 2: propose
profiles from the intended stack, set every group to `block`, and note "greenfield" in the
report. Phases 3 to 6 still apply.

## Phase 2 · Assess (read-only)

1. **Choose profiles** (report Section 2):
   - `base`: always.
   - `python-api`: a Python backend (FastAPI is the default stack).
   - `react-web`: a React frontend. If the repo has a frontend in another framework, do not
     propose a rewrite. Propose a waiver for `UI-001`/`UI-002` with scope set to that app, and
     apply the rest of `UI` (accessibility, Web Vitals, tests) where it fits.
   - `c-embedded`: embedded C or C++ firmware.
   - `deployed: true`: the repo is deployed, or the user says it will be. This turns on the
     production pack.
   - Packs: `llm` when the code calls an LLM, `mobile` for mobile apps.
2. **Set `paths.source`** to the folders that hold application code (for example `app/` for
   FastAPI, `src/` for Vite).
3. **Find `checks.fast`**: the repo's own fast lint and unit test commands. Run it once. It
   must pass now (INS-008). If nothing passes today, propose a smaller command (lint changed
   files only) and say so in the report.
4. **Assess each rule group** (report Section 3) as Compliant, Adopt, Conflict, Migrate or N/A.
   Read the group's file in `.dev-standard/standards/` to do this.
5. **Write up each conflict** (report Section 4) with three options: keep with a waiver,
   apply to new code only (the default, INS-004), or migrate in a separate PR. Recommend one.
6. **Prefer existing tools** that meet a rule (INS-010). For example, keep `pre-commit` and add
   the gitleaks and commitlint hooks there instead of adding lefthook.

## Phase 3 · Propose, then stop

1. Fill Sections 5 (rollout plan) and 6 (questions) of the report.
2. Commit only the report: `docs: add dev-standard adoption report`.
3. Show the user a short summary: profiles, the conflicts, the proposed waivers, and the
   questions.
4. **Stop.** Continue only after the user approves. Apply their answers to the report and set
   its status to `Approved`.

## Phase 4 · Apply (one commit per step)

Use the user's approved choices. For every existing file, merge (INS-003). Replace
`{{PLACEHOLDERS}}` in templates with real values.

### 4.1 Instructions: `chore: add dev-standard agent instructions`

- `.dev-standard.json` from `templates/dev-standard.json`: version, date, profiles,
  `deployed`, packs, `paths.source`, `checks`, enforcement levels (INS-007), approved waivers.
  Validate it against `schema/manifest.schema.json`.
- `AGENTS.md` from `templates/AGENTS.md.tmpl`. Keep only the sections for the chosen profiles.
  Fill "Repo-specific conventions" from Phase 1. If `AGENTS.md` exists, insert the marked block
  and leave the rest alone. If existing text contradicts a rule, don't edit it: it should already
  be listed as a conflict in the report.
- `CLAUDE.md` from `templates/CLAUDE.md.tmpl`. If it exists, add the marked block with
  `@AGENTS.md`.
- Other agents' files (`.cursorrules`, `.github/copilot-instructions.md`): add one marked line
  that points to `AGENTS.md`.

### 4.2 Workflow: `chore: add spec-driven workflow`

1. Install GitHub Spec Kit if `.specify/` doesn't exist. Check `specify init --help` for the
   current flags:

   ```bash
   uvx --from git+https://github.com/github/spec-kit.git specify init --here --ai claude
   ```

2. Merge `templates/.specify/templates/*.md` into the generated
   `.specify/templates/`. Keep every Spec Kit section and placeholder; add ours.
3. Write `.specify/memory/constitution.md` from `templates/constitution.md.tmpl`, using the
   MUST rules of the selected groups.
4. Copy `templates/.claude/commands/` and `templates/.claude/agents/` into `.claude/`.
5. Merge `templates/.github/pull_request_template.md`, and add `brainstorms/.gitkeep`.
   Decision log: if the repo has no decision records, add `docs/adr/0000-template.md`,
   `docs/adr/README.md` and `docs/adr/0001-record-architecture-decisions.md` (status `proposed`;
   the user accepts it). If it already has records elsewhere, keep them and their numbering and
   add only the template and index there (ADR-009).
6. If `deployed: true`, add `docs/prr.md` from `templates/prr.md` and `docs/runbooks/` with
   `templates/runbook.md`.

### 4.3 Agent hooks: `chore: add dev-standard agent hooks`

Merge `templates/.claude/settings.json` into `.claude/settings.json`: append the hook entries
to existing `hooks` arrays and keep everything else. Hooks in the repo reach every contributor.
If the user runs the dev-standard Claude Code plugin instead (solo use), skip this step and
the `.claude/commands/` and `.claude/agents/` copies in 4.2: loading both runs every hook twice. Hooks need `jq` on the PATH. Then run the
fast check once more.

### 4.4 Local checks: `chore: add local checks in warn mode`

Merge the config fragments from `profiles/<profile>/` as described in
[profiles/README.md](profiles/README.md). Install the git hook manager the report chose. Don't
reformat the repo in this commit (INS-006).

### 4.5 CI: `ci: add dev-standard checks`

Add the jobs from `profiles/base/.github/workflows/standard-ci.yml` and the profile jobs. The
`standard` job runs `.dev-standard/cli/dev-standard check`, which reports each finding at its
group's level, so it can be a required check from the start.
New jobs check only changed files or changed lines (INS-004) and start in warn mode where the
platform allows it (for example `continue-on-error: true` on GitHub Actions) until the user
moves the group to `block`.

### 4.6 Branch protection: `chore: add branch protection rulesets`

1. Copy `templates/.github/rulesets/` to `.github/rulesets/` and `templates/.github/CODEOWNERS`
   to `.github/CODEOWNERS` (merge if one exists). Replace `@OWNER`.
2. Use `main.json` if the agent has its own GitHub identity, otherwise `main-solo.json` plus a
   `BRA-009` waiver (BRA-009). Set `required_status_checks` to the CI jobs at `block`.
3. If the repo already has protection, compare it with the ruleset and list the differences in
   the report. Never loosen existing protection.
4. Applying a ruleset changes the repository on GitHub and needs admin rights. Show the user
   the `gh api ... --method POST --input` commands from `.github/rulesets/README.md` and let
   them run or approve each one (BRA-011). On GitLab, give the settings from the table in
   `.dev-standard/standards/branching.md` instead.

## Phase 5 · Verify

1. Run `checks.fast` and `checks.full`. Both pass, or the report says why not.
   Run `python3 .dev-standard/cli/dev-standard check manifest adr trace branch` and fix
   or report every error.
2. Test one hook: on a scratch branch named `999-hook-test`, try to edit a file under
   `paths.source`. The edit must be blocked with `SDD-001`. Delete the branch afterward.
3. Confirm `git status` shows only the files listed in the report.
4. Set the report's status to `Applied` and list every file created or changed.

## Phase 6 · Hand off

Open a draft PR from `chore/adopt-dev-standard` using the repo's PR template. Its description
links the adoption report and lists:

- what is now enforced and at which level,
- the waivers and their expiry dates,
- the follow-up PRs from report Section 4 (reformat, renames, migrations), each separate (INS-006).

---

## Upgrading

1. `git -C .dev-standard fetch --tags && git -C .dev-standard checkout vX.Y.Z`
2. Read `.dev-standard/CHANGELOG.md` from the current version to the new one.
3. Reassess only the changed rules (Phase 2), add a dated "Upgrade to vX.Y.Z" section to the
   adoption report, and stop for approval (Phase 3).
4. Update the marked blocks, `version` in `.dev-standard.json`, and any changed templates.
   Re-run Phase 5.

## Uninstalling

See [standards/installation.md](standards/installation.md#uninstall).
