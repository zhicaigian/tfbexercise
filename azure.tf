# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.rgName
  location = var.rgLocation
}

#virtual network/VPC
resource "azurerm_virtual_network" "vnet" {
  name                = "myTFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#subnet
resource "azurerm_subnet" "subnet" {
  name                 = "myTFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#network security group for our resource
resource "azurerm_network_security_group" "nsg" {
  name                = "myTFNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  #firewall rules for web port 80 tcp
  security_rule {
    name                       = "WebPort80Tcp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#public ip address
resource "azurerm_public_ip" "publicIP" {
  name                = "myTFPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

#network interface card configuration
resource "azurerm_network_interface" "nic" {
  name                = "myTFNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNICConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.publicIP.id
  }
}

#linux vm 
resource "azurerm_virtual_machine" "vm" {
  name                = "myTFVM"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  #a vm needs NIC so..
  network_interface_ids = [azurerm_network_interface.nic.id]

  #WARNING: DO NOT USE THIS IN PRODUCTION UNLESS IN CONFIG
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  #vm size
  vm_size = "Standard_B1ls"

  #os profile
  os_profile {
    computer_name  = "azureVMNAME"
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data = file("files/web_bootstrap.sh")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  #we need a storage
  storage_os_disk {
    name              = "myOSDisk"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  #we os info for our storage
  storage_image_reference {
    # for reference, refer to az cli command:
    # az vm image list --output table
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
} //end of vm resource

# Use this data source to access information about a set of existing Public IP Addresses.
# Data sources allow data to be fetched or computed for use elsewhere in Terraform configuration.
data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicIP.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_virtual_machine.vm
  ]
}

#this is retrieved from our data source.
output "public_ip_address" {
  value = data.azurerm_public_ip.ip.ip_address #note the "data."
}