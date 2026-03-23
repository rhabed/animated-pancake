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

WEBHOOK_URL        = os.environ["WEBHOOK_URL"]
WEBHOOK_SECRET_ARN = os.environ["WEBHOOK_SECRET_ARN"]

# Cache secret in Lambda execution context to avoid repeated Secrets Manager calls
_secret_cache: str | None = None

def get_webhook_secret() -> str:
    global _secret_cache
    if _secret_cache is None:
        client = boto3.client("secretsmanager")
        response = client.get_secret_value(SecretId=WEBHOOK_SECRET_ARN)
        _secret_cache = response["SecretString"]
    return _secret_cache

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

        # HMAC-SHA256 signature  →  base64( HMAC( "{timestamp}:{body}" ) )
        signing_input = f"{timestamp}:{body}"
        signature = base64.b64encode(
            hmac.new(
                get_webhook_secret().encode("utf-8"),
                signing_input.encode("utf-8"),
                hashlib.sha256,
            ).digest()
        ).decode("utf-8")

        req = urllib.request.Request(
            WEBHOOK_URL,
            data=body.encode("utf-8"),
            headers={
                "Content-Type":            "application/json",
                "x-amzn-event-timestamp":  timestamp,
                "x-amzn-event-signature":  signature,
            },
            method="POST",
        )

        logger.info("Sending request to DevOps Agent webhook at %s", WEBHOOK_URL)

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
