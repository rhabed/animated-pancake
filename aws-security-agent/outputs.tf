# ------------------------------------------------------------------------------
# AWS Security Agent Terraform Module — Outputs
# ------------------------------------------------------------------------------

output "agent_space_id" {
  description = "Unique identifier of the Security Agent Space."
  value       = awscc_securityagent_agent_space.this.agent_space_id
}

output "agent_space_account_id" {
  description = "AWS account ID where the Security Agent Space is managed."
  value       = awscc_securityagent_agent_space.this.account_id
}

output "agent_space_region" {
  description = "AWS region where the Security Agent Space is managed."
  value       = awscc_securityagent_agent_space.this.region
}

output "agent_space_name" {
  description = "Name of the Security Agent Space."
  value       = awscc_securityagent_agent_space.this.name
}

output "security_agent_role_arn" {
  description = "ARN of the IAM role used by the Security Agent."
  value       = aws_iam_role.security_agent.arn
}

output "security_agent_role_name" {
  description = "Name of the IAM role used by the Security Agent."
  value       = aws_iam_role.security_agent.name
}

output "manual_setup_instructions" {
  description = "Next steps and verification commands after deployment."
  value       = <<-EOT
    Next steps:
    1. Verify Agent Space exists in the AWS console:
       https://console.aws.amazon.com/security-agent/
    2. Check Agent Space status via AWS CLI:
       aws securityagent get-agent-space \
         --agent-space-id ${awscc_securityagent_agent_space.this.agent_space_id} \
         --region ${local.region}
    3. Ensure Security Hub / Inspector / GuardDuty are enabled in the account
       so the Security Agent has findings to work with.
    4. If GitHub integration is configured, verify the repository connections
       in the AWS Security Agent console.
  EOT
}
