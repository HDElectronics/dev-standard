---
id: SEC
title: Security baseline
version: 0.1.0
applies_to: all
based_on:
  - name: NIST SP 800-218 Secure Software Development Framework (SSDF)
    url: https://csrc.nist.gov/pubs/sp/800/218/final
  - name: OWASP Top 10
    url: https://owasp.org/www-project-top-ten/
  - name: OpenSSF Scorecard
    url: https://scorecard.dev/
---

# Security baseline (SEC)

Security rules for every repository, deployed or not. They cover secrets, dependencies, input validation, static analysis and what an agent may run. Services that are deployed also follow the production pack ([production/](production/README.md)).

## Rules

### SEC-001 · MUST NOT · Commit secrets

No API keys, passwords, tokens, private keys or connection strings with credentials in the repository, including tests and examples. Use environment variables locally and a secret manager in production (`OPS-005`).

- **Why:** Secrets in git history are effectively public and stay there after deletion. Rotating them is the only fix.
- **Check:** gitleaks in the pre-commit hook (lefthook) and in CI, both blocking. GitHub secret scanning and push protection where available.

### SEC-002 · MUST · Commit lockfiles and automate dependency updates

Commit `uv.lock`, `package-lock.json` or `pnpm-lock.yaml`. Renovate or Dependabot opens update PRs.

- **Why:** Lockfiles make builds reproducible and pin what was reviewed. Automated updates keep known vulnerabilities from piling up.
- **Check:** CI installs with the lockfile in frozen mode (`uv sync --frozen`, `npm ci`) and fails when it is missing or out of date.

### SEC-003 · MUST · Validate input at trust boundaries with a schema

Data crossing a trust boundary (HTTP requests, messages, files, environment, third-party responses) is parsed with a schema: Pydantic v2 models in Python, Zod in TypeScript. Reject what does not match; do not pass raw dictionaries inward.

- **Why:** Most injection and logic bugs start with unvalidated input. Parsing once at the edge gives typed data everywhere else.
- **Check:** Advisory. FastAPI enforces Pydantic models on declared parameters; review checks for raw `dict` or `any` at boundaries.

### SEC-004 · SHOULD · Justify every new dependency in the PR

For each new dependency, state its purpose, size, license and maintenance activity (recent releases, open issues, maintainers).

- **Why:** Every dependency is code you run and did not review. Supply-chain attacks target popular, unmaintained packages.
- **Check:** Advisory. Dependency review in CI (for example GitHub's dependency-review action) flags known-vulnerable or disallowed-license packages.

### SEC-005 · MUST NOT · Let an agent run destructive commands without confirmation

The agent asks a human before running commands that delete data or rewrite shared state: `rm -rf` outside temp folders, `git push --force`, `git reset --hard` on shared branches, `DROP` or `TRUNCATE`, and production deploys.

- **Why:** These actions are hard or impossible to reverse, and an agent acting on a wrong assumption can do serious damage in one command.
- **Check:** `no-bypass.sh` blocks force pushes to `main`. Claude Code permission settings deny or require approval for the other commands.

### SEC-006 · MUST · Run static analysis on every PR

CodeQL or Semgrep runs on every PR for each language in the repo. High and critical findings block.

- **Why:** SAST catches injection, unsafe deserialization and similar flaws that tests rarely exercise. NIST SSDF practice PW.7 calls for it.
- **Check:** CI workflow (CodeQL default setup, or `semgrep ci`), required status check.

## Reference

### Mapping to NIST SSDF

| SSDF practice | Covered by |
|---------------|------------|
| PO.1 Define security requirements | `SEC`, production pack, ASVS level in `plan.md` |
| PS.1 Protect all forms of code | Branch protection (`GIT-005`), no secrets (`SEC-001`) |
| PW.4 Reuse well-secured software | Dependency justification (`SEC-004`), lockfiles (`SEC-002`) |
| PW.7 Review and analyze code | Code review (`REV`), static analysis (`SEC-006`) |
| PW.8 Test executable code | Tests (`TST`), ZAP scans (`WEB-002`) |
| RV.1 Identify vulnerabilities on an ongoing basis | Renovate or Dependabot, image scanning (`OPS-002`) |

### lefthook (excerpt)

```yaml
pre-commit:
  commands:
    gitleaks:
      run: gitleaks git --staged --redact --verbose
```

The gitleaks command syntax changed in v8.19 (`gitleaks git` replaced `gitleaks protect`); match it to the installed version.

### Claude Code permission settings (excerpt)

```json
{
  "permissions": {
    "deny": ["Bash(git push --force:*)", "Bash(rm -rf /:*)"],
    "ask": ["Bash(rm -rf:*)", "Bash(git reset --hard:*)"]
  }
}
```

### OpenSSF Scorecard

Run Scorecard on the repository itself (GitHub Action `ossf/scorecard-action`) to track branch protection, pinned dependencies, token permissions and other hygiene checks.

## Sources

- [NIST SP 800-218 SSDF](https://csrc.nist.gov/pubs/sp/800/218/final)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OpenSSF Scorecard](https://scorecard.dev/)
- [gitleaks](https://github.com/gitleaks/gitleaks)
- [CodeQL](https://codeql.github.com/) and [Semgrep](https://semgrep.dev/)
- [Claude Code settings: permissions](https://docs.claude.com/en/docs/claude-code/settings)
