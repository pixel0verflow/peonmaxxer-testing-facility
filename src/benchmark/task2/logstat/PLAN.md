# Task 2 — Implement `logstat` (Rust, std-only)

Implement a small log-analysis CLI in `src/main.rs`. The contract is
pinned by `tests/cli.rs` plus the goldens in `fixtures/` — `cargo test`
(run in this directory) must pass byte-exact. Do not modify the tests,
the fixtures, or `Cargo.toml`; **no external crates** (the build host has
no crates.io access).

## Input format

One request per line:

    <RFC3339-UTC-timestamp> <METHOD> <PATH> <STATUS> <LATENCY_MS>

e.g. `2026-08-30T10:00:01Z GET /api/users 200 120`. A line is **valid**
when it has exactly five space-separated fields and: the timestamp is 20
chars ending in `Z` containing `T`; the method is one of GET POST PUT
PATCH DELETE HEAD OPTIONS; the path starts with `/`; the status is
exactly three digits; the latency is a non-negative integer. Anything
else is a **skipped** line — never an error.

## Commands

### `logstat summary <file> [--json]`

Aggregates valid lines per path. Default output is TSV:

    path\trequests\terrors\tp50_ms\tp95_ms
    <one row per path>
    skipped\t<count>

- `errors` counts status >= 500.
- Percentiles use **nearest-rank**: for percentile p over N ascending
  latencies, take the value at index `ceil(p/100 * N)` (1-indexed).
- Rows sort by requests descending, then path ascending.
- With `--json`: one line of compact JSON (no spaces), keys in this
  order — `{"paths":[{"path":…,"requests":…,"errors":…,"p50_ms":…,"p95_ms":…}],"skipped":…}` —
  ending with a newline. Path order identical to the TSV.

### `logstat filter <file> --status <2xx|4xx|5xx> [--method <METHOD>]`

Prints valid matching lines verbatim (normalized single spaces, as in
the input), in input order. `--status 5xx` means 500–599, etc.

## Exit codes

- `0` success
- `1` the input file cannot be read (report on stderr, nothing on stdout)
- `2` usage error: missing/unknown subcommand, missing file argument,
  missing or invalid `--status` class (report on stderr)

## Definition of done

`cargo test` passes. Write idiomatic, readable Rust; structure the code
so parsing, aggregation, and formatting are separable — the reviewer
will judge structure as well as correctness.
