variable "enable_default_standards" {
  description = "Enable Security Hub AWS Foundational and other default standards"
  type        = bool
  default     = true
}

variable "standards_arns" {
  description = "List of Security Hub standards ARNs to subscribe to"
  type        = list(string)
  default     = []
}

variable "member_accounts" {
  description = "Map of member accounts to add to Security Hub"
  type = map(object({
    account_id = string
    email      = string
  }))
  default = {}
}

