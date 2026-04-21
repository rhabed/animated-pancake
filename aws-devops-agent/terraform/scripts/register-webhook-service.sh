#!/usr/bin/env bash
set -euo pipefail

# Terraform external data source contract:
# - Reads JSON from stdin
# - Writes JSON to stdout
#
# This script only registers the eventChannel (webhook) *service* and returns
# service_id for the Event Channel association. It does not produce the webhook
# URL or HMAC signing secret — those exist only after the association is created
# and ListWebhooks can run (see module/scripts/store-webhook-credentials.sh and
# webhook-secrets.tf for writing URL + optional secret to AWS Secrets Manager).

in="$(cat)"
region="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read() or "{}").get("region","us-east-1"))' <<<"$in")"
endpoint_url="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read() or "{}").get("endpoint_url","https://api.prod.cp.aidevops.us-east-1.api.aws"))' <<<"$in")"

# 1) Register Event Channel (webhook). If already registered, it may error; ignore.
aws devopsagent register-service \
  --service eventChannel \
  --service-details '{"eventChannel":{"type":"webhook"}}' \
  --region "$region" \
  --endpoint-url "$endpoint_url" >/dev/null 2>&1 || true

# 2) Discover the service ID
svc_json="$(aws devopsagent list-services \
  --filter-service-type eventChannel \
  --region "$region" \
  --endpoint-url "$endpoint_url" \
  --output json)"

python3 - <<'PY' "$svc_json"
import json, sys
payload = json.loads(sys.argv[1])
services = payload.get("services") or []
if not services:
  raise SystemExit("No eventChannel services found after registration.")

last = services[-1]
service_id = last.get("serviceId") or last.get("service_id") or last.get("id")
if not service_id:
  raise SystemExit(f"Could not find serviceId in: {last}")

print(json.dumps({"service_id": service_id}))
PY

