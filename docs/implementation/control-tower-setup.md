# Control Tower Setup Guide

## Overview

AWS Control Tower provides an automated way to set up and govern a secure, multi-account AWS environment. This guide covers the setup process for Phase 1 of the Enterprise Multi-Account AWS Organization project.

## Prerequisites

### Account Requirements
- **Management Account:** Must be the organization's management account
- **Administrative Access:** Full administrative permissions required
- **Clean Environment:** No existing Control Tower deployment
- **Service Limits:** Ensure adequate service limits for multi-account setup

### Regional Requirements
- **Home Region:** us-east-1 (recommended for global services)
- **Governed Regions:** us-east-1, us-west-2 (can be expanded later)
- **Service Availability:** Control Tower must be available in selected regions

## Phase 1: Control Tower Landing Zone Setup

### Step 1: Pre-Setup Verification

Before setting up Control Tower, verify the following:

```powershell
# Verify current account is the management account
aws organizations describe-organization --query 'Organization.MasterAccountId'

# Verify no existing Control Tower deployment
aws controltower list-landing-zones --region us-east-1

# Check service quotas
aws service-quotas get-service-quota --service-code organizations --quota-code L-0710851D
```

### Step 2: Navigate to Control Tower Console

1. Open the AWS Management Console
2. Navigate to AWS Control Tower: https://console.aws.amazon.com/controltower/
3. Ensure you're in the us-east-1 region (N. Virginia)

### Step 3: Set Up Landing Zone

#### 3.1 Choose Landing Zone Configuration

1. Click **"Set up landing zone"**
2. Select **"Set up landing zone"** (not "Enroll existing organization")

#### 3.2 Configure Home Region

- **Home Region:** us-east-1 (N. Virginia)
- **Governed Regions:** 
  - us-east-1 (N. Virginia) - Required
  - us-west-2 (Oregon) - Additional

#### 3.3 Configure Core Accounts

**Audit Account:**
- **Account Name:** Audit
- **Account Email:** audit@company.com
- **Purpose:** Centralized audit and compliance monitoring

**Log Archive Account:**
- **Account Name:** Log Archive  
- **Account Email:** log-archive@company.com
- **Purpose:** Centralized logging and log retention

#### 3.4 Configure Additional Settings

**CloudTrail Configuration:**
- ✅ Enable organization-wide CloudTrail
- ✅ Enable CloudTrail insights
- **S3 Bucket:** aws-controltower-logs-{account-id}-{region}

**AWS Config Configuration:**
- ✅ Enable AWS Config in all accounts and regions
- ✅ Enable configuration history and snapshots

**Access Logging:**
- ✅ Enable access logging
- **S3 Bucket:** aws-controltower-s3-access-logs-{account-id}-{region}

### Step 4: Review and Launch

1. Review all configuration settings
2. Acknowledge the following:
   - Landing zone setup will take 60-90 minutes
   - Core accounts will be created automatically
   - Guardrails will be enabled automatically
   - Billing will be consolidated under the management account

3. Click **"Set up landing zone"**

### Step 5: Monitor Setup Progress

The landing zone setup process includes:

1. **Account Creation** (10-15 minutes)
   - Audit account creation
   - Log Archive account creation

2. **Service Configuration** (30-45 minutes)
   - CloudTrail setup across all accounts
   - AWS Config configuration
   - S3 bucket creation and policy setup

3. **Guardrail Deployment** (15-30 minutes)
   - Mandatory guardrails activation
   - Service Control Policy deployment
   - Cross-account role setup

4. **Verification and Testing** (5-10 minutes)
   - Account access verification
   - Service functionality testing

## Phase 1: Post-Setup Configuration

### Step 6: Verify Landing Zone Deployment

```powershell
# Run the verification script
.\scripts\verify-control-tower.ps1

# Check landing zone status
aws controltower get-landing-zone --landing-zone-identifier {landing-zone-id}

# Verify core accounts
aws organizations list-accounts --query 'Accounts[?contains(Name, `Audit`) || contains(Name, `Log`)]'
```

### Step 7: Configure Additional Guardrails

After the landing zone is deployed, configure additional guardrails:

#### Strongly Recommended Guardrails

1. **Disallow internet access for an RDS database instance**
2. **Disallow unrestricted incoming TCP traffic**
3. **Disallow unrestricted incoming SSH traffic**
4. **Require MFA to delete CloudTrail**
5. **Disallow public read access to S3 buckets**

#### Configuration Steps

1. Navigate to Control Tower > Guardrails
2. Select each guardrail from the "Strongly recommended" section
3. Click **"Enable guardrail"**
4. Select target OUs (apply to all OUs initially)
5. Click **"Enable guardrail"**

### Step 8: Set Up Account Factory

Configure the Account Factory for automated account provisioning:

1. Navigate to Control Tower > Account Factory
2. Configure account factory settings:
   - **Account name prefix:** org-
   - **Email domain:** company.com
   - **Default OU:** Sandbox OU (for new accounts)

## Monitoring and Maintenance

### CloudWatch Dashboard

Create a dashboard to monitor Control Tower:

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ControlTower", "LandingZoneStatus"],
          ["AWS/ControlTower", "GuardrailViolations"],
          ["AWS/ControlTower", "AccountProvisioningStatus"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Control Tower Status"
      }
    }
  ]
}
```

### Automated Monitoring

Set up automated monitoring using the provided Terraform module:

```powershell
# Navigate to management environment
Set-Location terraform\environments\management

# Add Control Tower module to main.tf
# module "control_tower" {
#   source = "../../modules/control-tower"
#   
#   account_id              = data.aws_caller_identity.current.account_id
#   region                  = var.region
#   enable_notifications    = true
#   notification_endpoints  = ["admin@company.com"]
#   governed_regions       = ["us-east-1", "us-west-2"]
#   
#   tags = var.default_tags
# }

# Apply the configuration
terraform plan
terraform apply
```

## Troubleshooting

### Common Issues

#### Issue 1: Landing Zone Setup Fails
**Symptoms:** Setup process stops or fails during deployment
**Solution:**
```powershell
# Check service limits
aws service-quotas get-service-quota --service-code organizations --quota-code L-0710851D

# Verify permissions
aws iam get-user --user-name $(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)

# Check for existing resources that might conflict
aws s3 ls | Select-String "aws-controltower"
```

#### Issue 2: Core Account Creation Fails
**Symptoms:** Audit or Log Archive accounts not created
**Solution:**
```powershell
# Check organization status
aws organizations describe-organization

# Verify email addresses are unique and valid
aws organizations list-accounts --query 'Accounts[].Email'

# Check for email conflicts
```

#### Issue 3: Guardrail Deployment Issues
**Symptoms:** Guardrails not applying or showing violations
**Solution:**
```powershell
# Check guardrail status
aws controltower list-enabled-guardrails --landing-zone-identifier {landing-zone-id}

# Review CloudTrail logs for guardrail events
aws logs filter-log-events --log-group-name /aws/controltower --filter-pattern "guardrail"
```

### Support Resources

- **AWS Control Tower Documentation:** https://docs.aws.amazon.com/controltower/
- **AWS Support:** Create a support case for Control Tower issues
- **AWS re:Post:** Community support for Control Tower questions

## Next Steps

After Control Tower setup is complete:

1. **Verify all components** using the verification script
2. **Configure additional guardrails** based on security requirements
3. **Set up Account Factory** for automated account provisioning
4. **Proceed to Phase 2:** Security & Compliance implementation
5. **Train team members** on Control Tower operations

## Security Considerations

- **Root User Access:** Secure root user access for all accounts
- **Cross-Account Roles:** Review and audit cross-account access roles
- **Guardrail Violations:** Set up monitoring and alerting for violations
- **Regular Reviews:** Schedule quarterly reviews of Control Tower configuration

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Next Review:** January 2025
