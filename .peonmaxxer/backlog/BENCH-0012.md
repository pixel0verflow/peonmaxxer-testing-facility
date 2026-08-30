---
id: BENCH-0012
title: Implement the logstat CLI from its spec (Rust, std-only)
area: benchmark
priority: 110
verify: 'export PATH="/opt/homebrew/bin:$PATH" && cd src/opencode-muse-spark-1.2-contributor-free/r1/task2/logstat && cargo test'
workflow: bench-opencode-muse-spark-1.2-contributor-free
done_when:
  - "cargo test passes byte-exact against the shipped goldens without editing tests, fixtures, or Cargo.toml"
  - "the implementation is std-only and structured so parsing, aggregation, and formatting are separable"
---
## Goal
Implement the `logstat` log-analysis CLI specified in
`src/opencode-muse-spark-1.2-contributor-free/r1/task2/logstat/PLAN.md` so its shipped test contract passes.

## Context
The crate skeleton is in `src/opencode-muse-spark-1.2-contributor-free/r1/task2/logstat`: a stub `src/main.rs`, a
pinned executable contract in `tests/cli.rs`, and byte-exact goldens in
`fixtures/`. No external crates — the host has no crates.io access; flag
parsing and JSON output are hand-rolled. Percentiles use nearest-rank;
the spec pins every format decision. Run `cargo test` yourself as you
work (current peonmaxxer builds allow it in-session); if your sandbox
cannot, the verify gate runs it and feeds failures back to you.

## Do
Read `src/opencode-muse-spark-1.2-contributor-free/r1/task2/logstat/PLAN.md` and implement `src/main.rs` (split
into modules if it helps readability) until `cargo test` passes. Write
idiomatic Rust — the reviewer judges structure as well as correctness.

## Do not
Do not modify `tests/`, `fixtures/`, or `Cargo.toml`. Do not add
dependencies. Do not touch anything outside `src/opencode-muse-spark-1.2-contributor-free/r1/task2/`.
