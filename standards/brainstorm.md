---
id: BRN
title: Brainstorm
version: 0.1.0
applies_to: all
based_on:
  - name: Double Diamond (Design Council)
    url: https://www.designcouncil.org.uk/our-resources/the-double-diamond/
  - name: Shape Up (Basecamp)
    url: https://basecamp.com/shapeup
  - name: GV Design Sprint
    url: https://www.gv.com/sprint/
  - name: ICE scoring
    url: ""
---

# Brainstorm (BRN)

The first diamond of the workflow: find the right problem and pick a direction before anyone writes a spec. The output is a decision record, `brainstorm.md`, that the spec builds on. A list of ideas is not an output.

The work happens on an interactive board, [templates/brainstorm/brainstorm.html](../templates/brainstorm/brainstorm.html). `/brainstorm <slug> "problem"` copies it to `brainstorms/<slug>/brainstorm.html` and fills in only its JSON seed. You work the board in a browser and save the export as `brainstorms/<slug>/brainstorm.md`.

The brainstorm starts outside `specs/` because Spec Kit picks the next spec number by scanning `specs/`; a folder created there early would shift the numbering. Once `/speckit.specify` creates `specs/NNN-slug/`, the agent moves both files there (see [Moving into the spec folder](#moving-into-the-spec-folder)).

## Rules

### BRN-001 · MUST · Start every feature spec from a decided brainstorm

A feature spec (`specs/NNN-slug/spec.md` on a feature branch) is edited only after `specs/NNN-slug/brainstorm.md` exists with `status: decided`. You can also write a short `brainstorm.md` yourself with `status: skipped` and a reason, for a feature whose direction is already settled; only you can set either status (BRN-004). Bug fixes (`fix/` branches) and chores (`chore/` branches) don't write specs, so they need no brainstorm.

- **Why:** Specs written straight from the first idea lock in a solution before alternatives were compared. The brainstorm makes the comparison explicit and cheap.
- **Check:** `require-brainstorm.sh` (PreToolUse hook) blocks edits to `specs/NNN-slug/spec.md` unless `specs/NNN-*/brainstorm.md` has `status: decided` or `status: skipped`, or an unexpired `BRN-001` waiver in `.dev-standard.json` covers the path. This is why the agent moves the brainstorm files into the spec folder before it edits `spec.md`. In CI, `dev-standard check brainstorm` reports PRs that add a spec without one.

### BRN-002 · MUST · Propose at least 5 materially different options, including a do-nothing baseline

The agent seeds the board with at least 5 options that differ in approach, not just in detail. One option is always "do nothing" or the cheapest change to the current flow.

- **Why:** The do-nothing baseline shows what the other options must beat. Five different options push past the obvious first answer, which is the purpose of the diverge stage.
- **Check:** Advisory. The board shows the count; the reviewer checks the seed.

### BRN-003 · MUST · Set the appetite before scoring

In the Frame stage, set the appetite (how much time the problem is worth) before any option is scored.

- **Why:** Shape Up fixes time and varies scope. Setting the appetite first stops a large solution from being chosen for a small problem.
- **Check:** Advisory. `brainstorm.md` records the appetite in its front matter.

### BRN-004 · MUST NOT · Let the agent mark a direction as decided

The agent may recommend an option and explain why. Only you choose the direction and write the reason. The agent never writes `brainstorm.md` with `status: decided` or `status: skipped`; you save the export from the board.

- **Why:** The decision is a product judgment. Gates that the agent can pass by itself do not protect anything.
- **Check:** A PreToolUse hook blocks the agent from writing `brainstorm.md` with `status: decided` or `status: skipped`. The board sets `status: decided` in its export only when a direction is chosen and "Why this one" is filled in.

### BRN-005 · SHOULD · Give every rejected option a one-line reason

Each option you did not choose gets a short reason. The spec copies these into its non-goals.

- **Why:** Without a reason, rejected options come back in review or in the next planning round. A recorded reason ends the discussion.
- **Check:** Advisory. The export marks missing reasons as `_no reason given_`.

## Reference

### The four stages

The board implements the first diamond of the Double Diamond (discover, define).

| Stage | You do | Board shows |
|-------|--------|-------------|
| 01 Frame | Write the problem with evidence, one "How might we" question, users, constraints, success signal, appetite | Stage marked done when problem and question are filled |
| 02 Diverge | Add your own ideas next to the agent's. No judging yet | Idea cards, by agent or by you |
| 03 Converge | Spend dots on favorites, score impact, effort and confidence from 1 to 5 | Dot budget, ICE per idea, impact/effort matrix, ranking |
| 04 Decide | Pick one direction, write why, give rejected options a reason, list open questions and risks | Live `brainstorm.md` preview, copy and download buttons |

### Scoring

- **Dot budget:** `voters × ceil(ideas / 3)`. Each voter gets about one dot per three ideas, a common dot-voting rule.
- **ICE:** `impact × confidence × ease`, where `ease = 6 − effort`. Range 1 to 125.
- **Matrix quadrants** (split at 3 on both axes): quick wins (high impact, low effort), big bets (high impact, high effort), fillers (low impact, low effort), money pits (low impact, high effort).

Scores inform the decision. They do not make it.

### Appetite values

| Value | Meaning |
|-------|---------|
| `small` | Small batch: 1 to 2 weeks |
| `big` | Big batch: up to 6 weeks |
| `spike` | Spike: 1 to 3 days, to learn, not to ship |

### Seed format

The agent replaces only the JSON inside `<script type="application/json" id="seed">`:

`id` is the brainstorm slug, and the board header shows it as `BRN-<slug>`. `spec` stays `""` until Spec Kit assigns a number.

```json
{
  "id": "faster-restock",
  "spec": "",
  "title": "Faster restock for repeat buyers",
  "example": false,
  "date": "2026-10-18",
  "voters": 1,
  "frame": {
    "problem": "...", "hmw": "How might we ...?", "users": "...",
    "constraints": "one per line", "appetite": "small", "success": "..."
  },
  "ideas": [
    { "id": "i1", "title": "...", "pitch": "...", "tags": ["..."], "by": "agent",
      "votes": 0, "impact": 3, "effort": 3, "confidence": 3 }
  ],
  "decision": { "chosen": null, "combine": [], "why": "", "rejected": {} },
  "questions": "one per line",
  "risks": "one per line"
}
```

Board state is kept in the browser's `localStorage` under `brainstorm:<id>`. The exported `brainstorm.md` is the record; the HTML file is the working tool.

### brainstorm.md export

```markdown
---
id: BRN-faster-restock
spec:                  # empty until Spec Kit assigns a number
date: 2026-10-18
status: decided        # open | decided | skipped (decided and skipped are set only by you)
appetite: small
---

# Brainstorm: Faster restock for repeat buyers

## Problem
## How might we
## Users
## Constraints
## Success signal
## Appetite
## Options considered
| # | Idea | Dots | Impact | Effort | Confidence | ICE |
## Decision
Chosen: **#3 Paste a BOM**
Why: ...
## Rejected alternatives
- #5 Chat ordering bot: effort too high for a small batch
## Open questions for Clarify
- [ ] ...
## Risks
## Next
Run `/speckit.specify` with this file as input.
```

Save it as `brainstorms/<slug>/brainstorm.md`. `/speckit.specify` takes it as input: the decision becomes the feature description, rejected alternatives become non-goals, and open questions go to `/speckit.clarify`.

### Moving into the spec folder

1. `/brainstorm faster-restock "Repeat buyers reorder parts one by one"` creates `brainstorms/faster-restock/brainstorm.html`.
2. You work the board and save the export as `brainstorms/faster-restock/brainstorm.md`.
3. Run `/speckit.specify` with `brainstorm.md` as input. Spec Kit creates the branch and `specs/013-faster-restock/`.
4. Before it edits `spec.md`, the agent moves the brainstorm:

   ```bash
   git mv brainstorms/faster-restock/brainstorm.* specs/013-faster-restock/
   ```

5. The agent edits `spec.md`. The `BRN-001` hook now finds `specs/013-*/brainstorm.md` with `status: decided`.

The final spec folder contains both `brainstorm.html` and `brainstorm.md`.

## Sources

- [Design Council: The Double Diamond](https://www.designcouncil.org.uk/our-resources/the-double-diamond/)
- [Shape Up: Set Boundaries (appetite)](https://basecamp.com/shapeup/1.2-chapter-03)
- [GV: The Design Sprint](https://www.gv.com/sprint/)
