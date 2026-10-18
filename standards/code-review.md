---
id: REV
title: Code review
version: 0.1.0
applies_to: all
based_on:
  - name: Google Engineering Practices, The Standard of Code Review
    url: https://google.github.io/eng-practices/review/reviewer/standard.html
  - name: Google Engineering Practices, What to look for in a code review
    url: https://google.github.io/eng-practices/review/reviewer/looking-for.html
  - name: Conventional Comments
    url: https://conventionalcomments.org/
---

# Code review (REV)

How changes are reviewed, by people and by the reviewer subagent. The approval standard and the checklist come from Google's code review guide. Comment format comes from Conventional Comments, so every comment states its intent and whether it blocks.

## Rules

### REV-001 · MUST · Approve once the change definitely improves overall code health

Approve when the change, as it stands, makes the codebase better, even if it is not perfect. Do not block on personal preference. Ask for changes when something makes the code worse or breaks a MUST rule.

- **Why:** Google's standard of code review. Holding out for perfection slows every change; approving anything lets the codebase decay. "Better than before" is the line.
- **Check:** Advisory.

### REV-002 · MUST · Review in order of weight

Look at, in order: design, functionality, complexity, tests, naming, comments, style, documentation. Read every line you were asked to review, and look at the change in the context of the whole file and system.

- **Why:** A design problem makes line-level comments moot. Starting from the top catches the expensive problems first.
- **Check:** Advisory. The reviewer subagent follows this order.

### REV-003 · MUST · Label every comment and cite rule IDs

Write comments in Conventional Comments form: `label (decoration): subject`. Labels include `issue`, `suggestion`, `nitpick`, `question`, `praise`, `todo`, `thought`, `chore`, `note`. Mark each as `(blocking)` or `(non-blocking)`. When a comment enforces a rule, cite its ID.

- **Why:** The author knows at once what must change before merge and what is optional. Rule IDs point to the reasoning instead of re-arguing it.
- **Check:** The reviewer subagent writes every finding in this format. Human comments: advisory.

```text
issue (blocking): REL-003 — this call to the supplier API has no timeout,
so a slow supplier holds the request open. Add a 2 s timeout and retry
with jitter.

nitpick (non-blocking): NAM-003 — rename `delay` to `delay_ms`.

praise: Clear split between parsing and matching.
```

### REV-004 · MUST · Require a human approval for agent-written PRs

The reviewer subagent is a first pass. A PR written by an agent merges only after a human approves it.

- **Why:** The agent and its reviewer share blind spots. A human approval keeps accountability with a person.
- **Check:** Branch protection requires at least one approval from a human account.

### REV-005 · SHOULD · Respond within one business day

Give a first response to a review request within one business day, even if it is only "I'll look tomorrow".

- **Why:** Google's guide on speed of reviews: slow reviews make authors batch changes into larger PRs and erode the small-PR habit.
- **Check:** Advisory.

## Reference

### What to look for (Google)

| Area | Questions |
|------|-----------|
| Design | Do the parts interact sensibly? Does this belong here or in a library? Does it fit the system? |
| Functionality | Does it do what the author intended, and is that good for users? Edge cases, concurrency, failure paths? |
| Complexity | Could it be simpler? Is anything built for needs that don't exist yet? |
| Tests | Are there correct, useful tests? Would they fail if the code broke? |
| Naming | Are names clear and do they follow `NAM`? |
| Comments | Do comments explain why? Are any out of date? |
| Style | Leave to the formatter (`STY-001`). |
| Consistency | Does it follow the standard and the surrounding code? |
| Documentation | Are README, reference docs and changelog updated? |

### Conventional Comments labels

| Label | Meaning |
|-------|---------|
| `praise` | Something done well. Use at least once per review where it is true. |
| `nitpick` | Trivial preference. Always non-blocking. |
| `suggestion` | A proposed improvement; say what and why. |
| `issue` | A problem that needs a fix. Pair with a suggestion where possible. |
| `todo` | A small, necessary change. |
| `question` | You are unsure; ask before assuming. |
| `thought` | An idea for later. Non-blocking. |
| `chore` | A process step to do before merge (for example, run a migration check). |
| `note` | Information the author should know. Non-blocking. |

Decorations go in parentheses after the label: `(blocking)`, `(non-blocking)`, `(if-minor)`, or a domain tag such as `(security)`.

### Reviewer subagent output

The reviewer subagent reads the diff, the spec and the relevant standard files, then reports findings ordered by severity, each in Conventional Comments form with a rule ID and a file and line reference. It never approves.

## Sources

- [Google: The Standard of Code Review](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [Google: What to look for in a code review](https://google.github.io/eng-practices/review/reviewer/looking-for.html)
- [Google: Speed of Code Reviews](https://google.github.io/eng-practices/review/reviewer/speed.html)
- [Conventional Comments](https://conventionalcomments.org/)
