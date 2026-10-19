# 04-join-domain.ps1
# Run on NBF-MYPC01, signed in as the local admin (.\rpatel-admin).
# Run in Windows PowerShell 5.1 (the default in Terminal), NOT pwsh 7.
# Add-Computer does not exist in PowerShell 7.

$DomainName = "northbridge.internal"
$OUPath     = "OU=Session Hosts,OU=Northbridge,DC=northbridge,DC=internal"

# Stop if this computer is already in the domain
$cs = Get-CimInstance Win32_ComputerSystem
if ($cs.PartOfDomain -and $cs.Domain -eq $DomainName) {
    Write-Host "$env:COMPUTERNAME is already in $DomainName. Nothing to do." -ForegroundColor Yellow
    return
}

# Check 1: can DNS find a domain controller?
Write-Host "Looking for a domain controller..."
$srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$DomainName" -Type SRV -ErrorAction Stop |
       Where-Object Type -eq "SRV"
$dcName = $srv[0].NameTarget
Write-Host "Found DC: $dcName" -ForegroundColor Green

# Check 2: can we reach the DC on LDAP (port 389)?
if (-not (Test-NetConnection -ComputerName $dcName -Port 389 -InformationLevel Quiet)) {
    Write-Host "Cannot reach $dcName on port 389. Stop and fix the network first." -ForegroundColor Red
    return
}
Write-Host "DC is reachable." -ForegroundColor Green

# Join the domain. The password prompt keeps the password out of the script.
$cred = Get-Credential -UserName "NORTHBRIDGE\rpatel-admin" -Message "Domain admin password"

Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $cred -Restart -Force
