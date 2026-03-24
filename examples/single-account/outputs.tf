output "agent_space_id" {
  value = module.devops_agent.agent_space_id
}

output "event_channel_association_id" {
  value = module.devops_agent.event_channel_association_id
}

output "webhook_credentials_secret_arn" {
  value = module.devops_agent.webhook_credentials_secret_arn
}

output "sns_topic_arn" {
  value = module.devops_agent.sns_topic_arn
}

output "sns_lambda_function_arn" {
  value = module.devops_agent.sns_lambda_function_arn
}

output "sns_lambda_function_name" {
  value = module.devops_agent.sns_lambda_function_name
}

output "manual_setup_instructions" {
  value = module.devops_agent.manual_setup_instructions
}
