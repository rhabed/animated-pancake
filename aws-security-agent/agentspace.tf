# ------------------------------------------------------------------------------
# AWS Security Agent — Agent Space
# awscc_securityagent_agent_space (AWS::SecurityAgent::AgentSpace)
# ------------------------------------------------------------------------------

# Small IAM propagation buffer (mirrors the devops-agent pattern)
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on      = [aws_iam_role.security_agent]
  create_duration = "20s"
}

resource "awscc_securityagent_agent_space" "this" {
  name = var.agent_space_name

  depends_on = [time_sleep.wait_for_iam_propagation]

  # ── VPC / network resources (optional) ────────────────────────────────────
  aws_resources = local.has_network ? {
    vpc_arn             = var.vpc_arn
    subnet_arns         = length(var.subnet_arns) > 0 ? var.subnet_arns : null
    security_group_arns = length(var.security_group_arns) > 0 ? var.security_group_arns : null
  } : null

  # ── Code review scanning settings (optional) ───────────────────────────────
  code_review_settings = local.has_code_review ? {
    controls_scanning      = var.enable_controls_scanning
    general_purpose_scanning = var.enable_general_purpose_scanning
  } : null

  # ── GitHub integrated resources (optional) ──────────────────────────────────
  integrated_resources = local.has_github ? {
    integration = var.github_integration
    provider_resources = [
      for repo in var.github_repositories : {
        git_hub_repository = {
          owner = repo.owner
          name  = repo.name
        }
        git_hub_capabilities = {
          remediate_code = repo.remediate_code
        }
      }
    ]
  } : null

  # ── Tags ──────────────────────────────────────────────────────────────────
  tags = length(local.resource_tags) > 0 ? local.resource_tags : null
}
