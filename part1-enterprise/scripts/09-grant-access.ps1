# 09-grant-access.ps1
# Run on NBF-DC01 as NORTHBRIDGE\rpatel-admin, after an access request is approved.
# Adds a user to an SG-* group (or removes them with -Remove) and writes one log line.
#
# Examples:
#   C:\Scripts\09-grant-access.ps1 -User daniel.okafor -Group SG-NightlyAudits-Modify -Ticket REQ-1001 -Reason "Cover for Priya during vacation"
#   C:\Scripts\09-grant-access.ps1 -User daniel.okafor -Group SG-NightlyAudits-Modify -Ticket REQ-1002 -Reason "Priya is back" -Remove

param(
    [Parameter(Mandatory)] [string] $User,
    [Parameter(Mandatory)] [string] $Group,
    [Parameter(Mandatory)] [string] $Ticket,
    [Parameter(Mandatory)] [string] $Reason,
    [switch] $Remove
)

if ($env:COMPUTERNAME -ne "NBF-DC01") {
    Write-Host "This script is for NBF-DC01. You are on $env:COMPUTERNAME. Stopping." -ForegroundColor Red
    return
}

$LogFile = "C:\Shares\Company\IT\Access Requests\access-log.csv"

# Only SG-* groups. This blocks mistakes like adding someone to Domain Admins.
if ($Group -notlike "SG-*") {
    Write-Host "Only SG-* groups are allowed. Request refused." -ForegroundColor Red
    return
}

# -Filter returns nothing (instead of an error) when the name does not exist
$adUser  = Get-ADUser  -Filter "SamAccountName -eq '$User'"
$adGroup = Get-ADGroup -Filter "Name -eq '$Group'"

if (-not $adUser)  { Write-Host "User $User not found."   -ForegroundColor Red; return }
if (-not $adGroup) { Write-Host "Group $Group not found." -ForegroundColor Red; return }

$isMember = (Get-ADGroupMember -Identity $adGroup).SamAccountName -contains $User

if ($Remove) {
    if (-not $isMember) { Write-Host "$User is not in $Group. Nothing to do." -ForegroundColor Yellow; return }
    Remove-ADGroupMember -Identity $adGroup -Members $adUser -Confirm:$false
    $action = "Removed"
} else {
    if ($isMember) { Write-Host "$User is already in $Group. Nothing to do." -ForegroundColor Yellow; return }
    Add-ADGroupMember -Identity $adGroup -Members $adUser
    $action = "Added"
}

# Write the log line (create the folder the first time)
New-Item -Path (Split-Path $LogFile) -ItemType Directory -Force | Out-Null

[PSCustomObject]@{
    Date       = Get-Date -Format "yyyy-MM-dd HH:mm"
    Ticket     = $Ticket
    User       = $User
    Group      = $Group
    Action     = $action
    ApprovedBy = $env:USERNAME
    Reason     = $Reason
} | Export-Csv -Path $LogFile -Append -NoTypeInformation

Write-Host "Done: $action $User in $Group (ticket $Ticket)." -ForegroundColor Green
Write-Host "Tell $User to sign out and sign in again."