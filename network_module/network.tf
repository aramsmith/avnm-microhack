variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "cidr" {
  type = string
}

variable "vmsize" {
  type = string
}

variable "prefix" {
  type = string
}

variable "admin_username" {
 type = string
}

variable "admin_password" {
  type =  string
  sensitive = true
}

locals {
  Subnets = cidrsubnets(var.cidr,8,11)
  cidrDefaultSubnet = local.Subnets[0]
  cidrBastionSubnet = local.Subnets[1]
}

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-${var.prefix}"
  location = var.region
 
  tags = {
    environment = var.project
    deployment  = var.prefix
    }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cidr]
  subnet {
        name                 = "infra-${var.prefix}-subnet"
        address_prefix       = local.cidrDefaultSubnet
        security_group       = azurerm_network_security_group.nsg.id
    }

  tags = {
    location = var.region
    }
}

resource "azurerm_subnet" "BastionSubnet" {
    count                = var.prefix == "hub" ? 1 : 0
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    name                 = "AzureBastionSubnet"
    address_prefixes     = [local.cidrBastionSubnet]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic" {
  name                 = "${var.prefix}-vm-nic"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_virtual_network.vnet.subnet.*.id[0]
    private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.vmsize
  delete_os_disk_on_termination = true
 
   storage_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_public_ip" "bastion-pip" {
  count               = var.prefix == "hub" ? 1 : 0
  name                = "${var.prefix}-bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-host" {
  count               = var.prefix == "hub" ? 1 : 0
  name                = "${var.prefix}-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bastion-host"
    subnet_id            = azurerm_subnet.BastionSubnet[0].id
    public_ip_address_id = azurerm_public_ip.bastion-pip[0].id
 }
}

  resource "azurerm_network_manager" "avnm" {
  count               = var.prefix == "hub" ? 1 : 0
  name                = "avnmmicrohack"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
  scope_accesses = ["Connectivity", "SecurityAdmin"]
  description    = "Azure Virtual Network Manager for Microsoft"
}
