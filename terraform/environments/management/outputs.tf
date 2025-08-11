# Outputs for Management Account Environment

# Organization Information
output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = module.aws_organizations.organization_id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization"
  value       = module.aws_organizations.organization_arn
}

output "organization_root_id" {
  description = "The ID of the organization root"
  value       = module.aws_organizations.organization_root_id
}

output "management_account_id" {
  description = "The ID of the management account"
  value       = module.aws_organizations.organization_master_account_id
}

output "management_account_email" {
  description = "The email of the management account"
  value       = module.aws_organizations.organization_master_account_email
}

# Organizational Units
output "organizational_units" {
  description = "Information about created organizational units"
  value       = module.aws_organizations.organizational_units
}

output "security_ou_id" {
  description = "The ID of the Security OU"
  value       = module.aws_organizations.organizational_units["security"].id
}

output "infrastructure_ou_id" {
  description = "The ID of the Infrastructure OU"
  value       = module.aws_organizations.organizational_units["infrastructure"].id
}

output "application_ou_id" {
  description = "The ID of the Application OU"
  value       = module.aws_organizations.organizational_units["application"].id
}

output "sandbox_ou_id" {
  description = "The ID of the Sandbox OU"
  value       = module.aws_organizations.organizational_units["sandbox"].id
}

# Policies
output "service_control_policies" {
  description = "Information about created Service Control Policies"
  value       = module.aws_organizations.service_control_policies
}

output "tag_policies" {
  description = "Information about created Tag Policies"
  value       = module.aws_organizations.tag_policies
}

# Infrastructure Resources
output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "organization_log_group_name" {
  description = "Name of the organization CloudWatch log group"
  value       = aws_cloudwatch_log_group.organization_logs.name
}

output "notification_topic_arn" {
  description = "ARN of the organization notification SNS topic"
  value       = aws_sns_topic.organization_notifications.arn
}

# Account Information
output "current_account_id" {
  description = "The current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "current_region" {
  description = "The current AWS region"
  value       = data.aws_region.current.name
}

# Guardrails Information
output "guardrails_summary" {
  description = "Summary of guardrails configuration"
  value       = module.guardrails.guardrails_summary
}

output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = module.guardrails.config_bucket_name
}

output "guardrail_notification_topic" {
  description = "ARN of the guardrail notifications SNS topic"
  value       = module.guardrails.notification_topic_arn
}

output "enabled_config_rules_count" {
  description = "Number of enabled AWS Config rules"
  value       = module.guardrails.enabled_config_rules_count
}

# Phase 1 Summary
output "phase_1_summary" {
  description = "Summary of Phase 1 implementation"
  value = {
    organization_created     = true
    organizational_units     = length(module.aws_organizations.organizational_units)
    service_control_policies = length(module.aws_organizations.service_control_policies)
    tag_policies            = length(module.aws_organizations.tag_policies)
    config_rules_enabled    = module.guardrails.enabled_config_rules_count
    cloudtrail_bucket       = aws_s3_bucket.cloudtrail_logs.bucket
    config_bucket           = module.guardrails.config_bucket_name
    notification_topic      = aws_sns_topic.organization_notifications.name
    guardrail_notifications = module.guardrails.notification_topic_arn
    phase_status           = "Foundation with Guardrails Complete"
  }
}
