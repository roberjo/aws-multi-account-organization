# Monitoring Module
# Comprehensive monitoring and alerting for AWS Organization

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Dashboard for Organization Overview
resource "aws_cloudwatch_dashboard" "organization_overview" {
  dashboard_name = "AWS-Organization-Overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Organizations", "TotalAccounts"],
            ["AWS/Organizations", "ActiveAccounts"],
            ["AWS/Organizations", "SuspendedAccounts"]
          ]
          period = 300
          stat   = "Maximum"
          region = var.region
          title  = "Organization Account Status"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Config", "ComplianceByConfigRule", "ComplianceType", "COMPLIANT"],
            ["AWS/Config", "ComplianceByConfigRule", "ComplianceType", "NON_COMPLIANT"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "Config Rule Compliance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        
        properties = {
          metrics = [
            ["AWS/SecurityHub", "Findings", "ProductName", "Security Hub", "ComplianceStatus", "PASSED"],
            ["AWS/SecurityHub", "Findings", "ProductName", "Security Hub", "ComplianceStatus", "FAILED"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "Security Hub Findings"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        
        properties = {
          metrics = [
            ["AWS/GuardDuty", "FindingCount"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "GuardDuty Findings"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        
        properties = {
          metrics = [
            ["AWS/CloudTrail", "DataEvents"],
            ["AWS/CloudTrail", "ManagementEvents"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "CloudTrail Activity"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        
        properties = {
          query = "SOURCE '/aws/organizations' | fields @timestamp, eventName, sourceIPAddress, userIdentity.type\n| filter eventName like /Create|Delete|Update/\n| sort @timestamp desc\n| limit 20"
          region = var.region
          title = "Recent Organization Changes"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "Organization Overview Dashboard"
    Purpose = "High-level organization monitoring"
  })
}

# CloudWatch Dashboard for Security Monitoring
resource "aws_cloudwatch_dashboard" "security_monitoring" {
  dashboard_name = "AWS-Organization-Security"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/SecurityHub", "Findings", "SeverityLabel", "CRITICAL"],
            ["AWS/SecurityHub", "Findings", "SeverityLabel", "HIGH"],
            ["AWS/SecurityHub", "Findings", "SeverityLabel", "MEDIUM"],
            ["AWS/SecurityHub", "Findings", "SeverityLabel", "LOW"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "Security Hub Findings by Severity"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/GuardDuty", "FindingCount", "ThreatListName", "ProofPointThreatList"],
            ["AWS/GuardDuty", "FindingCount", "ThreatListName", "CrowdStrikeThreatList"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "GuardDuty Threat Intelligence"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        
        properties = {
          query = "SOURCE '/aws/guardrails/violations' | fields @timestamp, configRuleName, resourceId, complianceType\n| filter complianceType = \"NON_COMPLIANT\"\n| sort @timestamp desc\n| limit 20"
          region = var.region
          title = "Recent Guardrail Violations"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "Security Monitoring Dashboard"
    Purpose = "Security-focused monitoring"
  })
}

# CloudWatch Alarms for Critical Events
resource "aws_cloudwatch_metric_alarm" "high_severity_findings" {
  alarm_name          = "high-severity-security-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Findings"
  namespace           = "AWS/SecurityHub"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High severity security findings detected"
  
  dimensions = {
    SeverityLabel = "HIGH"
  }
  
  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = merge(var.tags, {
    Name     = "High Severity Findings Alarm"
    Severity = "Critical"
  })
}

resource "aws_cloudwatch_metric_alarm" "critical_severity_findings" {
  alarm_name          = "critical-security-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Findings"
  namespace           = "AWS/SecurityHub"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Critical severity security findings detected"
  
  dimensions = {
    SeverityLabel = "CRITICAL"
  }
  
  alarm_actions = [aws_sns_topic.critical_alerts.arn]

  tags = merge(var.tags, {
    Name     = "Critical Findings Alarm"
    Severity = "Critical"
  })
}

resource "aws_cloudwatch_metric_alarm" "config_compliance_violations" {
  alarm_name          = "config-compliance-violations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ComplianceByConfigRule"
  namespace           = "AWS/Config"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High number of Config compliance violations"
  
  dimensions = {
    ComplianceType = "NON_COMPLIANT"
  }
  
  alarm_actions = [aws_sns_topic.compliance_alerts.arn]

  tags = merge(var.tags, {
    Name     = "Config Compliance Alarm"
    Severity = "High"
  })
}

resource "aws_cloudwatch_metric_alarm" "guardduty_findings" {
  alarm_name          = "guardduty-threat-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FindingCount"
  namespace           = "AWS/GuardDuty"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "GuardDuty threat findings detected"
  
  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = merge(var.tags, {
    Name     = "GuardDuty Findings Alarm"
    Severity = "High"
  })
}

# SNS Topics for Different Alert Levels
resource "aws_sns_topic" "critical_alerts" {
  name = "organization-critical-alerts"

  tags = merge(var.tags, {
    Name     = "Critical Alerts"
    Severity = "Critical"
  })
}

resource "aws_sns_topic" "security_alerts" {
  name = "organization-security-alerts"

  tags = merge(var.tags, {
    Name     = "Security Alerts"
    Severity = "High"
  })
}

resource "aws_sns_topic" "compliance_alerts" {
  name = "organization-compliance-alerts"

  tags = merge(var.tags, {
    Name     = "Compliance Alerts"
    Severity = "Medium"
  })
}

resource "aws_sns_topic" "operational_alerts" {
  name = "organization-operational-alerts"

  tags = merge(var.tags, {
    Name     = "Operational Alerts"
    Severity = "Low"
  })
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "critical_email" {
  for_each = toset(var.critical_notification_emails)
  
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "security_email" {
  for_each = toset(var.security_notification_emails)
  
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "compliance_email" {
  for_each = toset(var.compliance_notification_emails)
  
  topic_arn = aws_sns_topic.compliance_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "operational_email" {
  for_each = toset(var.operational_notification_emails)
  
  topic_arn = aws_sns_topic.operational_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# EventBridge Rules for Organization Events
resource "aws_cloudwatch_event_rule" "organization_changes" {
  name        = "organization-changes"
  description = "Capture organization structure changes"

  event_pattern = jsonencode({
    source = ["aws.organizations"]
    detail-type = [
      "AWS Organizations Account State Change",
      "AWS Organizations OU State Change",
      "AWS Organizations Policy State Change"
    ]
  })

  tags = merge(var.tags, {
    Name    = "Organization Changes Rule"
    Purpose = "Monitor organization structure changes"
  })
}

resource "aws_cloudwatch_event_target" "organization_changes_sns" {
  rule      = aws_cloudwatch_event_rule.organization_changes.name
  target_id = "OrganizationChangesSNS"
  arn       = aws_sns_topic.operational_alerts.arn
}

# CloudWatch Log Groups for Centralized Logging
resource "aws_cloudwatch_log_group" "organization_security" {
  name              = "/aws/organization/security"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "Organization Security Logs"
    Purpose = "Centralized security event logging"
  })
}

resource "aws_cloudwatch_log_group" "organization_compliance" {
  name              = "/aws/organization/compliance"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "Organization Compliance Logs"
    Purpose = "Centralized compliance event logging"
  })
}

resource "aws_cloudwatch_log_group" "organization_operations" {
  name              = "/aws/organization/operations"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "Organization Operations Logs"
    Purpose = "Centralized operations event logging"
  })
}

# CloudWatch Insights Queries
resource "aws_cloudwatch_query_definition" "security_incidents" {
  name = "Security Incidents"

  log_group_names = [
    aws_cloudwatch_log_group.organization_security.name,
    "/aws/guardrails/violations"
  ]

  query_string = <<EOF
fields @timestamp, eventName, sourceIPAddress, userIdentity.type, errorCode
| filter eventName like /Delete|Terminate|Stop|Disable/
| sort @timestamp desc
| limit 50
EOF
}

resource "aws_cloudwatch_query_definition" "compliance_violations" {
  name = "Compliance Violations"

  log_group_names = [
    aws_cloudwatch_log_group.organization_compliance.name
  ]

  query_string = <<EOF
fields @timestamp, configRuleName, resourceId, complianceType, resourceType
| filter complianceType = "NON_COMPLIANT"
| stats count() by configRuleName
| sort count desc
EOF
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
