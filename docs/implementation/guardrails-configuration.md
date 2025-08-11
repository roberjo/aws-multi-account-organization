# Guardrails Configuration Guide

## Overview

AWS Control Tower Guardrails provide ongoing governance for your AWS multi-account environment. This guide covers the implementation of both Control Tower guardrails and custom AWS Config rules for comprehensive compliance monitoring.

## Guardrails Architecture

### Types of Guardrails

1. **Preventive Guardrails** - Block non-compliant actions using Service Control Policies (SCPs)
2. **Detective Guardrails** - Monitor and alert on violations using AWS Config rules
3. **Custom Guardrails** - Organization-specific compliance rules using AWS Config

### Implementation Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    GUARDRAILS ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                CONTROL TOWER GUARDRAILS                 │ │
│  │                                                         │ │
│  │ • Mandatory Guardrails (Always On)                     │ │
│  │ • Strongly Recommended Guardrails                      │ │
│  │ • Elective Guardrails                                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                CUSTOM CONFIG RULES                      │ │
│  │                                                         │ │
│  │ • S3 Bucket Security Rules                              │ │
│  │ • EC2 Security Rules                                    │ │
│  │ • IAM Security Rules                                    │ │
│  │ • Network Security Rules                                │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                AUTO-REMEDIATION                         │ │
│  │                                                         │ │
│  │ • Lambda-based Remediation                              │ │
│  │ • EventBridge Integration                               │ │
│  │ • SNS Notifications                                     │ │
│  │ • CloudWatch Logging                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Mandatory Guardrails

### Control Tower Mandatory Guardrails

These guardrails are automatically enabled when you set up Control Tower:

1. **AWS-GR_AUDIT_BUCKET_PUBLIC_READ_PROHIBITED**
   - Prevents public read access to audit bucket
   - Type: Preventive
   - Level: Mandatory

2. **AWS-GR_AUDIT_BUCKET_PUBLIC_WRITE_PROHIBITED**
   - Prevents public write access to audit bucket
   - Type: Preventive
   - Level: Mandatory

3. **AWS-GR_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS**
   - Ensures CloudTrail is enabled on member accounts
   - Type: Detective
   - Level: Mandatory

4. **AWS-GR_LOG_GROUP_POLICY**
   - Manages log group policies
   - Type: Preventive
   - Level: Mandatory

5. **AWS-GR_MFA_ENABLED_FOR_ROOT_USER**
   - Detects if MFA is enabled for root user
   - Type: Detective
   - Level: Mandatory

## Phase 2: Strongly Recommended Guardrails

### Network Security Guardrails

```json
{
  "guardrails": [
    {
      "name": "AWS-GR_RESTRICTED_COMMON_PORTS",
      "description": "Disallow unrestricted incoming traffic on common ports",
      "type": "Preventive",
      "ports": ["20", "21", "3389", "3306", "4333"]
    },
    {
      "name": "AWS-GR_RESTRICTED_SSH",
      "description": "Disallow unrestricted incoming SSH traffic",
      "type": "Preventive",
      "port": "22"
    },
    {
      "name": "AWS-GR_DISALLOW_VPC_INTERNET_ACCESS",
      "description": "Disallow internet access for VPCs",
      "type": "Preventive",
      "scope": "VPC"
    }
  ]
}
```

### S3 Security Guardrails

```json
{
  "guardrails": [
    {
      "name": "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED",
      "description": "Detect whether public read access to S3 buckets is prohibited",
      "type": "Detective",
      "service": "S3"
    },
    {
      "name": "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED", 
      "description": "Detect whether public write access to S3 buckets is prohibited",
      "type": "Detective",
      "service": "S3"
    },
    {
      "name": "AWS-GR_S3_BUCKET_SSL_REQUESTS_ONLY",
      "description": "Require SSL requests for S3 bucket access",
      "type": "Detective",
      "service": "S3"
    }
  ]
}
```

## Custom Config Rules Implementation

### Terraform Configuration

```hcl
# Enable guardrails module in management environment
module "guardrails" {
  source = "../../modules/guardrails"

  enable_notifications    = true
  notification_endpoints  = ["security@company.com", "devops@company.com"]
  enable_auto_remediation = true
  
  target_organizational_units = [
    "Security OU",
    "Infrastructure OU", 
    "Application OU"
  ]
  
  compliance_frameworks = ["SOC2", "PCI-DSS", "CIS"]
  log_retention_days   = 90

  tags = {
    Environment = "Management"
    Owner       = "Security"
    Project     = "AWS Organization"
    Phase       = "1-Foundation"
  }
}
```

### Custom Config Rules

#### 1. S3 Bucket Encryption
```hcl
s3_bucket_server_side_encryption_enabled = {
  source_owner      = "AWS"
  source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
}
```

#### 2. Security Group SSH Restriction
```hcl
incoming_ssh_disabled = {
  source_owner      = "AWS"
  source_identifier = "INCOMING_SSH_DISABLED"
}
```

#### 3. Root User Access Keys
```hcl
root_access_key_check = {
  source_owner      = "AWS"
  source_identifier = "ROOT_ACCESS_KEY_CHECK"
}
```

#### 4. VPC Flow Logs
```hcl
vpc_flow_logs_enabled = {
  source_owner      = "AWS"
  source_identifier = "VPC_FLOW_LOGS_ENABLED"
}
```

## Auto-Remediation Implementation

### Supported Remediation Actions

1. **S3 Public Access Block**
   - Automatically enables public access block for S3 buckets
   - Triggers on: S3_BUCKET_PUBLIC_ACCESS_PROHIBITED violations

2. **S3 Bucket Encryption**
   - Enables default AES256 encryption for S3 buckets
   - Triggers on: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED violations

3. **Security Group SSH Remediation**
   - Removes unrestricted SSH access (0.0.0.0/0:22)
   - Triggers on: INCOMING_SSH_DISABLED violations

4. **VPC Flow Logs**
   - Enables VPC Flow Logs for non-compliant VPCs
   - Triggers on: VPC_FLOW_LOGS_ENABLED violations

### Lambda Remediation Function

The auto-remediation Lambda function processes Config compliance events:

```python
def lambda_handler(event, context):
    """
    Main handler for guardrail auto-remediation
    """
    detail = event.get('detail', {})
    config_rule_name = detail.get('configRuleName', '')
    compliance_type = detail.get('newEvaluationResult', {}).get('complianceType', '')
    resource_type = detail.get('resourceType', '')
    resource_id = detail.get('resourceId', '')
    
    if compliance_type == 'NON_COMPLIANT':
        remediation_result = route_remediation(
            config_rule_name, resource_type, resource_id, detail
        )
        
        # Send notification
        send_notification(sns_topic_arn, config_rule_name, resource_id, remediation_result)
```

## Deployment Process

### Step 1: Deploy Guardrails Module

```powershell
# Navigate to management environment
Set-Location terraform\environments\management

# Update terraform.tfvars
$tfvarsContent = @"
notification_endpoints = ["security@company.com", "devops@company.com"]
enable_auto_remediation = true
"@

$tfvarsContent | Add-Content terraform.tfvars

# Deploy the configuration
terraform plan
terraform apply
```

### Step 2: Enable Control Tower Guardrails

1. **Navigate to Control Tower Console**
   ```
   https://console.aws.amazon.com/controltower/home/guardrails
   ```

2. **Enable Strongly Recommended Guardrails**
   - Select each guardrail from the "Strongly recommended" section
   - Click "Enable guardrail"
   - Select target OUs
   - Confirm enablement

3. **Configure Elective Guardrails**
   - Review elective guardrails based on compliance requirements
   - Enable relevant guardrails for specific OUs

### Step 3: Configure Notifications

```powershell
# Subscribe to SNS topics for notifications
aws sns subscribe \
  --topic-arn "arn:aws:sns:us-east-1:ACCOUNT:guardrail-violations" \
  --protocol email \
  --notification-endpoint "security@company.com"

aws sns subscribe \
  --topic-arn "arn:aws:sns:us-east-1:ACCOUNT:organization-notifications" \
  --protocol email \
  --notification-endpoint "devops@company.com"
```

## Monitoring and Alerting

### CloudWatch Dashboard

Create a comprehensive monitoring dashboard:

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Config", "ComplianceByConfigRule", "ConfigRuleName", "s3-bucket-server-side-encryption-enabled"],
          ["AWS/Config", "ComplianceByConfigRule", "ConfigRuleName", "incoming-ssh-disabled"],
          ["AWS/Config", "ComplianceByConfigRule", "ConfigRuleName", "vpc-flow-logs-enabled"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Config Rule Compliance"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/guardrails/violations' | fields @timestamp, configRuleName, resourceId, complianceType\n| filter complianceType = \"NON_COMPLIANT\"\n| sort @timestamp desc\n| limit 20",
        "region": "us-east-1",
        "title": "Recent Guardrail Violations"
      }
    }
  ]
}
```

### Automated Reporting

```powershell
# Create weekly compliance report
aws config get-compliance-summary-by-config-rule \
  --output table \
  --query 'ComplianceSummary.{Rule:ConfigRuleName,Compliant:ComplianceByConfigRule.COMPLIANT,NonCompliant:ComplianceByConfigRule.NON_COMPLIANT}'
```

## Compliance Frameworks

### SOC 2 Type II Mapping

| Control | Guardrail | Type | Status |
|---------|-----------|------|---------|
| CC6.1 | S3_BUCKET_PUBLIC_ACCESS_PROHIBITED | Detective | ✅ Enabled |
| CC6.2 | INCOMING_SSH_DISABLED | Detective | ✅ Enabled |
| CC6.3 | VPC_FLOW_LOGS_ENABLED | Detective | ✅ Enabled |
| CC6.4 | ROOT_ACCESS_KEY_CHECK | Detective | ✅ Enabled |

### PCI DSS Mapping

| Requirement | Guardrail | Implementation | Status |
|-------------|-----------|----------------|---------|
| 1.1.4 | Security Group Rules | Config Rule | ✅ Enabled |
| 2.1 | Default Passwords | Custom Rule | 🟡 Planned |
| 3.4 | Data Encryption | S3 Encryption Rule | ✅ Enabled |
| 10.1 | Audit Logs | CloudTrail Enabled | ✅ Enabled |

## Troubleshooting

### Common Issues

#### Issue 1: Config Rules Not Evaluating
**Symptoms:** Config rules show as "No results reported"
**Solution:**
```powershell
# Check Config recorder status
aws config describe-configuration-recorders

# Start Config recorder if stopped
aws config start-configuration-recorder --configuration-recorder-name default
```

#### Issue 2: Auto-Remediation Not Working
**Symptoms:** Violations detected but no remediation occurs
**Solution:**
```powershell
# Check Lambda function logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/guardrail-auto-remediation" \
  --start-time $(date -d '1 hour ago' +%s)000

# Check EventBridge rule
aws events list-rules --name-prefix "config-compliance"
```

#### Issue 3: False Positive Violations
**Symptoms:** Resources flagged as non-compliant when they should be compliant
**Solution:**
```powershell
# Re-evaluate specific Config rule
aws config start-config-rules-evaluation --config-rule-names "rule-name"

# Check resource configuration
aws config get-resource-config-history \
  --resource-type "AWS::S3::Bucket" \
  --resource-id "bucket-name"
```

## Best Practices

### 1. Guardrail Selection
- Start with mandatory and strongly recommended guardrails
- Gradually add elective guardrails based on compliance needs
- Test guardrails in sandbox environment first

### 2. Notification Management
- Use separate SNS topics for different severity levels
- Implement email filtering rules for guardrail notifications
- Set up escalation procedures for critical violations

### 3. Auto-Remediation
- Enable auto-remediation only for well-understood violations
- Always test remediation actions in non-production first
- Maintain manual override capabilities

### 4. Regular Reviews
- Monthly review of guardrail violations and trends
- Quarterly assessment of guardrail effectiveness
- Annual review of compliance framework alignment

## Next Steps

### Phase 1 Completion
- ✅ Deploy guardrails module
- ✅ Enable Control Tower guardrails
- ✅ Configure notifications and monitoring
- ✅ Test auto-remediation functions

### Phase 2 Preparation
- 🟡 Security Hub integration
- 🟡 Advanced compliance reporting
- 🟡 Custom remediation workflows
- 🟡 Cross-account guardrail management

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Next Review:** January 2025
