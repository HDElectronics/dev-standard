# dev-standard

A versioned engineering standard that coding agents install, follow, and can't quietly skip.

Every rule has an ID, an [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) level, the published
standard it comes from, and the check that enforces it. Rules are adopted from established
sources (Google Engineering Practices and Style Guides, GitHub Spec Kit, EARS, OWASP, IETF
RFCs, NIST, Google SRE, Twelve-Factor) rather than invented.

## Install into a repo

The install is an interview run by your coding agent. Start it in either way:

- **Claude Code with the plugin** (the repo is its own marketplace):

  ```text
  /plugin marketplace add HDElectronics/dev-standard
  /plugin install dev-standard@dev-standard
  /dev-standard:install
  ```

- **Any agent:** tell it

  > Install dev-standard from https://github.com/HDElectronics/dev-standard by following its INSTALL.md.

The agent adds dev-standard as a pinned submodule (`.dev-standard/`), studies your repo, and
then asks you about what it couldn't work out on its own: whether the project is deployed, who
works on it, which profiles fit, how strict to start, and what to do about each place where your
repo differs from the standard. Every question comes with its recommendation and the evidence
for it. Choose **Quick** mode and it only asks about conflicts, the final plan and actions
outside the repo.

Nothing changes until you approve the plan. The agent then merges the standard in without
overwriting your files. Existing code keeps its conventions; the standard applies to new and
changed code. Every answer is logged in `docs/dev-standard/adoption-report.md`, so an
interrupted install picks up where it stopped. See [INSTALL.md](INSTALL.md),
[install/interview.md](install/interview.md) and
[standards/installation.md](standards/installation.md).

The plugin does nothing in repos without `.dev-standard.json`.

## How work flows after install

1. **Brainstorm**: `/brainstorm <slug> "problem"` creates an interactive board
   ([example](templates/brainstorm/brainstorm.html)). You frame the problem, compare at least five
   options, and record a decision.
2. **Spec**: [GitHub Spec Kit](https://github.com/github/spec-kit) as is:
   `/speckit.specify`, `/speckit.clarify` (you approve), `/speckit.plan`, `/speckit.tasks`,
   `/speckit.analyze`, `/speckit.implement`. Requirements use EARS; plans use Google design-doc
   sections.
3. **Ship**: one task per short-lived branch off `main` (trunk-based), small PRs per Google's
   guidance, Conventional Commits, review with Conventional Comments. `main` is protected by
   rulesets kept in the repo.
4. **Remember**: significant decisions go into the ADR log in `docs/adr/` and bind later work
   until a new ADR supersedes them.

Agent hooks enforce the gates: no spec without a decided brainstorm, no source edits before
the spec is approved, no ADR accepted by the agent, no skipped git hooks, no `--admin` merges,
no finishing while checks fail.

## Layout

| Path | Contents |
|------|----------|
| [docs/guide/](docs/guide/index.html) | The illustrated guide: workflow, screenshots, real hook and CI output, install, full rule catalog. Open `docs/guide/index.html` in a browser; rebuild with `python3 docs/guide/build.py` |
| [INSTALL.md](INSTALL.md) | Runbook an agent follows to adopt the standard |
| [install/interview.md](install/interview.md) | The questions the agent asks during install, and what each answer changes |
| [standards/](standards/README.md) | The rules, one file per group |
| [standards/production/](standards/production/README.md) | Production pack for deployed backends |
| [templates/](templates/) | Files copied or merged into adopting repos |
| [profiles/](profiles/README.md) | Config fragments per stack: `base`, `python-api`, `react-web` |
| [enforce/hooks/](enforce/hooks/) | Claude Code hooks |
| [cli/dev-standard](cli/dev-standard) | `dev-standard check`: CI checks for rules the hooks can't see (Python 3.11+, stdlib only) |
| [.claude-plugin/](.claude-plugin/plugin.json), [plugin/](plugin/hooks.json) | Claude Code plugin and marketplace |
| [tests/](tests/test_dev_standard.py) | Tests for the hooks and the CLI |
| [docs/adr/](docs/adr/README.md) | This repo's own decision log |
| [schema/](schema/manifest.schema.json) | Schema for `.dev-standard.json` |

## Default stack

| Layer | Default | Rule |
|-------|---------|------|
| Backend | FastAPI, Python 3.12+, uv, Pydantic v2, SQLAlchemy 2 + Alembic | `python-api` profile |
| Frontend | React + TypeScript, Vite (Next.js only for SEO), Tailwind, shadcn/ui, lucide-react, Recharts | UI-001, UI-002 |
| Auth | Keycloak (OIDC), FastAPI as backend-for-frontend with HttpOnly session cookies | AUTH-001 |
| Deploy | Containers (Dockerfile + compose); target chosen by ADR before first deploy | OPS-001 |
| Agents | Claude Code first; `AGENTS.md` for every other agent | |

## Status

Version 0.1.0, a first draft. Standards, templates, profiles, hooks, the check CLI and the
plugin exist and are tested (`python3 -m unittest discover -s tests`). Still planned:
`dev-standard init` and `sync`, the `c-embedded` profile, and a trial install in a real repo;
see [CHANGELOG.md](CHANGELOG.md).
