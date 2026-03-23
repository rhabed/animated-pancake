#!/usr/bin/env bash
# Called by Terraform (null_resource) after the Event Channel association exists.
# Fetches webhookUrl via list-webhooks and writes JSON to Secrets Manager.
# Signing secret is not available from the API; pass WEBHOOK_SIGNING_SECRET when known.
set -euo pipefail

: "${AWS_REGION:?}"
: "${ENDPOINT_URL:?}"
: "${AGENT_SPACE_ID:?}"
: "${ASSOCIATION_ID:?}"
: "${SECRET_ID:?}"

WEBHOOK_JSON=""
for _ in $(seq 1 15); do
  WEBHOOK_JSON="$(aws devopsagent list-webhooks \
    --agent-space-id "$AGENT_SPACE_ID" \
    --association-id "$ASSOCIATION_ID" \
    --region "$AWS_REGION" \
    --endpoint-url "$ENDPOINT_URL" \
    --output json 2>/dev/null || true)"
  if echo "$WEBHOOK_JSON" | python3 -c 'import json,sys; w=json.load(sys.stdin).get("webhooks") or []; sys.exit(0 if w else 1)' 2>/dev/null; then
    break
  fi
  sleep 5
done

export WEBHOOK_JSON
export WEBHOOK_SIGNING_SECRET="${WEBHOOK_SIGNING_SECRET:-}"

SECRET_STRING="$(python3 <<'PY'
import json, os

raw = os.environ.get("WEBHOOK_JSON") or "{}"
signing = os.environ.get("WEBHOOK_SIGNING_SECRET") or ""
try:
    payload = json.loads(raw)
except json.JSONDecodeError as e:
    raise SystemExit(f"Invalid list-webhooks JSON: {e}") from e

webhooks = payload.get("webhooks") or []
if not webhooks:
    raise SystemExit(
        "list-webhooks returned no webhooks after retries. "
        "Confirm the Event Channel association is active and IAM allows devopsagent:ListWebhooks."
    )

first = webhooks[0]
url = first.get("webhookUrl") or first.get("webhook_url")
if not url:
    raise SystemExit(f"Could not find webhookUrl in: {first}")

out = {"webhookUrl": url, "webhookSecret": signing}
print(json.dumps(out))
PY
)"

aws secretsmanager put-secret-value \
  --secret-id "$SECRET_ID" \
  --secret-string "$SECRET_STRING" \
  --region "$AWS_REGION"
