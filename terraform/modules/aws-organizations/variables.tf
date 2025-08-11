# Variables for AWS Organizations Module

variable "aws_service_access_principals" {
  description = "List of AWS service principals that require access to the organization"
  type        = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "securityhub.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "controltower.amazonaws.com"
  ]
}

variable "enabled_policy_types" {
  description = "List of policy types to enable in the organization"
  type        = list(string)
  default = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name        = string
    description = string
  }))
  
  validation {
    condition     = length(var.organizational_units) > 0
    error_message = "At least one organizational unit must be defined."
  }
}

variable "service_control_policies" {
  description = "Map of Service Control Policies to create and attach"
  type = map(object({
    name        = string
    description = string
    content     = string
    target_ous  = list(string)
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for policy in var.service_control_policies : 
      can(jsondecode(policy.content))
    ])
    error_message = "All SCP content must be valid JSON."
  }
}

variable "tag_policies" {
  description = "Map of Tag Policies to create and attach"
  type = map(object({
    name        = string
    description = string
    content     = string
    target_ous  = list(string)
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for policy in var.tag_policies : 
      can(jsondecode(policy.content))
    ])
    error_message = "All tag policy content must be valid JSON."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
