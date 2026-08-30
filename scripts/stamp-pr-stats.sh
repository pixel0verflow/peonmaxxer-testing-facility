#!/usr/bin/env bash
# stamp-pr-stats.sh <run-id> <pr-number>
#
# Fills the PR stats line (time to complete, tokens in/out) after a
# benchmark run finishes. The peonmaxxer PR-body template cannot render
# these — workflow templates see no run stats (core limitation, noted in
# the README) — so they are stamped from the core's API afterwards.
#
# Needs: PEON_CORE_URL, PEON_TOKEN (viewer or admin scope), gh, jq.
set -euo pipefail
RUN_ID="${1:?usage: stamp-pr-stats.sh <run-id> <pr-number>}"
PR="${2:?usage: stamp-pr-stats.sh <run-id> <pr-number>}"
: "${PEON_CORE_URL:?set PEON_CORE_URL}"
: "${PEON_TOKEN:?set PEON_TOKEN}"

auth=(-H "Authorization: Bearer ${PEON_TOKEN}")

run_json=$(curl -sf "${auth[@]}" "${PEON_CORE_URL}/v0/runs/${RUN_ID}")
started=$(jq -r '.started_at // empty' <<<"$run_json")
ended=$(jq -r '.ended_at // empty' <<<"$run_json")
if [ -n "$started" ] && [ -n "$ended" ]; then
  secs=$(( $(date -j -f '%Y-%m-%dT%H:%M:%SZ' "${ended%%.*}Z" +%s 2>/dev/null || date -d "$ended" +%s) \
         - $(date -j -f '%Y-%m-%dT%H:%M:%SZ' "${started%%.*}Z" +%s 2>/dev/null || date -d "$started" +%s) ))
  dur=$(printf '%dm%02ds' $((secs / 60)) $((secs % 60)))
else
  dur="unknown"
fi

# Token totals: sum every usage event on the run's event log.
tokens=$(curl -sf "${auth[@]}" "${PEON_CORE_URL}/v0/runs/${RUN_ID}/events" \
  | jq -s -r 'map(select(.type == "usage") | .payload) | "\(map(.in_tokens) | add // 0) \(map(.out_tokens) | add // 0)"')
tin=${tokens% *}; tout=${tokens#* }

body=$(gh pr view "$PR" --json body -q .body)
line1=$(head -1 <<<"$body")
rest=$(tail -n +2 <<<"$body")
stamped=$(sed -E \
  -e "s/⏳ pending( \`scripts\/stamp-pr-stats.sh\`)?/${dur}/" \
  -e "s/⏳ pending/${tin} \/ ${tout}/" <<<"$line1")
printf '%s\n%s' "$stamped" "$rest" | gh pr edit "$PR" --body-file -
echo "PR #${PR}: time=${dur} tokens=${tin}/${tout}"
