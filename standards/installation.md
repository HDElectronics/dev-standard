---
id: INS
title: Installation and adoption
version: 0.1.0
applies_to: all
based_on:
  - name: Software Engineering at Google, ch. 22 "Large-Scale Changes"
    url: https://abseil.io/resources/swe-book/html/ch22.html
  - name: Martin Fowler, "Strangler Fig Application"
    url: https://martinfowler.com/bliki/StranglerFigApplication.html
  - name: Git submodules
    url: https://git-scm.com/book/en/v2/Git-Tools-Submodules
  - name: git blame --ignore-revs-file
    url: https://git-scm.com/docs/git-blame#Documentation/git-blame.txt---ignore-revs-fileltfilegt
---

# Installation and adoption (INS)

How an agent brings dev-standard into a repository, new or existing. The agent learns the
repository first, proposes how the standard fits it, and changes nothing until the user
approves. Existing code is never rewritten to match the standard as a side effect of
installing it. The step-by-step runbook is [INSTALL.md](../INSTALL.md); this file holds the
rules that runbook follows.

## Rules

### INS-001 · MUST · Discover before changing anything

The first phase of an install is read-only. The agent inventories the repository and writes
`docs/dev-standard/adoption-report.md`. The first commit of the install contains only that file.

- **Why:** A standard applied without looking at the repo breaks working conventions, tools and CI that the team relies on.
- **Check:** advisory. The adoption PR's first commit is reviewed for this.

### INS-002 · MUST · Get the user's approval before applying

No file outside `docs/dev-standard/` changes until the user approves Sections 2 to 5 of the
adoption report. The agent asks its open questions in Section 6 and waits.

- **Why:** Profile choice, waivers and rollout order are product decisions with real cost. They belong to the user.
- **Check:** advisory. The report's approval checkbox is ticked by the user.

### INS-003 · MUST NOT · Overwrite or delete existing files

Existing files are merged, never replaced. Text files get a block between
`<!-- dev-standard:start vX.Y.Z -->` and `<!-- dev-standard:end -->` markers (or `# dev-standard:start`
in formats with `#` comments). Structured files (JSON, TOML, YAML) get only missing keys; a key
that already exists keeps its value unless the report lists the change and the user approved it.

- **Why:** Markers make the standard's content easy to find, upgrade and remove, and keep the repo's own content intact.
- **Check:** advisory. The report lists every file touched.

### INS-004 · MUST · Apply the standard to new and changed code

Existing code keeps its current conventions until a planned migration changes it. Rules apply
to code that is added or modified after install. Checks run on changed lines or changed files
(diff coverage, linting changed files), so old code does not block new work.

- **Why:** This is the ratchet: quality only goes up, one change at a time, without a big-bang rewrite (Strangler Fig).
- **Check:** CI jobs from the profiles run on the diff against the base branch.

### INS-005 · MUST · Record every deviation as a waiver

When the repo keeps doing something the standard forbids, the agent proposes a waiver and the
user approves it. Waivers live in `.dev-standard.json` with `rule`, `scope`, `reason`,
`approved_by`, `expires` and, when the gap will close, `plan`.

- **Why:** Unwritten exceptions turn into permanent drift. An expiry date forces the question again.
- **Check:** `schema/manifest.schema.json` validates waivers. Hooks honor unexpired waivers whose `scope` matches the file path.

### INS-006 · MUST · Ship mechanical changes in their own PR

Repo-wide reformatting, renames and file moves are never mixed into the install or into
feature work. Each is its own PR, produced by a tool, and its commit hash is added to
`.git-blame-ignore-revs`.

- **Why:** Large-scale changes are reviewed differently from logic changes (Google SWE book, ch. 22), and blame stays useful.
- **Check:** advisory. `PR-004` (one self-contained change) also applies.

### INS-007 · MUST · Roll out checks from warn to block

Groups that only affect new work (`AGT`, `BRN`, `SDD`, `GIT`, `BRA`) start at `block`. Every other
group starts at `warn` and moves to `block` once its checks are green on the base branch.
Levels are set per group in `.dev-standard.json` under `enforcement.groups`.

- **Why:** A check that blocks on day one over legacy code gets disabled. A warning that turns into a block on a known date gets fixed.
- **Check:** The hooks read the level for each group from `.dev-standard.json`.

### INS-008 · MUST · Make the fast check green before turning on hooks

`checks.fast` in `.dev-standard.json` is a command that passes on a clean checkout at install
time, such as the repo's existing lint and unit test commands scoped to changed files. The
Stop hook runs it (AGT-003).

- **Why:** A Stop hook over an already-failing command blocks every session.
- **Check:** The installing agent runs the command once and records the result in the report.

### INS-009 · MUST · Pin a release and upgrade on purpose

The repo pins a dev-standard release tag. An upgrade reads `CHANGELOG.md` from the current to
the new version, reassesses only the rules that changed, and goes through the same report and
approval steps.

- **Why:** A floating standard changes the rules under the team without a review.
- **Check:** `version` in `.dev-standard.json` matches the checked-out tag.

### INS-010 · SHOULD · Keep existing tools that meet the rule

If the repo already uses a tool that satisfies a rule (pre-commit instead of lefthook,
Prettier instead of Biome, mypy instead of pyright), keep it and record the equivalence in the
report instead of adding a second tool.

- **Why:** Two formatters or two hook managers fight each other. The rule matters, not the tool.
- **Check:** advisory.

### INS-011 · MUST · Follow the precedence order

When instructions conflict, agents follow this order:

1. The user's explicit instruction in the current task.
2. Approved waivers in `.dev-standard.json`.
3. The repo-specific conventions block in `AGENTS.md`, for existing code.
4. dev-standard rules.

- **Why:** The standard serves the repo. It must never override a decision the user already made.
- **Check:** advisory.

### INS-012 · MUST · Ask about what the repo can't answer, with a recommendation

The install is an interview ([install/interview.md](../install/interview.md)). The agent asks
the user about every decision that discovery can't settle, and never asks about what the repo
already shows. Each question states the evidence, offers 2 to 4 options with the recommended
one first, and comes in rounds of at most 4 questions. In Claude Code the agent uses the
AskUserQuestion tool; other agents ask numbered questions in chat and wait.

- **Why:** Guessing at a deployment target or a team size produces the wrong profile and the wrong protection. Asking about things the files already show wastes the user's attention and hides the questions that matter.
- **Check:** advisory. The interview log (INS-013) shows each question with its evidence.

### INS-013 · MUST · Log every answer in the adoption report

Each answer goes into the Interview section of `docs/dev-standard/adoption-report.md` as soon
as it is given: question ID, answer, and whether the user gave it or it was assumed in Quick
mode. The report's `Phase` field records where the install is. An agent that starts an install
reads the log first and resumes from the first unanswered round (`Q-RESUME-1`).

- **Why:** Installs get interrupted. The log lets any agent continue without asking twice, and it is the audit trail for why the repo is configured the way it is.
- **Check:** advisory. The adoption PR includes the report.

### INS-014 · MUST · Ask right before each action outside the repo

Even after the plan is approved, and in every mode, the agent asks again immediately before an
action that reaches outside the working tree: network installs (Spec Kit), installing tools,
pushing, opening a PR, and changing settings on the Git host such as branch protection.

- **Why:** Approving a plan is not approving each command that touches shared systems, and the user may want to run those commands themselves.
- **Check:** `no-bypass.sh` also asks before ruleset and branch protection changes.

## Reference

### What the install adds to a repo

| Path | Purpose | How it is added |
|------|---------|-----------------|
| `.dev-standard/` | This repository, pinned to a tag | git submodule (or vendored copy) |
| `.dev-standard.json` | Version, profiles, enforcement levels, waivers | new file |
| `AGENTS.md` | MUST rules, workflow, repo-specific conventions | marked block, merged |
| `CLAUDE.md` | `@AGENTS.md` import plus Claude notes | marked block, merged |
| `.claude/settings.json` | Agent hooks | hook entries merged into existing arrays |
| `.claude/commands/`, `.claude/agents/` | `/brainstorm`, `/pr`, reviewer subagent | new files |
| `.specify/` | Spec Kit, with dev-standard template additions | `specify init`, then merged |
| `.github/pull_request_template.md` | PR template | merged |
| `docs/adr/0000-template.md` | MADR template | new file |
| Profile configs | Formatter, linter, git hooks, CI | merged per profile |
| `docs/dev-standard/adoption-report.md` | The install record | new file |

### Uninstall

Remove the marked blocks, the hook entries that point into `.dev-standard/`, the files listed
as new in the adoption report, and the submodule (`git rm .dev-standard`).

## Sources

- [Software Engineering at Google, ch. 22: Large-Scale Changes](https://abseil.io/resources/swe-book/html/ch22.html)
- [Martin Fowler: Strangler Fig Application](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Pro Git: Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [git blame --ignore-revs-file](https://git-scm.com/docs/git-blame)
