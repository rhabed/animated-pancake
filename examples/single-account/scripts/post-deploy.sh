#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$EXAMPLE_DIR"

ENDPOINT_URL="https://api.prod.cp.aidevops.us-east-1.api.aws"
REGION="us-east-1"

log() { echo "[$(date +%H:%M:%S)] $*"; }

agent_space_id="$(terraform output -raw agent_space_id 2>/dev/null || true)"
if [[ -z "$agent_space_id" ]]; then
  log "Run ./scripts/deploy.sh first."
  exit 1
fi

log "Agent Space ID: $agent_space_id"

aws devopsagent get-agent-space \
  --agent-space-id "$agent_space_id" \
  --endpoint-url "$ENDPOINT_URL" \
  --region "$REGION" \
  --output table 2>/dev/null || true

aws devopsagent list-associations \
  --agent-space-id "$agent_space_id" \
  --endpoint-url "$ENDPOINT_URL" \
  --region "$REGION" \
  --output table 2>/dev/null || true

assoc_id="$(terraform output -raw event_channel_association_id 2>/dev/null || true)"
if [[ -n "$assoc_id" ]]; then
  log "Event Channel association ID: $assoc_id"
  aws devopsagent list-webhooks \
    --agent-space-id "$agent_space_id" \
    --association-id "$assoc_id" \
    --endpoint-url "$ENDPOINT_URL" \
    --region "$REGION" \
    --output json 2>/dev/null || true
fi

log "Console: https://console.aws.amazon.com/devopsagent/"

