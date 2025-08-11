# Variables for Guardrails Module

variable "custom_config_rules" {
  description = "Map of custom AWS Config rules for additional guardrails"
  type = map(object({
    source_owner      = string
    source_identifier = string
    input_parameters  = optional(string)
  }))
  
  default = {
    # Require S3 bucket encryption
    s3_bucket_server_side_encryption_enabled = {
      source_owner      = "AWS"
      source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
    }
    
    # Require S3 bucket public access block
    s3_bucket_public_access_prohibited = {
      source_owner      = "AWS"
      source_identifier = "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
    }
    
    # Require EC2 instances to be in VPC
    ec2_instances_in_vpc = {
      source_owner      = "AWS"
      source_identifier = "INSTANCES_IN_VPC"
    }
    
    # Require root access key check
    root_access_key_check = {
      source_owner      = "AWS"
      source_identifier = "ROOT_ACCESS_KEY_CHECK"
    }
    
    # Require MFA for root user
    mfa_enabled_for_root = {
      source_owner      = "AWS"
      source_identifier = "ROOT_HARDWARE_MFA_ENABLED"
    }
    
    # Require CloudTrail enabled
    cloudtrail_enabled = {
      source_owner      = "AWS"
      source_identifier = "CLOUD_TRAIL_ENABLED"
    }
    
    # Require VPC flow logs enabled
    vpc_flow_logs_enabled = {
      source_owner      = "AWS"
      source_identifier = "VPC_FLOW_LOGS_ENABLED"
    }
    
    # Require security groups no unrestricted ingress
    security_groups_restricted_ssh = {
      source_owner      = "AWS"
      source_identifier = "INCOMING_SSH_DISABLED"
    }
    
    # Require EBS encryption
    ebs_encrypted_volumes = {
      source_owner      = "AWS"
      source_identifier = "ENCRYPTED_VOLUMES"
    }
    
    # Require RDS encryption
    rds_storage_encrypted = {
      source_owner      = "AWS"
      source_identifier = "RDS_STORAGE_ENCRYPTED"
    }
  }
}

variable "mandatory_guardrails" {
  description = "List of mandatory Control Tower guardrails to enable"
  type        = list(string)
  
  default = [
    # Preventive guardrails
    "AWS-GR_RESTRICTED_COMMON_PORTS",
    "AWS-GR_RESTRICTED_SSH",
    "AWS-GR_DISALLOW_VPC_INTERNET_ACCESS",
    "AWS-GR_DISALLOW_VPN_CONNECTIONS",
    "AWS-GR_DISALLOW_INTERNET_CONNECTION_THROUGH_EGRESS_ONLY_INTERNET_GATEWAY",
    
    # Detective guardrails
    "AWS-GR_DETECT_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS",
    "AWS-GR_DETECT_WHETHER_PUBLIC_READ_ACCESS_TO_S3_BUCKETS_IS_PROHIBITED",
    "AWS-GR_DETECT_WHETHER_PUBLIC_WRITE_ACCESS_TO_S3_BUCKETS_IS_PROHIBITED",
    "AWS-GR_DETECT_WHETHER_MFA_IS_ENABLED_FOR_ROOT_USER",
    "AWS-GR_DETECT_ROOT_USER_HAS_ACCESS_KEYS"
  ]
}

variable "strongly_recommended_guardrails" {
  description = "List of strongly recommended Control Tower guardrails to enable"
  type        = list(string)
  
  default = [
    "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
    "AWS-GR_LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED",
    "AWS-GR_EBS_OPTIMIZED_INSTANCE",
    "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP",
    "AWS-GR_ELB_LOGGING_ENABLED",
    "AWS-GR_ENCRYPTED_VOLUMES",
    "AWS-GR_IAM_USER_MFA_ENABLED",
    "AWS-GR_S3_BUCKET_SSL_REQUESTS_ONLY"
  ]
}

variable "target_organizational_units" {
  description = "List of organizational unit names to apply guardrails to"
  type        = list(string)
  default     = ["Security OU", "Infrastructure OU", "Application OU"]
}

variable "enable_notifications" {
  description = "Enable SNS notifications for guardrail violations"
  type        = bool
  default     = true
}

variable "notification_endpoints" {
  description = "List of email addresses for guardrail violation notifications"
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
  description = "Enable automated remediation for certain guardrail violations"
  type        = bool
  default     = false
}

variable "remediation_actions" {
  description = "Map of remediation actions for specific guardrail violations"
  type = map(object({
    action_type = string
    parameters  = map(string)
  }))
  
  default = {
    s3_public_bucket = {
      action_type = "block_public_access"
      parameters = {
        block_public_acls       = "true"
        ignore_public_acls      = "true"
        block_public_policy     = "true"
        restrict_public_buckets = "true"
      }
    }
    
    security_group_open_ssh = {
      action_type = "revoke_ingress"
      parameters = {
        protocol    = "tcp"
        port        = "22"
        cidr_blocks = "0.0.0.0/0"
      }
    }
  }
}

variable "log_retention_days" {
  description = "Number of days to retain guardrail logs in CloudWatch"
  type        = number
  default     = 90
  
  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Log retention must be at least 30 days."
  }
}

variable "config_delivery_frequency" {
  description = "Frequency for AWS Config snapshot delivery"
  type        = string
  default     = "TwentyFour_Hours"
  
  validation {
    condition = contains([
      "One_Hour", "Three_Hours", "Six_Hours", 
      "Twelve_Hours", "TwentyFour_Hours"
    ], var.config_delivery_frequency)
    error_message = "Config delivery frequency must be a valid option."
  }
}

variable "enable_config_rules" {
  description = "Enable AWS Config rules for compliance monitoring"
  type        = bool
  default     = true
}

variable "compliance_frameworks" {
  description = "List of compliance frameworks to enable guardrails for"
  type        = list(string)
  default     = ["SOC2", "PCI-DSS", "CIS"]
  
  validation {
    condition = alltrue([
      for framework in var.compliance_frameworks :
      contains(["SOC2", "PCI-DSS", "CIS", "HIPAA", "ISO27001"], framework)
    ])
    error_message = "Compliance frameworks must be from the supported list."
  }
}

variable "tags" {
  description = "Tags to apply to all guardrail resources"
  type        = map(string)
  default     = {}
}
