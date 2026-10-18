---
status: proposed
date: 2026-10-18
decision-makers: Ibrahim Khadraoui
consulted: ""
informed: ""
---

# Distribute as a pinned submodule, an agent runbook and a Claude Code plugin

## Context and Problem Statement

Repos must adopt the standard without it overwriting their conventions, and agents must be able to install it themselves. How is it distributed?

## Decision Drivers

* Adopting repos pin a version (INS-009)
* The agent studies the repo before changing it (INS-001)
* Claude Code first, other agents through AGENTS.md

## Considered Options

* Git submodule `.dev-standard/` plus `INSTALL.md` runbook, plus this repo as a Claude Code plugin
* A CLI that writes files (`init`)
* A template repository

## Decision Outcome

Chosen option: "Git submodule plus runbook plus plugin", because the runbook lets the agent assess the repo and ask before merging anything, which a file-writing CLI can't do well.

### Consequences

* Good, because installs adapt to each repo
* Bad, because hooks can be loaded twice (plugin and `.claude/settings.json`); INSTALL.md says to use one
