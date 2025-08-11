# Outputs for Control Tower Module

output "access_logs_bucket_name" {
  description = "Name of the Control Tower access logs S3 bucket"
  value       = aws_s3_bucket.access_logs.bucket
}

output "access_logs_bucket_arn" {
  description = "ARN of the Control Tower access logs S3 bucket"
  value       = aws_s3_bucket.access_logs.arn
}

output "control_tower_log_group_name" {
  description = "Name of the Control Tower CloudWatch log group"
  value       = aws_cloudwatch_log_group.control_tower.name
}

output "control_tower_log_group_arn" {
  description = "ARN of the Control Tower CloudWatch log group"
  value       = aws_cloudwatch_log_group.control_tower.arn
}

output "control_tower_events_rule_name" {
  description = "Name of the Control Tower EventBridge rule"
  value       = aws_cloudwatch_event_rule.control_tower_events.name
}

output "control_tower_events_rule_arn" {
  description = "ARN of the Control Tower EventBridge rule"
  value       = aws_cloudwatch_event_rule.control_tower_events.arn
}

output "notification_topic_arn" {
  description = "ARN of the Control Tower notification SNS topic"
  value       = var.enable_notifications ? aws_sns_topic.control_tower_notifications[0].arn : null
}

output "notification_topic_name" {
  description = "Name of the Control Tower notification SNS topic"
  value       = var.enable_notifications ? aws_sns_topic.control_tower_notifications[0].name : null
}

output "service_role_arn" {
  description = "ARN of the Control Tower service role"
  value       = aws_iam_role.control_tower_service.arn
}

output "service_role_name" {
  description = "Name of the Control Tower service role"
  value       = aws_iam_role.control_tower_service.name
}

output "current_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "current_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

# Control Tower landing zone information (manual setup)
output "landing_zone_setup_instructions" {
  description = "Instructions for setting up Control Tower landing zone"
  value = {
    console_url = "https://console.aws.amazon.com/controltower/home/landingzone"
    requirements = [
      "Must be run from the management account",
      "Requires administrative permissions",
      "Home region should be ${var.region}",
      "Governed regions: ${join(", ", var.governed_regions)}"
    ]
    next_steps = [
      "1. Navigate to Control Tower console",
      "2. Choose 'Set up landing zone'",
      "3. Configure home region as ${var.region}",
      "4. Select governed regions: ${join(", ", var.governed_regions)}",
      "5. Configure core accounts (Audit, Log Archive)",
      "6. Review and launch landing zone"
    ]
  }
}
