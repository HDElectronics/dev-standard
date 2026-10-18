# Standards

The source of truth for dev-standard. Each file covers one rule group, identified by a prefix.
Agents load a file when the task touches its area. `AGENTS.md` in a consuming repo carries only the MUST rules and links here.

## Levels

Levels follow [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

| Level | Meaning | Enforcement |
|-------|---------|-------------|
| MUST / MUST NOT | Required. A violation blocks the change. | Hook or CI blocks |
| SHOULD / SHOULD NOT | Expected. Deviate only with a reason in the PR. | Warning |
| MAY | Guidance. | None |

A rule with no automated check says `Check: advisory`. Advisory MUST rules are enforced by review (`REV`).

## Index

| Prefix | File | Applies to |
|--------|------|------------|
| AGT | [agent-conduct.md](agent-conduct.md) | all |
| INS | [installation.md](installation.md) | all, at install and upgrade |
| BRN | [brainstorm.md](brainstorm.md) | all |
| SDD | [sdd.md](sdd.md) | all |
| NAM | [naming.md](naming.md) | all |
| STY | [code-style.md](code-style.md) | all |
| GIT | [git.md](git.md) | all |
| BRA | [branching.md](branching.md) | all |
| PR | [pull-requests.md](pull-requests.md) | all |
| REV | [code-review.md](code-review.md) | all |
| DOC | [documentation.md](documentation.md) | all |
| ADR | [decisions.md](decisions.md) | all |
| TST | [testing.md](testing.md) | all |
| SEC | [security.md](security.md) | all |
| ERR | [errors-logging.md](errors-logging.md) | all |
| UI | [frontend.md](frontend.md) | profile `react-web` |
| AUTH, ABU, API, WEB, REL, OBS, OPS, DAT | [production/](production/README.md) | `deployed: true` |
| EMB, LLM, MOB | [packs/](packs/) | opt-in packs |

## File format

Every standard file uses the same shape, so tools can parse it.

```markdown
---
id: NAM
title: Naming conventions
version: 0.1.0
applies_to: all            # all | react-web | python-api | deployed | pack
based_on:
  - name: Google Style Guides
    url: https://google.github.io/styleguide/
---

# Naming conventions (NAM)

One paragraph: what this group covers and why.

## Rules

### NAM-003 · MUST · Put units in numeric names

Numbers with a unit carry it in the name: `timeoutMs`, `supply_voltage_mv`.

- **Why:** One or two sentences.
- **Check:** The tool and setting that enforce it, or `advisory`.

## Reference

Tables, examples and configuration snippets.

## Sources

- [Google Style Guides](https://google.github.io/styleguide/)
```

Rules:

- Rule headings are exactly `### <ID> · <LEVEL> · <short imperative title>`. IDs never change meaning; a retired rule keeps its ID and is marked `Retired in vX.Y`.
- Each rule has **Why** and **Check**. Add a short example when it removes ambiguity.
- Cite the external standard the rule comes from. Do not restate long sources; link them.
- Write in plain, active English, second person where natural (Google developer documentation style).
