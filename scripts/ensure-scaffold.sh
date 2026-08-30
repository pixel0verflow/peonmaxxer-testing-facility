#!/usr/bin/env sh
# ensure-scaffold.sh <model-slug> <task-id>
# First workflow step: confirms this run's benchmark scaffold was
# generated and committed (scripts/new-benchmark-run.sh does that). It
# never copies anything itself — an uncommitted copy would pollute the
# agent's diff with scaffold files.
set -eu

SLUG="$1"
TASK_ID="$2"

NUM="${TASK_ID##*-}"                 # BENCH-203 -> 203
RUN=$((NUM / 100))                   # -> 2
TASK=$((NUM % 100))                  # -> 3
DIR="src/${SLUG}/r${RUN}/task${TASK}"

if [ ! -d "$DIR" ]; then
  echo "ensure-scaffold: $DIR is missing from this worktree." >&2
  echo "Run scripts/new-benchmark-run.sh and push before queueing $TASK_ID." >&2
  exit 1
fi
if ! find "$DIR" -name PLAN.md | grep -q .; then
  echo "ensure-scaffold: $DIR has no PLAN.md — scaffold looks incomplete." >&2
  exit 1
fi
echo "scaffold ok: $DIR"
