# 02-dns-forwarder.ps1
# NBF-DC01 answers northbridge.internal itself.
# every other name goes to azure DNS.
# run on NBF-DC01 as NORTHBRIDGE\rpatel-admin

$AzureDns = "168.63.129.16"

Set-DnsServerForwarder -IPAddress $AzureDns -UseRootHint $false

Write-Host "Forwarders now set to:" -ForegroundColor Cyan
Get-DnsServerForwarder | Select-Object IPAddress, UseRootHint