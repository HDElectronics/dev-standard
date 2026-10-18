---
id: STY
title: Code style
version: 0.1.0
applies_to: all
based_on:
  - name: Google Style Guides
    url: https://google.github.io/styleguide/
  - name: BARR-C:2018 Embedded C Coding Standard
    url: https://barrgroup.com/embedded-systems/books/embedded-c-coding-standard
  - name: MISRA C:2023
    url: https://misra.org.uk/
---

# Code style (STY)

Formatting is decided by tools, so it never comes up in review. The remaining rules cover what formatters cannot decide: strictness, docstrings, constants, comments and function shape.

## Rules

### STY-001 · MUST · Let the formatter decide formatting

Formatting is whatever the formatter outputs:

| Language | Formatter |
|----------|-----------|
| TypeScript, JavaScript, JSON, CSS | Biome |
| Python | `ruff format` |
| C, C++ | `clang-format` with `BasedOnStyle: Google` |

Do not comment on formatting in review, and do not hand-format around the tool.

- **Why:** Formatting debates cost review time and produce nothing. One tool, one output.
- **Check:** `format-file.sh` (PostToolUse hook) formats each file the agent edits. lefthook formats staged files at pre-commit. CI runs the formatter in check mode (`ruff format --check`, `biome ci`) and blocks.

### STY-002 · MUST · Use the strictest compiler and type-checker mode

| Language | Setting |
|----------|---------|
| TypeScript | `"strict": true` in `tsconfig.json`, plus `noUncheckedIndexedAccess` |
| Python | pyright `typeCheckingMode = "strict"` |
| C | `-Wall -Wextra -Werror` (and `-std=c11` or later) |

- **Why:** Strict modes catch whole classes of bugs (null access, implicit `any`, missing returns) before tests run.
- **Check:** CI runs `tsc --noEmit`, `pyright` and the compiler with these settings, and blocks on errors.

### STY-003 · MUST · Write Python docstrings in Google style

Public modules, classes and functions have docstrings with `Args:`, `Returns:` and `Raises:` sections, per the Google Python Style Guide.

- **Why:** One docstring format makes generated reference docs consistent and lets tools check the sections.
- **Check:** ruff `D` rules (pydocstyle) with `convention = "google"`.

```python
def match_lines(text: str, *, max_suggestions: int = 3) -> list[MatchResult]:
    """Match pasted BOM lines to products.

    Args:
        text: Pasted lines, one SKU or MPN and quantity per line.
        max_suggestions: Suggestions to return for an unmatched line.

    Returns:
        One result per non-empty input line, in input order.

    Raises:
        BomParseError: If a line has a quantity that is not a positive integer.
    """
```

### STY-004 · MUST · Replace magic numbers with named constants that carry units

```python
CHECKOUT_LOCK_TIMEOUT_SECONDS = 300
```

```ts
const SEARCH_DEBOUNCE_MS = 250;
```

`0`, `1` and `-1` in obvious positions (indexes, increments) are fine.

- **Why:** A named constant says what the number means and gives it one place to change. Units follow `NAM-003`.
- **Check:** Python: ruff `PLR2004` (magic value comparison). Others: advisory.

### STY-005 · MUST · Comment why, not what; no commented-out code; link every TODO

Comments explain intent, constraints and non-obvious decisions. Delete code instead of commenting it out; git keeps history. Every TODO links an issue: `TODO(#123): drop after v2 migration`.

- **Why:** "What" comments go stale as code changes. Commented-out code confuses readers. A TODO without an issue is never done.
- **Check:** ruff `ERA` (eradicate) flags commented-out Python code. A CI grep rejects `TODO` without `(#<number>)`. "Why, not what" is advisory.

### STY-006 · SHOULD · Keep functions short and flat

Aim for functions under about 40 lines with nesting depth 3 or less. Prefer early returns over `else` chains.

- **Why:** Short, flat functions are easier to name, test and review.
- **Check:** ruff `C901` (complexity) and `PLR0915` (too many statements) as warnings; Biome `complexity/noExcessiveCognitiveComplexity` as a warning.

## Reference

### Python (pyproject.toml)

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "D", "B", "UP", "S", "ERA", "PL", "C90"]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["D", "S101", "PLR2004"]

[tool.pyright]
typeCheckingMode = "strict"
pythonVersion = "3.12"
```

### TypeScript (tsconfig.json excerpt)

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### C (.clang-format)

```yaml
BasedOnStyle: Google
ColumnLimit: 100
```

For embedded C, also apply the `EMB` pack (BARR-C:2018 and a MISRA C:2023 subset).

## Sources

- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [Ruff rules](https://docs.astral.sh/ruff/rules/)
- [Biome](https://biomejs.dev/)
- [Pyright configuration](https://microsoft.github.io/pyright/#/configuration)
- [BARR-C:2018](https://barrgroup.com/embedded-systems/books/embedded-c-coding-standard)
- [MISRA C](https://misra.org.uk/)
