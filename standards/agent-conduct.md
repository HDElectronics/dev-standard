---
id: AGT
title: Agent conduct
version: 0.1.0
applies_to: all
based_on:
  - name: dev-standard (agent-specific)
    url: ""
  - name: Google Engineering Practices, The CL author's guide
    url: https://google.github.io/eng-practices/review/developer/
---

# Agent conduct (AGT)

How a coding agent behaves while it works in a repository that follows dev-standard. These rules target the failure modes agents actually show: skipping checks, editing tests to go green, widening scope, and claiming a task is done before it is. They apply to every agent (Claude Code first, and any agent that reads `AGENTS.md`) and to humans working the same way.

Rules for installing or upgrading dev-standard in a repository live in [installation.md](installation.md) (`INS`).

## Rules

### AGT-001 · MUST · Read the spec, plan and tasks before editing code

Before you change source code on a feature branch, read `specs/NNN-slug/spec.md`, `plan.md` and `tasks.md`, and identify which task you are working on.

- **Why:** The spec is the contract. Code written without it drifts from what was approved, and the drift is found late, in review or in production.
- **Check:** `require-spec.sh` (PreToolUse hook) blocks source edits on a feature branch until the spec is approved. Reading is advisory; the reviewer checks that the PR names its task (`PR-003`).

### AGT-002 · MUST NOT · Bypass checks

Do not use `git commit --no-verify` or `git push --no-verify`, do not add blanket `eslint-disable`, `biome-ignore` or `# noqa` comments without a reason, and do not skip or delete tests to make a run pass.

- **Why:** A check that the agent can switch off is not a check. Every bypass hides a problem from the human who approves the change.
- **Check:** `no-bypass.sh` (PreToolUse hook on Bash) rejects `--no-verify` and force pushes to `main`. CI re-runs every check regardless of local hooks. Lint rules require a reason on suppressions where the tool supports it (for example Biome requires an explanation after `biome-ignore`).

A targeted suppression is allowed when it names the rule and the reason:

```python
result = eval_expression(text)  # noqa: S307 -- input is a parsed AST from our own grammar, not user text
```

### AGT-003 · MUST · Run checks before saying a task is done, and report results as they are

Before you report a task as done, run format, lint, type check and tests. Report the commands you ran and their actual results, including failures.

- **Why:** "Done" from an agent is only useful if it means the same thing every time. Unreported failures cost more to find later than to state now.
- **Check:** `definition-of-done.sh` (Stop hook) runs the fast check suite and blocks the agent from stopping while it fails. CI enforces the same checks as required status checks.

### AGT-004 · MUST NOT · Change a test's assertion to make it pass without saying why

If a test fails, fix the code. If the test itself is wrong, change it and explain why in the PR description under "How I tested".

- **Why:** Weakening an assertion is the easiest way for an agent to turn a red run green, and it silently removes protection for a behavior someone wanted.
- **Check:** Advisory. The reviewer subagent flags diffs that modify assertions in test files together with source changes (`REV-002`).

### AGT-005 · MUST · Stay inside the current task

Change only what the current task needs. Record anything else you notice (bugs, refactors, missing docs) in the PR's "Follow-ups (out of scope)" section.

- **Why:** Scope creep makes PRs large and hard to review (`PR-002`, `PR-004`), and mixes unrelated risk into one change.
- **Check:** Advisory. PR size warnings (`PR-002`) and review catch most cases.

### AGT-006 · SHOULD · Ask one precise question when a requirement is ambiguous

When a requirement can be read in more than one way, stop and ask one specific question that offers the readings you see, instead of picking one silently.

- **Why:** A guess turns into code, tests and docs that all have to be redone. One question costs less.
- **Check:** Advisory.

## Reference

### Definition of done

A task is done when all of these are true:

| Item | Evidence |
|------|----------|
| Code matches the task in `tasks.md` and its requirement IDs | Task checkbox ticked, FR IDs in test names |
| Formatter, linter and type checker pass | Command output |
| Tests pass, including a new test for new behavior | Command output, diff coverage (`TST-003`) |
| Docs and changelog updated where behavior changed | Diff of `docs/` or explanation (`DOC-007`) |
| PR description complete | Template sections filled (`PR-003`) |

### Commands per profile

| Profile | Format | Lint | Types | Tests |
|---------|--------|------|-------|-------|
| `python-api` | `uv run ruff format --check .` | `uv run ruff check .` | `uv run pyright` | `uv run pytest` |
| `react-web` | `npx biome format .` | `npx biome lint .` | `npx tsc --noEmit` | `npx vitest run` |

### Agent instruction files

`AGENTS.md` is the canonical instruction file in a consuming repo. `CLAUDE.md` contains one line, `@AGENTS.md`, so Claude Code imports the same content. Other agents (Codex, Cursor, Copilot) read `AGENTS.md` directly.

## Sources

- [Google Engineering Practices: The CL author's guide](https://google.github.io/eng-practices/review/developer/)
- [Claude Code hooks](https://docs.claude.com/en/docs/claude-code/hooks)
- [AGENTS.md](https://agents.md/)
