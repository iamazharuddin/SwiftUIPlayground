#!/usr/bin/env bash
# Post a build status message to Slack via an Incoming Webhook.
# Usage: notify_slack.sh <status> <context>
#   <status>  = success | failure | cancelled   (pass GitHub's ${{ job.status }})
#   <context> = free text, e.g. "TestFlight beta (build 412)"
# Teaching reference: docs/cicd/part-17-notifications.md
set -euo pipefail

STATUS="${1:-unknown}"
CONTEXT="${2:-build}"

# Best-effort: if the webhook isn't configured, don't fail the job.
if [[ -z "${SLACK_WEBHOOK:-}" ]]; then
  echo "SLACK_WEBHOOK not set — skipping Slack notification."
  exit 0
fi

case "$STATUS" in
  success)   EMOJI="✅"; COLOR="#36a64f" ;;
  failure)   EMOJI="❌"; COLOR="#d92d20" ;;
  cancelled) EMOJI="⚪"; COLOR="#98a2b3" ;;
  *)         EMOJI="ℹ️"; COLOR="#667085" ;;
esac

# Link back to the run when GitHub context is available.
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"

PAYLOAD=$(cat <<JSON
{
  "attachments": [{
    "color": "${COLOR}",
    "text": "${EMOJI} *${CONTEXT}* — ${STATUS}\n<${RUN_URL}|View run> · \`${GITHUB_REF_NAME:-}\` @ \`${GITHUB_SHA:0:7}\`"
  }]
}
JSON
)

curl -sf -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK" \
  || echo "Slack notify failed (non-fatal)."
