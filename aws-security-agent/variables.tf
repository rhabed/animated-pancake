# ------------------------------------------------------------------------------
# AWS Security Agent Terraform Module - Input Variables
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "agent_space_name" {
  description = "Name for the Security Agent Space."
  type        = string
}

# ---------------------------------------------------------------------------
# VPC / Network (optional)
# ---------------------------------------------------------------------------

variable "vpc_arn" {
  description = "ARN of the VPC where Security Agent resources will be associated. Required when using AWS-managed network resources."
  type        = string
  default     = null
}

variable "subnet_arns" {
  description = "List of subnet ARNs to associate with the Security Agent Space."
  type        = list(string)
  default     = []
}

variable "security_group_arns" {
  description = "List of security group ARNs to associate with the Security Agent Space."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Code Review Settings (optional)
# ---------------------------------------------------------------------------

variable "enable_controls_scanning" {
  description = "Enable controls scanning in code review. When true, Security Agent can scan code for compliance controls violations."
  type        = bool
  default     = null
}

variable "enable_general_purpose_scanning" {
  description = "Enable general purpose scanning in code review. When true, Security Agent can perform broad code vulnerability scanning."
  type        = bool
  default     = null
}

# ---------------------------------------------------------------------------
# Integrated Resources / GitHub (optional)
# ---------------------------------------------------------------------------

variable "github_integration" {
  description = "Type of GitHub integration (e.g. 'github'). Required when configuring github_repositories."
  type        = string
  default     = null
}

variable "github_repositories" {
  description = <<-EOT
    List of GitHub repositories to integrate with the Security Agent Space.
    Each entry has:
      owner            - GitHub organisation or user that owns the repository.
      name             - Repository name (without owner prefix).
      remediate_code   - When true, Security Agent may open PRs with automated fixes.
  EOT
  type = list(object({
    owner          = string
    name           = string
    remediate_code = optional(bool, false)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Tagging
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources that support tagging."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# IAM naming
# ---------------------------------------------------------------------------

variable "iam_name_prefix" {
  description = "Prefix for IAM role and policy names. A deterministic suffix is appended to avoid collisions across multiple deployments."
  type        = string
  default     = "securityagent"
}
