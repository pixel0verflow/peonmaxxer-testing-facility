#!/usr/bin/env bash
# new-benchmark-run.sh [model] [--local|--api] [--queue]
#
# Full peonmaxxer setup for one benchmark run of one model:
#   1. pick a model (interactive picker over `opencode models` when no
#      argument is given),
#   2. generate .peonmaxxer/workflows/bench-<slug>.yaml with the model,
#      harness, and locality (local runs embed this machine's specs into
#      the PR stats line),
#   3. register it under workflow.named in peonmaxxer.yaml,
#   4. generate three BENCH-<run><task>.md task files,
#   5. copy the benchmark scaffolds to src/<slug>/r<run>/task{1,2,3},
#   6. commit. With --queue (and PEON_CORE_URL/PEON_TOKEN/PEON_PROJECT_ID
#      set) it also pushes, reconciles, and queues the three tasks.
#
# Rerunnable by construction: every invocation is a fresh numbered run
# with fresh task ids, fresh scaffold copies, and the same per-model
# workflow.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MODEL=""
LOCALITY_MODE="auto"
QUEUE=0
for arg in "$@"; do
  case "$arg" in
    --local) LOCALITY_MODE="local" ;;
    --api) LOCALITY_MODE="api" ;;
    --queue) QUEUE=1 ;;
    *) MODEL="$arg" ;;
  esac
done

PROJECT_NAME="peonmaxxer-testing-facility"
PROJECT_ID=""
if [ "$QUEUE" = 1 ]; then
  # Everything that can refuse does so NOW, before a run is generated —
  # a failed --queue attempt must never leave a committed run behind.
  if [ -z "${PEON_CORE_URL:-}" ] || [ -z "${PEON_TOKEN:-}" ]; then
    echo "--queue needs PEON_CORE_URL and PEON_TOKEN set (see README)." >&2
    exit 2
  fi
  command -v peon >/dev/null || { echo "--queue needs peon on PATH." >&2; exit 2; }
  PROJECT_ID="${PEON_PROJECT_ID:-$(peon project list --json 2>/dev/null | python3 -c '
import json,sys
name=sys.argv[1]
try: rows=json.load(sys.stdin)
except Exception: rows=[]
for r in rows if isinstance(rows,list) else rows.get("projects",[]):
    if r.get("name")==name: print(r.get("id","")); break
' "$PROJECT_NAME")}"
  if [ -z "$PROJECT_ID" ]; then
    cat >&2 <<REGISTER
Project "$PROJECT_NAME" is not registered on the core (or the core is
unreachable). Register it once, then re-run:

  peon project add --name $PROJECT_NAME \
    --repo-url "$(git remote get-url origin)" --local-path "$(pwd)"

REGISTER
    exit 2
  fi
fi

if [ -z "$MODEL" ]; then
  command -v opencode >/dev/null || { echo "opencode CLI not on PATH and no model given" >&2; exit 2; }
  echo "Fetching models from the opencode connectors..." >&2
  MODELS=$(opencode models 2>/dev/null | grep -E '^[a-z0-9._-]+/' || true)
  [ -n "$MODELS" ] || { echo "no models reported by 'opencode models'" >&2; exit 2; }
  i=0
  while IFS= read -r m; do i=$((i+1)); printf '%3d) %s\n' "$i" "$m"; done <<<"$MODELS"
  printf 'Pick a model [1-%d]: ' "$i"
  read -r CHOICE
  MODEL=$(sed -n "${CHOICE}p" <<<"$MODELS")
  [ -n "$MODEL" ] || { echo "invalid choice" >&2; exit 2; }
fi

# Locality: local engines serve from this machine; everything else is an
# API model. Override with --local / --api.
if [ "$LOCALITY_MODE" = "auto" ]; then
  case "$MODEL" in
    ollama/*|lmstudio/*|llama.cpp/*|llamacpp/*|mlx/*|local/*) LOCALITY_MODE="local" ;;
    *) LOCALITY_MODE="api" ;;
  esac
fi
if [ "$LOCALITY_MODE" = "local" ]; then
  CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown CPU")
  CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "?")
  RAM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))
  OSV="$(sw_vers -productName 2>/dev/null || uname -s) $(sw_vers -productVersion 2>/dev/null || uname -r)"
  LOCALITY="local — ${CHIP}, ${CORES} cores, ${RAM_GB} GB RAM, ${OSV}"
else
  LOCALITY="api"
fi

SLUG=$(printf '%s' "$MODEL" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9.-' '-' | sed 's/-*$//;s/^-*//')

# Next run number. Ids are BENCH-<run><task>: run zero-padded to 3
# digits, task 1-3 — BENCH-0011..0013 is run 1. (A legacy 3-digit id
# BENCH-1xx counts as run 1.)
RUN=$(ls .peonmaxxer/backlog/BENCH-*.md 2>/dev/null | sed -E 's/.*BENCH-([0-9]+)\.md/\1/' | python3 -c '
import sys
best = 0
for line in sys.stdin:
    n = line.strip()
    if not n.isdigit(): continue
    best = max(best, int(n) // (10 if len(n) >= 4 else 100))
print(best + 1)
')

WF_NAME="bench-${SLUG}"
WF_PATH=".peonmaxxer/workflows/${WF_NAME}.yaml"
sed -e "s|__MODEL__|${MODEL}|g" -e "s|__SLUG__|${SLUG}|g" -e "s|__LOCALITY__|${LOCALITY}|g" \
  scripts/templates/workflow.yaml > "$WF_PATH"

python3 - "$WF_NAME" "$WF_PATH" <<'PYEOF'
import re, sys
name, path = sys.argv[1], sys.argv[2]
with open("peonmaxxer.yaml") as f:
    cfg = f.read()
entry = f"    {name}: {path}"
if entry in cfg:
    sys.exit(0)
if "  named: {}" in cfg:
    cfg = cfg.replace("  named: {}", "  named:\n" + entry, 1)
elif re.search(r"^  named:$", cfg, re.M):
    cfg = re.sub(r"^  named:$", "  named:\n" + entry, cfg, count=1, flags=re.M)
else:
    sys.exit("peonmaxxer.yaml: could not find workflow.named to extend")
with open("peonmaxxer.yaml", "w") as f:
    f.write(cfg)
PYEOF

for T in 1 2 3; do
  ID=$(printf 'BENCH-%03d%d' "$RUN" "$T")
  TASKDIR="src/${SLUG}/r${RUN}/task${T}"
  mkdir -p "$TASKDIR"
  case "$T" in
    1) SRC="src/benchmark/task1/RecurKit"; cp -R "$SRC" "$TASKDIR/RecurKit" ;;
    2) SRC="src/benchmark/task2/logstat"; cp -R "$SRC" "$TASKDIR/logstat" ;;
    3) SRC="src/benchmark/task3/pricing-site"; cp -R "$SRC" "$TASKDIR/pricing-site" ;;
  esac
  sed -e "s|__ID__|${ID}|g" -e "s|__SLUG__|${SLUG}|g" -e "s|__TASKDIR__|${TASKDIR}|g" \
    "scripts/templates/task${T}.md" > ".peonmaxxer/backlog/${ID}.md"
done

git add -A
git commit -m "bench: run ${RUN} for ${MODEL} (${LOCALITY_MODE})"

echo
echo "Run ${RUN} for ${MODEL} is committed:"
echo "  workflow:  ${WF_PATH}"
echo "  tasks:     $(printf 'BENCH-%03d1 BENCH-%03d2 BENCH-%03d3' "$RUN" "$RUN" "$RUN")"
echo "  scaffolds: src/${SLUG}/r${RUN}/task{1,2,3}"
echo
if [ "$QUEUE" = 1 ] && [ -n "${PEON_CORE_URL:-}" ] && [ -n "${PEON_TOKEN:-}" ]; then
  git push
  # Bootstrap the project on the core if this is the first run: identity
  # by name, repo/paths derived from this checkout. Needs an admin-scope
  # PEON_TOKEN the first time; reconcile/queue work with it thereafter.
  PROJECT_NAME="peonmaxxer-testing-facility"
  PROJECT_ID="${PEON_PROJECT_ID:-$(peon project list --json 2>/dev/null | python3 -c '
import json,sys
name=sys.argv[1]
try: rows=json.load(sys.stdin)
except Exception: rows=[]
for r in rows if isinstance(rows,list) else rows.get("projects",[]):
    if r.get("name")==name: print(r.get("id","")); break
' "$PROJECT_NAME")}"
  if [ -z "$PROJECT_ID" ]; then
    echo "project not found on the core; creating it..."
    PROJECT_ID=$(peon project add --name "$PROJECT_NAME"       --repo-url "$(git remote get-url origin)" --local-path "$(pwd)"       | grep -oE '[a-z0-9_-]+$' | tail -1)
    [ -n "$PROJECT_ID" ] || { echo "peon project add did not yield a project id" >&2; exit 1; }
  fi
  peon project reconcile "$PROJECT_ID"
  for T in 1 2 3; do peon task queue "$PROJECT_ID" "$(printf 'BENCH-%03d%d' "$RUN" "$T")"; done
  echo "Pushed, reconciled, and queued on project ${PROJECT_ID}."
  echo "Any connected worker advertising the opencode adapter will pick these up;"
  echo "watch with: peon worker --dashboard"
else
  cat <<NEXT
Next steps (the core reads config and backlog from origin/<default branch>):
  git push
  scripts/new-benchmark-run.sh --queue   # …or by hand:
  peon project reconcile <project-id>
  peon task queue <project-id> BENCH-$((RUN*100+1))   # then 2 and 3
  peon worker --dashboard        # watch the live pane; t takes over
NEXT
fi
