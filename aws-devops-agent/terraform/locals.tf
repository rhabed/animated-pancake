# ------------------------------------------------------------------------------
# Shared locals/data
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = coalesce(var.aws_region, data.aws_region.current.id)

  devopsagent_endpoint_url = "https://api.prod.cp.aidevops.us-east-1.api.aws"

  # Deterministic, short suffix to make IAM names unique per deployment
  # (stable across applies; avoids collisions for multiple Agent Spaces).
  iam_name_suffix = substr(sha1("${local.account_id}:${var.agent_space_name}"), 0, 8)
  iam_name_prefix = "${var.iam_name_prefix}-${local.iam_name_suffix}"
}

