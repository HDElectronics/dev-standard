# Install interview

The questions an agent asks the user while installing dev-standard. [INSTALL.md](../INSTALL.md)
says when each round happens; this file says what to ask, when to skip a question, and what
each answer changes. Rules: `INS-012` to `INS-014` in
[standards/installation.md](../standards/installation.md).

## How to ask

1. **Ask only what the repo can't tell you.** Run discovery first. If a file, a config or the
   git history answers a question, don't ask it. Put the evidence in the question instead
   ("I found `app/main.py` with FastAPI and `web/` with Vite + React").
2. **Recommend.** Put the recommended option first and mark it `(Recommended)`. Base the
   recommendation on what you found and say why in its description.
3. **Small rounds.** At most 4 questions per round, 2 to 4 options each. The user can always
   answer in their own words.
4. **In Claude Code, use the AskUserQuestion tool.** Use `header` for the question ID's topic
   (12 characters max), `multiSelect` where noted, and `preview` to show file snippets, such as
   the `AGENTS.md` block or a ruleset, when the user is choosing between them.
5. **In other agents, ask in chat.** Number the questions, letter the options, mark the
   recommended one, and wait for the answer before continuing:

   ```text
   Q-SCOPE-3 · How strict should the checks be at first?
     a) Gradual (recommended): workflow gates block now; style, docs and tests warn until green
     b) Strict: everything blocks from day one
     c) Advisory: everything only warns
   ```

6. **Log every answer right away** in the Interview section of
   `docs/dev-standard/adoption-report.md`: question ID, the answer, and whether the user gave it
   or it was assumed in Quick mode. The log is how an interrupted install resumes (`INS-013`).
7. **Never ask for secrets** (tokens, passwords, keys). If a step needs one, tell the user
   which command to run themselves.

## Modes

The first question (`Q-START-1`) picks one of three modes.

| Mode | What the agent asks |
|------|---------------------|
| **Guided** | Every question below whose condition applies. |
| **Quick** | Only questions that have no recommended answer, every conflict that would change existing code, the plan approval (`Q-APPROVE-1`), and every action outside the repo (Round 5). Every other answer takes the recommended option and is logged as `assumed`. |
| **Report only** | Rounds 0 to 3, then stop after writing the adoption report. Nothing else changes. |

Whatever the mode, the plan approval and the Round 5 actions are always asked (`INS-002`, `INS-014`).

## Round 0 · Start (before Phase 1)

### Q-RESUME-1 · Resume or restart

- **Ask when:** `docs/dev-standard/adoption-report.md` exists and its `Phase` is not `Applied`.
- **Question:** "I found an unfinished dev-standard install from {date}, stopped at {phase}. Continue it?"
- **Options:** Continue from {phase} (Recommended) · Start over (the old report is kept as `adoption-report.{date}.md`) · Stop
- **Changes:** Where the install resumes. On Continue, skip every question already in the log.

### Q-START-1 · Install mode

- **Ask when:** always.
- **Question:** "How do you want to run the install?"
- **Options:** Guided (Recommended): I ask before each decision · Quick: I take my recommendations and ask only about conflicts, approval and actions outside the repo · Report only: I study the repo and write a report; nothing else changes
- **Changes:** The mode for the rest of the interview.

### Q-START-2 · How dev-standard is added

- **Ask when:** `.dev-standard/` doesn't exist.
- **Question:** "dev-standard isn't in this repo yet. How should I add it?"
- **Options:** Git submodule pinned to the latest release (Recommended): easy to upgrade · Vendored copy: plain files, no submodule; upgrades are manual
- **Changes:** Phase 0. Record the version either way.

### Q-START-3 · Uncommitted changes

- **Ask when:** `git status --porcelain` prints anything.
- **Question:** "There are uncommitted changes in {n} files. What should I do before starting?"
- **Options:** Stop so you can commit them (Recommended) · Stash them (`git stash push -u`), restore at the end · Continue on top of them (the install PR will include them)
- **Changes:** Phase 0. Never discard the changes.

## Round 1 · Confirm the picture (after Phase 1)

### Q-REPO-1 · Discovery summary

- **Ask when:** always, as one question with the summary in its text or `preview`.
- **Question:** "Here is what I found: {languages and frameworks with paths, tools, CI, commit style, existing agent files, decision records}. Is this right?"
- **Options:** Yes (Recommended) · Mostly; I'll correct a detail · No; let me explain
- **Changes:** Report Section 1. Corrections override discovery.

### Q-REPO-2 · Deployment

- **Ask when:** discovery found no deployment signals (Dockerfile, compose, IaC, hosting config), or found them but can't tell whether they are used.
- **Question:** "Is this project deployed, or will it be?"
- **Options:** Yes, it runs in production · Later; it will be deployed · No; it's a library, tool or local project
- **Recommendation:** "Yes" if deploy files exist, "No" otherwise.
- **Changes:** `deployed`. "Later" sets `deployed: true` with the production groups (`AUTH` to `DAT`) at `warn`.

### Q-REPO-3 · Who works on the repo

- **Ask when:** always, unless `CODEOWNERS` or more than one recent committer already shows a team. In that case, state what you found and skip.
- **Question:** "Who works on this repo?"
- **Options:** Just me, with coding agents · A small team (2 to 5) · A larger team
- **Changes:** Approvals and code owners (`BRA-009`, `BRA-010`), review expectations (`REV-005`).

### Q-REPO-4 · The agent's GitHub identity

- **Ask when:** the remote is on GitHub and the answer to `Q-REPO-3` is "Just me".
- **Question:** "GitHub won't let you approve your own PR. Under which identity should the agent push and open PRs?"
- **Options:** A separate bot account or GitHub App (Recommended): you approve its PRs · My own account: approvals set to 0, with a `BRA-009` waiver
- **Changes:** Which ruleset: `main.json` or `main-solo.json`, and the waiver.

## Round 2 · Scope and strictness (Phase 2)

### Q-SCOPE-1 · Profiles

- **Ask when:** always. `multiSelect`. Pre-select (and list first) the profiles discovery supports; `base` is always on and isn't offered.
- **Question:** "Which profiles should apply? I recommend the ones that match what I found."
- **Options:** `python-api` (FastAPI found in `app/`) · `react-web` (React found in `web/`) · `c-embedded` · None beyond base
- **Changes:** `profiles`. A frontend in another framework gets the `UI-001`/`UI-002` waiver question in Round 3, never a rewrite.

### Q-SCOPE-2 · Packs

- **Ask when:** discovery found signals: LLM SDK imports (`anthropic`, `openai`, `langchain`…) for `llm`, a mobile app for `mobile`, firmware for `embedded-c`. `multiSelect`.
- **Question:** "I found {signal}. Add the matching pack?"
- **Options:** One per signal found · None
- **Changes:** `packs`.

### Q-SCOPE-3 · Strictness

- **Ask when:** always.
- **Question:** "How strict should the checks be at first?"
- **Options:** Gradual (Recommended for an existing repo): workflow gates (`AGT`, `BRN`, `SDD`, `GIT`, `BRA`) block now, everything else warns until it's green · Strict (Recommended for a new repo): everything blocks from day one · Advisory: everything only warns
- **Changes:** `enforcement` in `.dev-standard.json` (`INS-007`).

### Q-SCOPE-4 · Fast check command

- **Ask when:** always. Run each candidate first and list only those that pass, with their run time.
- **Question:** "Which command should run before the agent finishes a task? It must pass today."
- **Options:** Each passing candidate, e.g. `uv run ruff check . && uv run pytest -m small` (passed in 14 s) · Lint changed files only · None for now (the Stop hook stays off)
- **Changes:** `checks.fast` (`INS-008`).

## Round 3 · Conflicts (Phase 2; repeat until every conflict is decided)

### Q-CONFLICT-n · One per conflict

- **Ask when:** for each row of report Section 4. In Quick mode, ask only conflicts whose recommended option would change existing code.
- **Question:** "Your repo {does X} ({evidence}). Rule {ID} says {Y}. What should happen?"
- **Options, in this order with one marked recommended:** Apply to new and changed code only (the default, `INS-004`) · Keep as is with a waiver · Migrate in a separate PR later · Adopt now (offer only when the change is cheap and mechanical)
- **Changes:** Report Section 4, waivers, follow-up PRs.

### Q-CONFLICT-AGENTS · Existing agent instructions

- **Ask when:** existing `AGENTS.md`, `CLAUDE.md`, `.cursorrules` or `.github/copilot-instructions.md` text contradicts a MUST rule. Use `preview` to show both texts.
- **Question:** "Your {file} says {quote}. The standard says {rule}. Which should agents follow?"
- **Options:** Keep yours: recorded as a repo-specific convention with a waiver · Use the standard: I'll mark your line for you to remove · Decide later: both stay; yours wins (`INS-011`)
- **Changes:** The repo-specific conventions block and waivers. The agent never edits the user's own lines (`INS-003`).

### Q-WAIVER-EXPIRY · Waiver expiry

- **Ask when:** at least one waiver was chosen. Ask once for all of them.
- **Question:** "When should the {n} waivers expire, so they get reviewed again?"
- **Options:** In 6 months (Recommended) · In 3 months · In 12 months
- **Changes:** `expires` on each waiver (`INS-005`).

## Round 4 · Approve the plan (end of Phase 3)

### Q-APPROVE-1 · Plan approval

- **Ask when:** always, in every mode. Show the plan in the question or `preview`: profiles, strictness, waivers, the commits in report Section 5, and the files that will change.
- **Question:** "Here is the plan. Approve it?"
- **Options:** Approve and apply (Recommended) · Change something first · Stop here and keep the report
- **Changes:** Report status `Approved` and Phase 4, or back to the round the change belongs to, or the end.

## Round 5 · Actions outside the repo (Phase 4; ask right before each, in every mode)

### Q-ACT-1 · Install Spec Kit

- **Ask when:** `.specify/` doesn't exist.
- **Question:** "Spec Kit is installed with `uvx` from GitHub (network access). Run it now?"
- **Options:** Yes, run it (Recommended) · Skip; I'll install it myself
- **Changes:** Step 4.2.

### Q-ACT-2 · Git hook manager

- **Ask when:** step 4.4 needs to install or enable a tool (`lefthook install`, `pre-commit install`).
- **Question:** "Install the git hooks with `{command}` now?"
- **Options:** Yes (Recommended) · I'll run it myself
- **Changes:** Step 4.4.

### Q-ACT-3 · Branch protection

- **Ask when:** the remote is on GitHub. Say whether the repo is private, since rulesets there need a paid plan.
- **Question:** "Branch protection changes the repo on GitHub and needs admin rights. How should we apply it?"
- **Options:** Show me the commands; I'll run them (Recommended) · Run them now; ask me before each · Skip for now
- **Changes:** Step 4.6. On GitLab, give the settings table instead.

## Round 6 · Hand off (Phase 6)

### Q-END-1 · Pull request

- **Ask when:** always.
- **Question:** "Everything is applied on `chore/adopt-dev-standard`. Open the PR?"
- **Options:** Open a draft PR (Recommended) · Push the branch only · Leave it local
- **Changes:** Phase 6.

### Q-END-2 · First decision records

- **Ask when:** the repo has no ADRs yet. `multiSelect`.
- **Question:** "Which decisions should I record now as proposed ADRs? You accept them afterward."
- **Options:** Backend stack ({found}) · Frontend build ({found}) · Auth provider · Deploy target
- **Changes:** New files in `docs/adr/` with `status: proposed` (`ADR-005`).
