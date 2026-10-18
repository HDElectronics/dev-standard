# Profile: react-web

For React frontends (UI group). This is the stack Claude's React artifacts use, so prototypes move into the codebase without a rewrite.

## Stack

| Concern | Tool | Rule |
|---------|------|------|
| Framework | React + TypeScript strict, Vite (Next.js App Router only for SEO or server rendering) | UI-001 |
| Styling and components | Tailwind CSS, shadcn/ui on Radix, lucide-react, Recharts | UI-002 |
| Tokens | CSS variables mapped into the Tailwind theme | UI-003 |
| Server state, forms | TanStack Query, React Hook Form + Zod | UI-005 |
| API types | openapi-typescript + openapi-fetch, generated from the FastAPI schema | UI-005 |
| Format, lint | Biome; ESLint only for react-hooks, jsx-a11y and boolean naming | STY-001, UI-004 |
| Tests | Vitest, Testing Library, MSW, Playwright, axe | UI-007, UI-009 |
| Performance | Lighthouse CI budgets | UI-008 |

## New project

```bash
npm create vite@latest web -- --template react-ts
cd web
npm install tailwindcss @tailwindcss/vite
npx shadcn@latest init
npm install lucide-react recharts @tanstack/react-query react-hook-form zod @hookform/resolvers openapi-fetch
npm install --save-dev --save-exact @biomejs/biome
npm install --save-dev eslint typescript-eslint eslint-plugin-react-hooks eslint-plugin-jsx-a11y openapi-typescript
npm install --save-dev vitest @vitest/coverage-v8 jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event msw
npm install --save-dev @playwright/test @axe-core/playwright @lhci/cli
npx playwright install
```

Tailwind CSS v4 setup: add `tailwindcss()` from `@tailwindcss/vite` to the `plugins` in `vite.config.ts`, and put `@import "tailwindcss";` at the top of `src/index.css`. `shadcn init` needs the `@/*` path alias in `tsconfig.json`, `tsconfig.app.json` and `vite.config.ts`; follow the prompts and the [shadcn Vite guide](https://ui.shadcn.com/docs/installation/vite).

Then merge the fragments:

- `biome.json`: merge into the repo's `biome.json` (run `npx @biomejs/biome migrate --write` if the Biome version differs).
- `eslint.config.js`: add as is, or merge its block into an existing flat config.
- `tsconfig.strict.json`: copy, then add `"extends": "./tsconfig.strict.json"` to `tsconfig.app.json`, or merge its `compilerOptions`.

## Tokens (UI-003)

shadcn/ui already defines its colors as CSS variables (`--background`, `--primary`, ...). Set their values from your Design System artifact and add any extra tokens the same way. Components use only the token classes (`bg-primary`, `text-muted-foreground`), never `bg-[#1e40af]` or inline hex values.

## API types from FastAPI (UI-005)

FastAPI serves its schema at `/openapi.json`.

```bash
npx openapi-typescript http://localhost:8000/openapi.json -o src/api/schema.d.ts
```

```ts
// src/api/client.ts
import createClient from "openapi-fetch";
import type { paths } from "./schema";

export const api = createClient<paths>({ baseUrl: "/api", credentials: "include" });
```

`credentials: "include"` sends the HttpOnly session cookie set by the backend (UI-010). Add the generate command as an npm script (`"api:types"`) and regenerate when the backend contract changes. Wrap calls in TanStack Query hooks inside `src/features/<name>/api/`.

## Layout (UI-006)

```
src/
├── app/                  # providers, router, layout
├── components/ui/        # shadcn components (generated, then owned)
├── features/<name>/
│   ├── components/
│   ├── api/              # TanStack Query hooks over the typed client
│   └── hooks/
├── api/                  # schema.d.ts (generated), client.ts
└── lib/                  # utils, cn()
```

Files are kebab-case (`user-card.tsx`), components PascalCase (`UserCard`), hooks `useX` (NAM-001).

## Accessibility check in Playwright (UI-007)

```ts
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("cart page has no WCAG 2.2 AA violations", async ({ page }) => {
  await page.goto("/cart");
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

## Performance budgets (UI-008)

`lighthouserc.json`:

```json
{
  "ci": {
    "collect": { "staticDistDir": "./dist" },
    "assert": {
      "assertions": {
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "total-blocking-time": ["error", { "maxNumericValue": 200 }]
      }
    }
  }
}
```

Run with `npx lhci autorun` after `npm run build`. INP (≤ 200 ms) is a field metric that Lighthouse cannot measure in the lab; Total Blocking Time is the lab proxy above. Measure real INP with the `web-vitals` package in production.

## checks.fast

A good value for `.dev-standard.json`:

```bash
npx biome ci . && npx eslint . && npx tsc --noEmit -p tsconfig.app.json && npx vitest run
```
