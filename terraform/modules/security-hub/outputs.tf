output "securityhub_admin_account_id" {
  description = "Security Hub admin account ID"
  value       = aws_securityhub_organization_admin_account.this.admin_account_id
}

output "standards_subscribed" {
  description = "List of standards subscribed"
  value       = [for s in aws_securityhub_standards_subscription.selected : s.standards_arn]
}

output "organization_auto_enable" {
  description = "Whether organization auto-enable is configured"
  value       = aws_securityhub_organization_configuration.org_config.auto_enable
}

