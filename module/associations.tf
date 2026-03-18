# ------------------------------------------------------------------------------
# AWS DevOps Agent — Account associations
# ------------------------------------------------------------------------------

resource "awscc_devopsagent_association" "primary" {
  agent_space_id = awscc_devopsagent_agent_space.this.agent_space_id
  service_id     = "aws"

  depends_on = [time_sleep.wait_for_agent_space_creation]

  configuration = {
    aws = {
      account_id         = local.account_id
      account_type       = "monitor"
      assumable_role_arn = aws_iam_role.devops_agent_agentspace.arn
      tags = var.resource_discovery_tags != null && length(var.resource_discovery_tags) > 0 ? [
        for k, v in var.resource_discovery_tags : { key = k, value = v }
      ] : null
    }
  }
}

resource "awscc_devopsagent_association" "external" {
  for_each = toset(var.external_account_ids)

  agent_space_id = awscc_devopsagent_agent_space.this.agent_space_id
  service_id     = "aws"

  configuration = {
    source_aws = {
      account_id         = each.key
      account_type       = "source"
      assumable_role_arn = "arn:aws:iam::${each.key}:role/DevOpsAgentCrossAccountRole"
      tags = var.resource_discovery_tags != null && length(var.resource_discovery_tags) > 0 ? [
        for k, v in var.resource_discovery_tags : { key = k, value = v }
      ] : null
    }
  }
}

