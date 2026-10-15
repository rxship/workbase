# 03-create-ous-users-groups.ps1
# Creates the Northbridge Freight OUs, security groups and staff accounts.
# Safe to run more than once: it skips anything that already exists.
# Run on NBF-DC01 as NORTHBRIDGE\rpatel-admin.

Import-Module ActiveDirectory

$Domain    = Get-ADDomain
$DomainDN  = $Domain.DistinguishedName      # DC=northbridge,DC=internal
$UpnSuffix = $Domain.DNSRoot                # northbridge.internal
$RootOU    = "OU=Northbridge,$DomainDN"
$StaffOU   = "OU=Staff,$RootOU"
$GroupsOU  = "OU=Groups,$RootOU"

# ---------- 1. OUs ----------
Write-Host "`n[1/3] Organizational units" -ForegroundColor Cyan

$ous = @(
    @{ Name = "Northbridge";   Path = $DomainDN }
    @{ Name = "Staff";         Path = $RootOU }
    @{ Name = "Groups";        Path = $RootOU }
    @{ Name = "Session Hosts"; Path = $RootOU }
    @{ Name = "Billing";       Path = $StaffOU }
    @{ Name = "Audit";         Path = $StaffOU }
    @{ Name = "HR";            Path = $StaffOU }
    @{ Name = "IT";            Path = $StaffOU }
)

foreach ($ou in $ous) {
    $dn = "OU=$($ou.Name),$($ou.Path)"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'") {
        Write-Host "  exists   $dn"
    } else {
        New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path -ProtectedFromAccidentalDeletion $true
        Write-Host "  created  $dn" -ForegroundColor Green
    }
}

# ---------- 2. Security groups ----------
Write-Host "`n[2/3] Security groups" -ForegroundColor Cyan

$groups = @(
    @{ Name = "SG-Billing-Modify";       Description = "Edit files in the Billing share" }
    @{ Name = "SG-Billing-Read";         Description = "Read-only access to the Billing share" }
    @{ Name = "SG-NightlyAudits-Modify"; Description = "Edit files in the Nightly Audits share" }
    @{ Name = "SG-NightlyAudits-Read";   Description = "Read-only access to the Nightly Audits share" }
    @{ Name = "SG-HR-Modify";            Description = "Edit files in the HR share (restricted)" }
    @{ Name = "SG-IT-Modify";            Description = "Edit files in the IT share (admin only)" }
    @{ Name = "SG-MYPC-Users";           Description = "Allowed to sign in to NBF-MYPC01 over RDP" }
)

foreach ($g in $groups) {
    if (Get-ADGroup -Filter "Name -eq '$($g.Name)'") {
        Write-Host "  exists   $($g.Name)"
    } else {
        New-ADGroup -Name $g.Name -GroupScope Global -GroupCategory Security `
            -Path $GroupsOU -Description $g.Description
        Write-Host "  created  $($g.Name)" -ForegroundColor Green
    }
}

# ---------- 3. Staff accounts ----------
Write-Host "`n[3/3] Staff accounts" -ForegroundColor Cyan

$staff = @(
    @{ First = "Sarah";  Last = "Mitchell"; Title = "Billing Lead";     OU = "Billing"
       Groups = @("SG-Billing-Modify", "SG-NightlyAudits-Modify") }
    @{ First = "Daniel"; Last = "Okafor";   Title = "Billing Analyst";  OU = "Billing"
       Groups = @("SG-Billing-Modify", "SG-NightlyAudits-Read") }
    @{ First = "Marcus"; Last = "Leblanc";  Title = "Billing Trainee";  OU = "Billing"
       Groups = @("SG-Billing-Read") }
    @{ First = "Priya";  Last = "Sharma";   Title = "Auditor";          OU = "Audit"
       Groups = @("SG-NightlyAudits-Modify") }
    @{ First = "Linda";  Last = "Chen";     Title = "HR Coordinator";   OU = "HR"
       Groups = @("SG-HR-Modify") }
    @{ First = "Rishi";  Last = "Patel";    Title = "IT Administrator"; OU = "IT"
       Groups = @("SG-IT-Modify") }
)

$tempPassword = Read-Host "Temporary password for all staff accounts" -AsSecureString

foreach ($p in $staff) {
    $sam      = "$($p.First).$($p.Last)".ToLower()
    $fullName = "$($p.First) $($p.Last)"

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Host "  exists   $sam"
    } else {
        New-ADUser -Name $fullName `
            -GivenName $p.First -Surname $p.Last -DisplayName $fullName `
            -SamAccountName $sam -UserPrincipalName "$sam@$UpnSuffix" `
            -Title $p.Title -Department $p.OU -Company "Northbridge Freight Ltd." `
            -Path "OU=$($p.OU),$StaffOU" `
            -AccountPassword $tempPassword -Enabled $true `
            -ChangePasswordAtLogon $false   # RDP + NLA cannot show the change-password screen
        Write-Host "  created  $sam ($($p.Title))" -ForegroundColor Green
    }

    # Everyone signs in to the shared desktop
    $allGroups = $p.Groups + "SG-MYPC-Users"
    foreach ($g in $allGroups) {
        Add-ADGroupMember -Identity $g -Members $sam
    }
}

Write-Host "`nDone." -ForegroundColor Cyan