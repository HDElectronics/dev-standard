---
id: UI
title: React frontend
version: 0.1.0
applies_to: react-web
based_on:
  - name: Rules of React
    url: https://react.dev/reference/rules
  - name: bulletproof-react
    url: https://github.com/alan2207/bulletproof-react
  - name: WCAG 2.2
    url: https://www.w3.org/TR/WCAG22/
  - name: Core Web Vitals
    url: https://web.dev/articles/vitals
---

# React frontend (UI)

Every project with a user interface uses one stack: React, TypeScript, Tailwind CSS and shadcn/ui. It is the stack Claude's React artifacts are built on, so a prototype made with Claude moves into the codebase without a rewrite, and the agent writes the code it knows best. The backend is FastAPI, so the frontend gets its API types from FastAPI's OpenAPI schema instead of sharing code.

## Rules

### UI-001 · MUST · Use React with strict TypeScript

Write the frontend in React with TypeScript in `strict` mode. Use Vite for apps and dashboards. Use the Next.js App Router only when the page needs SEO or server rendering, and record that choice in an ADR.

- **Why:** One stack keeps components, tests and agent output consistent across projects. Vite is the simpler default; Next.js adds a server that most apps behind a login don't need.
- **Check:** `tsconfig.json` has `"strict": true`; `tsc --noEmit` runs in CI. The CLI profile check fails when `vite.config.*` or `next.config.*` is missing.

### UI-002 · MUST · Use Tailwind, shadcn/ui, lucide-react and Recharts

Style with Tailwind CSS. Build components from shadcn/ui (Radix primitives), icons from lucide-react, charts from Recharts. Adding any other component or CSS library needs an ADR.

- **Why:** These are the libraries Claude's artifacts use, so designs and generated code carry over. A single component library avoids two button styles in one app.
- **Check:** `dev-standard check deps` in CI flags new UI dependencies (`@mui/*`, `antd`, `bootstrap`, `styled-components`, `@emotion/*`, `chakra-ui`) that have no ADR reference in the PR.

### UI-003 · MUST · Take every visual value from design tokens

Colors, spacing, radius and type come from design tokens: CSS variables mapped into the Tailwind theme. Components never contain raw hex values or arbitrary Tailwind values such as `bg-[#1a2b3c]` or `p-[13px]`. Export the tokens from your Design System artifact.

- **Why:** Tokens keep light and dark themes consistent and make a rebrand a one-file change. Raw values drift.
- **Check:** Lint rule bans hex literals in `.tsx` and arbitrary values in `className` (Biome `noRestrictedSyntax`-style pattern or `eslint-plugin-tailwindcss` `no-arbitrary-value`). Blocks in CI, warns in pre-commit.

### UI-004 · MUST · Follow the Rules of React

Components and hooks are pure during render, hooks are called unconditionally at the top level, and props and state are never mutated. `eslint-plugin-react-hooks` and `eslint-plugin-jsx-a11y` run at error level.

- **Why:** Breaking these rules causes bugs that only show up under concurrent rendering or Strict Mode.
- **Check:** ESLint with `react-hooks/rules-of-hooks: error`, `react-hooks/exhaustive-deps: error` and `jsx-a11y` recommended rules, in pre-commit and CI.

### UI-005 · MUST · Use TanStack Query, a generated API client, and Zod forms

- Server state goes through TanStack Query. Don't copy server data into `useState` or a global store.
- API types and the client are generated from FastAPI's OpenAPI schema with `openapi-typescript` and called through `openapi-fetch`. Never hand-write request or response types.
- CI regenerates the types and fails if the result differs from the committed file.
- Forms use React Hook Form with a Zod schema. The Zod schema mirrors the generated request type; the server's Pydantic model stays the source of truth.

- **Why:** Generated types turn a backend change into a compile error in the frontend, not a runtime bug. TanStack Query handles caching, retries and invalidation that hand-written effects get wrong.
- **Check:** CI job `api-types`: start the API (or export `openapi.json`), run `openapi-typescript`, then `git diff --exit-code src/lib/api/schema.d.ts`.

### UI-006 · MUST · Organize code by feature

Use feature folders: `src/features/<name>/{api,components,hooks,types}`. shadcn components live in `src/components/ui`. A feature never imports from another feature's internals; shared code moves to `src/components`, `src/hooks` or `src/lib`.

- **Why:** Feature folders keep related code together and make a feature easy to delete. Cross-feature imports create tangled dependencies.
- **Check:** ESLint `import/no-restricted-paths` zones forbid `src/features/a` → `src/features/b`.

### UI-007 · MUST · Meet WCAG 2.2 AA

Every screen meets WCAG 2.2 level AA: keyboard reachable, visible focus, labels on controls, 4.5:1 text contrast, no information carried by color alone.

- **Why:** Accessibility is a legal requirement in many markets and improves usability for everyone.
- **Check:** `@axe-core/playwright` runs on every route in the Playwright suite. Any violation of impact `serious` or `critical` blocks the PR.

### UI-008 · MUST · Stay inside the Core Web Vitals budget

At the 75th percentile: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1. The initial JavaScript bundle stays under the budget set in `lighthouserc.json` (default 200 KB gzipped).

- **Why:** These are Google's thresholds for a "good" experience, and they affect search ranking.
- **Check:** Lighthouse CI with assertions on the main routes blocks regressions. Production field data comes from the `web-vitals` library sent to telemetry (OBS).

### UI-009 · MUST · Test with Vitest, Testing Library, Playwright and MSW

Component and hook tests use Vitest and Testing Library, querying by role and label, not by class or test ID where a role exists. User flows use Playwright. Network calls are mocked with MSW, using handlers typed from the generated schema.

- **Why:** Testing through roles checks what users see and doubles as an accessibility check. MSW mocks at the network layer, so the code under test is the code that ships.
- **Check:** `vitest run --coverage` and `playwright test` in CI; diff coverage per TST-003.

### UI-010 · MUST NOT · Store auth tokens in browser storage

Never put access tokens, refresh tokens or session IDs in `localStorage`, `sessionStorage` or IndexedDB. The FastAPI backend-for-frontend sets an HttpOnly, Secure, SameSite cookie (AUTH-004), and the frontend sends it with `credentials: "include"`.

- **Why:** Any XSS bug can read browser storage. HttpOnly cookies are out of reach of scripts.
- **Check:** Lint rule bans `localStorage.setItem` / `sessionStorage.setItem` with keys matching `/token|jwt|session|auth/i`. Code review per REV.

### UI-011 · SHOULD · Design the four states of every screen

Each screen and data-bound component handles loading, empty, error and success. The empty state says what will appear and how to add the first item. The error state says what went wrong and what to do.

- **Why:** Most UI bugs users see are unhandled states, not wrong success screens.
- **Check:** advisory. The reviewer subagent checks for `isPending`, `isError` and empty-list branches.

## Reference

### Stack

| Concern | Choice | Notes |
|---------|--------|-------|
| Framework | React + TypeScript (strict) | Current stable React |
| Build | Vite | Next.js App Router only for SEO or SSR, with an ADR |
| Styling | Tailwind CSS | Theme mapped to CSS variables |
| Components | shadcn/ui on Radix | Copied into `src/components/ui` |
| Icons | lucide-react | |
| Charts | Recharts | |
| Server state | TanStack Query | |
| API client | openapi-typescript + openapi-fetch | Generated from FastAPI |
| Forms | React Hook Form + Zod | `@hookform/resolvers/zod` |
| Routing | React Router or TanStack Router | Pick one per repo |
| Unit tests | Vitest + Testing Library | |
| E2E tests | Playwright + `@axe-core/playwright` | |
| API mocks | MSW | |
| Lint and format | Biome (format) + ESLint (react-hooks, jsx-a11y, import) | |

### Folder layout

```text
src/
├── app/                    # app shell: providers, router, layout
│   ├── providers.tsx       # QueryClientProvider, ThemeProvider
│   └── routes/
├── components/
│   └── ui/                 # shadcn/ui components (button.tsx, dialog.tsx, ...)
├── features/
│   └── restock/
│       ├── api/            # query and mutation hooks: use-bom-import.ts
│       ├── components/     # bom-paste-form.tsx, unmatched-lines.tsx
│       ├── hooks/
│       └── types/
├── hooks/                  # shared hooks
├── lib/
│   ├── api/
│   │   ├── schema.d.ts     # generated, do not edit
│   │   └── client.ts       # openapi-fetch client
│   └── utils.ts            # cn() helper from shadcn
├── styles/
│   └── tokens.css          # design tokens
└── testing/
    └── msw/handlers.ts
```

### Design tokens mapped into Tailwind (example)

shadcn/ui expects semantic CSS variables such as `--background`, `--foreground`, `--primary`. Define them once, with dark values under `.dark`, and map them into the Tailwind theme.

```css
/* src/styles/tokens.css (example, Tailwind v4 syntax) */
@import "tailwindcss";

:root {
  --background: oklch(0.98 0.005 250);
  --foreground: oklch(0.2 0.02 250);
  --primary: oklch(0.45 0.18 265);
  --primary-foreground: oklch(0.98 0 0);
  --muted: oklch(0.95 0.01 250);
  --muted-foreground: oklch(0.5 0.02 250);
  --border: oklch(0.9 0.01 250);
  --radius: 0.5rem;
}

.dark {
  --background: oklch(0.18 0.01 250);
  --foreground: oklch(0.93 0.01 250);
  --primary: oklch(0.72 0.14 265);
  --primary-foreground: oklch(0.18 0.01 250);
  --muted: oklch(0.24 0.01 250);
  --muted-foreground: oklch(0.7 0.02 250);
  --border: oklch(0.3 0.01 250);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-border: var(--border);
  --radius-lg: var(--radius);
}
```

Components then use `bg-primary text-primary-foreground rounded-lg`, never `bg-[#2742c9]`.

### Generated API client (example)

```bash
# package.json script
openapi-typescript http://localhost:8000/openapi.json -o src/lib/api/schema.d.ts
```

```ts
// src/lib/api/client.ts
import createClient from "openapi-fetch";
import type { paths } from "./schema";

export const api = createClient<paths>({
  baseUrl: import.meta.env.VITE_API_URL,
  credentials: "include", // session cookie from the BFF (UI-010)
});
```

```ts
// src/features/restock/api/use-bom-import.ts
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api/client";

export function useBomImport() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (lines: string) => {
      const { data, error } = await api.POST("/v1/carts/current:importBom", {
        body: { lines },
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["cart"] }),
  });
}
```

### Core Web Vitals budget (example `lighthouserc.json`)

```json
{
  "ci": {
    "assert": {
      "assertions": {
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "total-blocking-time": ["error", { "maxNumericValue": 200 }],
        "categories:accessibility": ["error", { "minScore": 0.95 }]
      }
    }
  }
}
```

Lighthouse runs in a lab and cannot measure INP directly; Total Blocking Time is the lab proxy. INP is measured in the field with the `web-vitals` library.

| Metric | Good (p75) | Measured by |
|--------|-----------|-------------|
| LCP | ≤ 2.5 s | Lighthouse CI (lab), web-vitals (field) |
| INP | ≤ 200 ms | web-vitals (field); TBT as lab proxy |
| CLS | ≤ 0.1 | Lighthouse CI (lab), web-vitals (field) |

## Sources

- [Rules of React](https://react.dev/reference/rules)
- [bulletproof-react](https://github.com/alan2207/bulletproof-react)
- [shadcn/ui theming](https://ui.shadcn.com/docs/theming)
- [openapi-typescript and openapi-fetch](https://openapi-ts.dev/)
- [TanStack Query](https://tanstack.com/query)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [Core Web Vitals](https://web.dev/articles/vitals)
