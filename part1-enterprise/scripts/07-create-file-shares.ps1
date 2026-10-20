# 07-create-file-shares.ps1
# Run on NBF-DC01 as NORTHBRIDGE\rpatel-admin, in Terminal (Admin).
# Creates the Company share with one folder per department.
# NTFS permissions come from the SG-* groups. Access-based enumeration (ABE)
# hides folders a user cannot open.

if ($env:COMPUTERNAME -ne "NBF-DC01") {
    Write-Host "This script is for NBF-DC01. You are on $env:COMPUTERNAME. Stopping." -ForegroundColor Red
    return
}

$Root = "C:\Shares\Company"

# Folder name -> group:right   (M = Modify, RX = Read and execute)
$Folders = [ordered]@{
    "Billing"        = @("SG-Billing-Modify:M", "SG-Billing-Read:RX")
    "Nightly Audits" = @("SG-NightlyAudits-Modify:M", "SG-NightlyAudits-Read:RX")
    "HR"             = @("SG-HR-Modify:M")
    "IT"             = @("SG-IT-Modify:M")
}

# 1. Root folder: admins get full control, staff can only list this folder
New-Item -Path $Root -ItemType Directory -Force | Out-Null
icacls $Root /inheritance:r /grant:r "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" "NORTHBRIDGE\SG-MYPC-Users:RX" | Out-Null
Write-Host "Set permissions on $Root" -ForegroundColor Green

# 2. Department folders
foreach ($name in $Folders.Keys) {
    $path = Join-Path $Root $name
    New-Item -Path $path -ItemType Directory -Force | Out-Null

    $grants = @("Administrators:(OI)(CI)F", "SYSTEM:(OI)(CI)F")
    foreach ($entry in $Folders[$name]) {
        $group, $right = $entry -split ":"
        $grants += "NORTHBRIDGE\${group}:(OI)(CI)$right"
    }

    icacls $path /inheritance:r /grant:r $grants | Out-Null
    Write-Host "Set permissions on $path" -ForegroundColor Green
}

# 3. Test file for the file-locking demo
$penske = Join-Path $Root "Nightly Audits\Penske.xlsx"
if (-not (Test-Path $penske)) {
    New-Item -Path $penske -ItemType File | Out-Null
}

# 4. The share
$shareParams = @{
    Name                  = "Company"
    Path                  = $Root
    FullAccess            = "BUILTIN\Administrators"
    ChangeAccess          = "NT AUTHORITY\Authenticated Users"
    FolderEnumerationMode = "AccessBased"
}

if (Get-SmbShare -Name "Company" -ErrorAction SilentlyContinue) {
    Set-SmbShare -Name "Company" -FolderEnumerationMode AccessBased -Force
    Write-Host "Share Company already exists. ABE is on." -ForegroundColor Yellow
} else {
    New-SmbShare @shareParams | Out-Null
    Write-Host "Created share \\$env:COMPUTERNAME\Company" -ForegroundColor Green
}

Get-SmbShare -Name "Company" | Select-Object Name, Path, FolderEnumerationMode