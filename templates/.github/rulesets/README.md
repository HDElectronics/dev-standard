# Rulesets (BRA-007 to BRA-012)

GitHub repository rulesets kept as code. Apply them with the GitHub API; the installing agent
prepares the commands and you run or approve them, because they change the repository on
GitHub and need admin rights.

| File | Protects | Rules |
|------|----------|-------|
| `main.json` | the default branch | PR required, 1 human approval of the latest push, code owners, resolved threads, squash only, linear history, required checks on an up-to-date branch, no force push, no deletion |
| `main-solo.json` | the default branch, solo repo | same, with approvals set to 0. Use only with a `BRA-009` waiver |
| `release-tags.json` | tags `v*` | no deletion, no move |

Before applying:

1. Set `required_status_checks` to the CI jobs that `.dev-standard.json` sets to `block`. The
   context is the job ID in the workflow (`secrets`, `commits`, `standard`, `python`, `web`). `standard` reports by each group's level itself, so it can be required from day one.
2. Use `main.json` if the agent works under its own GitHub identity, otherwise `main-solo.json`.
3. Add `{ "type": "required_signatures" }` once every committer signs commits (BRA-013).

```bash
gh api repos/{owner}/{repo}/rulesets --method POST --input .github/rulesets/main.json
gh api repos/{owner}/{repo}/rulesets --method POST --input .github/rulesets/release-tags.json
```

Rulesets on private repositories need a paid GitHub plan. GitLab equivalents are in
`.dev-standard/standards/branching.md`.
