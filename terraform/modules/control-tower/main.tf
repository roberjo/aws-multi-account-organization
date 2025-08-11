# Control Tower Module
# Manages AWS Control Tower landing zone and configuration

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Note: Control Tower landing zone is typically set up through the AWS Console
# This module provides supporting resources and configuration

# Data source for Control Tower information
data "aws_organizations_organization" "current" {}

# S3 bucket for Control Tower access logs
resource "aws_s3_bucket" "access_logs" {
  bucket = "aws-controltower-logs-${var.account_id}-${var.region}"

  tags = merge(var.tags, {
    Name    = "Control Tower Access Logs"
    Purpose = "Access logging for Control Tower"
  })
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for Control Tower events
resource "aws_cloudwatch_log_group" "control_tower" {
  name              = "/aws/controltower"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "Control Tower Logs"
    Purpose = "Control Tower event logging"
  })
}

# EventBridge rule for Control Tower events
resource "aws_cloudwatch_event_rule" "control_tower_events" {
  name        = "control-tower-events"
  description = "Capture Control Tower lifecycle events"

  event_pattern = jsonencode({
    source      = ["aws.controltower"]
    detail-type = [
      "AWS Control Tower Landing Zone Operation",
      "AWS Control Tower Account Operation"
    ]
  })

  tags = merge(var.tags, {
    Name    = "Control Tower Events"
    Purpose = "Event monitoring for Control Tower"
  })
}

# EventBridge target to send events to CloudWatch Logs
resource "aws_cloudwatch_event_target" "control_tower_logs" {
  rule      = aws_cloudwatch_event_rule.control_tower_events.name
  target_id = "ControlTowerLogTarget"
  arn       = aws_cloudwatch_log_group.control_tower.arn
}

# SNS topic for Control Tower notifications
resource "aws_sns_topic" "control_tower_notifications" {
  count = var.enable_notifications ? 1 : 0
  name  = "control-tower-notifications"

  tags = merge(var.tags, {
    Name    = "Control Tower Notifications"
    Purpose = "Notifications for Control Tower events"
  })
}

# EventBridge target to send notifications to SNS
resource "aws_cloudwatch_event_target" "control_tower_notifications" {
  count     = var.enable_notifications ? 1 : 0
  rule      = aws_cloudwatch_event_rule.control_tower_events.name
  target_id = "ControlTowerSNSTarget"
  arn       = aws_sns_topic.control_tower_notifications[0].arn
}

# IAM role for Control Tower service
resource "aws_iam_role" "control_tower_service" {
  name = "AWSControlTowerServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "controltower.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "Control Tower Service Role"
    Purpose = "Service role for AWS Control Tower"
  })
}

# Attach AWS managed policy to Control Tower service role
resource "aws_iam_role_policy_attachment" "control_tower_service" {
  role       = aws_iam_role.control_tower_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSControlTowerServiceRolePolicy"
}

# Custom policy for additional Control Tower permissions
resource "aws_iam_role_policy" "control_tower_additional" {
  name = "ControlTowerAdditionalPermissions"
  role = aws_iam_role.control_tower_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.control_tower.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.enable_notifications ? aws_sns_topic.control_tower_notifications[0].arn : "*"
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
