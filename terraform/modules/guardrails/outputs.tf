# Outputs for Guardrails Module

output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config_bucket.bucket
}

output "config_bucket_arn" {
  description = "ARN of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config_bucket.arn
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.recorder.name
}

output "config_delivery_channel_name" {
  description = "Name of the AWS Config delivery channel"
  value       = aws_config_delivery_channel.channel.name
}

output "config_rules" {
  description = "Map of created AWS Config rules"
  value = {
    for k, v in aws_config_config_rule.custom_guardrails : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "config_role_arn" {
  description = "ARN of the AWS Config service role"
  value       = aws_iam_role.config_role.arn
}

output "guardrail_violations_log_group" {
  description = "Name of the guardrail violations log group"
  value       = aws_cloudwatch_log_group.guardrail_violations.name
}

output "guardrail_violations_log_group_arn" {
  description = "ARN of the guardrail violations log group"
  value       = aws_cloudwatch_log_group.guardrail_violations.arn
}

output "compliance_event_rule_name" {
  description = "Name of the Config compliance EventBridge rule"
  value       = aws_cloudwatch_event_rule.config_compliance.name
}

output "compliance_event_rule_arn" {
  description = "ARN of the Config compliance EventBridge rule"
  value       = aws_cloudwatch_event_rule.config_compliance.arn
}

output "notification_topic_arn" {
  description = "ARN of the guardrail notifications SNS topic"
  value       = var.enable_notifications ? aws_sns_topic.guardrail_notifications[0].arn : null
}

output "notification_topic_name" {
  description = "Name of the guardrail notifications SNS topic"
  value       = var.enable_notifications ? aws_sns_topic.guardrail_notifications[0].name : null
}

output "remediation_function_name" {
  description = "Name of the auto-remediation Lambda function"
  value       = var.enable_auto_remediation ? aws_lambda_function.guardrail_remediation[0].function_name : null
}

output "remediation_function_arn" {
  description = "ARN of the auto-remediation Lambda function"
  value       = var.enable_auto_remediation ? aws_lambda_function.guardrail_remediation[0].arn : null
}

output "enabled_config_rules_count" {
  description = "Number of enabled AWS Config rules"
  value       = length(aws_config_config_rule.custom_guardrails)
}

output "mandatory_guardrails" {
  description = "List of mandatory Control Tower guardrails"
  value       = var.mandatory_guardrails
}

output "strongly_recommended_guardrails" {
  description = "List of strongly recommended Control Tower guardrails"
  value       = var.strongly_recommended_guardrails
}

output "target_organizational_units" {
  description = "List of OUs where guardrails are applied"
  value       = var.target_organizational_units
}

output "compliance_frameworks" {
  description = "List of enabled compliance frameworks"
  value       = var.compliance_frameworks
}

output "guardrails_summary" {
  description = "Summary of guardrails configuration"
  value = {
    config_rules_enabled      = length(aws_config_config_rule.custom_guardrails)
    notifications_enabled     = var.enable_notifications
    auto_remediation_enabled  = var.enable_auto_remediation
    target_ous               = length(var.target_organizational_units)
    compliance_frameworks    = length(var.compliance_frameworks)
    log_retention_days       = var.log_retention_days
  }
}
