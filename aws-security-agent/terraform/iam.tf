# ------------------------------------------------------------------------------
# IAM role: SecurityAgentRole
# Allows the AWS Security Agent service to act on behalf of this account.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "security_agent" {
  name        = "${local.iam_name_prefix}-AgentRole"
  description = "IAM role for AWS Security Agent Space"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "security-agent.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Managed policy: AmazonSecurityAgentServiceRolePolicy
# Grants the Security Agent read access to security findings and resources.
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "security_agent_managed" {
  role       = aws_iam_role.security_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSecurityAgentServiceRolePolicy"
}

# ------------------------------------------------------------------------------
# Custom policy: additional permissions for Security Hub, Inspector, GuardDuty
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "security_agent_custom" {
  name        = "${local.iam_name_prefix}-Custom"
  description = "Custom permissions for AWS Security Agent (Security Hub, Inspector, GuardDuty read)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecurityHubReadAccess"
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "securityhub:ListFindings",
          "securityhub:DescribeHub",
          "securityhub:GetInsights",
          "securityhub:GetInsightResults"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "InspectorReadAccess"
        Effect = "Allow"
        Action = [
          "inspector2:ListFindings",
          "inspector2:GetFinding",
          "inspector2:ListCoverage",
          "inspector2:BatchGetAccountStatus"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "GuardDutyReadAccess"
        Effect = "Allow"
        Action = [
          "guardduty:ListDetectors",
          "guardduty:GetDetector",
          "guardduty:ListFindings",
          "guardduty:GetFindings"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "CodeReviewAccess"
        Effect = "Allow"
        Action = [
          "codeguru-reviewer:ListRepositoryAssociations",
          "codeguru-reviewer:DescribeRepositoryAssociation",
          "codeguru-reviewer:ListCodeReviews",
          "codeguru-reviewer:DescribeCodeReview"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "security_agent_custom" {
  role       = aws_iam_role.security_agent.name
  policy_arn = aws_iam_policy.security_agent_custom.arn
}
