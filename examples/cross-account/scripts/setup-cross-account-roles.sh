#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$EXAMPLE_DIR"

REGION="us-east-1"

log() { echo "[$(date +%H:%M:%S)] $*"; }
err() { echo "[$(date +%H:%M:%S)] ERROR: $*" >&2; }

MONITORING_ACCOUNT_ID=""
AGENT_SPACE_ID=""
AGENT_SPACE_ROLE_ARN=""

load_outputs() {
  MONITORING_ACCOUNT_ID=$(terraform output -raw devops_agentspace_role_arn 2>/dev/null | sed -n 's|.*arn:aws:iam::\([0-9]*\):role/.*|\1|p')
  if [[ -z "$MONITORING_ACCOUNT_ID" ]]; then
    MONITORING_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
  fi
  AGENT_SPACE_ID=$(terraform output -raw agent_space_id 2>/dev/null) || true
  AGENT_SPACE_ROLE_ARN=$(terraform output -raw devops_agentspace_role_arn 2>/dev/null) || true

  if [[ -z "$AGENT_SPACE_ID" || -z "$AGENT_SPACE_ROLE_ARN" ]]; then
    err "Run 'terraform apply' first so agent_space_id and devops_agentspace_role_arn are available."
    exit 1
  fi
  log "Monitoring account ID: $MONITORING_ACCOUNT_ID"
  log "Agent Space ID: $AGENT_SPACE_ID"
  log "Agent Space role ARN: $AGENT_SPACE_ROLE_ARN"
}

print_setup_instructions() {
  local external_id
  external_id="arn:aws:aidevops:${REGION}:${MONITORING_ACCOUNT_ID}:agentspace/${AGENT_SPACE_ID}"

  echo "# Run these commands in EACH external account"
  echo ""
  echo "cat > trust-policy.json << 'TRUST'"
  cat << TRUST_INNER
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${AGENT_SPACE_ROLE_ARN}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${external_id}"
        }
      }
    }
  ]
}
TRUST_INNER
  echo "TRUST"
  echo ""
  echo "aws iam create-role \\"
  echo "  --role-name DevOpsAgentCrossAccountRole \\"
  echo "  --assume-role-policy-document file://trust-policy.json \\"
  echo "  --description \"Allows AWS DevOps Agent (monitoring account) to access this account\""
  echo ""
  echo "aws iam attach-role-policy \\"
  echo "  --role-name DevOpsAgentCrossAccountRole \\"
  echo "  --policy-arn arn:aws:iam::aws:policy/AIOpsAssistantPolicy"
}

main() {
  load_outputs
  echo ""
  print_setup_instructions
}

main "$@"

