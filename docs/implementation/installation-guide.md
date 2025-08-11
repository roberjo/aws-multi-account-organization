# Installation Guide

## Overview

This guide provides step-by-step instructions for installing and configuring the Enterprise Multi-Account AWS Organization. The installation process is divided into phases to ensure a systematic and controlled deployment.

## Prerequisites

### AWS Account Requirements
- **Management Account:** A dedicated AWS account for organization management
- **AWS Organizations:** Enabled on the management account
- **AWS Control Tower:** Available in supported regions
- **Required Permissions:** Full administrative access to the management account

### Software Requirements
- **Terraform:** Version 1.5 or higher
- **AWS CLI:** Version 2.0 or higher
- **Git:** For version control
- **Python:** Version 3.8 or higher (for Lambda functions)

### Network Requirements
- **Internet Connectivity:** Required for AWS service access
- **DNS Resolution:** Proper DNS configuration for AWS services
- **Firewall Rules:** Allow HTTPS (443) and SSH (22) traffic

### Security Requirements
- **MFA Device:** Hardware or software MFA for root user
- **Access Keys:** AWS access keys for programmatic access
- **IAM User:** Dedicated IAM user for Terraform operations

## Phase 1: Foundation Setup

### Step 1: Prepare the Management Account

#### 1.1 Configure AWS CLI
```bash
# Configure AWS CLI with management account credentials
aws configure

# Set default region (recommended: us-east-1 for Control Tower)
aws configure set region us-east-1

# Verify configuration
aws sts get-caller-identity
```

#### 1.2 Create IAM User for Terraform
```bash
# Create IAM user
aws iam create-user --user-name terraform-admin

# Create access keys
aws iam create-access-key --user-name terraform-admin

# Attach required policies
aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### 1.3 Enable AWS Organizations
```bash
# Create organization
aws organizations create-organization \
  --feature-set ALL \
  --aws-service-access-principals \
    cloudtrail.amazonaws.com \
    config.amazonaws.com \
    securityhub.amazonaws.com \
    guardduty.amazonaws.com
```

### Step 2: Set Up Terraform Backend

#### 2.1 Create S3 Bucket for Terraform State
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://terraform-state-organization-$(date +%s)

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-organization-$(date +%s) \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket terraform-state-organization-$(date +%s) \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

#### 2.2 Create DynamoDB Table for State Locking
```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

#### 2.3 Configure Terraform Backend
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-organization-123456789"
    key            = "organization/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
  
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Step 3: Deploy Control Tower

#### 3.1 Prepare Control Tower Configuration
```hcl
# control-tower.tf
resource "aws_servicecatalog_product" "control_tower" {
  name        = "AWS Control Tower"
  description = "Multi-account AWS environment with governance"
  
  provisioning_artifact_parameters {
    template_url = "https://s3.amazonaws.com/aws-control-tower/templates/latest/control-tower.template"
    type         = "CLOUD_FORMATION_TEMPLATE"
  }
  
  tags = {
    Environment = "Production"
    Owner       = "DevOps"
  }
}
```

#### 3.2 Deploy Control Tower Landing Zone
```bash
# Navigate to Control Tower console
# https://console.aws.amazon.com/controltower

# Follow the setup wizard:
# 1. Choose "Set up landing zone"
# 2. Select home region (us-east-1 recommended)
# 3. Configure organizational email
# 4. Set up core accounts:
#    - Audit account
#    - Log archive account
# 5. Configure guardrails
# 6. Review and launch
```

#### 3.3 Verify Control Tower Deployment
```bash
# Verify organization structure
aws organizations list-accounts

# Verify organizational units
aws organizations list-organizational-units-for-parent \
  --parent-id r-xxxx

# Verify guardrails
aws organizations list-policies \
  --filter SERVICE_CONTROL_POLICY
```

## Phase 2: Security Configuration

### Step 4: Configure Security Hub

#### 4.1 Enable Security Hub in Master Account
```hcl
# security-hub.tf
resource "aws_securityhub_account" "master" {
  enable_default_standards = true
  
  standards_subscription {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0"
  }
  
  standards_subscription {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
  }
  
  standards_subscription {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  }
}
```

#### 4.2 Configure Member Account Integration
```hcl
# Enable Security Hub in member accounts
resource "aws_securityhub_member" "member" {
  for_each = var.member_accounts
  
  account_id = each.value.account_id
  email      = each.value.email
  invite     = true
}
```

### Step 5: Configure GuardDuty

#### 5.1 Enable GuardDuty in Master Account
```hcl
# guardduty.tf
resource "aws_guardduty_detector" "master" {
  enable = true
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}
```

#### 5.2 Configure Member Account Integration
```hcl
# Invite member accounts to GuardDuty
resource "aws_guardduty_invite_accepter" "member" {
  for_each = var.member_accounts
  
  detector_id       = aws_guardduty_detector.master.id
  master_account_id = each.value.account_id
}
```

### Step 6: Configure AWS Config

#### 6.1 Set Up Configuration Aggregator
```hcl
# config.tf
resource "aws_config_configuration_aggregator" "organization" {
  name = "organization-aggregator"
  
  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator.arn
  }
}
```

#### 6.2 Create IAM Role for Config Aggregator
```hcl
resource "aws_iam_role" "config_aggregator" {
  name = "ConfigAggregatorRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}
```

## Phase 3: Monitoring and Logging

### Step 7: Configure CloudTrail

#### 7.1 Create S3 Bucket for CloudTrail Logs
```hcl
# cloudtrail.tf
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "cloudtrail-logs-${random_string.suffix.result}"
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

#### 7.2 Configure CloudTrail
```hcl
resource "aws_cloudtrail" "organization" {
  name                          = "organization-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

### Step 8: Configure CloudWatch

#### 8.1 Create Log Groups
```hcl
# cloudwatch.tf
resource "aws_cloudwatch_log_group" "organization" {
  name              = "/aws/organization"
  retention_in_days = 30
  
  tags = {
    Environment = "Production"
    Owner       = "DevOps"
  }
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security"
  retention_in_days = 90
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

#### 8.2 Create Dashboards
```hcl
resource "aws_cloudwatch_dashboard" "organization" {
  dashboard_name = "organization-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Organizations", "AccountCount"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Organization Account Count"
        }
      }
    ]
  })
}
```

## Phase 4: Automation Setup

### Step 9: Create Lambda Functions

#### 9.1 Account Provisioning Function
```python
# lambda/account_provisioning.py
import boto3
import json
import logging

def lambda_handler(event, context):
    organizations = boto3.client('organizations')
    
    try:
        # Create new account
        response = organizations.create_account(
            Email=event['email'],
            AccountName=event['account_name'],
            RoleName='OrganizationAccountAccessRole',
            IamUserAccessToBilling='DENY'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'accountId': response['CreateAccountStatus']['AccountId'],
                'status': response['CreateAccountStatus']['State']
            })
        }
    except Exception as e:
        logging.error(f"Error creating account: {str(e)}")
        raise
```

#### 9.2 Deploy Lambda Function
```hcl
# lambda.tf
resource "aws_lambda_function" "account_provisioning" {
  filename         = "lambda/account_provisioning.zip"
  function_name    = "account-provisioning"
  role            = aws_iam_role.lambda_role.arn
  handler         = "account_provisioning.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      ORGANIZATION_ID = aws_organizations_organization.main.id
    }
  }
  
  tags = {
    Environment = "Production"
    Owner       = "DevOps"
  }
}
```

### Step 10: Create Step Functions Workflow

#### 10.1 Account Provisioning Workflow
```json
{
  "Comment": "Account Provisioning Workflow",
  "StartAt": "CreateAccount",
  "States": {
    "CreateAccount": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:${region}:${account}:function:create-account",
      "Next": "WaitForAccount",
      "Catch": [{
        "ErrorEquals": ["States.ALL"],
        "Next": "HandleError"
      }]
    },
    "WaitForAccount": {
      "Type": "Wait",
      "Seconds": 300,
      "Next": "CheckAccountStatus"
    },
    "CheckAccountStatus": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:${region}:${account}:function:check-account-status",
      "Next": "AccountReady?"
    },
    "AccountReady?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.status",
          "StringEquals": "SUCCEEDED",
          "Next": "ConfigureAccount"
        }
      ],
      "Default": "WaitForAccount"
    },
    "ConfigureAccount": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:${region}:${account}:function:configure-account",
      "End": true
    },
    "HandleError": {
      "Type": "Fail",
      "Cause": "Account creation failed"
    }
  }
}
```

#### 10.2 Deploy Step Functions
```hcl
resource "aws_sfn_state_machine" "account_provisioning" {
  name     = "account-provisioning"
  role_arn = aws_iam_role.step_functions_role.arn
  
  definition = file("step-functions/account-provisioning.json")
  
  tags = {
    Environment = "Production"
    Owner       = "DevOps"
  }
}
```

## Phase 5: Testing and Validation

### Step 11: Test Account Provisioning

#### 11.1 Create Test Account
```bash
# Test account creation via Step Functions
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:ACCOUNT:stateMachine:account-provisioning \
  --input '{
    "email": "test-account@company.com",
    "account_name": "Test Account",
    "environment": "sandbox"
  }'
```

#### 11.2 Verify Account Configuration
```bash
# Check account status
aws organizations list-accounts

# Verify Security Hub integration
aws securityhub list-members

# Verify GuardDuty integration
aws guardduty list-members --detector-id DETECTOR_ID

# Verify Config aggregation
aws config describe-configuration-aggregators
```

### Step 12: Validate Security Controls

#### 12.1 Test Guardrails
```bash
# Test preventive guardrails
aws s3api create-bucket \
  --bucket test-bucket-in-unauthorized-region \
  --region eu-west-3

# Should be blocked by region restriction SCP
```

#### 12.2 Test Monitoring
```bash
# Generate test activity
aws s3api list-buckets

# Check CloudTrail logs
aws logs filter-log-events \
  --log-group-name /aws/cloudtrail \
  --start-time $(date -d '1 hour ago' +%s)000
```

## Troubleshooting

### Common Issues

#### Issue 1: Control Tower Deployment Fails
**Symptoms:** Control Tower setup wizard fails or times out
**Solution:**
```bash
# Check service quotas
aws service-quotas get-service-quota \
  --service-code organizations \
  --quota-code L-29A0A3C3

# Request quota increase if needed
aws service-quotas request-service-quota-increase \
  --service-code organizations \
  --quota-code L-29A0A3C3 \
  --desired-value 10
```

#### Issue 2: Terraform State Lock Issues
**Symptoms:** Terraform operations fail with state lock errors
**Solution:**
```bash
# Force unlock state (use with caution)
terraform force-unlock LOCK_ID

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock
```

#### Issue 3: Security Hub Integration Fails
**Symptoms:** Member accounts not appearing in Security Hub
**Solution:**
```bash
# Check member account status
aws securityhub list-members

# Re-invite member account
aws securityhub invite-members \
  --account-ids ACCOUNT_ID
```

### Log Analysis

#### CloudTrail Log Analysis
```bash
# Search for specific API calls
aws logs filter-log-events \
  --log-group-name /aws/cloudtrail \
  --filter-pattern '{ $.eventName = "CreateAccount" }'

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/cloudtrail \
  --filter-pattern '{ $.errorCode = "*" }'
```

#### CloudWatch Log Analysis
```bash
# Search Lambda function logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/account-provisioning \
  --start-time $(date -d '1 hour ago' +%s)000
```

## Post-Installation Tasks

### Step 13: Documentation and Training

#### 13.1 Create User Documentation
- Account request procedures
- Access management guidelines
- Security policies and procedures
- Troubleshooting guides

#### 13.2 Conduct Training Sessions
- Admin training for account management
- User training for self-service portal
- Security awareness training
- Compliance training

### Step 14: Monitoring and Maintenance

#### 14.1 Set Up Alerts
```hcl
# cloudwatch-alarms.tf
resource "aws_cloudwatch_metric_alarm" "account_creation_failures" {
  alarm_name          = "account-creation-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Account creation Lambda function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.account_provisioning.function_name
  }
}
```

#### 14.2 Schedule Maintenance Tasks
- Monthly security reviews
- Quarterly compliance assessments
- Annual disaster recovery testing
- Regular backup verification

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Next Review:** January 2025
