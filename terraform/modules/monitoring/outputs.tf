# Outputs for Monitoring Module

output "organization_dashboard_url" {
  description = "URL for the organization overview dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.organization_overview.dashboard_name}"
}

output "security_dashboard_url" {
  description = "URL for the security monitoring dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.security_monitoring.dashboard_name}"
}

output "critical_alerts_topic_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = aws_sns_topic.critical_alerts.arn
}

output "security_alerts_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}

output "compliance_alerts_topic_arn" {
  description = "ARN of the compliance alerts SNS topic"
  value       = aws_sns_topic.compliance_alerts.arn
}

output "operational_alerts_topic_arn" {
  description = "ARN of the operational alerts SNS topic"
  value       = aws_sns_topic.operational_alerts.arn
}

output "cloudwatch_alarms" {
  description = "Map of created CloudWatch alarms"
  value = {
    high_severity_findings    = aws_cloudwatch_metric_alarm.high_severity_findings.arn
    critical_severity_findings = aws_cloudwatch_metric_alarm.critical_severity_findings.arn
    config_compliance_violations = aws_cloudwatch_metric_alarm.config_compliance_violations.arn
    guardduty_findings        = aws_cloudwatch_metric_alarm.guardduty_findings.arn
  }
}

output "log_groups" {
  description = "Map of created CloudWatch log groups"
  value = {
    security    = aws_cloudwatch_log_group.organization_security.name
    compliance  = aws_cloudwatch_log_group.organization_compliance.name
    operations  = aws_cloudwatch_log_group.organization_operations.name
  }
}

output "log_group_arns" {
  description = "Map of CloudWatch log group ARNs"
  value = {
    security    = aws_cloudwatch_log_group.organization_security.arn
    compliance  = aws_cloudwatch_log_group.organization_compliance.arn
    operations  = aws_cloudwatch_log_group.organization_operations.arn
  }
}

output "eventbridge_rules" {
  description = "Map of EventBridge rules"
  value = {
    organization_changes = aws_cloudwatch_event_rule.organization_changes.arn
  }
}

output "insights_queries" {
  description = "Map of CloudWatch Insights query definitions"
  value = {
    security_incidents     = aws_cloudwatch_query_definition.security_incidents.name
    compliance_violations  = aws_cloudwatch_query_definition.compliance_violations.name
  }
}

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    dashboards_created           = 2
    alarms_configured           = 4
    sns_topics_created          = 4
    log_groups_created          = 3
    eventbridge_rules_created   = 1
    insights_queries_created    = 2
    critical_email_subscribers  = length(var.critical_notification_emails)
    security_email_subscribers  = length(var.security_notification_emails)
    compliance_email_subscribers = length(var.compliance_notification_emails)
    operational_email_subscribers = length(var.operational_notification_emails)
    log_retention_days          = var.log_retention_days
    detailed_monitoring_enabled = var.enable_detailed_monitoring
    cost_monitoring_enabled     = var.enable_cost_monitoring
  }
}

output "dashboard_names" {
  description = "Names of created CloudWatch dashboards"
  value = {
    organization_overview = aws_cloudwatch_dashboard.organization_overview.dashboard_name
    security_monitoring   = aws_cloudwatch_dashboard.security_monitoring.dashboard_name
  }
}

output "alarm_names" {
  description = "Names of created CloudWatch alarms"
  value = {
    high_severity_findings       = aws_cloudwatch_metric_alarm.high_severity_findings.alarm_name
    critical_severity_findings   = aws_cloudwatch_metric_alarm.critical_severity_findings.alarm_name
    config_compliance_violations = aws_cloudwatch_metric_alarm.config_compliance_violations.alarm_name
    guardduty_findings          = aws_cloudwatch_metric_alarm.guardduty_findings.alarm_name
  }
}

output "sns_topic_names" {
  description = "Names of created SNS topics"
  value = {
    critical_alerts     = aws_sns_topic.critical_alerts.name
    security_alerts     = aws_sns_topic.security_alerts.name
    compliance_alerts   = aws_sns_topic.compliance_alerts.name
    operational_alerts  = aws_sns_topic.operational_alerts.name
  }
}

output "current_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

output "current_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
