# Outputs for AWS Organizations Module

output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization"
  value       = aws_organizations_organization.main.arn
}

output "organization_master_account_arn" {
  description = "The ARN of the master account"
  value       = aws_organizations_organization.main.master_account_arn
}

output "organization_master_account_email" {
  description = "The email address of the master account"
  value       = aws_organizations_organization.main.master_account_email
}

output "organization_master_account_id" {
  description = "The ID of the master account"
  value       = aws_organizations_organization.main.master_account_id
}

output "organization_root_id" {
  description = "The ID of the organization root"
  value       = aws_organizations_organization.main.roots[0].id
}

output "organizational_units" {
  description = "Map of created organizational units"
  value = {
    for k, v in aws_organizations_organizational_unit.ous : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "service_control_policies" {
  description = "Map of created Service Control Policies"
  value = {
    for k, v in aws_organizations_policy.scps : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "tag_policies" {
  description = "Map of created Tag Policies"
  value = {
    for k, v in aws_organizations_policy.tag_policies : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "current_account_id" {
  description = "The current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "current_region" {
  description = "The current AWS region"
  value       = data.aws_region.current.name
}
