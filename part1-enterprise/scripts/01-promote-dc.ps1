# 01-promote-dc.ps1
# turns NBF-DC01 into the first domain controller for Northbridge Freight
# Run on NBF-DC01 as rpatel-admin. The server restarts by itself at the end.

$DomainName  = "northbridge.internal"
$NetbiosName = "NORTHBRIDGE"

Write-Host "Step 1 of 2: Installing the Active Directory role..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "Step 2 of 2: Creating the forest $DomainName..." -ForegroundColor Cyan
$dsrmPassword = Read-Host "Enter a DSRM (recovery) password" -AsSecureString

Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -InstallDns `
    -SafeModeAdministratorPassword $dsrmPassword `
    -Force