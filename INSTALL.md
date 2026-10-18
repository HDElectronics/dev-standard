# Installing dev-standard

This file is a runbook for a coding agent. The install is an interview: the agent studies the
repo, asks the user about whatever the repo can't tell it, and applies only what the user
approved. Start it in one of two ways:

- With the dev-standard Claude Code plugin: run `/dev-standard:install`.
- In any agent: say *"Install dev-standard: follow `.dev-standard/INSTALL.md`"*, or, if the repo
  doesn't have it yet, *"Install dev-standard from https://github.com/HDElectronics/dev-standard
  by following its INSTALL.md"*.

The agent works through the phases below in order. Each **Ask** step is a round of questions
from [install/interview.md](install/interview.md), which says what to ask, when to skip a
question, and what each answer changes. The rules behind each step are in
[standards/installation.md](standards/installation.md) (`INS-*`).

**Agent: four rules hold for the whole install.**

1. Phases 1 to 3 are read-only, apart from writing the adoption report (INS-001).
2. Ask before deciding: anything the repo doesn't answer is a question to the user, with your
   recommendation and the evidence for it (INS-012). Log each answer in the report (INS-013).
3. Apply nothing until the user approves the plan in `Q-APPROVE-1` (INS-002), and ask again
   right before each action outside the repo (INS-014).
4. Never overwrite or delete an existing file. Merge into it (INS-003).

---

## Phase 0 · Start

**Ask: Round 0** (`Q-RESUME-1`, `Q-START-1` to `Q-START-3`): resume or restart, install mode,
how to add dev-standard, uncommitted changes.

1. Add dev-standard if it isn't there yet, the way the user chose in `Q-START-2`. Pin the latest
   release tag (INS-009), or `main` if there is no release yet, and record which:

   ```bash
   git submodule add https://github.com/HDElectronics/dev-standard.git .dev-standard
   tag=$(git -C .dev-standard tag --list 'v*' --sort=-v:refname | head -n 1)
   [ -n "$tag" ] && git -C .dev-standard checkout "$tag"
   git add .gitmodules .dev-standard
   ```

   For a vendored copy, download that release into `.dev-standard/` instead.
2. Handle uncommitted changes as the user chose in `Q-START-3`. Never discard them.
3. Create the branch `chore/adopt-dev-standard` from the default branch.
4. Read `.dev-standard/README.md`, `.dev-standard/standards/README.md`,
   `.dev-standard/standards/installation.md` and `.dev-standard/install/interview.md`.
5. Copy the report template to `docs/dev-standard/adoption-report.md`, set its `Phase` to
   `Discover`, and log the Round 0 answers.

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

**Greenfield shortcut.** For a new repo, skip the rule-by-rule assessment in Phase 2: ask about
the intended stack in Round 2 instead of detecting it, recommend `Strict` in `Q-SCOPE-3`, and note
"greenfield" in the report. Phases 3 to 6 still apply.

**Ask: Round 1** (`Q-REPO-1` to `Q-REPO-4`): confirm the discovery summary, deployment, who works
on the repo, and the agent's GitHub identity. Apply the user's corrections to Section 1 before
assessing.

## Phase 2 · Assess (read-only)

**Ask: Round 2** (`Q-SCOPE-1` to `Q-SCOPE-4`) once steps 1 to 3 below have produced your
recommendations: profiles, packs, strictness, and the fast check command.

1. **Recommend profiles** (report Section 2):
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

**Ask: Round 3** (`Q-CONFLICT-n`, `Q-CONFLICT-AGENTS`, `Q-WAIVER-EXPIRY`): one question per
conflict, four per round, until every conflict in Section 4 has a decision.

## Phase 3 · Propose and approve

1. Fill Section 5 (rollout plan) of the report from the answers so far, and set `Phase` to
   `Propose`.
2. Commit only the report: `docs: add dev-standard adoption report`.
3. In **Report only** mode, stop here and tell the user where the report is.
4. **Ask: Round 4** (`Q-APPROVE-1`): show the plan and ask for approval. If the user wants
   changes, go back to the round they belong to, then ask `Q-APPROVE-1` again. Continue only on
   "Approve and apply": set the report's status to `Approved` and `Phase` to `Apply`.

## Phase 4 · Apply (one commit per step)

Use the user's approved choices. For every existing file, merge (INS-003). Replace
`{{PLACEHOLDERS}}` in templates with real values. **Ask: Round 5** happens inside this phase:
ask `Q-ACT-1`, `Q-ACT-2` and `Q-ACT-3` right before the step that needs them, in every mode.

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

1. Install GitHub Spec Kit if `.specify/` doesn't exist and the user said yes to `Q-ACT-1`.
   Check `specify init --help` for the current flags:

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
[profiles/README.md](profiles/README.md). Install the git hook manager the report chose, if the
user said yes to `Q-ACT-2`. Don't reformat the repo in this commit (INS-006).

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
2. Use `main.json` or `main-solo.json` plus a `BRA-009` waiver, per the answer to `Q-REPO-4`.
   Set `required_status_checks` to the CI jobs at `block`.
3. If the repo already has protection, compare it with the ruleset and list the differences in
   the report. Never loosen existing protection.
4. Applying a ruleset changes the repository on GitHub and needs admin rights. Do what the
   user chose in `Q-ACT-3`: show the `gh api ... --method POST --input` commands from
   `.github/rulesets/README.md`, or run them one at a time with the user's approval for each
   (BRA-011). On GitLab, give the settings from the table in
   `.dev-standard/standards/branching.md` instead.

## Phase 5 · Verify

1. Run `checks.fast` and `checks.full`. Both pass, or the report says why not.
   Run `python3 .dev-standard/cli/dev-standard check manifest adr trace branch` and fix
   or report every error.
2. Test one hook: on a scratch branch named `999-hook-test`, try to edit a file under
   `paths.source`. The edit must be blocked with `SDD-001`. Delete the branch afterward.
3. Confirm `git status` shows only the files listed in the report.
4. Set the report's status and `Phase` to `Applied` and list every file created or changed.

## Phase 6 · Hand off

**Ask: Round 6** (`Q-END-1`, `Q-END-2`): how to hand over the branch, and which decisions to
record as proposed ADRs.

If the user chose a PR, open it as a draft from `chore/adopt-dev-standard` using the repo's PR
template. Its description links the adoption report and lists:

- what is now enforced and at which level,
- the waivers and their expiry dates,
- the follow-up PRs from report Section 4 (reformat, renames, migrations), each separate (INS-006).

---

## Upgrading

1. `git -C .dev-standard fetch --tags && git -C .dev-standard checkout vX.Y.Z`
2. Read `.dev-standard/CHANGELOG.md` from the current version to the new one.
3. Reassess only the changed rules (Phase 2), add a dated "Upgrade to vX.Y.Z" section to the
   adoption report, ask Round 3 for any new conflicts, and ask `Q-APPROVE-1` (Phase 3).
4. Update the marked blocks, `version` in `.dev-standard.json`, and any changed templates.
   Re-run Phase 5.

## Uninstalling

See [standards/installation.md](standards/installation.md#uninstall).
