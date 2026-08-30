---
id: BENCH-101
title: Find and fix the recurrence drift bug in RecurKit (Swift)
area: benchmark
priority: 100
verify: 'cd src/opencode-muse-spark-1.2-contributor-free/r1/task1/RecurKit && swift run RecurKitChecks'
workflow: bench-opencode-muse-spark-1.2-contributor-free
done_when:
  - "a new check in Sources/RecurKitChecks reproduces the reported drift deterministically and is registered in main.swift"
  - "the root cause in Sources/RecurKit is fixed without changing the public API"
  - "swift run RecurKitChecks exits 0 with every pre-existing check intact"
---
## Goal
Fix the bug behind the user report in `src/opencode-muse-spark-1.2-contributor-free/r1/task1/RecurKit/PLAN.md`, and
prove it with a regression check you write yourself.

## Context
RecurKit is a small date library (spans, span sets, recurrence rules)
with a passing check suite: `swift run RecurKitChecks` inside
`src/opencode-muse-spark-1.2-contributor-free/r1/task1/RecurKit`. A user reports weekly/daily series drifting by an
hour twice a year; the library's own documentation says occurrences are
calendar times. The bug is real, deterministic, and NOT covered by the
shipped checks — reproducing it is part of the task. Full report and
rules: `src/opencode-muse-spark-1.2-contributor-free/r1/task1/RecurKit/PLAN.md`.

## Do
Read `src/opencode-muse-spark-1.2-contributor-free/r1/task1/RecurKit/PLAN.md`. Write a deterministic check that
fails on the current code because of the reported bug, find and fix the
root cause in `Sources/RecurKit/`, and leave the whole suite green. Do
not weaken or delete existing checks; do not change the public API.

## Do not
Do not touch anything outside `src/opencode-muse-spark-1.2-contributor-free/r1/task1/`. Do not special-case the
symptom instead of fixing the cause.
