---
id: TST
title: Testing
version: 0.1.0
applies_to: all
based_on:
  - name: Software Engineering at Google (Winters, Manshreck, Wright)
    url: https://abseil.io/resources/swe-book
  - name: Google Testing Blog
    url: https://testing.googleblog.com/
---

# Testing (TST)

What to test, how to classify tests, and how much coverage a change needs. Test sizes, the Beyoncé rule and DAMP tests come from *Software Engineering at Google*.

## Rules

### TST-001 · MUST · Start a bug fix with a failing test

Write a test that reproduces the bug and fails, then fix the code until it passes.

- **Why:** The failing test proves you found the actual bug, and it keeps the bug from coming back.
- **Check:** Advisory. The PR description for a `fix:` change names the reproducing test.

### TST-002 · MUST · Classify tests by size, and run small tests on every commit

| Size | Constraints | Runs |
|------|-------------|------|
| Small | One process, no network, no disk beyond temp files, no sleeps | Every commit (pre-commit or Stop hook) and every CI run |
| Medium | One machine; may use localhost services (database in a container) | Every CI run |
| Large | Real or remote dependencies, end-to-end flows | Before merge to `main` or on a schedule |

Mark medium and large tests so they can be selected: pytest markers `medium` and `large`; Vitest and Playwright separate projects or folders.

- **Why:** Size, not "unit" versus "integration", predicts speed and flakiness. Fast, hermetic small tests are what make a tight feedback loop possible.
- **Check:** pytest `--strict-markers` with registered markers. CI runs sizes in separate jobs.

### TST-003 · MUST · Reach 80% coverage on changed lines

Diff coverage (coverage of the lines this PR adds or changes) is at least 80%. Global coverage is reported but not gated.

- **Why:** A global threshold punishes legacy code and rewards padding. Diff coverage asks only that new code is tested.
- **Check:** Python: pytest-cov writes `coverage.xml`, then `diff-cover coverage.xml --compare-branch=origin/main --fail-under=80`. TypeScript: Vitest coverage with an lcov or Cobertura report fed to diff-cover. Blocks in CI.

### TST-004 · MUST · Follow the Beyoncé rule

"If you liked it, then you shoulda put a test on it." Any behavior you want to keep, including configuration, infrastructure and migrations, has a test. If it has no test, others may break it without being at fault.

- **Why:** Google uses this rule to decide responsibility: a change that breaks untested behavior is not the changer's fault.
- **Check:** Advisory. Review checks that config and migration changes come with tests.

### TST-005 · SHOULD · Write DAMP tests with one behavior each

Tests are DAMP (descriptive and meaningful phrases) rather than DRY: each test reads on its own, even if that repeats setup. One behavior per test, named for the behavior. No sleeps; inject clocks and random seeds. Arrange, act, assert.

- **Why:** A test is read when it fails. Shared helpers that hide setup make failures hard to understand.
- **Check:** Advisory. ruff `PT` rules catch some pytest anti-patterns.

## Reference

### Test names

| Language | Pattern | Example |
|----------|---------|---------|
| Python | `test_<behavior>` | `test_rejects_expired_reset_token` |
| TypeScript | `it("<behavior>")` | `it("rejects an expired reset token")` |

Add the requirement ID when the test covers one (`SDD-003`).

### Python (pyproject.toml)

```toml
[tool.pytest.ini_options]
addopts = "--strict-markers --cov --cov-report=xml"
markers = [
  "medium: uses localhost services such as a database container",
  "large: uses real or remote dependencies",
  "req(id): requirement ID covered by this test, for example 013/FR-002",
]

[tool.coverage.run]
branch = true
source = ["src"]
```

Run small tests only:

```bash
uv run pytest -m "not medium and not large"
```

Check diff coverage in CI:

```bash
uv run diff-cover coverage.xml --compare-branch=origin/main --fail-under=80
```

### TypeScript (vitest.config.ts excerpt)

```ts
export default defineConfig({
  test: {
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
    },
  },
});
```

UI testing tools (Testing Library, Playwright, MSW) are covered in `UI-009`.

### Injecting time

```python
def is_token_expired(token: ResetToken, *, now: datetime) -> bool:
    return now >= token.expires_at
```

Pass `now` from the caller; in tests, pass a fixed `datetime`.

## Sources

- [Software Engineering at Google, chapters 11 to 14](https://abseil.io/resources/swe-book)
- [Google Testing Blog: Test Sizes](https://testing.googleblog.com/2010/12/test-sizes.html)
- [pytest](https://docs.pytest.org/)
- [pytest-cov](https://pytest-cov.readthedocs.io/)
- [diff-cover](https://github.com/Bachmann1234/diff_cover)
- [Vitest](https://vitest.dev/)
