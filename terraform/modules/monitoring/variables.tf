# Variables for Monitoring Module

variable "region" {
  description = "AWS region for monitoring resources"
  type        = string
  default     = "us-east-1"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90
  
  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Log retention must be at least 30 days."
  }
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

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring with additional metrics"
  type        = bool
  default     = true
}

variable "alarm_thresholds" {
  description = "Thresholds for CloudWatch alarms"
  type = object({
    high_severity_findings    = number
    critical_severity_findings = number
    config_violations         = number
    guardduty_findings        = number
  })
  
  default = {
    high_severity_findings    = 5
    critical_severity_findings = 0
    config_violations         = 10
    guardduty_findings        = 0
  }
}

variable "dashboard_refresh_interval" {
  description = "Dashboard refresh interval in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = var.dashboard_refresh_interval >= 60
    error_message = "Dashboard refresh interval must be at least 60 seconds."
  }
}

variable "enable_cost_monitoring" {
  description = "Enable cost monitoring and alerting"
  type        = bool
  default     = true
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD for cost alerts"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Monthly budget limit must be greater than 0."
  }
}

variable "enable_performance_insights" {
  description = "Enable performance insights for monitoring"
  type        = bool
  default     = true
}

variable "custom_metrics" {
  description = "Custom metrics to monitor"
  type = map(object({
    namespace   = string
    metric_name = string
    dimensions  = map(string)
    statistic   = string
    threshold   = number
  }))
  default = {}
}

variable "notification_channels" {
  description = "Additional notification channels (Slack, Teams, etc.)"
  type = map(object({
    type     = string
    endpoint = string
    enabled  = bool
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all monitoring resources"
  type        = map(string)
  default     = {}
}
