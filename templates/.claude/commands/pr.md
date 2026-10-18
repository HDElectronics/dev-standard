---
description: Check, self-review and open a draft pull request (dev-standard PR, GIT)
argument-hint: [optional notes for the description]
---

# /pr

Open a draft pull request for the current branch. Rules: GIT and PR groups in `.dev-standard/standards/`, plus AGT-003.

Extra notes from the user: `$ARGUMENTS`

## Steps

1. **Check the branch.** Stop if you are on `main` (GIT-005). The branch name follows BRA-003: `NNN-slug` (spec documents), `NNN-tTTT-slug` (one task), `fix/slug`, `chore/slug` or `docs/slug`. Rebase on `origin/main` first (BRA-005).
2. **Check the scope.** Run `git diff --stat main...HEAD`.
   - One concern only (PR-004). If the diff mixes a refactor with a feature, stop and propose splitting it.
   - Count changed lines without lockfiles and generated code. Above about 400, suggest a split. Above 1000, a split is required unless the user gives a reason, which goes in the description (PR-002).
3. **Run the checks.** Run the `checks.fast` command from `.dev-standard.json`, then the full test suite. Report the results as they are (AGT-003). If anything fails, stop and fix it or report it; never open the PR with failing checks claimed as passing.
4. **Check the commits.** Every commit since `main` follows Conventional Commits with a header of 72 characters or fewer (GIT-001). If one does not, tell the user; do not rewrite pushed history without asking.
5. **Self-review.** Ask the `standard-reviewer` subagent to review `git diff main...HEAD`. Resolve every `(blocking)` finding, or list it under Risk with the reason it stays.
6. **Write the title.** A Conventional Commit line, imperative, 72 characters or fewer: `feat(cart): match pasted BOM lines by SKU` (PR-001).
7. **Fill the template.** Use `.github/pull_request_template.md`. Fill every section:
   - **What and why**: self-contained; a reader should not need the issue.
   - **Spec**: `NNN-slug · tasks Txxx · FR-xxx`, or the issue link for `fix/` and `chore/`.
   - **How I tested**: the commands from step 3 and their summary lines.
   - **Risk and rollback**, **Follow-ups**: write `n/a` with a reason if empty.
   - Tick only the self-review boxes that are true.
8. **Push and open as draft.**
   ```bash
   git push -u origin HEAD
   gh pr create --draft --title "<title>" --body-file <file with the filled template>
   ```
9. **Report** the PR URL and anything still open. The PR stays a draft until CI is green; a human approves it (PR-006, REV-004).
