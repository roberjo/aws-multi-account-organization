# Guardrails Module
# Manages AWS Control Tower Guardrails and custom security controls

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for organization information
data "aws_organizations_organization" "current" {}

# Data source for organizational units
data "aws_organizations_organizational_units" "all" {
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

# Custom Config Rules for additional guardrails
resource "aws_config_config_rule" "custom_guardrails" {
  for_each = var.custom_config_rules

  name = each.key

  source {
    owner             = each.value.source_owner
    source_identifier = each.value.source_identifier
  }

  input_parameters = each.value.input_parameters

  depends_on = [aws_config_configuration_recorder.recorder]

  tags = merge(var.tags, {
    Name        = each.key
    Type        = "CustomGuardrail"
    Compliance  = "Required"
  })
}

# Config Configuration Recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "guardrails-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  tags = merge(var.tags, {
    Name    = "Guardrails Config Recorder"
    Purpose = "Configuration recording for guardrails"
  })
}

# Config Delivery Channel
resource "aws_config_delivery_channel" "channel" {
  name           = "guardrails-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  tags = merge(var.tags, {
    Name    = "Guardrails Delivery Channel"
    Purpose = "Configuration delivery for guardrails"
  })
}

# S3 Bucket for Config
resource "aws_s3_bucket" "config_bucket" {
  bucket        = "aws-config-guardrails-${random_string.suffix.result}"
  force_destroy = false

  tags = merge(var.tags, {
    Name    = "Config Guardrails Bucket"
    Purpose = "AWS Config configuration storage"
  })
}

resource "aws_s3_bucket_versioning" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Config
resource "aws_s3_bucket_policy" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# IAM Role for Config
resource "aws_iam_role" "config_role" {
  name = "AWSConfigRole-Guardrails"

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

  tags = merge(var.tags, {
    Name    = "Config Guardrails Role"
    Purpose = "Service role for AWS Config guardrails"
  })
}

# Attach AWS managed policy to Config role
resource "aws_iam_role_policy_attachment" "config_role" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# CloudWatch Log Group for guardrail violations
resource "aws_cloudwatch_log_group" "guardrail_violations" {
  name              = "/aws/guardrails/violations"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "Guardrail Violations"
    Purpose = "Logging for guardrail violations"
  })
}

# EventBridge rule for Config compliance events
resource "aws_cloudwatch_event_rule" "config_compliance" {
  name        = "config-compliance-changes"
  description = "Capture Config compliance change events"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      messageType = ["ComplianceChangeNotification"]
    }
  })

  tags = merge(var.tags, {
    Name    = "Config Compliance Events"
    Purpose = "Monitoring Config rule compliance changes"
  })
}

# EventBridge target for compliance violations
resource "aws_cloudwatch_event_target" "compliance_violations" {
  rule      = aws_cloudwatch_event_rule.config_compliance.name
  target_id = "ComplianceViolationTarget"
  arn       = aws_cloudwatch_log_group.guardrail_violations.arn
}

# SNS topic for guardrail notifications
resource "aws_sns_topic" "guardrail_notifications" {
  count = var.enable_notifications ? 1 : 0
  name  = "guardrail-violations"

  tags = merge(var.tags, {
    Name    = "Guardrail Notifications"
    Purpose = "Notifications for guardrail violations"
  })
}

# EventBridge target for SNS notifications
resource "aws_cloudwatch_event_target" "guardrail_sns" {
  count     = var.enable_notifications ? 1 : 0
  rule      = aws_cloudwatch_event_rule.config_compliance.name
  target_id = "GuardrailSNSTarget"
  arn       = aws_sns_topic.guardrail_notifications[0].arn
}

# SNS topic policy
resource "aws_sns_topic_policy" "guardrail_notifications" {
  count = var.enable_notifications ? 1 : 0
  arn   = aws_sns_topic.guardrail_notifications[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.guardrail_notifications[0].arn
      }
    ]
  })
}

# Lambda function for custom remediation
resource "aws_lambda_function" "guardrail_remediation" {
  count = var.enable_auto_remediation ? 1 : 0

  filename         = "guardrail_remediation.zip"
  function_name    = "guardrail-auto-remediation"
  role            = aws_iam_role.lambda_role[0].arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      LOG_LEVEL = "INFO"
      SNS_TOPIC_ARN = var.enable_notifications ? aws_sns_topic.guardrail_notifications[0].arn : ""
    }
  }

  tags = merge(var.tags, {
    Name    = "Guardrail Auto Remediation"
    Purpose = "Automated remediation for guardrail violations"
  })
}

# IAM role for Lambda remediation function
resource "aws_iam_role" "lambda_role" {
  count = var.enable_auto_remediation ? 1 : 0
  name  = "GuardrailRemediationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "Guardrail Remediation Role"
    Purpose = "Execution role for guardrail remediation Lambda"
  })
}

# IAM policy for Lambda remediation function
resource "aws_iam_role_policy" "lambda_remediation" {
  count = var.enable_auto_remediation ? 1 : 0
  name  = "GuardrailRemediationPolicy"
  role  = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "config:GetComplianceDetailsByConfigRule",
          "config:GetComplianceDetailsByResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.enable_notifications ? aws_sns_topic.guardrail_notifications[0].arn : "*"
      }
    ]
  })
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
