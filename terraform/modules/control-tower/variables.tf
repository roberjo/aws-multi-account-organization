# Variables for Control Tower Module

variable "account_id" {
  description = "AWS account ID for the management account"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "region" {
  description = "AWS region for Control Tower deployment"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-2", 
      "eu-west-1", "eu-west-2", "eu-central-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1"
    ], var.region)
    error_message = "Region must be supported by AWS Control Tower."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain Control Tower logs in CloudWatch"
  type        = number
  default     = 90
  
  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Log retention must be at least 30 days."
  }
}

variable "enable_notifications" {
  description = "Enable SNS notifications for Control Tower events"
  type        = bool
  default     = true
}

variable "notification_endpoints" {
  description = "List of email addresses for Control Tower notifications"
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

variable "landing_zone_version" {
  description = "Version of the Control Tower landing zone"
  type        = string
  default     = "3.3"
  
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.landing_zone_version))
    error_message = "Landing zone version must be in format X.Y."
  }
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail in the Control Tower landing zone"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config in the Control Tower landing zone"
  type        = bool
  default     = true
}

variable "governed_regions" {
  description = "List of AWS regions to be governed by Control Tower"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
  
  validation {
    condition     = length(var.governed_regions) > 0
    error_message = "At least one governed region must be specified."
  }
}

variable "tags" {
  description = "Tags to apply to all Control Tower resources"
  type        = map(string)
  default     = {}
}
