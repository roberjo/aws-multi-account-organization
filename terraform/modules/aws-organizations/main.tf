# AWS Organizations Module
# Creates and manages AWS Organizations structure

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create the organization
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = "ALL"

  tags = var.tags
}

# Create organizational units
resource "aws_organizations_organizational_unit" "ous" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = merge(var.tags, {
    Name = each.value.name
    Type = "OrganizationalUnit"
  })
}

# Create Service Control Policies
resource "aws_organizations_policy" "scps" {
  for_each = var.service_control_policies

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.content

  tags = merge(var.tags, {
    Name = each.value.name
    Type = "ServiceControlPolicy"
  })
}

# Attach SCPs to organizational units
resource "aws_organizations_policy_attachment" "scp_attachments" {
  for_each = {
    for attachment in local.scp_attachments : "${attachment.policy_key}-${attachment.ou_key}" => attachment
  }

  policy_id = aws_organizations_policy.scps[each.value.policy_key].id
  target_id = aws_organizations_organizational_unit.ous[each.value.ou_key].id
}

# Create Tag Policies
resource "aws_organizations_policy" "tag_policies" {
  for_each = var.tag_policies

  name        = each.value.name
  description = each.value.description
  type        = "TAG_POLICY"
  content     = each.value.content

  tags = merge(var.tags, {
    Name = each.value.name
    Type = "TagPolicy"
  })
}

# Attach tag policies to organizational units
resource "aws_organizations_policy_attachment" "tag_policy_attachments" {
  for_each = {
    for attachment in local.tag_policy_attachments : "${attachment.policy_key}-${attachment.ou_key}" => attachment
  }

  policy_id = aws_organizations_policy.tag_policies[each.value.policy_key].id
  target_id = aws_organizations_organizational_unit.ous[each.value.ou_key].id
}

# Local values for policy attachments
locals {
  # Create SCP attachments based on policy configuration
  scp_attachments = flatten([
    for policy_key, policy in var.service_control_policies : [
      for ou_key in policy.target_ous : {
        policy_key = policy_key
        ou_key     = ou_key
      }
    ]
  ])

  # Create tag policy attachments
  tag_policy_attachments = flatten([
    for policy_key, policy in var.tag_policies : [
      for ou_key in policy.target_ous : {
        policy_key = policy_key
        ou_key     = ou_key
      }
    ]
  ])
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}
