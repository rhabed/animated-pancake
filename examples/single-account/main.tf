module "devops_agent" {
  source = "../../module"

  aws_region               = var.aws_region
  agent_space_name         = var.agent_space_name
  agent_space_description  = var.agent_space_description
  enable_operator_app      = var.enable_operator_app
  auth_flow                = var.auth_flow
  resource_discovery_tags  = var.resource_discovery_tags
  external_account_ids     = []
  enable_webhook           = var.enable_webhook
  event_channel_service_id = var.event_channel_service_id
  tags                     = var.tags
}

