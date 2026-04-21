# ------------------------------------------------------------------------------
# Shared locals / data sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = coalesce(var.aws_region, data.aws_region.current.id)

  # Build the tags list expected by awscc_securityagent_agent_space
  resource_tags = [
    for k, v in var.tags : { key = k, value = v }
  ]

  # Deterministic short suffix — keeps IAM names unique per deployment
  iam_name_suffix = substr(sha1("${local.account_id}:${var.agent_space_name}"), 0, 8)
  iam_name_prefix = "${var.iam_name_prefix}-${local.iam_name_suffix}"

  # Convenience flag: are any network params provided?
  has_network = (
    var.vpc_arn != null ||
    length(var.subnet_arns) > 0 ||
    length(var.security_group_arns) > 0
  )

  # Convenience flag: are any code-review settings provided?
  has_code_review = (
    var.enable_controls_scanning != null ||
    var.enable_general_purpose_scanning != null
  )

  # GitHub integration present?
  has_github = (
    var.github_integration != null &&
    length(var.github_repositories) > 0
  )
}
