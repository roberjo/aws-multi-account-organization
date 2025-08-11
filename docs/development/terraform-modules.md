# Terraform Modules Documentation

## Overview

This document describes the Terraform modules used to deploy and manage the Enterprise Multi-Account AWS Organization. These modules provide reusable, configurable infrastructure components that follow infrastructure as code best practices.

## Module Structure

```
terraform/
├── modules/
│   ├── aws-organizations/
│   ├── control-tower/
│   ├── security-hub/
│   ├── guardduty/
│   ├── aws-config/
│   ├── cloudtrail/
│   ├── cloudwatch/
│   ├── lambda/
│   ├── step-functions/
│   └── vpc/
├── environments/
│   ├── management/
│   ├── security/
│   ├── infrastructure/
│   └── application/
└── examples/
    ├── basic-setup/
    ├── security-focused/
    └── production-ready/
```

## Core Modules

### 1. AWS Organizations Module

**Purpose:** Manages AWS Organizations structure and policies

**File:** `modules/aws-organizations/main.tf`

```hcl
module "aws_organizations" {
  source = "../../modules/aws-organizations"
  
  organization_name = "Enterprise Organization"
  
  organizational_units = {
    security = {
      name = "Security OU"
      description = "Security and compliance accounts"
    }
    infrastructure = {
      name = "Infrastructure OU"
      description = "Shared services and infrastructure"
    }
    application = {
      name = "Application OU"
      description = "Application-specific accounts"
    }
    sandbox = {
      name = "Sandbox OU"
      description = "Development and testing accounts"
    }
  }
  
  service_control_policies = {
    restrict_regions = {
      name = "Restrict Regions"
      description = "Restrict AWS regions to approved list"
      content = file("${path.module}/policies/restrict-regions.json")
    }
    require_mfa = {
      name = "Require MFA"
      description = "Require MFA for all operations"
      content = file("${path.module}/policies/require-mfa.json")
    }
  }
  
  tag_policies = {
    required_tags = {
      name = "Required Tags"
      description = "Enforce required resource tagging"
      content = file("${path.module}/policies/required-tags.json")
    }
  }
}
```

**Variables:**
```hcl
variable "organization_name" {
  description = "Name of the AWS Organization"
  type        = string
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name        = string
    description = string
  }))
}

variable "service_control_policies" {
  description = "Map of service control policies to create"
  type = map(object({
    name        = string
    description = string
    content     = string
  }))
  default = {}
}

variable "tag_policies" {
  description = "Map of tag policies to create"
  type = map(object({
    name        = string
    description = string
    content     = string
  }))
  default = {}
}
```

**Outputs:**
```hcl
output "organization_id" {
  description = "ID of the AWS Organization"
  value       = aws_organizations_organization.main.id
}

output "organizational_units" {
  description = "Map of created organizational units"
  value       = aws_organizations_organizational_unit.ous
}

output "service_control_policies" {
  description = "Map of created service control policies"
  value       = aws_organizations_policy.scps
}
```

### 2. Security Hub Module

**Purpose:** Configures Security Hub with compliance standards and member account integration

**File:** `modules/security-hub/main.tf`

```hcl
module "security_hub" {
  source = "../../modules/security-hub"
  
  enable_default_standards = true
  
  compliance_standards = [
    "cis-aws-foundations-benchmark/v/1.2.0",
    "pci-dss/v/3.2.1",
    "aws-foundational-security-best-practices/v/1.0.0"
  ]
  
  member_accounts = {
    "123456789012" = {
      email = "security-admin@company.com"
      invite = true
    }
    "987654321098" = {
      email = "dev-admin@company.com"
      invite = true
    }
  }
  
  custom_actions = {
    high_severity = {
      name = "HighSeverityAction"
      description = "Action for high severity findings"
    }
  }
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

**Variables:**
```hcl
variable "enable_default_standards" {
  description = "Enable AWS default security standards"
  type        = bool
  default     = true
}

variable "compliance_standards" {
  description = "List of compliance standards to enable"
  type        = list(string)
  default     = []
}

variable "member_accounts" {
  description = "Map of member accounts to invite"
  type = map(object({
    email  = string
    invite = bool
  }))
  default = {}
}

variable "custom_actions" {
  description = "Map of custom actions to create"
  type = map(object({
    name        = string
    description = string
  }))
  default = {}
}
```

### 3. GuardDuty Module

**Purpose:** Configures GuardDuty threat detection with member account integration

**File:** `modules/guardduty/main.tf`

```hcl
module "guardduty" {
  source = "../../modules/guardduty"
  
  enable_s3_logs = true
  enable_kubernetes_audit_logs = true
  enable_malware_protection = true
  
  member_accounts = [
    "123456789012",
    "987654321098"
  ]
  
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

**Variables:**
```hcl
variable "enable_s3_logs" {
  description = "Enable S3 protection"
  type        = bool
  default     = true
}

variable "enable_kubernetes_audit_logs" {
  description = "Enable Kubernetes audit logs"
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = "Enable malware protection"
  type        = bool
  default     = true
}

variable "member_accounts" {
  description = "List of member account IDs"
  type        = list(string)
  default     = []
}

variable "finding_publishing_frequency" {
  description = "Frequency of finding publishing"
  type        = string
  default     = "FIFTEEN_MINUTES"
  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Finding publishing frequency must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}
```

### 4. AWS Config Module

**Purpose:** Configures AWS Config for compliance monitoring and resource tracking

**File:** `modules/aws-config/main.tf`

```hcl
module "aws_config" {
  source = "../../modules/aws-config"
  
  enable_organization_aggregator = true
  enable_multi_region = true
  
  config_rules = {
    required_tags = {
      name = "required-tags"
      source = {
        owner             = "AWS"
        source_identifier = "REQUIRED_TAGS"
      }
      input_parameters = jsonencode({
        tag1Key   = "Environment"
        tag1Value = "Production"
        tag2Key   = "Owner"
        tag2Value = "DevOps"
      })
    }
    
    s3_bucket_encryption = {
      name = "s3-bucket-encryption"
      source = {
        owner             = "AWS"
        source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
      }
    }
  }
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

**Variables:**
```hcl
variable "enable_organization_aggregator" {
  description = "Enable organization-wide configuration aggregator"
  type        = bool
  default     = true
}

variable "enable_multi_region" {
  description = "Enable multi-region configuration recording"
  type        = bool
  default     = true
}

variable "config_rules" {
  description = "Map of AWS Config rules to create"
  type = map(object({
    name = string
    source = object({
      owner             = string
      source_identifier = string
    })
    input_parameters = optional(string)
  }))
  default = {}
}
```

### 5. CloudTrail Module

**Purpose:** Configures centralized logging with CloudTrail

**File:** `modules/cloudtrail/main.tf`

```hcl
module "cloudtrail" {
  source = "../../modules/cloudtrail"
  
  trail_name = "organization-trail"
  
  enable_multi_region = true
  enable_global_service_events = true
  enable_log_file_validation = true
  
  s3_bucket_name = "cloudtrail-logs-${random_string.suffix.result}"
  
  event_selectors = [
    {
      read_write_type = "All"
      include_management_events = true
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3:::"]
        }
      ]
    }
  ]
  
  cloudwatch_log_group_name = "/aws/cloudtrail"
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

**Variables:**
```hcl
variable "trail_name" {
  description = "Name of the CloudTrail"
  type        = string
}

variable "enable_multi_region" {
  description = "Enable multi-region trail"
  type        = bool
  default     = true
}

variable "enable_global_service_events" {
  description = "Include global service events"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable log file validation"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "event_selectors" {
  description = "List of event selectors"
  type = list(object({
    read_write_type = string
    include_management_events = bool
    data_resources = optional(list(object({
      type   = string
      values = list(string)
    })))
  }))
  default = []
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = null
}
```

### 6. Lambda Module

**Purpose:** Deploys Lambda functions for automation

**File:** `modules/lambda/main.tf`

```hcl
module "account_provisioning" {
  source = "../../modules/lambda"
  
  function_name = "account-provisioning"
  description   = "Automated AWS account provisioning"
  
  filename = "lambda/account_provisioning.zip"
  handler = "account_provisioning.lambda_handler"
  runtime = "python3.9"
  
  timeout = 300
  memory_size = 512
  
  environment_variables = {
    ORGANIZATION_ID = var.organization_id
    LOG_LEVEL       = "INFO"
  }
  
  vpc_config = {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
  
  tags = {
    Environment = "Production"
    Owner       = "DevOps"
  }
}
```

**Variables:**
```hcl
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "filename" {
  description = "Path to the function deployment package"
  type        = string
}

variable "handler" {
  description = "Function entrypoint"
  type        = string
}

variable "runtime" {
  description = "Runtime environment"
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Memory allocation in MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}
```

## Environment Configurations

### Management Environment

**File:** `environments/management/main.tf`

```hcl
terraform {
  required_version = ">= 1.5"
  
  backend "s3" {
    bucket         = "terraform-state-organization"
    key            = "management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "Management"
      Owner       = "DevOps"
      Project     = "AWS Organization"
    }
  }
}

# AWS Organizations
module "aws_organizations" {
  source = "../../modules/aws-organizations"
  
  organization_name = "Enterprise Organization"
  
  organizational_units = var.organizational_units
  service_control_policies = var.service_control_policies
  tag_policies = var.tag_policies
}

# Security Hub
module "security_hub" {
  source = "../../modules/security-hub"
  
  enable_default_standards = true
  compliance_standards = var.compliance_standards
  member_accounts = var.member_accounts
}

# GuardDuty
module "guardduty" {
  source = "../../modules/guardduty"
  
  enable_s3_logs = true
  enable_kubernetes_audit_logs = true
  enable_malware_protection = true
  member_accounts = var.member_account_ids
}

# AWS Config
module "aws_config" {
  source = "../../modules/aws-config"
  
  enable_organization_aggregator = true
  enable_multi_region = true
  config_rules = var.config_rules
}

# CloudTrail
module "cloudtrail" {
  source = "../../modules/cloudtrail"
  
  trail_name = "organization-trail"
  enable_multi_region = true
  enable_global_service_events = true
  s3_bucket_name = "cloudtrail-logs-${random_string.suffix.result}"
}
```

### Security Environment

**File:** `environments/security/main.tf`

```hcl
terraform {
  required_version = ">= 1.5"
  
  backend "s3" {
    bucket         = "terraform-state-organization"
    key            = "security/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "Security"
      Owner       = "Security"
      Project     = "AWS Organization"
    }
  }
}

# Security-specific configurations
module "security_monitoring" {
  source = "../../modules/security-monitoring"
  
  security_hub_arn = var.security_hub_arn
  guardduty_detector_id = var.guardduty_detector_id
  
  alert_topics = {
    critical = var.critical_alert_topic_arn
    high     = var.high_alert_topic_arn
    medium   = var.medium_alert_topic_arn
  }
}

module "compliance_reporting" {
  source = "../../modules/compliance-reporting"
  
  compliance_frameworks = [
    "SOC2",
    "ISO27001",
    "PCI-DSS"
  ]
  
  reporting_schedule = "cron(0 0 * * ? *)"  # Daily at midnight
}
```

## Usage Examples

### Basic Setup

**File:** `examples/basic-setup/main.tf`

```hcl
# Basic AWS Organization setup
module "basic_organization" {
  source = "../../modules/aws-organizations"
  
  organization_name = "My Organization"
  
  organizational_units = {
    production = {
      name = "Production"
      description = "Production workloads"
    }
    development = {
      name = "Development"
      description = "Development and testing"
    }
  }
  
  service_control_policies = {
    restrict_regions = {
      name = "Restrict Regions"
      description = "Limit to approved regions"
      content = file("${path.module}/policies/restrict-regions.json")
    }
  }
}
```

### Security-Focused Setup

**File:** `examples/security-focused/main.tf`

```hcl
# Security-focused organization setup
module "security_organization" {
  source = "../../modules/aws-organizations"
  
  organization_name = "Secure Organization"
  
  organizational_units = {
    security = {
      name = "Security"
      description = "Security and compliance"
    }
    production = {
      name = "Production"
      description = "Production workloads"
    }
    development = {
      name = "Development"
      description = "Development and testing"
    }
  }
  
  service_control_policies = {
    restrict_regions = {
      name = "Restrict Regions"
      content = file("${path.module}/policies/restrict-regions.json")
    }
    require_mfa = {
      name = "Require MFA"
      content = file("${path.module}/policies/require-mfa.json")
    }
    restrict_root = {
      name = "Restrict Root User"
      content = file("${path.module}/policies/restrict-root.json")
    }
  }
}

module "security_hub" {
  source = "../../modules/security-hub"
  
  enable_default_standards = true
  compliance_standards = [
    "cis-aws-foundations-benchmark/v/1.2.0",
    "pci-dss/v/3.2.1"
  ]
}

module "guardduty" {
  source = "../../modules/guardduty"
  
  enable_s3_logs = true
  enable_kubernetes_audit_logs = true
  enable_malware_protection = true
}
```

## Best Practices

### 1. Module Design

- **Single Responsibility:** Each module should have a single, well-defined purpose
- **Reusability:** Design modules to be reusable across different environments
- **Configurability:** Use variables to make modules configurable
- **Validation:** Include input validation for critical variables

### 2. State Management

- **Remote State:** Use S3 backend for state storage
- **State Locking:** Use DynamoDB for state locking
- **State Encryption:** Enable encryption for state files
- **State Separation:** Separate state files for different environments

### 3. Security

- **Least Privilege:** Use minimal required permissions
- **Encryption:** Enable encryption for all resources
- **Access Control:** Implement proper IAM policies
- **Audit Logging:** Enable comprehensive logging

### 4. Documentation

- **README Files:** Include README files for each module
- **Variable Documentation:** Document all variables and their purposes
- **Example Usage:** Provide example configurations
- **Change Log:** Maintain change logs for modules

### 5. Testing

- **Unit Tests:** Write tests for module logic
- **Integration Tests:** Test module interactions
- **Validation Tests:** Test input validation
- **Security Tests:** Test security configurations

## Module Versioning

### Version Strategy

```hcl
module "aws_organizations" {
  source = "git::https://github.com/company/terraform-modules.git//aws-organizations?ref=v1.2.0"
  
  # Module configuration
}
```

### Version Constraints

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **State Lock Issues**
   ```bash
   # Force unlock state (use with caution)
   terraform force-unlock LOCK_ID
   ```

2. **Module Source Issues**
   ```bash
   # Clean module cache
   terraform init -upgrade
   ```

3. **Variable Validation Errors**
   ```bash
   # Validate configuration
   terraform validate
   ```

4. **Provider Version Conflicts**
   ```bash
   # Update provider versions
   terraform init -upgrade
   ```

### Debugging

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform commands
terraform plan
```

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Next Review:** January 2025
