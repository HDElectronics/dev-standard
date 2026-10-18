---
id: LLM
title: LLM features
version: 0.1.0
applies_to: pack
based_on:
  - name: OWASP Top 10 for LLM Applications (2025)
    url: https://genai.owasp.org/llm-top-10/
---

# LLM features (LLM)

An opt-in pack for products that call a large language model: chat features, summarization, extraction, and agents that call tools. It turns the OWASP Top 10 for LLM Applications into checkable rules. The core principle: model output is untrusted input, and anything the model reads may contain instructions.

## Rules

### LLM-001 · MUST · Treat all model input as possibly hostile (prompt injection)

Keep system instructions separate from user content and from retrieved documents, mark untrusted content clearly in the prompt, and never rely on the prompt alone to enforce a security boundary. Authorization decisions are made in code, outside the model.

- **Why:** Prompt injection (OWASP LLM01) through user input or retrieved web pages and files can override instructions. No prompt wording reliably prevents it.
- **Check:** An injection test suite (`tests/llm/injection/`) runs known attack prompts against each feature and asserts no forbidden action or data appears in the result.

### LLM-002 · MUST · Validate and encode model output before using it

Parse structured output against a schema (Pydantic) and reject invalid responses. Escape output before rendering it as HTML or Markdown, and never pass it to `eval`, a shell, SQL or a file path without validation.

- **Why:** Improper output handling (LLM05) turns a model response into XSS, injection or remote code execution.
- **Check:** Semgrep rule flags model responses flowing into `eval`, `subprocess`, raw SQL or `dangerouslySetInnerHTML`. Unit tests feed malformed output and expect rejection.

### LLM-003 · MUST · Limit what the model can do (excessive agency)

Give model-driven tools the narrowest permissions: read-only where possible, scoped to the current user's data, and with a human confirmation step for actions that spend money, send messages, or delete or change records.

- **Why:** Excessive agency (LLM06) means an injected or confused model can do whatever its tools allow.
- **Check:** Each tool is registered with a declared permission scope and `requires_confirmation` flag; a test asserts destructive tools require confirmation.

### LLM-004 · MUST NOT · Put secrets or other users' data in prompts

System prompts contain no secrets, keys or internal URLs, and prompts for one user never include another user's data. Retrieval enforces the same access rules as the rest of the app.

- **Why:** System prompts leak (LLM07), and models repeat what they were given (LLM02 sensitive information disclosure). Retrieval without access control leaks data across tenants (LLM08).
- **Check:** gitleaks scans prompt files. Retrieval tests query as user A and assert no documents owned by user B are returned.

### LLM-005 · MUST · Bound cost and consumption

Set limits on input size, output tokens, tool-call loops and requests per user, plus a monthly spend cap with alerts.

- **Why:** Unbounded consumption (LLM10) turns abuse or a loop bug into a large bill or an outage.
- **Check:** Rate limits per ABU apply to LLM routes. Integration test asserts oversized inputs are refused and agent loops stop at the maximum step count.

### LLM-006 · SHOULD · Evaluate quality and show uncertainty

Keep an evaluation set for each LLM feature and run it on every prompt or model change. Show users the sources behind generated claims, and make it easy to report wrong answers.

- **Why:** Misinformation (LLM09) is a product risk, and prompt changes regress quality silently without an eval set.
- **Check:** CI job runs the eval set and fails when the score drops below the recorded baseline.

### LLM-007 · SHOULD · Pin and review models and model dependencies

Pin model versions and the libraries that load models or embeddings. Treat third-party models, datasets and plugins as dependencies under SEC-004.

- **Why:** Supply chain risks (LLM03) and data or model poisoning (LLM04) come through unreviewed models, datasets and plugins.
- **Check:** Model IDs are configuration values checked in review; dependency rules from SEC apply.

## Reference

### OWASP mapping

| Rule | OWASP Top 10 for LLM Applications (2025) |
|------|-------------------------------------------|
| LLM-001 | LLM01 Prompt Injection |
| LLM-002 | LLM05 Improper Output Handling |
| LLM-003 | LLM06 Excessive Agency |
| LLM-004 | LLM02 Sensitive Information Disclosure, LLM07 System Prompt Leakage, LLM08 Vector and Embedding Weaknesses |
| LLM-005 | LLM10 Unbounded Consumption |
| LLM-006 | LLM09 Misinformation |
| LLM-007 | LLM03 Supply Chain, LLM04 Data and Model Poisoning |

### Structured output validation (example)

```python
from pydantic import BaseModel, ValidationError


class ExtractedOrder(BaseModel):
    sku: str
    quantity: int


def parse_model_output(raw_json: str) -> ExtractedOrder | None:
    try:
        return ExtractedOrder.model_validate_json(raw_json)
    except ValidationError:
        return None  # reject; never fall back to using the raw text
```

## Sources

- [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/)
- [OWASP GenAI Security Project](https://genai.owasp.org/)
