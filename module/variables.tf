# ------------------------------------------------------------------------------
# AWS DevOps Agent Terraform Module - Input Variables
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for deployment. AWS DevOps Agent is only available in us-east-1."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS DevOps Agent is only available in the us-east-1 region."
  }
}

variable "agent_space_name" {
  description = "Name for the Agent Space (logical container for DevOps Agent configuration)."
  type        = string
  default     = "MyAgentSpace"
}

variable "agent_space_description" {
  description = "Description for the Agent Space."
  type        = string
  default     = "AgentSpace for monitoring my application"
}

variable "enable_operator_app" {
  description = "Enable the Operator App web interface for interactive investigations."
  type        = bool
  default     = true
}

variable "auth_flow" {
  description = "Authentication flow for the Operator App: 'iam' (IAM identity) or 'idc' (IAM Identity Center)."
  type        = string
  default     = "iam"

  validation {
    condition     = contains(["iam", "idc"], var.auth_flow)
    error_message = "auth_flow must be either 'iam' or 'idc'."
  }
}

variable "external_account_ids" {
  description = "List of external AWS account IDs for cross-account monitoring. Requires cross-account roles to be created in those accounts first."
  type        = list(string)
  default     = []
}

variable "resource_discovery_tags" {
  description = "Optional map of tag key-value pairs to scope resource discovery. When set, only resources matching these tags are discovered for topology. When null or empty, all resources in the associated account(s) are discoverable."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources that support tagging."
  type        = map(string)
  default     = {}
}

variable "iam_name_prefix" {
  description = "Prefix for IAM role/policy names. A deterministic suffix is appended to avoid collisions across multiple deployments in the same account."
  type        = string
  default     = "devopsagent"
}

variable "enable_webhook" {
  description = "Enable webhook (Event Channel) integration."
  type        = bool
  default     = false
}

variable "event_channel_service_id" {
  description = "Optional Event Channel service ID. If not set and enable_webhook is true, Terraform will discover/register it via the external script (module/scripts/register-webhook-service.sh)."
  type        = string
  default     = null
}

