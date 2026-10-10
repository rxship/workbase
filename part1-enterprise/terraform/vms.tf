# NBF-DC01 - DOMAIN CONTROLLER (PRIVATE ONLY)

resource "azurerm_network_interface" "dc01" {
  name                = "nbf-dc01-nic"
  location            = azurerm_resource_group.workbase.location
  resource_group_name = azurerm_resource_group.workbase.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.servers.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.1.4"
  }
}

resource "azurerm_windows_virtual_machine" "dc01" {
  name                  = "nbf-dc01"
  computer_name         = "NBF-DC01"
  resource_group_name   = azurerm_resource_group.workbase.name
  location              = azurerm_resource_group.workbase.location
  #Basv2 quota is 0 on this subscription
  # 2 CPU / 4 GB. Move to B2als_v2 when the quota is approved
  size                  = "Standard_D2als_v6"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.dc01.id]
  tags                  = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}

# NBF-MYPC01 - SHARED "MY PC" DESKTOP

resource "azurerm_public_ip" "mypc01" {
  name                = "nbf-mypc01-pip"
  location            = azurerm_resource_group.workbase.location
  resource_group_name = azurerm_resource_group.workbase.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "mypc01" {
  name                = "nbf-mypc01-nic"
  location            = azurerm_resource_group.workbase.location
  resource_group_name = azurerm_resource_group.workbase.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.servers.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.1.5"
    public_ip_address_id          = azurerm_public_ip.mypc01.id
  }
}

resource "azurerm_windows_virtual_machine" "mypc01" {
  name                  = "nbf-mypc01"
  computer_name         = "NBF-MYPC01"
  location              = azurerm_resource_group.workbase.location
  resource_group_name   = azurerm_resource_group.workbase.name
  size                  = "Standard_B2s_v2"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.mypc01.id]
  tags                  = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}