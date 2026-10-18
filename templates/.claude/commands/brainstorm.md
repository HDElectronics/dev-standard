---
description: Start a feature brainstorm board (dev-standard BRN) before writing a spec
argument-hint: <slug> "problem statement"
---

# /brainstorm

Create the brainstorm board for a new feature. Rules: BRN-001 to BRN-005 in `.dev-standard/standards/brainstorm.md`.

Arguments: `$ARGUMENTS`
- First argument: `slug`, lowercase kebab-case, 2 to 5 words (for example `faster-restock`).
- Rest: the problem statement in the user's words.

If the slug or problem is missing, ask for it and stop.

## Steps

1. **Check the slug.** It must match `^[a-z0-9]+(-[a-z0-9]+)*$`. Stop if `brainstorms/<slug>/` already exists, and tell the user.
   Do not create anything under `specs/`. Spec Kit numbers features by scanning `specs/`, so the spec folder is created later by `/speckit.specify`.
2. **Gather context.** Read the problem statement, related code, existing specs in `specs/` and ADRs in `docs/adr/`. Ask at most two questions if the problem, the users or the constraints are unclear.
3. **Create the folder** `brainstorms/<slug>/` and copy `.dev-standard/templates/brainstorm/brainstorm.html` into it unchanged.
4. **Replace only the JSON inside `<script type="application/json" id="seed">`.** Do not edit markup, styles or scripts. The seed has exactly this shape:

   ```json
   {
     "id": "<slug>",
     "spec": "",
     "title": "Short feature title",
     "example": false,
     "date": "YYYY-MM-DD",
     "voters": 1,
     "frame": {
       "problem": "Who hurts, how often, and the evidence. No solution in it.",
       "hmw": "How might we ...?",
       "users": "Who this is for.",
       "constraints": "One constraint per line, separated by \\n",
       "appetite": "small",
       "success": "A number you could measure after launch."
     },
     "ideas": [
       { "id": "i1", "title": "...", "pitch": "One sentence.", "tags": ["..."], "by": "agent",
         "votes": 0, "impact": 3, "effort": 3, "confidence": 3 }
     ],
     "decision": { "chosen": null, "combine": [], "why": "", "rejected": {} },
     "questions": "One open question per line, separated by \\n",
     "risks": "One risk per line, separated by \\n"
   }
   ```

   - `spec` stays `""`: the spec number is not known yet.
   - `appetite` is one of `small` (1 to 2 weeks), `big` (up to 6 weeks) or `spike` (1 to 3 days). Leave `small` if the user gave no hint, and say so; the user sets it (BRN-003).
   - `impact`, `effort` and `confidence` are integers from 1 to 5: your first estimate, which the user will change. `votes` is always `0`.
   - Write **at least 5 materially different ideas** (BRN-002). Different means a different mechanism, not a variation of the same one. Include:
     - a **do-nothing baseline** (`"tags": ["baseline"]`), describing the cheapest improvement to the current flow;
     - at least one idea that is not a code change (process, content, pricing, a manual step), when one exists.
   - `ideas[].id` values are unique: `i1`, `i2`, ...
   - Keep `decision` exactly as shown. Never set `chosen` or `why` (BRN-004).
   - The result must be valid JSON. Check it before saving.
5. **Tell the user**, in this order:
   1. Open `brainstorms/<slug>/brainstorm.html` in a browser.
   2. Work through Frame, Diverge, Converge and Decide; add, remove and rescore ideas freely.
   3. On Decide, click **Download .md** (or **Copy brainstorm.md**) and save it as `brainstorms/<slug>/brainstorm.md`.
   4. Then run `/speckit.specify` with that file as input.

   Give a one-line recommendation if you have one, with the reason. The user decides.

## Rules for you

- Never write `brainstorm.md` yourself, and never write one with `status: decided` or `status: skipped`. A hook blocks it. The user exports it from the board.
- After the user exports it and runs `/speckit.specify`: right after Spec Kit creates `specs/NNN-slug/`, run
  `git mv brainstorms/<slug>/brainstorm.* specs/NNN-slug/` before editing `spec.md`.
  Then set the spec's `**Input**:` line to `specs/NNN-slug/brainstorm.md` and copy every rejected option, with its reason, into the spec's Non-goals (BRN-005).
