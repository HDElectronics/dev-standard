---
id: BRA
title: Branching and branch protection
version: 0.1.0
applies_to: all
based_on:
  - name: Trunk Based Development
    url: https://trunkbaseddevelopment.com/
  - name: DORA capability "Trunk-based development"
    url: https://dora.dev/capabilities/trunk-based-development/
  - name: Software Engineering at Google, ch. 16 "Version Control and Branch Management"
    url: https://abseil.io/resources/swe-book/html/ch16.html
  - name: GitHub rulesets
    url: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
  - name: OpenSSF Scorecard, Branch-Protection check
    url: https://github.com/ossf/scorecard/blob/main/docs/checks.md#branch-protection
  - name: SLSA
    url: https://slsa.dev/
---

# Branching and branch protection (BRA)

One long-lived branch, `main`, that is always releasable. Work happens on short branches that
each carry one task, and the server refuses anything that skips review or CI. This is
trunk-based development as described by trunkbaseddevelopment.com and measured by DORA, and
the single-trunk model Google describes for its own codebase. The protection rules are the
server-side half of `GIT-005` and `AGT-002`: the agent hooks stop the agent locally, branch
protection stops everyone, including an agent whose hooks are missing.

## Rules

### BRA-001 · MUST · Keep main as the only long-lived branch, always releasable

`main` is the integration branch and the release source. There are no `develop`,
`staging` or long-running feature branches. Every commit on `main` passes CI.

- **Why:** DORA's research links trunk-based development with higher delivery performance. Long-lived branches hide integration problems until a big, risky merge.
- **Check:** BRA-007 (protected `main`, required checks). A scheduled job can list branches other than `main` and `release/*` older than 3 days.

### BRA-002 · MUST · One short-lived branch per task

Each branch carries one task from `tasks.md`, or one fix or chore, and becomes one PR. It is
merged within 3 days, ideally within one. An agent keeps at most one open branch per task and
never pushes to a branch it didn't create.

- **Why:** One task per branch keeps PRs at the size Google recommends (`PR-002`) and keeps the merge cost near zero. DORA's guidance is three or fewer active branches and merging at least daily.
- **Check:** advisory. `/pr` refuses to open a PR whose diff spans tasks from several FR IDs without saying so.

### BRA-003 · MUST · Name branches by purpose

| Branch | Pattern | Example | Merges |
|--------|---------|---------|--------|
| Spec documents | `NNN-slug` (made by Spec Kit) | `013-faster-restock` | spec, plan, tasks, brainstorm, ADRs |
| One task of a spec | `NNN-tTTT-slug` | `013-t004-bom-parser` | code and tests for task T004 |
| Bug fix | `fix/slug` | `fix/cart-total-rounding` | |
| Chore, tooling | `chore/slug` | `chore/upgrade-ruff` | |
| Docs only | `docs/slug` | `docs/api-pagination` | |
| Release maintenance | `release/vMAJOR.MINOR` | `release/v1.4` | cherry-picks only (BRA-006) |

Git can't hold `013-faster-restock` and `013-faster-restock/t004` at the same time, so task
branches use a hyphen, not a slash.

- **Why:** The hooks read the spec number from the `NNN-` prefix, and reviewers can tell from the name what a PR should contain.
- **Check:** `require-spec.sh` relies on the prefix. A CI job can reject other patterns.

### BRA-004 · MUST · Merge the spec before the code, and hide unfinished work behind a flag

The flow for a feature is:

1. The spec branch (`NNN-slug`) merges the brainstorm, the spec and, after approval, the plan
   and tasks into `main` as a documents-only PR.
2. Each task branch (`NNN-tTTT-slug`) starts from the latest `main` and merges one task.
3. A feature that isn't complete yet ships behind a feature flag that defaults to off
   (OpenFeature, `OPS-008`), or behind an abstraction (branch by abstraction), never on a
   long-lived branch.

- **Why:** Trunk-based development keeps incomplete features on trunk, switched off. The approved spec on `main` is what `require-spec.sh` checks on every task branch.
- **Check:** `require-spec.sh` finds `specs/NNN-*/spec.md` on the task branch only if the spec PR was merged.

### BRA-005 · SHOULD · Rebase on main before asking for review

Update the branch from the latest `main` (`git fetch origin && git rebase origin/main`) before
marking the PR ready, and resolve conflicts on the branch. Force-push your own branch with
`--force-with-lease`, never plain `--force`.

- **Why:** Reviewers see the change as it will land, and CI tests the real result. `--force-with-lease` refuses to overwrite work you haven't seen.
- **Check:** BRA-008 requires branches to be up to date with `main` before merging.

### BRA-006 · MUST · Release from main with tags; fix forward, then cherry-pick

Releases are SemVer tags `vX.Y.Z` on `main` (`GIT-001` decides the bump). A `release/vX.Y`
branch is cut from a tag only when an older version still needs patches. A fix lands on `main`
first and is then cherry-picked with `git cherry-pick -x` into the release branch. Release
branches never merge back into `main`, and there are no code freezes on `main`.

- **Why:** Fixing trunk first guarantees the next release has the fix. `-x` records where each cherry-pick came from.
- **Check:** BRA-012 protects release tags. Review checks that a release-branch PR references the `main` commit it picks.

### BRA-007 · MUST · Protect main with a ruleset kept in the repo

`main` (the default branch) is protected by a ruleset stored as code in
`.github/rulesets/main.json` and applied with the GitHub API. It requires a pull request,
blocks direct pushes, force pushes and deletion, and requires linear history with squash
merges only (`PR-006`).

- **Why:** Settings changed by hand in a web UI drift and leave no review trail. A file in the repo is reviewed like code. OpenSSF Scorecard scores these settings in its Branch-Protection check.
- **Check:** `gh api repos/{owner}/{repo}/rulesets` matches the file. Scorecard runs in CI (`SEC`).

### BRA-008 · MUST · Require the blocking CI checks to pass on an up-to-date branch

The ruleset lists every CI job that `.dev-standard.json` sets to `block` as a required status
check, with "require branches to be up to date" turned on. A busy repo can use a merge queue
instead of the up-to-date requirement.

- **Why:** A check that isn't required can be merged past. Testing against the latest `main` catches two PRs that pass alone and break together.
- **Check:** The `required_status_checks` rule in `.github/rulesets/main.json`. When a group moves from `warn` to `block` (`INS-007`), its job is added here in the same PR.

### BRA-009 · MUST · Require a human approval of the latest push

At least one approval from a human other than the author of the latest push. Approvals are
dismissed when new commits arrive, and every review conversation is resolved before merge.

For a solo repository, choose one of two setups and record it in the adoption report:

- **Agent identity (recommended).** The agent commits and opens PRs as a separate GitHub
  account or GitHub App, so you are the reviewer and one approval is required.
- **Solo waiver.** Use `.github/rulesets/main-solo.json` (approvals set to 0, every other rule
  kept) and add a `BRA-009` waiver to `.dev-standard.json` with a reason and an expiry date.

- **Why:** `REV-004` makes a human the approver of agent-written code. GitHub doesn't let an author approve their own PR, so the identity setup decides whether the rule can be enforced.
- **Check:** The `pull_request` rule parameters in the ruleset file.

### BRA-010 · MUST · Make you a code owner of the enforcement files

`.github/CODEOWNERS` assigns you (or a maintainers team) to the files that define the rules,
and the ruleset requires code-owner review:

```text
/.dev-standard.json                @OWNER
/.claude/                          @OWNER
/.github/                          @OWNER
/.specify/memory/constitution.md   @OWNER
/docs/adr/                         @OWNER
```

- **Why:** An agent that can weaken a hook, a CI job or a waiver in the same PR it wants merged has no real gate. Code-owner review puts those changes in front of you.
- **Check:** `require_code_owner_review` in the ruleset.

### BRA-011 · MUST NOT · Bypass protection

The ruleset has no bypass actors. If an emergency needs one, an admin adds it temporarily,
says so in the PR, and removes it afterward. Agents never run `gh pr merge --admin`, never
change or delete rulesets, and never edit branch protection.

- **Why:** A bypass that anyone can use quietly is the same as no protection.
- **Check:** `no-bypass.sh` blocks `--admin` merges and asks you before any API call that changes rulesets or branch protection. `bypass_actors` is empty in the ruleset file.

### BRA-012 · MUST · Protect release tags

Tags matching `v*` can be created by the release process but never moved or deleted
(`.github/rulesets/release-tags.json`).

- **Why:** A moved tag silently changes what a version means, which breaks reproducible builds and SLSA provenance (`OPS-003`).
- **Check:** The tag ruleset.

### BRA-013 · SHOULD · Require signed commits on main

Turn on the `required_signatures` rule once every committer, including the agent identity,
signs commits (SSH or GPG keys, or Sigstore gitsign).

- **Why:** Signatures tie each commit on `main` to an identity, part of the source integrity SLSA describes.
- **Check:** Add `{ "type": "required_signatures" }` to `.github/rulesets/main.json`.

## Reference

### Applying the rulesets (GitHub)

Rulesets need admin rights on the repository. For private repositories they need a paid
GitHub plan; check your plan before relying on them. Apply them with:

```bash
gh api repos/{owner}/{repo}/rulesets --method POST --input .github/rulesets/main.json
gh api repos/{owner}/{repo}/rulesets --method POST --input .github/rulesets/release-tags.json
```

To update an existing ruleset, find its ID with `gh api repos/{owner}/{repo}/rulesets` and send
the file with `--method PUT` to `repos/{owner}/{repo}/rulesets/{id}`. Changing protection is an
outward-facing action: the agent prepares the command and you run or approve it.

Also set, under repository settings: allow squash merging only, and automatically delete head
branches. Turn on secret scanning push protection where available (`SEC-001`).

### GitLab equivalents

| GitHub ruleset rule | GitLab setting |
|---------------------|----------------|
| Require pull request, block direct push | Protected branch: Allowed to push = No one; Allowed to merge = Maintainers |
| Block force pushes | Protected branch: Allowed to force push = off |
| Required status checks | Merge checks: Pipelines must succeed |
| Required approvals, code owners | Merge request approval rules, Code Owners (some need a paid tier) |
| Conversation resolution | Merge checks: All threads must be resolved |
| Squash only, linear history | Merge method: Fast-forward merge; Squash commits: Require |
| Protected tags | Protected tags `v*` |

### Feature lifecycle on branches

```text
main ──●────────●──────────●──────────●──────────●── tag v1.5.0
        \      / spec PR    \        /  \        /
         013-faster-restock  013-t001-…  013-t002-…   (flag off until the last task)
```

## Sources

- [Trunk Based Development](https://trunkbaseddevelopment.com/)
- [DORA: Trunk-based development](https://dora.dev/capabilities/trunk-based-development/)
- [Software Engineering at Google, ch. 16](https://abseil.io/resources/swe-book/html/ch16.html)
- [GitHub: About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub REST API: Repository rulesets](https://docs.github.com/en/rest/repos/rules)
- [OpenSSF Scorecard checks](https://github.com/ossf/scorecard/blob/main/docs/checks.md)
- [SLSA](https://slsa.dev/)
