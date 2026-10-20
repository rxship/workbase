# 08-create-gpos.ps1
# Run on NBF-DC01 as NORTHBRIDGE\rpatel-admin, in Terminal (Admin).
# Creates and links two GPOs and sets their registry-based settings.
# Drive map and local group membership are added in the GPMC GUI (Preferences).

if ($env:COMPUTERNAME -ne "NBF-DC01") {
    Write-Host "This script is for NBF-DC01. You are on $env:COMPUTERNAME. Stopping." -ForegroundColor Red
    return
}

Import-Module GroupPolicy

$Domain  = "DC=northbridge,DC=internal"
$StaffOU = "OU=Staff,OU=Northbridge,$Domain"
$HostsOU = "OU=Session Hosts,OU=Northbridge,$Domain"

# Create a GPO if it does not exist, and link it to an OU if it is not linked
function New-LinkedGpo($Name, $Comment, $Target) {
    if (-not (Get-GPO -Name $Name -ErrorAction SilentlyContinue)) {
        New-GPO -Name $Name -Comment $Comment | Out-Null
        Write-Host "Created GPO $Name" -ForegroundColor Green
    }
    $links = (Get-GPInheritance -Target $Target).GpoLinks.DisplayName
    if ($links -notcontains $Name) {
        New-GPLink -Name $Name -Target $Target | Out-Null
        Write-Host "Linked $Name to $Target" -ForegroundColor Green
    }
}

# --- User GPO: staff lockdown ---
$UserGpo = "NBF-U-Staff-Lockdown"
New-LinkedGpo $UserGpo "Northbridge staff: drive map, no downloads, locked desktop" $StaffOU

# Block all downloads in Microsoft Edge (3 = block all)
Set-GPRegistryValue -Name $UserGpo -Key "HKCU\Software\Policies\Microsoft\Edge" `
    -ValueName "DownloadRestrictions" -Type DWord -Value 3 | Out-Null

# Block Control Panel and Settings
Set-GPRegistryValue -Name $UserGpo -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" -Type DWord -Value 1 | Out-Null

# Block Registry Editor
Set-GPRegistryValue -Name $UserGpo -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "DisableRegistryTools" -Type DWord -Value 1 | Out-Null

# Block Command Prompt (2 = block cmd, but still allow logon batch scripts)
Set-GPRegistryValue -Name $UserGpo -Key "HKCU\Software\Policies\Microsoft\Windows\System" `
    -ValueName "DisableCMD" -Type DWord -Value 2 | Out-Null

Write-Host "Set user settings in $UserGpo" -ForegroundColor Green

# --- Computer GPO: session hosts ---
$ComputerGpo = "NBF-C-SessionHosts"
New-LinkedGpo $ComputerGpo "Session host settings for NBF-MYPC01" $HostsOU

$TsKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"

# End disconnected sessions after 1 hour (value is in milliseconds)
Set-GPRegistryValue -Name $ComputerGpo -Key $TsKey `
    -ValueName "MaxDisconnectionTime" -Type DWord -Value 3600000 | Out-Null

# Disconnect idle sessions after 2 hours
Set-GPRegistryValue -Name $ComputerGpo -Key $TsKey `
    -ValueName "MaxIdleTime" -Type DWord -Value 7200000 | Out-Null

Write-Host "Set computer settings in $ComputerGpo" -ForegroundColor Green