import json
import hmac
import hashlib
import base64
import urllib.request
import urllib.error
import boto3
import os
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

WEBHOOK_SECRET_ARN = os.environ["WEBHOOK_SECRET_ARN"]
WEBHOOK_URL_ENV = os.environ.get("WEBHOOK_URL")

# Cache (webhook_url, signing_secret) in Lambda execution context
_webhook_cache: tuple[str, str] | None = None


def get_webhook_url_and_secret() -> tuple[str, str]:
    """Resolve URL and HMAC secret from Secrets Manager JSON (webhookUrl, webhookSecret)
    or raw secret string plus optional WEBHOOK_URL env (legacy)."""
    global _webhook_cache
    if _webhook_cache is None:
        client = boto3.client("secretsmanager")
        response = client.get_secret_value(SecretId=WEBHOOK_SECRET_ARN)
        raw = response["SecretString"]
        try:
            data = json.loads(raw)
            if isinstance(data, dict) and "webhookUrl" in data:
                url = str(data["webhookUrl"])
                secret = str(data.get("webhookSecret") or "")
                if not secret:
                    raise ValueError(
                        "webhookSecret is empty in JSON secret; set var.webhook_signing_secret or update the secret"
                    )
                _webhook_cache = (url, secret)
            else:
                raise ValueError("JSON secret must include webhookUrl")
        except json.JSONDecodeError:
            if not WEBHOOK_URL_ENV:
                raise ValueError(
                    "WEBHOOK_URL is required when the secret value is not JSON"
                ) from None
            _webhook_cache = (WEBHOOK_URL_ENV, raw)
    return _webhook_cache

# Map CloudWatch alarm severity to DevOps Agent priority
SEVERITY_MAP = {
    "CRITICAL": "CRITICAL",
    "HIGH":     "HIGH",
    "MEDIUM":   "MEDIUM",
    "LOW":      "LOW",
}

def build_priority(alarm_name: str) -> str:
    upper = alarm_name.upper()
    for key, val in SEVERITY_MAP.items():
        if key in upper:
            return val
    return "HIGH"   # default


def lambda_handler(event, context):
    logger.info("Received SNS event: %s", json.dumps(event))

    for record in event.get("Records", []):
        sns_message_raw = record["Sns"]["Message"]

        try:
            alarm = json.loads(sns_message_raw)
        except json.JSONDecodeError:
            logger.error("Could not parse SNS message as JSON: %s", sns_message_raw)
            continue

        # Only act on ALARM state transitions
        new_state = alarm.get("NewStateValue", "")
        if new_state != "ALARM":
            logger.info("Skipping state %s (not ALARM)", new_state)
            continue

        alarm_name   = alarm.get("AlarmName", "Unknown Alarm")
        alarm_desc   = alarm.get("AlarmDescription", "")
        state_reason = alarm.get("NewStateReason", "")
        region       = alarm.get("Region", "")
        account_id   = alarm.get("AWSAccountId", "")
        timestamp    = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")

        description = (
            f"{alarm_desc}\n\nReason: {state_reason}"
            if alarm_desc
            else state_reason
        )

        payload = {
            "eventType":  "incident",
            "incidentId": f"cw-{alarm_name}-{int(datetime.now(timezone.utc).timestamp())}",
            "action":     "created",
            "priority":   build_priority(alarm_name),
            "title":      f"CloudWatch Alarm: {alarm_name}",
            "description": description,
            "timestamp":  timestamp,
            "service":    "CloudWatch",
            "data": {
                "alarmName":    alarm_name,
                "region":       region,
                "accountId":    account_id,
                "stateReason":  state_reason,
                "originalEvent": alarm,
            },
        }

        body = json.dumps(payload)
        logger.info("Constructed payload for DevOps Agent: %s", body)

        webhook_url, signing_secret = get_webhook_url_and_secret()

        # HMAC-SHA256 signature  →  base64( HMAC( "{timestamp}:{body}" ) )
        signing_input = f"{timestamp}:{body}"
        signature = base64.b64encode(
            hmac.new(
                signing_secret.encode("utf-8"),
                signing_input.encode("utf-8"),
                hashlib.sha256,
            ).digest()
        ).decode("utf-8")

        req = urllib.request.Request(
            webhook_url,
            data=body.encode("utf-8"),
            headers={
                "Content-Type":            "application/json",
                "x-amzn-event-timestamp":  timestamp,
                "x-amzn-event-signature":  signature,
            },
            method="POST",
        )

        logger.info("Sending request to DevOps Agent webhook at %s", webhook_url)

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                logger.info(
                    "DevOps Agent webhook called successfully. Status: %s", resp.status
                )
        except urllib.error.HTTPError as e:
            logger.error(
                "HTTP error calling DevOps Agent webhook: %s %s", e.code, e.reason
            )
            raise
        except urllib.error.URLError as e:
            logger.error("URL error calling DevOps Agent webhook: %s", e.reason)
            raise

    return {"statusCode": 200, "body": "OK"}
