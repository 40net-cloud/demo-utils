##############################################################################################################
#
# Workshop student environment
#
##############################################################################################################

##############################################################################################################
# Virtual Machine
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-student${count.index}-VNET"
  address_space       = ["172.16.100.0/24"]
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup[count.index].name
  count               = var.ACCOUNTCOUNT
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.PREFIX}-student${count.index}-SUBNET"
  resource_group_name  = azurerm_resource_group.resourcegroup[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = ["172.16.100.0/24"]
  count                = var.ACCOUNTCOUNT
}


resource "azurerm_public_ip" "lnxapip" {
  name                = "${var.PREFIX}-student${count.index}-VM-ip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup[count.index].name
  allocation_method   = "Dynamic"
  count               = var.ACCOUNTCOUNT
}

resource "azurerm_network_interface" "lnxaifc" {
  name                 = "${var.PREFIX}-student${count.index}-VM-ifc"
  location             = var.LOCATION
  resource_group_name  = azurerm_resource_group.resourcegroup[count.index].name
  enable_ip_forwarding = false
  count                = var.ACCOUNTCOUNT

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lnxapip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "lnxavm" {
  name                  = "${var.PREFIX}-student${count.index}-VM"
  location              = var.LOCATION
  resource_group_name   = azurerm_resource_group.resourcegroup[count.index].name
  network_interface_ids = [azurerm_network_interface.lnxaifc[count.index].id]
  size               = "Standard_B1s"
  count                 = var.ACCOUNTCOUNT

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name              = "${var.PREFIX}-student${count.index}-VM-OSDISK"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "${var.PREFIX}-student${count.index}"
  admin_password = "StudentPassword123!"
  disable_password_authentication = false
  custom_data    = base64encode(templatefile("${path.module}/customdata-lnx.tpl", {}))
}

##############################################################################################################
# Shutdown schedule for virtual machine
##############################################################################################################

resource "azurerm_dev_test_global_vm_shutdown_schedule" "rg" {
  virtual_machine_id = azurerm_linux_virtual_machine.lnxavm[count.index].id
  location           = var.LOCATION
  enabled            = true
  count              = var.ACCOUNTCOUNT

  daily_recurrence_time = "1900"
  timezone              = "Central European Standard Time"


  notification_settings {
    enabled = false

  }
}

##############################################################################################################
# autoShutdownTimeZone Allowed values: Dateline Standard Time,UTC-11,Aleutian Standard Time,
# Hawaiian Standard Time,Marquesas Standard Time,Alaskan Standard Time,UTC-09,Pacific Standard Time (Mexico),
# UTC-08,Pacific Standard Time,US Mountain Standard Time,Mountain Standard Time (Mexico),
# Mountain Standard Time,Central America Standard Time,Central Standard Time,Easter Island Standard Time,
# Central Standard Time (Mexico),Canada Central Standard Time,SA Pacific Standard Time,
# Eastern Standard Time (Mexico),Eastern Standard Time,Haiti Standard Time,Cuba Standard Time,
# US Eastern Standard Time,Turks And Caicos Standard Time,Paraguay Standard Time,Atlantic Standard Time,
# Venezuela Standard Time,Central Brazilian Standard Time,SA Western Standard Time,Pacific SA Standard Time,
# Newfoundland Standard Time,Tocantins Standard Time,E. South America Standard Time,SA Eastern Standard Time,
# Argentina Standard Time,Greenland Standard Time,Montevideo Standard Time,Magallanes Standard Time,
# Saint Pierre Standard Time,Bahia Standard Time,UTC-02,Mid-Atlantic Standard Time,Azores Standard Time,
# Cape Verde Standard Time,UTC,GMT Standard Time,Greenwich Standard Time,Sao Tome Standard Time,
# Morocco Standard Time,W. Europe Standard Time,Central Europe Standard Time,Romance Standard Time,
# Central European Standard Time,W. Central Africa Standard Time,Jordan Standard Time,GTB Standard Time,
# Middle East Standard Time,Egypt Standard Time,E. Europe Standard Time,Syria Standard Time,
# West Bank Standard Time,South Africa Standard Time,FLE Standard Time,Israel Standard Time,
# Kaliningrad Standard Time,Sudan Standard Time,Libya Standard Time,Namibia Standard Time,
# Arabic Standard Time,Turkey Standard Time,Arab Standard Time,Belarus Standard Time,Russian Standard Time,
# E. Africa Standard Time,Iran Standard Time,Arabian Standard Time,Astrakhan Standard Time,
# Azerbaijan Standard Time,Russia Time Zone 3,Mauritius Standard Time,Saratov Standard Time,
# Georgian Standard Time,Volgograd Standard Time,Caucasus Standard Time,Afghanistan Standard Time,
# West Asia Standard Time,Ekaterinburg Standard Time,Pakistan Standard Time,Qyzylorda Standard Time,
# India Standard Time,Sri Lanka Standard Time,Nepal Standard Time,Central Asia Standard Time,
# Bangladesh Standard Time,Omsk Standard Time,Myanmar Standard Time,SE Asia Standard Time,
# Altai Standard Time,W. Mongolia Standard Time,North Asia Standard Time,N. Central Asia Standard Time,
# Tomsk Standard Time,China Standard Time,North Asia East Standard Time,Singapore Standard Time,
# W. Australia Standard Time,Taipei Standard Time,Ulaanbaatar Standard Time,Aus Central W. Standard Time,
# Transbaikal Standard Time,Tokyo Standard Time,North Korea Standard Time,Korea Standard Time,
# Yakutsk Standard Time,Cen. Australia Standard Time,AUS Central Standard Time,E. Australia Standard Time,
# AUS Eastern Standard Time,West Pacific Standard Time,Tasmania Standard Time,Vladivostok Standard Time,
# Lord Howe Standard Time,Bougainville Standard Time,Russia Time Zone 10,Magadan Standard Time,
# Norfolk Standard Time,Sakhalin Standard Time,Central Pacific Standard Time,Russia Time Zone 11,
# New Zealand Standard Time,UTC+12,Fiji Standard Time,Kamchatka Standard Time,Chatham Islands Standard Time,
# UTC+13,Tonga Standard Time,Samoa Standard Time,Line Islands Standard Time
##############################################################################################################
