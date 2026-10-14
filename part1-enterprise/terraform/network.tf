locals {
  tags = {
    project = "WorkBase"
    part    = "1-enterprise"
    owner   = "Rishi"
  }
}

resource "azurerm_resource_group" "workbase" {
  name     = "rg-workbase"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "nbf" {
  name                = "nbf-vnet"
  location            = azurerm_resource_group.workbase.location
  resource_group_name = azurerm_resource_group.workbase.name
  address_space       = ["10.10.0.0/16"]
  dns_servers         = ["10.10.1.4"] //NBF-DC01 is the DNS server for the whole network
  tags                = local.tags
}

resource "azurerm_subnet" "servers" {
  name                 = "nbf-servers"
  resource_group_name  = azurerm_resource_group.workbase.name
  virtual_network_name = azurerm_virtual_network.nbf.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "nbf" {
  name                = "nbf-nsg"
  location            = azurerm_resource_group.workbase.location
  resource_group_name = azurerm_resource_group.workbase.name
  tags                = local.tags

  security_rule {
    name                       = "allow-rdp-from-rishi"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "${var.my_ip}/32"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "servers" {
  subnet_id                 = azurerm_subnet.servers.id
  network_security_group_id = azurerm_network_security_group.nbf.id
}