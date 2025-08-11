# Management Account - Main Configuration
# Phase 1: Foundation Setup

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.region

  default_tags {
    tags = var.default_tags
  }
}

# Random string for unique resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# AWS Organizations Module
module "aws_organizations" {
  source = "../../modules/aws-organizations"

  organizational_units = var.organizational_units
  
  service_control_policies = {
    restrict_regions = {
      name        = "Restrict Regions"
      description = "Restrict AWS operations to approved regions only"
      content     = file("${path.module}/../../policies/scp/restrict-regions.json")
      target_ous  = ["security", "infrastructure", "application", "sandbox"]
    }
    
    restrict_root_user = {
      name        = "Restrict Root User"
      description = "Restrict root user access except for account management"
      content     = file("${path.module}/../../policies/scp/restrict-root-user.json")
      target_ous  = ["security", "infrastructure", "application", "sandbox"]
    }
    
    require_mfa = {
      name        = "Require MFA"
      description = "Require multi-factor authentication for all operations"
      content     = file("${path.module}/../../policies/scp/require-mfa.json")
      target_ous  = ["security", "infrastructure", "application"]
    }
  }

  tag_policies = {
    required_tags = {
      name        = "Required Tags"
      description = "Enforce required resource tagging standards"
      content     = file("${path.module}/../../policies/tag/required-tags.json")
      target_ous  = ["security", "infrastructure", "application", "sandbox"]
    }
  }

  tags = var.default_tags
}

# S3 Bucket for CloudTrail logs (Phase 1 preparation)
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "cloudtrail-logs-${random_string.suffix.result}"

  tags = merge(var.default_tags, {
    Name    = "CloudTrail Logs"
    Purpose = "Centralized logging for AWS API calls"
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for organization events
resource "aws_cloudwatch_log_group" "organization_logs" {
  name              = "/aws/organizations"
  retention_in_days = 90

  tags = merge(var.default_tags, {
    Name    = "Organization Logs"
    Purpose = "Organization activity logging"
  })
}

# SNS Topic for organization notifications
resource "aws_sns_topic" "organization_notifications" {
  name = "organization-notifications"

  tags = merge(var.default_tags, {
    Name    = "Organization Notifications"
    Purpose = "Organization event notifications"
  })
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "organization_notifications" {
  arn = aws_sns_topic.organization_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "organizations.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.organization_notifications.arn
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
