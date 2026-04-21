# ------------------------------------------------------------------------------
# Security Agent — Single-account example
#
# Deploys one Security Agent Space in the calling account with optional
# code-review scanning and GitHub repository integration.
# ------------------------------------------------------------------------------

module "security_agent" {
  source = "../../aws-security-agent/terraform"

  aws_region       = var.aws_region
  agent_space_name = var.agent_space_name

  # ── Code review scanning ──────────────────────────────────────────────────
  enable_controls_scanning        = var.enable_controls_scanning
  enable_general_purpose_scanning = var.enable_general_purpose_scanning

  # ── GitHub integration (uncomment and populate to enable) ─────────────────
  # github_integration = "github"
  # github_repositories = [
  #   {
  #     owner          = "my-org"
  #     name           = "my-repo"
  #     remediate_code = true
  #   }
  # ]

  # ── Network (uncomment and populate to enable) ────────────────────────────
  # vpc_arn             = "arn:aws:ec2:us-east-1:123456789012:vpc/vpc-0abc1234"
  # subnet_arns         = ["arn:aws:ec2:us-east-1:123456789012:subnet/subnet-0abc1234"]
  # security_group_arns = ["arn:aws:ec2:us-east-1:123456789012:security-group/sg-0abc1234"]

  tags = var.tags
}
