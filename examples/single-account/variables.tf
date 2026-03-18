variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "agent_space_name" {
  type    = string
  default = "MyCompanyAgentSpace"
}

variable "agent_space_description" {
  type    = string
  default = "DevOps monitoring"
}

variable "enable_operator_app" {
  type    = bool
  default = true
}

variable "auth_flow" {
  type    = string
  default = "iam"
}

variable "resource_discovery_tags" {
  type    = map(string)
  default = null
}

variable "enable_webhook" {
  type    = bool
  default = false
}

variable "event_channel_service_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

