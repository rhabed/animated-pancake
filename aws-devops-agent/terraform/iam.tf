# ------------------------------------------------------------------------------
# IAM role: DevOpsAgentRole-AgentSpace
# Primary account role for the Agent Space — grants the agent read-only access
# to resources in this account and allows it to assume secondary account roles.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "devops_agent_agentspace" {
  name        = "${local.iam_name_prefix}-AgentSpace"
  description = "IAM role for AWS DevOps Agent Space (primary account)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "aidevops.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:aidevops:${local.region}:${local.account_id}:agentspace/*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "devops_agent_agentspace" {
  role       = aws_iam_role.devops_agent_agentspace.name
  policy_arn = "arn:aws:iam::aws:policy/AIOpsAssistantPolicy"
}

# ------------------------------------------------------------------------------
# Custom IAM policy for Agent Space — support, expanded AIOps, service-linked role
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "devops_agent_agentspace_custom" {
  name        = "${local.iam_name_prefix}-AgentSpace-Custom"
  description = "Custom policy for DevOps Agent Space (support, expanded AIOps, Resource Explorer SLR)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAwsSupportActions"
        Effect = "Allow"
        Action = [
          "support:CreateCase",
          "support:DescribeCases"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "AllowExpandedAIOpsAssistantPolicy"
        Effect = "Allow"
        Action = [
          "aidevops:GetKnowledgeItem",
          "aidevops:ListKnowledgeItems",
          "eks:AccessKubernetesApi",
          "synthetics:GetCanaryRuns",
          "route53:GetHealthCheckStatus",
          "resource-explorer-2:Search",
          "codedeploy:GetDeploymentTarget",
          "ram:GetResourceShares"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "AllowCreateServiceLinkedRoles"
        Effect = "Allow"
        Action = ["iam:CreateServiceLinkedRole"]
        Resource = [
          "arn:aws:iam::${local.account_id}:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "devops_agent_agentspace_custom" {
  role       = aws_iam_role.devops_agent_agentspace.name
  policy_arn = aws_iam_policy.devops_agent_agentspace_custom.arn
}

# ------------------------------------------------------------------------------
# IAM role: DevOpsAgentRole-WebappAdmin (conditional)
# ------------------------------------------------------------------------------

resource "aws_iam_role" "devops_agent_webapp_admin" {
  count = var.enable_operator_app ? 1 : 0

  name        = "${local.iam_name_prefix}-WebappAdmin"
  description = "IAM role for AWS DevOps Agent Operator App (web app admin)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "aidevops.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        # Only SourceAccount condition: EnableOperatorApp verification session assumes this role
        # with a context that may not yet have agentspace ARN; ArnLike would cause verification to fail.
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

resource "aws_iam_role_policy_attachment" "devops_agent_webapp_admin_managed" {
  count = var.enable_operator_app ? 1 : 0

  role       = aws_iam_role.devops_agent_webapp_admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AIOpsOperatorAccess"
}

# ------------------------------------------------------------------------------
# Custom IAM policy for WebappAdmin — aidevops + support operator actions
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "devops_agent_webapp_admin_custom" {
  count = var.enable_operator_app ? 1 : 0

  name        = "${local.iam_name_prefix}-WebappAdmin-Custom"
  description = "Custom policy for DevOps Agent Operator App (aidevops + support actions)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBasicOperatorActions"
        Effect = "Allow"
        Action = [
          "aidevops:GetAgentSpace",
          "aidevops:GetAssociation",
          "aidevops:ListAssociations",
          "aidevops:CreateBacklogTask",
          "aidevops:GetBacklogTask",
          "aidevops:UpdateBacklogTask",
          "aidevops:ListBacklogTasks",
          "aidevops:ListJournalRecords",
          "aidevops:DiscoverTopology",
          "aidevops:ListGoals",
          "aidevops:ListRecommendations",
          "aidevops:ListExecutions",
          "aidevops:GetRecommendation",
          "aidevops:UpdateRecommendation",
          "aidevops:CreateKnowledgeItem",
          "aidevops:ListKnowledgeItems",
          "aidevops:GetKnowledgeItem",
          "aidevops:UpdateKnowledgeItem",
          "aidevops:DeleteKnowledgeItem",
          "aidevops:ListPendingMessages",
          "aidevops:InitiateChatForCase",
          "aidevops:EndChatForCase",
          "aidevops:DescribeSupportLevel",
          "aidevops:GetAccountUsage",
          "aidevops:SendChatMessage",
          "aidevops:ListChats",
          "aidevops:CreateChat",
          "aidevops:StreamMessage"
        ]
        Resource = "arn:aws:aidevops:${local.region}:${local.account_id}:agentspace/*"
      },
      {
        Sid    = "AllowSupportOperatorActions"
        Effect = "Allow"
        Action = [
          "support:DescribeCases",
          "support:InitiateChatForCase",
          "support:DescribeSupportLevel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "devops_agent_webapp_admin_custom" {
  count = var.enable_operator_app ? 1 : 0

  role       = aws_iam_role.devops_agent_webapp_admin[0].name
  policy_arn = aws_iam_policy.devops_agent_webapp_admin_custom[0].arn
}

