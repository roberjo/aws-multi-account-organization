# AWS Multi-Account Organization - Terraform Infrastructure

This directory contains the Terraform infrastructure code for the Enterprise Multi-Account AWS Organization project.

## Project Structure

```
terraform/
├── environments/           # Environment-specific configurations
│   ├── management/        # Management account infrastructure
│   ├── security/          # Security account infrastructure  
│   ├── infrastructure/    # Infrastructure OU configurations
│   └── application/       # Application OU configurations
├── modules/               # Reusable Terraform modules
│   ├── aws-organizations/ # AWS Organizations module
│   ├── control-tower/     # Control Tower module
│   ├── security-hub/      # Security Hub module
│   ├── guardduty/         # GuardDuty module
│   ├── aws-config/        # AWS Config module
│   ├── cloudtrail/        # CloudTrail module
│   └── lambda/            # Lambda functions module
├── policies/              # JSON policy files
│   ├── scp/              # Service Control Policies
│   └── tag/              # Tag Policies
└── scripts/              # Utility scripts
    ├── setup.ps1         # Initial setup script (PowerShell)
    └── deploy.ps1        # Deployment script (PowerShell)
```

## Phase 1 Implementation

### Prerequisites Checklist

- [ ] AWS Management account with administrative access
- [ ] Terraform >= 1.5 installed
- [ ] AWS CLI >= 2.0 configured
- [ ] PowerShell 7+ (Windows)
- [ ] MFA enabled on root account

### Phase 1 Deliverables

1. **AWS Organizations Setup**
   - Organization creation with all features enabled
   - Service access principals configuration
   - Initial policy framework

2. **Control Tower Landing Zone**
   - Landing zone deployment
   - Core accounts creation (Audit, Log Archive)
   - Basic guardrails implementation

3. **Organizational Units Structure**
   - Security OU
   - Infrastructure OU  
   - Application OU
   - Sandbox OU

4. **Initial Security Policies**
   - Region restriction SCP
   - Root user restriction SCP
   - Required tags policy

## Getting Started

### 1. Initial Setup

```powershell
# Run the setup script
.\scripts\setup.ps1
```

### 2. Deploy Management Environment

```powershell
# Navigate to management environment
Set-Location .\environments\management

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 3. Verify Deployment

```powershell
# Run verification script
.\scripts\verify-deployment.ps1
```

## Environment Variables

Set these environment variables before deployment:

```powershell
$env:AWS_REGION = "us-east-1"
$env:TF_VAR_organization_name = "Enterprise Organization"
$env:TF_VAR_management_account_email = "admin@company.com"
```

## Security Considerations

- All Terraform state is stored in encrypted S3 buckets
- State locking is enabled using DynamoDB
- MFA is required for all administrative operations
- All resources are tagged for compliance and cost management

## Support

For issues or questions regarding this infrastructure:
- Technical Issues: DevOps Team
- Security Questions: Security Team  
- Compliance: Compliance Team

---

**Last Updated:** December 2024  
**Version:** 1.0
