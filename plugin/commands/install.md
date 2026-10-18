---
description: Install dev-standard into this repo through a guided interview
argument-hint: "[guided|quick|report]"
---

Install dev-standard into the current repository. The install is an interview: study the repo,
ask the user about everything the repo can't answer, and change nothing until the user approves
the plan.

Mode requested by the user: `$ARGUMENTS` (empty means ask with `Q-START-1`).

1. If `.dev-standard/INSTALL.md` exists, read it and follow it from Phase 0.
2. If it doesn't, the repo hasn't added dev-standard yet. Ask Round 0 first (install mode, then
   `Q-START-2`: submodule or vendored copy), add it from
   `https://github.com/HDElectronics/dev-standard.git` as the user chose, then read
   `.dev-standard/INSTALL.md` and continue from Phase 0, step 2.
3. Take every question from `.dev-standard/install/interview.md`. Ask with the AskUserQuestion
   tool: at most 4 questions per call, recommended option first and marked `(Recommended)`,
   evidence in the question text, `preview` for file snippets. Skip any question the repo already
   answers.
4. Log each answer in `docs/dev-standard/adoption-report.md` as soon as you get it.
5. Ask again right before anything outside the working tree: network installs, pushes, PRs,
   and branch protection changes.
