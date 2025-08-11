# AWS Config Organization Aggregator Module

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# IAM role for organization aggregator (assumed by AWS Config)
resource "aws_iam_role" "config_aggregator" {
  name = "AWSConfigRole-OrganizationAggregator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

# Organization aggregator
resource "aws_config_configuration_aggregator" "org" {
  name = "organization-aggregator"

  organization_aggregation_source {
    all_regions = var.all_regions
    role_arn    = aws_iam_role.config_aggregator.arn
  }
}

