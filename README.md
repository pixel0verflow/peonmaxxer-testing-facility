# peonmaxxer-testing-facility

A model benchmark that runs on [peonmaxxer](https://github.com/pixel0verflow/peonmaxxer-core):
point it at an opencode connector model, and a peon worker autonomously
works three fixed software tasks — implement → verify → PR → fresh-session
review → fixes → PR update — while you watch (or take over) in the
worker dashboard's live harness pane. Every PR opens with a stats line:
model, API-vs-local (with machine specs when local), harness, and — once
stamped — wall-clock time and token totals.

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
peon project add --name peonmaxxer-testing-facility --repo-url <this repo> --local-path <this checkout>
peon profile add opencode --kind subscription --harness opencode
peon token create --scope worker --name bench-worker
```

Per model, per run:

```sh
scripts/new-benchmark-run.sh                 # interactive picker over `opencode models`
# or: scripts/new-benchmark-run.sh opencode/muse-spark-1.2-contributor-free
# or: scripts/new-benchmark-run.sh ollama/qwen3 --local
git push                                     # the core reads config/backlog from origin/main
peon project reconcile <project-id>
peon task queue <project-id> BENCH-<run>01   # then 02, 03
PEON_TOKEN=<worker token> peon worker --dashboard
```

Each invocation of `new-benchmark-run.sh` is a fresh, numbered run:
fresh task ids (`BENCH-<run><task>`), fresh scaffold copies, one
generated workflow per model (`.peonmaxxer/workflows/bench-<slug>.yaml`
— workflows pin the model statically; peonmaxxer cannot vary a model per
run yet). `--queue` pushes, reconciles, and queues in one go when
`PEON_CORE_URL`/`PEON_TOKEN`/`PEON_PROJECT_ID` are set. With the
dashboard up, the right pane hosts the real opencode session — `t`
takes over, `ctrl+\` hands back, and any takeover flags the run
`manual_review` with a PR disclosure.

After a run lands its PR:

```sh
scripts/stamp-pr-stats.sh <run-id> <pr-number>
```

fills line 1's time and token totals from the core's API (the workflow
template context exposes no run stats — a known peonmaxxer limitation;
the stats line ships with ⏳ placeholders until stamped).

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
- peonmaxxer-core with [PR #118](https://github.com/pixel0verflow/peonmaxxer-core/pull/118)
  (merged 2026-08-30) — it admits `/opt` read-only in the agent sandbox so
  sessions can run Homebrew toolchains (node, cargo) themselves. On older
  builds, tasks 2 and 3 fall back to the verify→fix feedback loop.
