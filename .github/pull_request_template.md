<!--
  Benchmark PRs are opened by peon workers from a generated workflow and
  already follow this shape. Use this template for MANUAL PRs against
  the facility (new benchmark tasks, script changes, scaffold fixes).

  Title: {tag}(scope): summary   — tags: bench | feat | fix | docs | chore
-->

**model:** `n/a — human` (local/api) · **harness:** `n/a` · **time to complete:** n/a · **tokens in/out:** n/a

<!-- For benchmark PRs the line above is generated with the real model,
     locality (API, or local + machine specs), wall-clock time, and token
     totals, all rendered by the workflow. Keep it as line 1: tooling
     parses it. -->

## What?

{One paragraph: what this PR changes and why.}

## How was it verified?

{Commands run and their results. For benchmark scaffolds: proof the
contract is satisfiable (reference implementation results) and that the
shipped state behaves as designed.}

## Checks

- [ ] task scaffolds keep their answer keys OUT of the repo (bug-hunt tasks)
- [ ] verify gates run with caches inside the worktree
- [ ] scripts pass `bash -n` / `sh -n`
- [ ] README updated where behavior changed
