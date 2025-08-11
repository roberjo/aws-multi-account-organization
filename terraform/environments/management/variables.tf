# Variables for Management Account Environment

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-west-2", "eu-west-1", "eu-central-1", 
      "ap-southeast-1", "ap-southeast-2"
    ], var.region)
    error_message = "Region must be one of the approved regions for the organization."
  }
}

variable "organization_name" {
  description = "Name of the AWS Organization"
  type        = string
  default     = "Enterprise Organization"
  
  validation {
    condition     = length(var.organization_name) > 0
    error_message = "Organization name cannot be empty."
  }
}

variable "management_account_email" {
  description = "Email address for the management account"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.management_account_email))
    error_message = "Management account email must be a valid email address."
  }
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name        = string
    description = string
  }))
  
  default = {
    security = {
      name        = "Security OU"
      description = "Security and compliance accounts"
    }
    infrastructure = {
      name        = "Infrastructure OU"
      description = "Shared services and infrastructure"
    }
    application = {
      name        = "Application OU"
      description = "Application workloads"
    }
    sandbox = {
      name        = "Sandbox OU"
      description = "Development and testing"
    }
  }
  
  validation {
    condition     = length(var.organizational_units) > 0
    error_message = "At least one organizational unit must be defined."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  
  default = {
    Environment = "Management"
    Owner       = "DevOps"
    Project     = "AWS Organization"
    Phase       = "1-Foundation"
  }
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for the organization"
  type        = bool
  default     = true
}

variable "cloudtrail_retention_days" {
  description = "Number of days to retain CloudTrail logs"
  type        = number
  default     = 90
  
  validation {
    condition     = var.cloudtrail_retention_days >= 30
    error_message = "CloudTrail retention must be at least 30 days."
  }
}

variable "notification_email" {
  description = "Email address for organization notifications"
  type        = string
  default     = ""
  
  validation {
    condition = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be empty or a valid email address."
  }
}

variable "notification_endpoints" {
  description = "List of email addresses for guardrail notifications"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.notification_endpoints : 
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All notification endpoints must be valid email addresses."
  }
}

variable "enable_auto_remediation" {
  description = "Enable automated remediation for guardrail violations"
  type        = bool
  default     = false
}

variable "critical_notification_emails" {
  description = "List of email addresses for critical alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.critical_notification_emails : 
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "security_notification_emails" {
  description = "List of email addresses for security alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.security_notification_emails : 
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "compliance_notification_emails" {
  description = "List of email addresses for compliance alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.compliance_notification_emails : 
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "operational_notification_emails" {
  description = "List of email addresses for operational alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.operational_notification_emails : 
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD for cost monitoring"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Monthly budget limit must be greater than 0."
  }
}
