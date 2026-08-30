# Task 1 — Bug hunt: RecurKit

RecurKit is a small date library: half-open `Span`s, a coalescing
`SpanSet`, and a `Recurrence` rule engine. It ships with a check suite
(`swift run RecurKitChecks`) that currently passes.

## The bug report

Filed by a user of the library, verbatim:

> We schedule a weekly standup with
> `Recurrence(start: <Monday 09:00>, frequency: .weekly, ...)` in
> `Europe/Warsaw`. Every spring the series silently shifts: after the
> last weekend of March the occurrences land on **10:00** instead of
> 09:00. In autumn it shifts the other way. Daily rules drift the same
> way across those weekends. The doc comment on `Recurrence` says
> occurrences are calendar times — this looks like a contract violation,
> not a feature.

## Your job

1. **Reproduce it**: write a new check in `Sources/RecurKitChecks/`
   (register it in `main.swift`) that fails on the current code because
   of this bug. Use a fixed time zone and fixed dates so it is
   deterministic on any host.
2. **Find and fix the root cause** in `Sources/RecurKit/`. Do not
   special-case the symptom; fix the actual defect.
3. Keep every existing check passing. Your new check must pass after the
   fix and would fail on the unfixed code.

## Rules

- Do not weaken or delete existing checks.
- Do not change the public API.
- `swift run RecurKitChecks` (run in this directory) must exit 0 when
  you are done.
