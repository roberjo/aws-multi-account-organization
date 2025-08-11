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

# Monitoring Information
output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value       = module.monitoring.monitoring_summary
}

output "organization_dashboard_url" {
  description = "URL for the organization overview dashboard"
  value       = module.monitoring.organization_dashboard_url
}

output "security_dashboard_url" {
  description = "URL for the security monitoring dashboard"
  value       = module.monitoring.security_dashboard_url
}

output "monitoring_topics" {
  description = "SNS topics for different alert levels"
  value = {
    critical_alerts     = module.monitoring.critical_alerts_topic_arn
    security_alerts     = module.monitoring.security_alerts_topic_arn
    compliance_alerts   = module.monitoring.compliance_alerts_topic_arn
    operational_alerts  = module.monitoring.operational_alerts_topic_arn
  }
}

# Phase 2 Outputs
output "security_hub_admin_account" {
  description = "Security Hub admin account ID"
  value       = module.security_hub_org.securityhub_admin_account_id
}

output "security_hub_standards" {
  description = "Security Hub standards enabled"
  value       = module.security_hub_org.standards_subscribed
}

output "config_org_aggregator" {
  description = "AWS Config organization aggregator name"
  value       = module.aws_config_org.aggregator_name
}

output "org_cloudtrail_trail" {
  description = "Organization CloudTrail trail name"
  value       = module.cloudtrail_org.trail_name
}

output "org_cloudtrail_bucket" {
  description = "Organization CloudTrail S3 bucket"
  value       = module.cloudtrail_org.trail_bucket
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
    monitoring_dashboards   = 2
    cloudwatch_alarms       = 4
    sns_topics_created      = 6
    cloudtrail_bucket       = aws_s3_bucket.cloudtrail_logs.bucket
    config_bucket           = module.guardrails.config_bucket_name
    notification_topic      = aws_sns_topic.organization_notifications.name
    guardrail_notifications = module.guardrails.notification_topic_arn
    organization_dashboard  = module.monitoring.organization_dashboard_url
    security_dashboard      = module.monitoring.security_dashboard_url
    phase_status           = "Phase 1 Complete - Foundation, Guardrails, and Monitoring"
  }
}
