# AWS Multi-Account Organization Verification Script
# Phase 1: Foundation Verification

param(
    [string]$Region = "us-east-1",
    [switch]$Detailed = $false
)

Write-Host "🔍 AWS Multi-Account Organization Verification" -ForegroundColor Cyan
Write-Host "Phase 1: Foundation Verification" -ForegroundColor Yellow
Write-Host ""

# Function to check AWS CLI command and display results
function Test-AwsCommand {
    param(
        [string]$Command,
        [string]$Description,
        [scriptblock]$ValidationScript = { $true }
    )
    
    Write-Host "Checking: $Description" -ForegroundColor Yellow
    
    try {
        $result = Invoke-Expression $Command
        
        if ($ValidationScript.Invoke($result)) {
            Write-Host "✅ $Description" -ForegroundColor Green
            if ($Detailed) {
                Write-Host "   Result: $result" -ForegroundColor Gray
            }
            return $true
        } else {
            Write-Host "❌ $Description - Validation failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ $Description - Command failed: $_" -ForegroundColor Red
        return $false
    }
}

# Initialize results
$results = @{
    Organization = $false
    OrganizationalUnits = $false
    ServiceControlPolicies = $false
    TagPolicies = $false
    CloudTrailBucket = $false
    NotificationTopic = $false
}

Write-Host "🏢 Verifying AWS Organization..." -ForegroundColor Green

# Check organization exists
$results.Organization = Test-AwsCommand `
    -Command "aws organizations describe-organization --query 'Organization.Id' --output text 2>$null" `
    -Description "AWS Organization exists" `
    -ValidationScript { $args[0] -and $args[0] -match "^o-[a-z0-9]{10,32}$" }

# Check organizational units
Write-Host ""
Write-Host "📁 Verifying Organizational Units..." -ForegroundColor Green

$ouCommand = "aws organizations list-organizational-units-for-parent --parent-id (aws organizations list-roots --query 'Roots[0].Id' --output text) --query 'OrganizationalUnits[].Name' --output text 2>$null"
$results.OrganizationalUnits = Test-AwsCommand `
    -Command $ouCommand `
    -Description "Organizational Units created" `
    -ValidationScript { 
        $ous = $args[0] -split "`t"
        $requiredOUs = @("Security OU", "Infrastructure OU", "Application OU", "Sandbox OU")
        $allPresent = $true
        foreach ($requiredOU in $requiredOUs) {
            if ($requiredOU -notin $ous) {
                $allPresent = $false
                break
            }
        }
        $allPresent
    }

# Check Service Control Policies
Write-Host ""
Write-Host "🛡️  Verifying Service Control Policies..." -ForegroundColor Green

$results.ServiceControlPolicies = Test-AwsCommand `
    -Command "aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[?Type==`SERVICE_CONTROL_POLICY`].Name' --output text 2>$null" `
    -Description "Service Control Policies created" `
    -ValidationScript { 
        $policies = $args[0] -split "`t"
        $requiredPolicies = @("Restrict Regions", "Restrict Root User", "Require MFA")
        $allPresent = $true
        foreach ($requiredPolicy in $requiredPolicies) {
            if ($requiredPolicy -notin $policies) {
                $allPresent = $false
                break
            }
        }
        $allPresent
    }

# Check Tag Policies
Write-Host ""
Write-Host "🏷️  Verifying Tag Policies..." -ForegroundColor Green

$results.TagPolicies = Test-AwsCommand `
    -Command "aws organizations list-policies --filter TAG_POLICY --query 'Policies[?Type==`TAG_POLICY`].Name' --output text 2>$null" `
    -Description "Tag Policies created" `
    -ValidationScript { 
        $policies = $args[0] -split "`t"
        "Required Tags" -in $policies
    }

# Check CloudTrail S3 bucket
Write-Host ""
Write-Host "📊 Verifying Infrastructure Resources..." -ForegroundColor Green

$results.CloudTrailBucket = Test-AwsCommand `
    -Command "aws s3 ls | Select-String 'cloudtrail-logs-' | Measure-Object | Select-Object -ExpandProperty Count" `
    -Description "CloudTrail S3 bucket exists" `
    -ValidationScript { [int]$args[0] -gt 0 }

# Check SNS topic
$results.NotificationTopic = Test-AwsCommand `
    -Command "aws sns list-topics --query 'Topics[?contains(TopicArn, `organization-notifications`)].TopicArn' --output text 2>$null" `
    -Description "Organization notification topic exists" `
    -ValidationScript { $args[0] -and $args[0].Length -gt 0 }

# Summary
Write-Host ""
Write-Host "📋 Verification Summary" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$totalChecks = $results.Count
$passedChecks = ($results.Values | Where-Object { $_ -eq $true }).Count

foreach ($check in $results.GetEnumerator()) {
    $status = if ($check.Value) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($check.Value) { "Green" } else { "Red" }
    Write-Host "$($check.Key): $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "Overall Status: $passedChecks/$totalChecks checks passed" -ForegroundColor $(if ($passedChecks -eq $totalChecks) { "Green" } else { "Yellow" })

if ($passedChecks -eq $totalChecks) {
    Write-Host ""
    Write-Host "🎉 Phase 1 Foundation verification completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ready for Phase 2: Security & Compliance" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "1. Set up Control Tower landing zone" -ForegroundColor Gray
    Write-Host "2. Configure Security Hub" -ForegroundColor Gray
    Write-Host "3. Enable GuardDuty" -ForegroundColor Gray
    Write-Host "4. Set up AWS Config" -ForegroundColor Gray
    
    # Additional detailed information if requested
    if ($Detailed) {
        Write-Host ""
        Write-Host "📊 Detailed Organization Information:" -ForegroundColor Cyan
        
        try {
            Write-Host "Organization ID: $(aws organizations describe-organization --query 'Organization.Id' --output text)" -ForegroundColor Gray
            Write-Host "Master Account ID: $(aws organizations describe-organization --query 'Organization.MasterAccountId' --output text)" -ForegroundColor Gray
            Write-Host "Feature Set: $(aws organizations describe-organization --query 'Organization.FeatureSet' --output text)" -ForegroundColor Gray
        }
        catch {
            Write-Host "Could not retrieve detailed organization information" -ForegroundColor Red
        }
    }
} else {
    Write-Host ""
    Write-Host "⚠️  Phase 1 verification completed with issues" -ForegroundColor Yellow
    Write-Host "Please review failed checks and re-run deployment if necessary" -ForegroundColor Yellow
    
    # Return non-zero exit code for CI/CD pipelines
    exit 1
}

Write-Host ""
