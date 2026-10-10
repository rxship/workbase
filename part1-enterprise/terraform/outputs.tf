output "mypc01_public_ip" {
  description = "RDP to this address"
  value       = azurerm_public_ip.mypc01.ip_address
}

output "dc01_private_ip" {
  description = "RDP to this from inside MYPC01"
  value       = azurerm_network_interface.dc01.private_ip_address
}