# Security Architecture

## Security Overview

The Enterprise Multi-Account AWS Organization implements a comprehensive security architecture based on the principle of defense in depth. This architecture ensures that multiple layers of security controls protect the organization's assets, data, and operations across all AWS accounts.

## Security Principles

### 1. Zero Trust Architecture
- **Never Trust, Always Verify:** All access requests are authenticated and authorized
- **Least Privilege Access:** Users and systems receive minimum necessary permissions
- **Continuous Monitoring:** All activities are logged, monitored, and analyzed
- **Micro-segmentation:** Network and resource isolation at the finest granularity

### 2. Defense in Depth
- **Multiple Security Layers:** Security controls at network, application, and data levels
- **Redundant Controls:** Backup security measures for critical systems
- **Fail-Safe Design:** Security controls default to deny when possible
- **Comprehensive Coverage:** Security controls span all AWS services and accounts

### 3. Security by Design
- **Built-in Security:** Security controls integrated into architecture from inception
- **Automated Security:** Security policies enforced through automation
- **Continuous Compliance:** Real-time compliance monitoring and enforcement
- **Proactive Security:** Threat detection and prevention before incidents occur

## Security Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 IDENTITY & ACCESS                       │ │
│  │                                                         │ │
│  │ • IAM Policies & Roles                                 │ │
│  │ • Multi-Factor Authentication                          │ │
│  │ • Single Sign-On (SSO)                                 │ │
│  │ • Privileged Access Management                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 NETWORK SECURITY                       │ │
│  │                                                         │ │
│  │ • VPC Isolation                                        │ │
│  │ • Security Groups & NACLs                              │ │
│  │ • Transit Gateway                                      │ │
│  │ • VPN & Direct Connect                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 DATA PROTECTION                        │ │
│  │                                                         │ │
│  │ • Encryption at Rest & Transit                         │ │
│  │ • Key Management (KMS)                                 │ │
│  │ • Data Classification                                  │ │
│  │ • Backup & Recovery                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 MONITORING & DETECTION                 │ │
│  │                                                         │ │
│  │ • Security Hub                                         │ │
│  │ • GuardDuty                                            │ │
│  │ • CloudTrail                                           │ │
│  │ • AWS Config                                           │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 COMPLIANCE & GOVERNANCE                │ │
│  │                                                         │ │
│  │ • Service Control Policies                             │ │
│  │ • Tag Policies                                         │ │
│  │ • Compliance Frameworks                                │ │
│  │ • Audit Procedures                                     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Identity and Access Management (IAM)

### IAM Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    IAM ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   IDENTITY      │    │   ACCESS        │                │
│  │   PROVIDER      │    │   MANAGEMENT    │                │
│  │                 │    │                 │                │
│  │ • Active        │    │ • IAM Users     │                │
│  │   Directory     │    │ • IAM Roles     │                │
│  │ • Azure AD      │    │ • IAM Groups    │                │
│  │ • Okta          │    │ • IAM Policies  │                │
│  │ • SAML 2.0     │    │ • Cross-Account │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                         │
│           └───────────────────────┼─────────────────────────┘
│                                   │
│  ┌─────────────────────────────────▼─────────────────────────┐
│  │                                                           │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │  │   MFA       │  │   PAM       │  │   SSO           │   │
│  │  │             │  │             │  │                 │   │
│  │  │ • Hardware  │  │ • Privileged│  │ • SAML          │   │
│  │  │   Tokens    │  │   Access    │  │ • OAuth 2.0     │   │
│  │  │ • Software  │  │   Workflows │  │ • Just-In-Time  │   │
│  │  │   Tokens    │  │ • Session   │  │   Access        │   │
│  │  │ • SMS       │  │   Recording │  │ • Role-Based    │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘   │
│  └───────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────┘
```

### IAM Policies and Roles

**Cross-Account Access Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::MANAGEMENT_ACCOUNT_ID:role/OrganizationAccountAccessRole"
      },
      "Action": [
        "sts:AssumeRole"
      ],
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "UNIQUE_EXTERNAL_ID"
        }
      }
    }
  ]
}
```

**Least Privilege Policy Example:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::specific-bucket",
        "arn:aws:s3:::specific-bucket/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Environment": "Production"
        }
      }
    }
  ]
}
```

### Multi-Factor Authentication (MFA)

**MFA Enforcement Policy:**
```hcl
# mfa-policy.tf
resource "aws_iam_policy" "mfa_enforcement" {
  name = "MFAPolicy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent": "false"
          }
        }
      }
    ]
  })
}
```

## Network Security

### VPC Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC SECURITY ARCHITECTURE               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   PUBLIC        │    │   PRIVATE       │                │
│  │   SUBNET        │    │   SUBNET        │                │
│  │                 │    │                 │                │
│  │ • Internet      │    │ • Application   │                │
│  │   Gateway       │    │   Servers       │                │
│  │ • Load          │    │ • Internal      │                │
│  │   Balancers     │    │   Services      │                │
│  │ • Bastion       │    │ • Database      │                │
│  │   Hosts         │    │   Servers       │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                         │
│           └───────────────────────┼─────────────────────────┘
│                                   │
│  ┌─────────────────────────────────▼─────────────────────────┐
│  │                                                           │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │  │   SECURITY  │  │   NAT       │  │   VPC           │   │
│  │  │   GROUPS    │  │   GATEWAY   │  │   ENDPOINTS     │   │
│  │  │             │  │             │  │                 │   │
│  │  │ • Inbound   │  │ • Outbound  │  │ • S3 Endpoint   │   │
│  │  │   Rules     │  │   Internet  │  │ • DynamoDB      │   │
│  │  │ • Outbound  │  │   Access    │  │   Endpoint      │   │
│  │  │   Rules     │  │ • Private   │  │ • API Gateway   │   │
│  │  │ • Tag-Based │  │   Subnet    │  │   Endpoint      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘   │
│  └───────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────┘
```

### Security Groups Configuration

**Web Tier Security Group:**
```hcl
# security-groups.tf
resource "aws_security_group" "web_tier" {
  name        = "web-tier-sg"
  description = "Security group for web tier"
  vpc_id      = aws_vpc.main.id
  
  # Allow HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow traffic to application tier
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "web-tier-sg"
    Environment = "Production"
    Owner       = "Security"
  }
}
```

### Network Access Control Lists (NACLs)

**Private Subnet NACL:**
```hcl
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  
  # Allow ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 1024
    to_port    = 65535
  }
  
  # Allow HTTPS from public subnet
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 443
    to_port    = 443
  }
  
  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = {
    Name        = "private-nacl"
    Environment = "Production"
  }
}
```

## Data Protection

### Encryption Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ENCRYPTION ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   ENCRYPTION    │    │   KEY           │                │
│  │   AT REST       │    │   MANAGEMENT    │                │
│  │                 │    │                 │                │
│  │ • S3            │    │ • AWS KMS       │                │
│  │   Encryption    │    │ • Customer      │                │
│  │ • EBS           │    │   Managed Keys  │                │
│  │   Encryption    │    │ • CloudHSM      │                │
│  │ • RDS           │    │ • Key Rotation  │                │
│  │   Encryption    │    │ • Key Policies  │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                         │
│           └───────────────────────┼─────────────────────────┘
│                                   │
│  ┌─────────────────────────────────▼─────────────────────────┐
│  │                                                           │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │  │   ENCRYPTION│  │   DATA      │  │   BACKUP        │   │
│  │  │   IN TRANSIT│  │   CLASSIFICATION│  │   ENCRYPTION   │   │
│  │  │             │  │             │  │                 │   │
│  │  │ • TLS 1.3   │  │ • Public    │  │ • S3            │   │
│  │  │ • HTTPS     │  │ • Internal  │  │   Encryption    │   │
│  │  │ • VPN       │  │ • Confidential│  │ • Cross-Region │   │
│  │  │ • Direct    │  │ • Restricted │  │   Replication  │   │
│  │  │   Connect   │  │ • Compliance │  │ • Versioning    │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘   │
│  └───────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────┘
```

### KMS Configuration

**Customer Managed Key:**
```hcl
# kms.tf
resource "aws_kms_key" "organization_key" {
  description             = "Organization encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService": "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
    Purpose     = "Organization Encryption"
  }
}
```

### Data Classification Policy

**Classification Levels:**
1. **Public:** Information that can be freely shared
2. **Internal:** Information for internal use only
3. **Confidential:** Sensitive business information
4. **Restricted:** Highly sensitive information (PII, PHI, etc.)

**Tagging Strategy:**
```hcl
# data-classification.tf
resource "aws_organizations_policy" "data_classification" {
  name = "data-classification-policy"
  
  content = jsonencode({
    tags = {
      DataClassification = {
        tag_key = {
          "@@assign": ["Public", "Internal", "Confidential", "Restricted"]
        }
      }
      DataRetention = {
        tag_key = {
          "@@assign": ["1-Year", "3-Years", "7-Years", "Indefinite"]
        }
      }
      DataOwner = {
        tag_key = {
          "@@assign": ["IT", "HR", "Finance", "Legal"]
        }
      }
    }
  })
}
```

## Monitoring and Detection

### Security Monitoring Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                SECURITY MONITORING ARCHITECTURE             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   SECURITY      │    │   GUARDDUTY     │                │
│  │     HUB         │    │                 │                │
│  │                 │    │                 │                │
│  │ • Centralized   │    │ • Threat        │                │
│  │   Findings      │    │   Detection     │                │
│  │ • Compliance    │    │ • Anomaly       │                │
│  │   Standards     │    │   Detection     │                │
│  │ • Remediation   │    │ • Machine       │                │
│  │   Workflows     │    │   Learning      │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                         │
│           └───────────────────────┼─────────────────────────┘
│                                   │
│  ┌─────────────────────────────────▼─────────────────────────┐
│  │                                                           │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │  │   CLOUDTRAIL│  │   AWS       │  │   CLOUDWATCH    │   │
│  │  │             │  │   CONFIG    │  │                 │   │
│  │  │ • API       │  │             │  │                 │   │
│  │  │   Activity  │  │ • Resource  │  │ • Metrics       │   │
│  │  │ • User      │  │   Inventory │  │ • Logs          │   │
│  │  │   Activity  │  │ • Compliance│  │ • Alarms        │   │
│  │  │ • Resource  │  │   Rules     │  │ • Dashboards    │   │
│  │  │   Changes   │  │ • Drift     │  │ • Insights      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘   │
│  └───────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────┘
```

### Security Hub Configuration

**Master Account Setup:**
```hcl
# security-hub.tf
resource "aws_securityhub_account" "master" {
  enable_default_standards = true
  
  standards_subscription {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0"
  }
  
  standards_subscription {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
  }
  
  standards_subscription {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  }
}

# Custom action for high severity findings
resource "aws_securityhub_action_target" "high_severity" {
  name        = "HighSeverityAction"
  description = "Action for high severity security findings"
  identifier  = "HighSeverityAction"
}
```

### GuardDuty Configuration

**GuardDuty Detector:**
```hcl
# guardduty.tf
resource "aws_guardduty_detector" "master" {
  enable = true
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
  
  tags = {
    Environment = "Production"
    Owner       = "Security"
  }
}
```

## Compliance and Governance

### Service Control Policies (SCPs)

**Restrict Root User SCP:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootUser",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::*:root"
      },
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

**Restrict Regions SCP:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnapprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "sts:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "us-west-2",
            "eu-west-1"
          ]
        }
      }
    }
  ]
}
```

### Compliance Frameworks

**SOC 2 Compliance:**
- **CC1 - Control Environment:** IAM policies and organizational structure
- **CC2 - Communication and Information:** Security awareness and training
- **CC3 - Risk Assessment:** Regular security assessments and threat modeling
- **CC4 - Monitoring Activities:** Continuous monitoring and alerting
- **CC5 - Control Activities:** Automated security controls and policies
- **CC6 - Logical and Physical Access Controls:** Access management and network security
- **CC7 - System Operations:** Operational procedures and change management
- **CC8 - Change Management:** Infrastructure as code and version control
- **CC9 - Risk Mitigation:** Incident response and disaster recovery

**ISO 27001 Compliance:**
- **Information Security Policies:** Documented security policies and procedures
- **Organization of Information Security:** Security roles and responsibilities
- **Human Resource Security:** Background checks and security training
- **Asset Management:** Asset inventory and classification
- **Access Control:** Identity and access management
- **Cryptography:** Encryption and key management
- **Physical and Environmental Security:** Data center security
- **Operations Security:** Operational procedures and monitoring
- **Communications Security:** Network security and data protection
- **System Acquisition, Development, and Maintenance:** Secure development
- **Supplier Relationships:** Third-party security requirements
- **Information Security Incident Management:** Incident response procedures
- **Information Security Aspects of Business Continuity:** Disaster recovery
- **Compliance:** Regulatory compliance and audits

## Incident Response

### Incident Response Plan

**Response Phases:**
1. **Preparation:** Tools, procedures, and team training
2. **Identification:** Detection and initial assessment
3. **Containment:** Isolate and prevent further damage
4. **Eradication:** Remove threat and vulnerabilities
5. **Recovery:** Restore systems and services
6. **Lessons Learned:** Document and improve procedures

**Response Team Roles:**
- **Incident Commander:** Overall incident coordination
- **Security Analyst:** Technical investigation and analysis
- **Communications Lead:** Stakeholder and public communications
- **Legal Counsel:** Legal and compliance guidance
- **IT Operations:** System restoration and recovery

### Automated Response

**Lambda Function for Automated Response:**
```python
# incident_response.py
import boto3
import json
import logging

def lambda_handler(event, context):
    # Parse Security Hub finding
    finding = event['detail']['findings'][0]
    
    # Determine severity and response
    severity = finding['Severity']['Label']
    
    if severity in ['CRITICAL', 'HIGH']:
        # Immediate response actions
        response_actions = [
            'isolate_affected_resources',
            'disable_compromised_credentials',
            'block_suspicious_ips',
            'notify_security_team'
        ]
        
        for action in response_actions:
            execute_response_action(action, finding)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Incident response executed')
    }

def execute_response_action(action, finding):
    # Implement specific response actions
    if action == 'isolate_affected_resources':
        isolate_resources(finding)
    elif action == 'disable_compromised_credentials':
        disable_credentials(finding)
    # ... other actions
```

## Security Metrics and KPIs

### Key Security Metrics

1. **Security Posture Score:** Overall security compliance percentage
2. **Mean Time to Detection (MTTD):** Average time to detect security incidents
3. **Mean Time to Response (MTTR):** Average time to respond to incidents
4. **Vulnerability Remediation Time:** Time to patch critical vulnerabilities
5. **Access Review Completion:** Percentage of access reviews completed on time
6. **Security Training Completion:** Percentage of employees completing security training
7. **Incident Response Time:** Time to contain and resolve security incidents
8. **Compliance Score:** Percentage of compliance requirements met

### Security Dashboard

**CloudWatch Dashboard Configuration:**
```hcl
# security-dashboard.tf
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "security-dashboard"
  
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
            ["AWS/SecurityHub", "Findings", "Severity", "CRITICAL"],
            ["AWS/SecurityHub", "Findings", "Severity", "HIGH"],
            ["AWS/SecurityHub", "Findings", "Severity", "MEDIUM"],
            ["AWS/SecurityHub", "Findings", "Severity", "LOW"]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
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
            ["AWS/GuardDuty", "TotalFindings"]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "GuardDuty Total Findings"
        }
      }
    ]
  })
}
```

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Next Review:** January 2025
