#Requires -Version 5.1

<#
.SYNOPSIS
    Tenjo Client Update Deployment Script (Windows)
    
.DESCRIPTION
    Automates the process of building, packaging, and deploying Tenjo client updates to VPS.
    - Builds client package
    - Generates version.json with checksum
    - Uploads to VPS via SCP
    - Optionally triggers update to clients via API
    
.PARAMETER Version
    Version number for the update (e.g., "1.0.1")
    
.PARAMETER VpsHost
    VPS hostname or IP address (default: tenjo.adilabs.id)
    
.PARAMETER VpsUser
    VPS SSH username (default: root)
    
.PARAMETER VpsPath
    Path on VPS where files will be uploaded (default: /var/www/html/tenjo/public/downloads/client)
    
.PARAMETER ApiUrl
    Base API URL (default: https://tenjo.adilabs.id)
    
.PARAMETER SkipUpload
    Skip uploading to VPS (useful for testing package build)
    
.PARAMETER SkipTrigger
    Skip triggering client updates
    
.EXAMPLE
    .\deploy_update_windows.ps1
    
.EXAMPLE
    .\deploy_update_windows.ps1 -Version "1.0.2" -SkipTrigger
    
.EXAMPLE
    .\deploy_update_windows.ps1 -VpsHost "103.129.149.67" -VpsUser "admin"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$VpsHost = $env:VPS_HOST ?? "tenjo.adilabs.id",
    
    [Parameter(Mandatory=$false)]
    [string]$VpsUser = $env:VPS_USER ?? "root",
    
    [Parameter(Mandatory=$false)]
    [string]$VpsPath = $env:VPS_PATH ?? "/var/www/html/tenjo/public/downloads/client",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = $env:API_URL ?? "https://tenjo.adilabs.id",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipUpload,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTrigger
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClientDir = Join-Path $ScriptDir "client"
$BuildDir = Join-Path $ClientDir "build"
$ChangesFile = Join-Path $ClientDir ".update_changes.txt"
$AdminToken = $env:TENJO_ADMIN_TOKEN

###############################################################################
# Helper Functions
###############################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "  $Message" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Test-Dependencies {
    Write-Header "Checking Dependencies"
    
    $missingDeps = @()
    
    # Check for Python
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
            $missingDeps += "python/python3"
        }
    }
    
    # Check for tar (Git Bash tar)
    if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
        Write-Warning "tar not found in PATH, will try to use 7-Zip"
        if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
            $missingDeps += "tar or 7-Zip"
        }
    }
    
    # Check for SCP (comes with Git Bash or OpenSSH)
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
        Write-Warning "scp not found, upload to VPS will not be available"
        Write-Info "Install Git for Windows or OpenSSH to enable upload"
    }
    
    # Check for SSH
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Warning "ssh not found, remote commands will not be available"
    }
    
    if ($missingDeps.Count -gt 0) {
        Write-ErrorMsg "Missing required dependencies: $($missingDeps -join ', ')"
        Write-Host "`nPlease install the missing dependencies:"
        Write-Host "  - Python: https://www.python.org/downloads/"
        Write-Host "  - Git Bash: https://git-scm.com/download/win (includes tar, scp, ssh)"
        Write-Host "  - 7-Zip: https://www.7-zip.org/ (alternative to tar)"
        exit 1
    }
    
    Write-Success "All dependencies satisfied"
}

function Get-ClientVersion {
    Write-Header "Version Information"
    
    $versionFile = Join-Path $ClientDir ".version"
    $currentVersion = "1.0.0"
    
    if (Test-Path $versionFile) {
        $currentVersion = (Get-Content $versionFile).Trim()
        Write-Info "Current version: $currentVersion"
    } else {
        Write-Warning "No .version file found, using default: $currentVersion"
    }
    
    if ([string]::IsNullOrEmpty($Version)) {
        $newVersion = Read-Host "Enter new version number (current: $currentVersion, press Enter to keep)"
        if (-not [string]::IsNullOrEmpty($newVersion)) {
            $Version = $newVersion
        } else {
            $Version = $currentVersion
        }
    }
    
    # Save version
    Set-Content -Path $versionFile -Value $Version -NoNewline
    Write-Success "Version: $Version"
    
    return $Version
}

function Get-UpdateChanges {
    Write-Header "Update Changes"
    
    if (Test-Path $ChangesFile) {
        $previousChanges = Get-Content $ChangesFile
        Write-Info "Previous changes found:"
        $previousChanges | ForEach-Object { Write-Host "  - $_" }
        
        $usePrevious = Read-Host "`nUse previous changes? (y/n)"
        if ($usePrevious -eq "y" -or $usePrevious -eq "Y") {
            return $previousChanges
        }
    }
    
    Write-Host "`nEnter update changes (one per line, empty line to finish):"
    $changes = @()
    
    while ($true) {
        $change = Read-Host
        if ([string]::IsNullOrEmpty($change)) {
            break
        }
        $changes += $change
    }
    
    if ($changes.Count -eq 0) {
        $changes = @("Bug fixes and improvements")
        Write-Warning "No changes entered, using default message"
    }
    
    # Save changes
    Set-Content -Path $ChangesFile -Value $changes
    Write-Success "Changes recorded"
    
    return $changes
}

function Build-ClientPackage {
    param([string]$Version)
    
    Write-Header "Building Client Package"
    
    $packageName = "tenjo_client_$Version.tar.gz"
    
    # Clean build directory
    if (Test-Path $BuildDir) {
        Remove-Item -Recurse -Force $BuildDir
    }
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
    
    Write-Info "Cleaning Python cache files..."
    Get-ChildItem -Path $ClientDir -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force
    Get-ChildItem -Path $ClientDir -Recurse -Filter "*.pyc" | Remove-Item -Force
    Get-ChildItem -Path $ClientDir -Recurse -Filter "*.pyo" | Remove-Item -Force
    
    Write-Info "Creating package structure..."
    
    # Create staging directory
    $stagingDir = Join-Path $BuildDir "tenjo_client"
    New-Item -ItemType Directory -Path $stagingDir | Out-Null
    
    # Copy necessary files
    Copy-Item -Path (Join-Path $ClientDir "main.py") -Destination $stagingDir
    Copy-Item -Path (Join-Path $ClientDir "requirements.txt") -Destination $stagingDir
    Copy-Item -Path (Join-Path $ClientDir "src") -Destination $stagingDir -Recurse
    
    # Copy autostart scripts
    @("install_autostart.sh", "install_autostart.ps1", "uninstall_autostart.sh", "uninstall_autostart.ps1") | ForEach-Object {
        $scriptPath = Join-Path $ClientDir $_
        if (Test-Path $scriptPath) {
            Copy-Item -Path $scriptPath -Destination $stagingDir
        }
    }
    
    # Create version file
    Set-Content -Path (Join-Path $stagingDir ".version") -Value $Version -NoNewline
    
    # Create package
    Write-Info "Creating tarball..."
    Push-Location $BuildDir
    
    try {
        if (Get-Command tar -ErrorAction SilentlyContinue) {
            tar -czf $packageName tenjo_client/ 2>$null
        } elseif (Get-Command 7z -ErrorAction SilentlyContinue) {
            # Use 7-Zip as fallback
            7z a -ttar "$packageName.tar" tenjo_client/ | Out-Null
            7z a -tgzip $packageName "$packageName.tar" | Out-Null
            Remove-Item "$packageName.tar"
        } else {
            throw "Neither tar nor 7z is available"
        }
        
        $packageSize = (Get-Item $packageName).Length
        $packageSizeMB = [math]::Round($packageSize / 1MB, 2)
        Write-Success "Package created: $packageName ($packageSizeMB MB)"
        
    } finally {
        Pop-Location
    }
    
    return @{
        Name = $packageName
        Path = Join-Path $BuildDir $packageName
        Size = $packageSize
    }
}

function Get-FileChecksum {
    param([string]$FilePath)
    
    Write-Header "Generating Checksum"
    
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    $checksum = $hash.Hash.ToLower()
    
    Write-Success "SHA256: $checksum"
    
    return $checksum
}

function New-VersionJson {
    param(
        [string]$Version,
        [string]$PackageName,
        [string]$Checksum,
        [long]$PackageSize,
        [string[]]$Changes
    )
    
    Write-Header "Generating version.json"
    
    # Create version JSON object
    $versionJson = @{
        version = $Version
        download_url = "$ApiUrl/downloads/client/$PackageName"
        server_url = $ApiUrl
        changes = $Changes
        checksum = $Checksum
        package_size = $PackageSize
        priority = "normal"
        release_date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json -Depth 10
    
    # Save to file
    $versionJsonPath = Join-Path $BuildDir "version.json"
    Set-Content -Path $versionJsonPath -Value $versionJson
    
    Write-Success "version.json generated"
    Write-Info "Content:"
    Write-Host $versionJson
    
    return $versionJsonPath
}

function Upload-ToVps {
    param(
        [string]$PackagePath,
        [string]$VersionJsonPath
    )
    
    Write-Header "Uploading to VPS"
    
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
        Write-ErrorMsg "scp command not found. Cannot upload to VPS."
        Write-Info "Install Git for Windows or OpenSSH to enable upload"
        return $false
    }
    
    Write-Info "Target: $VpsUser@$VpsHost`:$VpsPath"
    
    # Test SSH connection
    Write-Info "Testing SSH connection..."
    $sshTest = ssh -o ConnectTimeout=5 "$VpsUser@$VpsHost" "echo 'Connection OK'" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Cannot connect to VPS via SSH"
        Write-Warning "Make sure SSH key is configured or provide password"
        return $false
    }
    
    Write-Success "SSH connection established"
    
    # Create directory on VPS
    Write-Info "Ensuring directory exists on VPS..."
    ssh "$VpsUser@$VpsHost" "mkdir -p $VpsPath"
    
    # Upload package
    Write-Info "Uploading $(Split-Path -Leaf $PackagePath)..."
    scp $PackagePath "$VpsUser@$VpsHost`:$VpsPath/"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Package uploaded"
    } else {
        Write-ErrorMsg "Failed to upload package"
        return $false
    }
    
    # Upload version.json
    Write-Info "Uploading version.json..."
    scp $VersionJsonPath "$VpsUser@$VpsHost`:$VpsPath/"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "version.json uploaded"
    } else {
        Write-ErrorMsg "Failed to upload version.json"
        return $false
    }
    
    # Set permissions
    Write-Info "Setting permissions..."
    $packageName = Split-Path -Leaf $PackagePath
    ssh "$VpsUser@$VpsHost" "chmod 644 $VpsPath/$packageName $VpsPath/version.json"
    
    Write-Success "Upload completed successfully!"
    return $true
}

function Invoke-ClientUpdate {
    param(
        [string]$Version,
        [string]$PackageName,
        [string]$Checksum,
        [string[]]$Changes
    )
    
    Write-Header "Trigger Client Updates"
    
    if ([string]::IsNullOrEmpty($AdminToken)) {
        Write-Warning "TENJO_ADMIN_TOKEN not set, skipping automatic update trigger"
        Write-Info "You can manually trigger updates from the dashboard"
        return
    }
    
    Write-Host "`nUpdate deployment mode:"
    Write-Host "  1) Trigger specific client (requires client_id)"
    Write-Host "  2) Trigger all clients"
    Write-Host "  3) Skip (manual trigger from dashboard)"
    
    $mode = Read-Host "`nSelect option (1-3)"
    
    $headers = @{
        "Authorization" = "Bearer $AdminToken"
        "Content-Type" = "application/json"
    }
    
    $updateData = @{
        version = $Version
        update_url = "$ApiUrl/downloads/client/$PackageName"
        changes = $Changes
        checksum = $Checksum
        priority = "normal"
    } | ConvertTo-Json -Depth 10
    
    switch ($mode) {
        "1" {
            $clientId = Read-Host "`nEnter client_id"
            
            if ([string]::IsNullOrEmpty($clientId)) {
                Write-ErrorMsg "No client_id provided"
                return
            }
            
            Write-Info "Triggering update for client: $clientId"
            
            try {
                $response = Invoke-RestMethod -Uri "$ApiUrl/api/clients/$clientId/trigger-update" `
                    -Method Post -Headers $headers -Body $updateData
                
                if ($response.success) {
                    Write-Success "Update triggered successfully for $clientId"
                } else {
                    Write-ErrorMsg "Failed to trigger update: $($response.message)"
                }
            } catch {
                Write-ErrorMsg "API request failed: $($_.Exception.Message)"
            }
        }
        
        "2" {
            Write-Warning "This will trigger update for ALL registered clients!"
            $confirm = Read-Host "Are you sure? (yes/no)"
            
            if ($confirm -ne "yes") {
                Write-Info "Bulk update cancelled"
                return
            }
            
            Write-Info "Triggering bulk update..."
            
            try {
                $response = Invoke-RestMethod -Uri "$ApiUrl/api/clients/schedule-update" `
                    -Method Post -Headers $headers -Body $updateData
                
                if ($response.success) {
                    Write-Success "Bulk update triggered for $($response.targets) clients"
                } else {
                    Write-ErrorMsg "Failed to trigger bulk update: $($response.message)"
                }
            } catch {
                Write-ErrorMsg "API request failed: $($_.Exception.Message)"
            }
        }
        
        "3" {
            Write-Info "Skipping automatic trigger"
            Write-Info "You can manually trigger updates from: $ApiUrl/dashboard"
        }
        
        default {
            Write-Warning "Invalid option, skipping trigger"
        }
    }
}

function Show-Summary {
    param(
        [string]$Version,
        [string]$PackageName,
        [string]$Checksum,
        [string[]]$Changes
    )
    
    Write-Header "Deployment Summary"
    
    Write-Host "Version:      " -ForegroundColor Green -NoNewline
    Write-Host $Version
    Write-Host "Package:      " -ForegroundColor Green -NoNewline
    Write-Host $PackageName
    Write-Host "Checksum:     " -ForegroundColor Green -NoNewline
    Write-Host $Checksum
    Write-Host "VPS Path:     " -ForegroundColor Green -NoNewline
    Write-Host "$VpsUser@$VpsHost`:$VpsPath"
    Write-Host "Download URL: " -ForegroundColor Green -NoNewline
    Write-Host "$ApiUrl/downloads/client/$PackageName"
    
    Write-Host "`nChanges:" -ForegroundColor Cyan
    $Changes | ForEach-Object { Write-Host "  - $_" }
    
    Write-Host "`nDeployment completed successfully! 🚀`n" -ForegroundColor Green
}

###############################################################################
# Main Script
###############################################################################

function Main {
    Clear-Host
    
    Write-Host @"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ████████╗███████╗███╗   ██╗     ██╗ ██████╗             ║
║   ╚══██╔══╝██╔════╝████╗  ██║     ██║██╔═══██╗            ║
║      ██║   █████╗  ██╔██╗ ██║     ██║██║   ██║            ║
║      ██║   ██╔══╝  ██║╚██╗██║██   ██║██║   ██║            ║
║      ██║   ███████╗██║ ╚████║╚█████╔╝╚██████╔╝            ║
║      ╚═╝   ╚══════╝╚═╝  ╚═══╝ ╚════╝  ╚═════╝             ║
║                                                            ║
║            Client Update Deployment Script                ║
║                    (Windows Edition)                      ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green
    
    try {
        Test-Dependencies
        
        $version = Get-ClientVersion
        $changes = Get-UpdateChanges
        $package = Build-ClientPackage -Version $version
        $checksum = Get-FileChecksum -FilePath $package.Path
        $versionJsonPath = New-VersionJson -Version $version -PackageName $package.Name `
            -Checksum $checksum -PackageSize $package.Size -Changes $changes
        
        if (-not $SkipUpload) {
            $uploadSuccess = Upload-ToVps -PackagePath $package.Path -VersionJsonPath $versionJsonPath
            
            if ($uploadSuccess -and -not $SkipTrigger) {
                Invoke-ClientUpdate -Version $version -PackageName $package.Name `
                    -Checksum $checksum -Changes $changes
            }
        } else {
            Write-Warning "Upload skipped (use -SkipUpload:$false to enable)"
        }
        
        # Cleanup
        $keepBuild = Read-Host "`nKeep build directory? (y/n)"
        if ($keepBuild -ne "y" -and $keepBuild -ne "Y") {
            Remove-Item -Recurse -Force $BuildDir
            Write-Success "Build directory cleaned"
        } else {
            Write-Info "Build directory kept at: $BuildDir"
        }
        
        Show-Summary -Version $version -PackageName $package.Name `
            -Checksum $checksum -Changes $changes
        
    } catch {
        Write-ErrorMsg "Deployment failed: $($_.Exception.Message)"
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        exit 1
    }
}

# Run main function
Main
