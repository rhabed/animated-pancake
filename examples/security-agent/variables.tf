variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "agent_space_name" {
  description = "Name for the Security Agent Space."
  type        = string
  default     = "MySecurityAgentSpace"
}

variable "enable_controls_scanning" {
  description = "Enable controls scanning in code review."
  type        = bool
  default     = true
}

variable "enable_general_purpose_scanning" {
  description = "Enable general purpose scanning in code review."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
