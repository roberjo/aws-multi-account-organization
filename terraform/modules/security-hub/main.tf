# Security Hub Module (Organization)
# Enables Security Hub organization administrator and manages members

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Enable Security Hub in the current (management) account
resource "aws_securityhub_account" "this" {
  enable_default_standards = var.enable_default_standards
}

# Designate this account as the Security Hub organization admin
resource "aws_securityhub_organization_admin_account" "this" {
  admin_account_id = data.aws_caller_identity.current.account_id
}

# Standards subscriptions
resource "aws_securityhub_standards_subscription" "selected" {
  for_each = toset(var.standards_arns)

  standards_arn = each.value
  depends_on    = [aws_securityhub_account.this]
}

# Organization-wide auto enable
resource "aws_securityhub_organization_configuration" "org_config" {
  auto_enable = true
  depends_on  = [aws_securityhub_organization_admin_account.this]
}

# Optional explicit member accounts management (if provided)
resource "aws_securityhub_member" "members" {
  for_each  = var.member_accounts
  account_id = each.value.account_id
  email      = each.value.email
  invite     = true

  depends_on = [aws_securityhub_organization_admin_account.this]
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

