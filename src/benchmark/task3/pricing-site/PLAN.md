# Task 3 — Build "Peonware Pricing" (Svelte 5 + Vite)

Build a small product website for a fictional SaaS in THIS directory:
a landing page with a feature-comparison grid and an interactive pricing
calculator. Svelte 5 and Vite are pinned in `package.json` (lockfile
committed — run `npm ci`); vitest is wired via `vite.config.js`.

## Fixed contract (do not edit these files)

- `tests/pricing.test.js` — pins the pricing engine you must implement
  at `src/lib/pricing.js` (ES module, named export `computePrice`).
- `data/features.json` — the feature grid's data source.
- `package.json`, `package-lock.json`, `vite.config.js`, `.npmrc`.

## Pricing rules (encoded by the tests)

- Per-seat monthly rates: starter $9, team $18, enterprise $32.
- Marginal volume tiers: seats 1–10 full rate, 11–50 at 90% of the
  rate, 51+ at 75% — applied per seat, like tax brackets.
- Add-ons: flat `pricePerMonth` each, added to the subtotal.
- `months` is 1 or 12; 12 applies a 20% discount to the WHOLE subtotal
  (seats + add-ons).
- Round the monthly price half-up to cents; `total = monthly × months`;
  `savings` = undiscounted total minus `total`, rounded to cents.
- Invalid plan, `seats < 1`, or any other `months` value throws.

## The site

- `index.html` + `src/` Svelte app. Sections: hero, feature grid
  (render every row of `data/features.json` — no hard-coded copies),
  pricing calculator (plan picker, seat count, monthly/annual toggle,
  add-on checkboxes: SSO $25/mo, Backup $4.99/mo), and a footer.
- The calculator must use `computePrice` — one pricing implementation,
  used by both the tests and the UI.
- Presentable styling is part of the task (plain CSS or scoped Svelte
  styles; no CSS frameworks — no network beyond `npm ci`).

## Definition of done

`npm ci && npm test && npm run build` all succeed in this directory.
The reviewer will judge component structure, accessibility basics
(labels, keyboard use), and whether the grid really renders from the
JSON.
