# 05-install-rdsh.ps1
# Run on NBF-MYPC01 as NORTHBRIDGE\rpatel-admin, in Terminal (Admin).
# Installs the Remote Desktop Session Host role so many users can sign in at once.

if ($env:COMPUTERNAME -ne "NBF-MYPC01") {
    Write-Host "This script is for NBF-MYPC01. You are on $env:COMPUTERNAME. Stopping." -ForegroundColor Red
    return
}

$feature = Get-WindowsFeature -Name RDS-RD-Server
if ($feature.Installed) {
    Write-Host "Remote Desktop Session Host is already installed. Nothing to do." -ForegroundColor Yellow
    return
}

Write-Host "Installing Remote Desktop Session Host. The VM restarts when done."
Install-WindowsFeature -Name RDS-RD-Server -IncludeManagementTools -Restart