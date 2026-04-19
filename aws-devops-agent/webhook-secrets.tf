# ------------------------------------------------------------------------------
# Webhook URL (+ optional signing secret) in Secrets Manager
# URL is read from ListWebhooks after the Event Channel association exists.
# The signing secret is not returned by the API; set var.webhook_signing_secret
# or update the secret in the console / CLI later.
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "webhook_credentials" {
  count = var.enable_webhook && var.store_webhook_credentials_in_secrets_manager ? 1 : 0

  name                    = "${local.iam_name_prefix}-webhook-credentials"
  description             = "DevOps Agent webhook URL and optional signing secret (JSON: webhookUrl, webhookSecret)"
  recovery_window_in_days = 7

  tags = var.tags
}

resource "null_resource" "webhook_credentials" {
  count = var.enable_webhook && var.store_webhook_credentials_in_secrets_manager ? 1 : 0

  depends_on = [
    awscc_devopsagent_association.event_channel,
    aws_secretsmanager_secret.webhook_credentials,
  ]

  triggers = {
    association_id = awscc_devopsagent_association.event_channel[0].association_id
    agent_space_id = awscc_devopsagent_agent_space.this.agent_space_id
    # coalesce() rejects all-null / all-empty arguments; use an explicit branch for "unset".
    signing_revision = (
      var.webhook_signing_secret != null && var.webhook_signing_secret != ""
      ? sha256(nonsensitive(var.webhook_signing_secret))
      : sha256("webhook_signing_secret_unset")
    )
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/store-webhook-credentials.sh"
    environment = {
      AWS_REGION             = var.aws_region
      ENDPOINT_URL           = local.devopsagent_endpoint_url
      AGENT_SPACE_ID         = awscc_devopsagent_agent_space.this.agent_space_id
      ASSOCIATION_ID         = awscc_devopsagent_association.event_channel[0].association_id
      SECRET_ID              = aws_secretsmanager_secret.webhook_credentials[0].arn
      WEBHOOK_SIGNING_SECRET = nonsensitive(var.webhook_signing_secret != null ? var.webhook_signing_secret : "")
    }
  }
}
