# ------------------------------------------------------------------------------
# AWS DevOps Agent — Agent Space
# ------------------------------------------------------------------------------

resource "time_sleep" "wait_for_iam_propagation" {
  depends_on      = [aws_iam_role.devops_agent_agentspace, aws_iam_role.devops_agent_webapp_admin]
  create_duration = "30s"
}

resource "awscc_devopsagent_agent_space" "this" {
  name        = var.agent_space_name
  description = var.agent_space_description

  depends_on = [time_sleep.wait_for_iam_propagation]

  operator_app = var.enable_operator_app ? (
    var.auth_flow == "iam" ? {
      iam = {
        operator_app_role_arn = aws_iam_role.devops_agent_webapp_admin[0].arn
      }
      idc = null
    } : {
      iam = null
      idc = {} # Configure IAM Identity Center in the AWS console after creation
    }
  ) : null
}

resource "time_sleep" "wait_for_agent_space_creation" {
  depends_on      = [awscc_devopsagent_agent_space.this]
  create_duration = "30s"
}

