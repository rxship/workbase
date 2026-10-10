# Stop both VMs every night at 11PM Toronto Time
# Just in case if I forget to manually turn them off

resource "azurerm_dev_test_global_vm_shutdown_schedule" "dc01" {
  virtual_machine_id    = azurerm_windows_virtual_machine.dc01.id
  location              = azurerm_resource_group.workbase.location
  enabled               = true
  daily_recurrence_time = "2300"
  timezone              = "Eastern Standard Time"
  tags                  = local.tags

  notification_settings {
    enabled = false
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "mypc01" {
  virtual_machine_id    = azurerm_windows_virtual_machine.mypc01.id
  location              = azurerm_resource_group.workbase.location
  enabled               = true
  daily_recurrence_time = "2300"
  timezone              = "Eastern Standard Time"
  tags                  = local.tags

  notification_settings {
    enabled = false
  }
}