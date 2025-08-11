# AWS Multi-Account Organization Deployment Script
# Phase 1: Foundation Deployment

param(
    [string]$Environment = "management",
    [switch]$Plan = $false,
    [switch]$Apply = $false,
    [switch]$Destroy = $false,
    [switch]$AutoApprove = $false,
    [string]$Target = "",
    [switch]$Verbose = $false
)

Write-Host "🚀 AWS Multi-Account Organization Deployment" -ForegroundColor Cyan
Write-Host "Phase 1: Foundation Deployment" -ForegroundColor Yellow
Write-Host ""

# Validate parameters
if (-not ($Plan -or $Apply -or $Destroy)) {
    Write-Host "❌ Please specify one action: -Plan, -Apply, or -Destroy" -ForegroundColor Red
    exit 1
}

# Set environment path
$envPath = "environments\$Environment"
if (-not (Test-Path $envPath)) {
    Write-Host "❌ Environment path not found: $envPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Environment: $Environment" -ForegroundColor Green
Write-Host "📂 Path: $envPath" -ForegroundColor Green

# Change to environment directory
Push-Location $envPath

try {
    # Check if Terraform is initialized
    if (-not (Test-Path ".terraform")) {
        Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
            exit 1
        }
        Write-Host "✅ Terraform initialized" -ForegroundColor Green
    }

    # Validate Terraform configuration
    Write-Host "🔍 Validating Terraform configuration..." -ForegroundColor Yellow
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Terraform validation failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Terraform configuration is valid" -ForegroundColor Green

    # Build Terraform command
    $tfArgs = @()
    
    if ($Verbose) {
        $env:TF_LOG = "INFO"
    }

    if ($Target) {
        $tfArgs += "-target=$Target"
    }

    # Execute requested action
    if ($Plan) {
        Write-Host "📋 Planning deployment..." -ForegroundColor Yellow
        terraform plan @tfArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Plan completed successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Plan failed" -ForegroundColor Red
            exit 1
        }
    }
    
    if ($Apply) {
        Write-Host "🏗️  Applying configuration..." -ForegroundColor Yellow
        
        if ($AutoApprove) {
            $tfArgs += "-auto-approve"
        }
        
        terraform apply @tfArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Apply completed successfully" -ForegroundColor Green
            
            # Display outputs
            Write-Host ""
            Write-Host "📊 Deployment Outputs:" -ForegroundColor Cyan
            terraform output -json | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host
            
            # Display Phase 1 summary
            Write-Host ""
            Write-Host "🎉 Phase 1 Foundation Complete!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next Steps:" -ForegroundColor Yellow
            Write-Host "1. Verify organization structure in AWS Console" -ForegroundColor White
            Write-Host "2. Review Service Control Policies" -ForegroundColor White
            Write-Host "3. Prepare for Phase 2: Security & Compliance" -ForegroundColor White
            Write-Host "4. Set up Control Tower landing zone" -ForegroundColor White
            
        } else {
            Write-Host "❌ Apply failed" -ForegroundColor Red
            exit 1
        }
    }
    
    if ($Destroy) {
        Write-Host "⚠️  WARNING: This will destroy all resources!" -ForegroundColor Red
        
        if (-not $AutoApprove) {
            $confirm = Read-Host "Are you sure you want to destroy all resources? (yes/no)"
            if ($confirm -ne "yes") {
                Write-Host "❌ Destruction cancelled" -ForegroundColor Yellow
                exit 0
            }
        }
        
        Write-Host "🗑️  Destroying resources..." -ForegroundColor Yellow
        
        if ($AutoApprove) {
            $tfArgs += "-auto-approve"
        }
        
        terraform destroy @tfArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Resources destroyed successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Destruction failed" -ForegroundColor Red
            exit 1
        }
    }

} catch {
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
    
    # Clean up environment variables
    if ($env:TF_LOG) {
        Remove-Item env:TF_LOG
    }
}

Write-Host ""
Write-Host "🏁 Deployment script completed" -ForegroundColor Cyan
