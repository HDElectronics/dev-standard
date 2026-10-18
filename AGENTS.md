# Working on dev-standard

Instructions for agents changing this repository itself. To install dev-standard into another
repo, follow [INSTALL.md](INSTALL.md) instead.

## What this repo is

The rules live in `standards/`, in the format defined in [standards/README.md](standards/README.md).
Everything else (templates, profiles, hooks, schema) must agree with those files.

## Rules for changes here

- Every rule cites an external standard in `based_on` and has **Why** and **Check**. A rule with
  no automated check says `Check: advisory`.
- Rule IDs never change meaning. To drop a rule, mark it `Retired in vX.Y` and keep the ID.
- A rule change that affects adopting repos is listed in `CHANGELOG.md` under the next version,
  because upgrades are reviewed from the changelog (INS-009).
- When a rule changes, update every place that repeats it: `templates/AGENTS.md.tmpl`,
  `templates/constitution.md.tmpl`, `templates/prr.md`, the hooks and the profiles.
- Don't state tool flags or library APIs you haven't checked against current docs.
- Hooks are bash with `jq` as the only dependency; `cli/dev-standard` is Python 3.11+ with the
  standard library only. After changing either, run `shellcheck -x -S warning enforce/hooks/*.sh`
  and `python3 -m unittest discover -s tests`, and add a test for the new behavior.
- `plugin/hooks.json` mirrors `templates/.claude/settings.json` with `${CLAUDE_PLUGIN_ROOT}`
  paths. Change both together, then run `claude plugin validate .`.
- Decisions about this repo go in `docs/adr/` (ADR group); `cli/dev-standard check adr` must pass.
- The brainstorm board (`templates/brainstorm/brainstorm.html`) is one self-contained file.
  The agent-facing contract is its `<script id="seed">` JSON; changing that schema needs matching
  changes in `templates/.claude/commands/brainstorm.md` and `standards/brainstorm.md`.
- Commits follow Conventional Commits (GIT-001). Write plain, active English
  (Google developer documentation style).
