#!/usr/bin/env powershell
# Lab Validation Script - Validates lab completion for Unity Catalog Multi-Workspace Labs

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("lab-01", "lab-02", "lab-03", "all")]
    [string]$LabNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = ""
)

# Colors for output
$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue

function Write-ColorOutput {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColorOutput "`n🔍 Checking Prerequisites..." $Blue
    
    $allPassed = $true
    
    # Check Azure CLI
    try {
        $azVersion = az version --output json | ConvertFrom-Json
        Write-ColorOutput "  ✅ Azure CLI: $($azVersion.'azure-cli')" $Green
    }
    catch {
        Write-ColorOutput "  ❌ Azure CLI not found or not working" $Red
        $allPassed = $false
    }
    
    # Check Terraform
    try {
        $tfVersion = terraform version -json | ConvertFrom-Json
        Write-ColorOutput "  ✅ Terraform: $($tfVersion.terraform_version)" $Green
    }
    catch {
        Write-ColorOutput "  ❌ Terraform not found or not working" $Red
        $allPassed = $false
    }
    
    # Check Azure Authentication
    try {
        $account = az account show --output json | ConvertFrom-Json
        Write-ColorOutput "  ✅ Azure Account: $($account.name)" $Green
    }
    catch {
        Write-ColorOutput "  ❌ Not authenticated with Azure. Run 'az login'" $Red
        $allPassed = $false
    }
    
    return $allPassed
}

function Test-Lab01 {
    Write-ColorOutput "`n🧪 Validating Lab 1: Infrastructure Deployment" $Blue
    Write-ColorOutput "=" * 50
    
    $passed = 0
    $failed = 0
    
    # Check prerequisites
    if (Test-Prerequisites) {
        $passed++
    } else {
        $failed++
        return $false
    }
    
    # Navigate to infra directory
    $infraPath = Join-Path (Split-Path $PSScriptRoot -Parent) "infra"
    if (-not (Test-Path $infraPath)) {
        $infraPath = Join-Path $PSScriptRoot "..\infra"
    }
    
    Push-Location $infraPath
    
    try {
        # Check Terraform state
        Write-ColorOutput "`n📋 Checking Terraform Deployment..." $Blue
        
        if (Test-Path "terraform.tfstate") {
            Write-ColorOutput "  ✅ Terraform state file exists" $Green
            $passed++
        } else {
            Write-ColorOutput "  ❌ Terraform state file not found. Run 'terraform apply'" $Red
            $failed++
            Pop-Location
            return $false
        }
        
        # Check for workspace URLs in outputs
        try {
            $primaryUrl = terraform output -raw databricks_workspace_url 2>$null
            if ($primaryUrl) {
                Write-ColorOutput "  ✅ Primary Workspace URL: $primaryUrl" $Green
                $passed++
            } else {
                Write-ColorOutput "  ❌ Primary Workspace URL not found in outputs" $Red
                $failed++
            }
        } catch {
            Write-ColorOutput "  ❌ Could not get Primary Workspace URL" $Red
            $failed++
        }
        
        try {
            $analyticsUrl = terraform output -raw analytics_workspace_url 2>$null
            if ($analyticsUrl) {
                Write-ColorOutput "  ✅ Analytics Workspace URL: $analyticsUrl" $Green
                $passed++
            } else {
                Write-ColorOutput "  ⚠️ Analytics Workspace URL not found (may be named differently)" $Yellow
            }
        } catch {
            Write-ColorOutput "  ⚠️ Could not get Analytics Workspace URL" $Yellow
        }
        
        # Check resource group
        try {
            $rgName = terraform output -raw resource_group_name 2>$null
            if ($rgName) {
                $rg = az group show --name $rgName --output json 2>$null | ConvertFrom-Json
                if ($rg) {
                    Write-ColorOutput "  ✅ Resource Group exists: $rgName" $Green
                    $passed++
                }
            }
        } catch {
            Write-ColorOutput "  ⚠️ Could not verify Resource Group" $Yellow
        }
        
    } finally {
        Pop-Location
    }
    
    # Summary
    Write-ColorOutput "`n📊 Lab 1 Validation Summary" $Blue
    Write-ColorOutput "  Passed: $passed" $Green
    Write-ColorOutput "  Failed: $failed" $(if ($failed -gt 0) { $Red } else { $Green })
    
    return ($failed -eq 0)
}

function Test-Lab02 {
    Write-ColorOutput "`n🧪 Validating Lab 2: Data Engineering (Primary Workspace)" $Blue
    Write-ColorOutput "=" * 50
    
    Write-ColorOutput "`n📋 Manual Verification Required:" $Yellow
    Write-ColorOutput "  1. Open the Primary Workspace URL" 
    Write-ColorOutput "  2. Navigate to Catalog -> shared_data -> samples"
    Write-ColorOutput "  3. Verify these tables exist:"
    Write-ColorOutput "     - customers (10 records)"
    Write-ColorOutput "     - products (10 records)"
    Write-ColorOutput "     - transactions (12 records)"
    Write-ColorOutput "  4. Verify the customer_transactions view exists"
    
    Write-ColorOutput "`n📝 Validation Checklist:" $Blue
    Write-ColorOutput "  [ ] Notebook 01-data-ingestion-primary-workspace.ipynb imported"
    Write-ColorOutput "  [ ] Notebook executed successfully (all cells)"
    Write-ColorOutput "  [ ] Tables visible in Catalog Explorer"
    Write-ColorOutput "  [ ] Can query tables with: SELECT * FROM shared_data.samples.customers"
    
    $response = Read-Host "`nDid Lab 2 pass validation? (y/n)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

function Test-Lab03 {
    Write-ColorOutput "`n🧪 Validating Lab 3: Analytics & Cross-Workspace Access" $Blue
    Write-ColorOutput "=" * 50
    
    Write-ColorOutput "`n📋 Manual Verification Required:" $Yellow
    Write-ColorOutput "  1. Open the Analytics Workspace URL (different from Primary!)"
    Write-ColorOutput "  2. Verify you can see the shared_data catalog"
    Write-ColorOutput "  3. Query tables created in Lab 2:"
    Write-ColorOutput "     SELECT * FROM shared_data.samples.customers"
    Write-ColorOutput "  4. Verify customer_summary table was created"
    
    Write-ColorOutput "`n📝 Validation Checklist:" $Blue
    Write-ColorOutput "  [ ] Connected to Analytics workspace (NOT Primary)"
    Write-ColorOutput "  [ ] Notebook 02-cross-workspace-access-analytics.ipynb imported"
    Write-ColorOutput "  [ ] Can query tables from Primary workspace"
    Write-ColorOutput "  [ ] customer_summary table created in shared_data.samples"
    Write-ColorOutput "  [ ] Analytics queries executed successfully"
    
    Write-ColorOutput "`n🎯 Key Verification:" $Green
    Write-ColorOutput "  The same data from Lab 2 should be accessible here"
    Write-ColorOutput "  WITHOUT any data copy or ETL process!"
    
    $response = Read-Host "`nDid Lab 3 pass validation? (y/n)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

# Main execution
Write-ColorOutput "`n========================================" $Blue
Write-ColorOutput "  Unity Catalog Multi-Workspace Labs" $Blue  
Write-ColorOutput "  Validation Script" $Blue
Write-ColorOutput "========================================`n" $Blue

$result = $false

switch ($LabNumber) {
    "lab-01" { $result = Test-Lab01 }
    "lab-02" { $result = Test-Lab02 }
    "lab-03" { $result = Test-Lab03 }
    "all" {
        $lab1 = Test-Lab01
        $lab2 = Test-Lab02
        $lab3 = Test-Lab03
        
        Write-ColorOutput "`n========================================" $Blue
        Write-ColorOutput "  Overall Results" $Blue
        Write-ColorOutput "========================================" $Blue
        Write-ColorOutput "  Lab 1 (Infrastructure): $(if ($lab1) { '✅ PASSED' } else { '❌ FAILED' })" $(if ($lab1) { $Green } else { $Red })
        Write-ColorOutput "  Lab 2 (Data Engineering): $(if ($lab2) { '✅ PASSED' } else { '❌ FAILED' })" $(if ($lab2) { $Green } else { $Red })
        Write-ColorOutput "  Lab 3 (Analytics): $(if ($lab3) { '✅ PASSED' } else { '❌ FAILED' })" $(if ($lab3) { $Green } else { $Red })
        
        $result = $lab1 -and $lab2 -and $lab3
    }
}

if ($result) {
    Write-ColorOutput "`n🎉 Validation Passed!" $Green
} else {
    Write-ColorOutput "`n❌ Validation Failed - Review the issues above" $Red
}

exit $(if ($result) { 0 } else { 1 })
