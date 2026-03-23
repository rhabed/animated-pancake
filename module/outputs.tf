# ------------------------------------------------------------------------------
# AWS DevOps Agent Terraform Module — Outputs
# ------------------------------------------------------------------------------

output "agent_space_id" {
  description = "The unique identifier of the Agent Space."
  value       = awscc_devopsagent_agent_space.this.agent_space_id
}

output "agent_space_arn" {
  description = "The ARN of the Agent Space."
  value       = awscc_devopsagent_agent_space.this.arn
}

output "devops_agentspace_role_arn" {
  description = "ARN of the IAM role used by the Agent Space (DevOpsAgentRole-AgentSpace)."
  value       = aws_iam_role.devops_agent_agentspace.arn
}

output "devops_operator_role_arn" {
  description = "ARN of the Operator App IAM role (DevOpsAgentRole-WebappAdmin). Empty when enable_operator_app is false."
  value       = var.enable_operator_app ? aws_iam_role.devops_agent_webapp_admin[0].arn : null
}

output "primary_association_id" {
  description = "The unique identifier of the primary account association."
  value       = awscc_devopsagent_association.primary.association_id
}

output "external_association_ids" {
  description = "Map of external account ID to association ID for cross-account associations."
  value       = { for k, v in awscc_devopsagent_association.external : k => v.association_id }
}

output "event_channel_association_id" {
  description = "Association ID for the Event Channel (null when webhook is disabled). Use this with aws devopsagent list-webhooks to fetch the webhookUrl."
  value       = length(awscc_devopsagent_association.event_channel) > 0 ? awscc_devopsagent_association.event_channel[0].association_id : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic that invokes the Lambda (null when enable_sns_lambda is false)."
  value       = length(aws_sns_topic.notifications) > 0 ? aws_sns_topic.notifications[0].arn : null
}

output "sns_lambda_function_arn" {
  description = "ARN of the SNS-triggered Lambda function (null when enable_sns_lambda is false)."
  value       = length(aws_lambda_function.sns_handler) > 0 ? aws_lambda_function.sns_handler[0].arn : null
}

output "sns_lambda_function_name" {
  description = "Name of the SNS-triggered Lambda function (null when enable_sns_lambda is false)."
  value       = length(aws_lambda_function.sns_handler) > 0 ? aws_lambda_function.sns_handler[0].function_name : null
}

output "manual_setup_instructions" {
  description = "Next steps and verification commands after deployment."
  value       = <<-EOT
    Next steps:
    1. Verify: aws devopsagent get-agent-space --agent-space-id ${awscc_devopsagent_agent_space.this.agent_space_id} --endpoint-url "${local.devopsagent_endpoint_url}" --region ${var.aws_region}
    2. List associations: aws devopsagent list-associations --agent-space-id ${awscc_devopsagent_agent_space.this.agent_space_id} --endpoint-url "${local.devopsagent_endpoint_url}" --region ${var.aws_region}
    3. If you enabled Event Channel, fetch the webhook URL:
       aws devopsagent list-webhooks --agent-space-id ${awscc_devopsagent_agent_space.this.agent_space_id} --association-id <EVENT_CHANNEL_ASSOCIATION_ID> --endpoint-url "${local.devopsagent_endpoint_url}" --region ${var.aws_region}
    4. Access AWS DevOps Agent: https://console.aws.amazon.com/devopsagent/
  EOT
}

