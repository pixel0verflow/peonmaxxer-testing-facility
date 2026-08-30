---
id: __ID__
title: Build the Peonware pricing site (Svelte 5 + Vite)
area: benchmark
priority: 120
verify: 'export PATH="/opt/homebrew/bin:$PATH" && cd __TASKDIR__/pricing-site && npm ci && npm test && npm run build'
workflow: bench-__SLUG__
done_when:
  - "npm ci, npm test, and npm run build all succeed without editing the pinned contract files"
  - "the pricing calculator and the vitest suite share one computePrice implementation in src/lib/pricing.js"
  - "the feature grid renders from data/features.json, not hard-coded markup"
---
## Goal
Build the small product website specified in
`__TASKDIR__/pricing-site/PLAN.md`: hero, data-driven feature grid, and
an interactive pricing calculator, in Svelte 5 + Vite.

## Context
The scaffold is in `__TASKDIR__/pricing-site`: pinned `package.json` +
lockfile (Svelte 5, Vite, vitest), `vite.config.js`, the pricing test
contract in `tests/pricing.test.js`, and grid data in
`data/features.json`. The pricing rules (marginal volume tiers, annual
discount, rounding) are fully pinned by the tests. Caches are kept
in-tree via `.npmrc`. Run `npm ci && npm test && npm run build` yourself
as you work (current peonmaxxer builds allow it in-session); if your
sandbox cannot, the verify gate runs it and feeds failures back to you.

## Do
Read `__TASKDIR__/pricing-site/PLAN.md`. Implement
`src/lib/pricing.js` to satisfy the tests, then build the site around
it (`index.html`, `src/` components, scoped styles). Keep components
small and accessible (labels, keyboard use).

## Do not
Do not edit `tests/`, `data/`, `package.json`, `package-lock.json`,
`vite.config.js`, or `.npmrc`. No CSS frameworks, no network beyond
`npm ci`. Do not touch anything outside `__TASKDIR__/`.
