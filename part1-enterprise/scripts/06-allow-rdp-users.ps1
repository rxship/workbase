# 06-allow-rdp-users.ps1
# Run on NBF-MYPC01 as NORTHBRIDGE\rpatel-admin, in Terminal (Admin).
# Adds the domain group SG-MYPC-Users to the local Remote Desktop Users group.
# Section 6 replaces this with a GPO.

if ($env:COMPUTERNAME -ne "NBF-MYPC01") {
    Write-Host "This script is for NBF-MYPC01. You are on $env:COMPUTERNAME. Stopping." -ForegroundColor Red
    return
}

$LocalGroup  = "Remote Desktop Users"
$DomainGroup = "NORTHBRIDGE\SG-MYPC-Users"

$members = Get-LocalGroupMember -Group $LocalGroup
if ($members.Name -contains $DomainGroup) {
    Write-Host "$DomainGroup is already in $LocalGroup. Nothing to do." -ForegroundColor Yellow
} else {
    Add-LocalGroupMember -Group $LocalGroup -Member $DomainGroup
    Write-Host "Added $DomainGroup to $LocalGroup." -ForegroundColor Green
}

Get-LocalGroupMember -Group $LocalGroup | Select-Object Name, ObjectClass, PrincipalSource