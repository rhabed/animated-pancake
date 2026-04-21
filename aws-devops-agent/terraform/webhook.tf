# ------------------------------------------------------------------------------
# Event Channel (Webhook)
# ------------------------------------------------------------------------------

data "external" "webhook_service" {
  count = var.enable_webhook && var.event_channel_service_id == null ? 1 : 0

  program = ["bash", "${path.module}/scripts/register-webhook-service.sh"]

  query = {
    region       = var.aws_region
    endpoint_url = local.devopsagent_endpoint_url
  }
}

resource "time_sleep" "wait_before_event_channel_creation" {
  count = var.enable_webhook ? 1 : 0

  depends_on      = [awscc_devopsagent_agent_space.this]
  create_duration = "30s"
}

resource "awscc_devopsagent_association" "event_channel" {
  count = var.enable_webhook ? 1 : 0

  depends_on = [time_sleep.wait_before_event_channel_creation]

  agent_space_id = awscc_devopsagent_agent_space.this.agent_space_id
  service_id     = coalesce(var.event_channel_service_id, try(data.external.webhook_service[0].result.service_id, null))

  configuration = {
    event_channel = {
      enable_webhook_updates = true
    }
  }
}

