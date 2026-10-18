---
id: NAM
title: Naming conventions
version: 0.1.0
applies_to: all
based_on:
  - name: Google Style Guides
    url: https://google.github.io/styleguide/
  - name: BARR-C:2018 Embedded C Coding Standard
    url: https://barrgroup.com/embedded-systems/books/embedded-c-coding-standard
---

# Naming conventions (NAM)

How to name files, types, functions, variables, branches and records. Casing follows Google's style guide for each language; embedded C follows BARR-C. The extra rules (verbs, units, booleans) close the gaps those guides leave open.

## Rules

### NAM-001 · MUST · Follow the casing table for the file's language

Use the casing in the Reference table. It follows the Google style guide for TypeScript and Python, and BARR-C for C.

- **Why:** Consistent casing lets readers tell a type from a value from a constant at a glance, and lets linters enforce it.
- **Check:** Python: ruff `N` rules (pep8-naming). TypeScript: Biome `style/useNamingConvention`, or `@typescript-eslint/naming-convention` in projects that use ESLint. C: clang-tidy `readability-identifier-naming`. Warn in pre-commit, block in CI.

### NAM-002 · MUST · Start function names with a verb

Functions and methods are named for what they do: `parseFrame`, `fetchUser`, `send_reset_email`, `uart_send_byte`.

- **Why:** A verb makes the call site read as an action and separates functions from the values they return.
- **Check:** Advisory. Reviewers check new names.

### NAM-003 · MUST · Put units in numeric names

A number that has a unit carries the unit in its name: `timeoutMs`, `retryDelaySeconds`, `supply_voltage_mv`, `distance_m`, `price_minor_units`.

- **Why:** Unit mix-ups (seconds for milliseconds, volts for millivolts) are common bugs that types alone rarely catch.
- **Check:** Advisory. Reviewers check new numeric names.

### NAM-004 · MUST · Start boolean names with is, has, can or should

`isReady`, `hasToken`, `can_retry`, `should_notify`.

- **Why:** The prefix makes the value read as a yes/no question and keeps it from being mistaken for an object or a count.
- **Check:** TypeScript: `@typescript-eslint/naming-convention` with a `types: ["boolean"]` selector and the prefix list, where ESLint is used. Python and C: advisory.

### NAM-005 · MUST · Write acronyms as words

Treat acronyms and abbreviations as one word: `HttpClient`, `userId`, `loadXmlUrl`, never `HTTPClient` or `userID`. This is the Google TypeScript and Java style rule.

- **Why:** Word boundaries stay visible (`XMLHTTPRequest` versus `XmlHttpRequest`), and camelCase converters produce predictable results.
- **Check:** Partly enforced by the naming-convention lint rules above; otherwise advisory.

### NAM-006 · MUST NOT · Use interface prefixes, Hungarian notation, or abbreviations outside the allowlist

No `IUser`, no `strName` or `pBuffer`, no `usr`, `cnt` or `mgr`. Allowed abbreviations: `id`, `url`, `api`, `db`, `io`, `ctx`. Loop indexes `i`, `j`, `k` are fine in short loops.

- **Why:** Google's TypeScript guide forbids `I` prefixes; type information belongs in the type system, not the name. Abbreviations save typing once and cost reading many times.
- **Check:** Advisory, except where a naming-convention lint rule forbids the `I` prefix.

### NAM-007 · MUST · Name branches and records by convention

| Thing | Pattern | Example |
|-------|---------|---------|
| Spec branch (spec documents) | `NNN-slug` (Spec Kit) | `013-faster-restock` |
| Task branch (one task) | `NNN-tTTT-slug` | `013-t004-bom-parser` |
| Bug fix branch | `fix/slug` | `fix/cart-total-rounding` |
| Chore branch | `chore/slug` | `chore/upgrade-ruff` |
| Docs branch | `docs/slug` | `docs/api-pagination` |
| Brainstorm folder (before Specify) | `brainstorms/<slug>/` | `brainstorms/faster-restock/` |
| Spec folder | `specs/NNN-slug/` | `specs/013-faster-restock/` |
| ADR | `docs/adr/NNNN-slug.md` | `docs/adr/0004-use-keycloak.md` |
| Runbook | `docs/runbooks/<alert-name>.md` | `docs/runbooks/api-error-budget-burn.md` |

Slugs are lowercase kebab-case, 2 to 5 words. Branch rules and release branches: [branching.md](branching.md) (`BRA-003`).

- **Why:** The hooks read the spec number from the branch name, and predictable paths let agents find records without searching.
- **Check:** `require-spec.sh` relies on the `NNN-` prefix. A CI branch-name check can block other patterns.

## Reference

### Casing table

| Thing | TypeScript / React | Python (Google style) | C (BARR-C) |
|-------|--------------------|-----------------------|------------|
| Files | `user-card.tsx`, `cart-api.ts` | `user_service.py` | `uart_driver.c`, `uart_driver.h` |
| Packages, modules | `kebab-case` folders | `snake_case` | `snake_case` |
| Types, classes, interfaces | `UserProfile` | `UserProfile` | `uart_config_t` |
| React components | `UserCard` (in `user-card.tsx`) | n/a | n/a |
| React hooks | `useCart` | n/a | n/a |
| Functions, methods | `fetchUser()` | `fetch_user()` | `uart_send_byte()` (module prefix first) |
| Variables, parameters | `lineCount` | `line_count` | `line_count` |
| Constants | `MAX_RETRIES` | `MAX_RETRIES` | `UART_BAUD_RATE` |
| Enum members | `OrderStatus.PAID` (`CONSTANT_CASE`) | `OrderStatus.PAID` | `ORDER_STATUS_PAID` |
| Exceptions | `class CartLockedError extends Error` | `class CartLockedError(Exception)` | n/a |
| Private members | no `_` prefix; use `private` | `_internal_name` | `static` at file scope |
| Booleans | `isReady` | `is_ready` | `is_ready` (`bool` from `<stdbool.h>`) |
| Maps | `userById` | `user_by_id` | n/a |
| Environment variables | `APP_DATABASE_URL` | `APP_DATABASE_URL` | n/a |

Notes:

- File names for React follow the shadcn/ui convention (`kebab-case.tsx`), so generated components and your own match.
- Python test files are `test_<module>.py`; TypeScript test files are `<name>.test.ts(x)`.
- In BARR-C, every public function in a module starts with the module name (`uart_`), and typedef names end in `_t`.

## Sources

- [Google TypeScript Style Guide: Naming](https://google.github.io/styleguide/tsguide.html#naming)
- [Google Python Style Guide: Naming](https://google.github.io/styleguide/pyguide.html#316-naming)
- [Google Java Style Guide: Camel case defined](https://google.github.io/styleguide/javaguide.html#s5.3-camel-case)
- [BARR-C:2018 Embedded C Coding Standard](https://barrgroup.com/embedded-systems/books/embedded-c-coding-standard)
- [GitHub Spec Kit](https://github.com/github/spec-kit)
