# peonmaxxer-testing-facility

A model benchmark that runs on [peonmaxxer](https://github.com/pixel0verflow/peonmaxxer-core):
point it at an opencode connector model, and a peon worker autonomously
works three fixed software tasks — implement → verify → PR → fresh-session
review → fixes → PR update — while you watch (or take over) in the
worker dashboard's live harness pane. Every PR opens with a stats line:
model, API-vs-local (with machine specs when local), harness, wall-clock
time, and token totals — rendered by the workflow itself.

## The three benchmark tasks

| task | language | shape | verify gate |
| --- | --- | --- | --- |
| `task1` RecurKit | Swift | find & fix a planted bug from a user report — the repo ships **no test for it**; the model must write the reproducing check itself | `swift run RecurKitChecks` |
| `task2` logstat | Rust (std-only) | implement a spec'd log-analysis CLI against byte-exact goldens | `cargo test` |
| `task3` pricing-site | Svelte 5 + Vite | build a product site around a test-pinned pricing engine | `npm ci && npm test && npm run build` |

Sources live under `src/benchmark/` and are copied per run to
`src/<model-slug>/r<run>/task{1,2,3}` — the benchmark itself is
protected by the project's gate config and stays pristine. The bug-hunt
task's answer key is deliberately **not** in this repository.

## Running a benchmark

One-time setup (see peonmaxxer-core's Quickstart for the full flow):

```sh
peon serve --data-dir ~/.peon/data &
peon project add --name peonmaxxer-testing-facility \
  --repo-url git@github.com:pixel0verflow/peonmaxxer-testing-facility.git \
  --local-path <this checkout>
peon profile list                             # already have an `opencode` profile? then skip the next line
peon profile add opencode --kind subscription --harness opencode
peon profile check opencode                   # preflight against the real binary
peon token create --scope worker --name bench-worker
```

Per model, per run — one command with `PEON_CORE_URL`/`PEON_TOKEN` set:

```sh
scripts/new-benchmark-run.sh --queue         # interactive picker over `opencode models`
# or: scripts/new-benchmark-run.sh opencode/muse-spark-1.2-contributor-free --queue
# or: scripts/new-benchmark-run.sh ollama/qwen3 --local --queue
PEON_TOKEN=<worker token> peon worker --dashboard
```

`--queue` refuses up front — before generating anything — if the env is
missing or the project isn't registered, then pushes, reconciles, and
queues all three tasks (project resolved by name; `PEON_PROJECT_ID`
overrides). Without `--queue` the script only generates and commits and
prints how to queue that run by hand. Every invocation is a new numbered
run — don't re-run it to retry queueing.

Each invocation of `new-benchmark-run.sh` is a fresh, numbered run:
fresh task ids (`BENCH-<run><task>` — run zero-padded to three digits,
task 1-3, so run 2 is `BENCH-0021..0023`), fresh scaffold copies, one
generated workflow per model (`.peonmaxxer/workflows/bench-<slug>.yaml`
— workflows pin the model statically; peonmaxxer cannot vary a model per
run yet). With the dashboard up, the right pane hosts the real opencode session —
`t` takes over, `ctrl+\` hands back, and any takeover flags the run
`manual_review` with a PR disclosure.

PR stat lines (time, tokens) are rendered by the workflow itself from
the run's own step reports — nothing to stamp afterwards.

## Comparing models

Every PR is one model × one task, opened from branch
`peon/BENCH-<run><task>-…`, its first line carrying the identity and
cost of the attempt, its body carrying the step ledger and the
fresh-session review trail. Compare runs by scanning PR list lines.
Unattended mode: queue all three tasks and let the worker chew through
them; `manual_review` marks any run a human touched.

## Host requirements

- macOS with Swift (Command Line Tools suffice — task1's checks use a
  framework-free runner on purpose), Node ≥ 20, Rust (`brew install rust`),
  `opencode` ≥ 1.18.21, `gh` authenticated for this repo.
- a `peon` binary built from peonmaxxer-core main of 2026-08-31 or later
  (in-sandbox Homebrew toolchains, template-rendered run stats, and the
  worker dashboard's live harness pane — `t` to take over — all ship by
  then; until CORE-031 lands on main, build from its PR branch for the
  live pane).
