---
id: __ID__
title: Implement the logstat CLI from its spec (Rust, std-only)
area: benchmark
priority: 110
verify: 'export PATH="/opt/homebrew/bin:$PATH" && cd __TASKDIR__/logstat && cargo test'
workflow: bench-__SLUG__
done_when:
  - "cargo test passes byte-exact against the shipped goldens without editing tests, fixtures, or Cargo.toml"
  - "the implementation is std-only and structured so parsing, aggregation, and formatting are separable"
---
## Goal
Implement the `logstat` log-analysis CLI specified in
`__TASKDIR__/logstat/PLAN.md` so its shipped test contract passes.

## Context
The crate skeleton is in `__TASKDIR__/logstat`: a stub `src/main.rs`, a
pinned executable contract in `tests/cli.rs`, and byte-exact goldens in
`fixtures/`. No external crates — the host has no crates.io access; flag
parsing and JSON output are hand-rolled. Percentiles use nearest-rank;
the spec pins every format decision. Your session sandbox may not be
able to run cargo itself; the verify gate runs it and feeds failures
back to you.

## Do
Read `__TASKDIR__/logstat/PLAN.md` and implement `src/main.rs` (split
into modules if it helps readability) until `cargo test` passes. Write
idiomatic Rust — the reviewer judges structure as well as correctness.

## Do not
Do not modify `tests/`, `fixtures/`, or `Cargo.toml`. Do not add
dependencies. Do not touch anything outside `__TASKDIR__/`.
