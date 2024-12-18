provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "<subscription_id>"
}

# Resource Group
resource "azurerm_resource_group" "cheap_env" {
  name     = "cheap-env-rg"
  location = "UK South"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "cheap-env-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.cheap_env.location
  resource_group_name = azurerm_resource_group.cheap_env.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "cheap-env-subnet"
  resource_group_name  = azurerm_resource_group.cheap_env.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "cheap-env-nic"
  location            = azurerm_resource_group.cheap_env.location
  resource_group_name = azurerm_resource_group.cheap_env.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "cheap-env-public-ip"
  location            = azurerm_resource_group.cheap_env.location
  resource_group_name = azurerm_resource_group.cheap_env.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# TLS Key Pair for SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Azure Spot Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "cheap-env-vm"
  resource_group_name = azurerm_resource_group.cheap_env.name
  location            = azurerm_resource_group.cheap_env.location
  size                = "Standard_DS1_v2"  # VM size
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "cheap-env-os-disk"
  }

  eviction_policy = "Deallocate" # Spot instance eviction setting
  priority        = "Spot"

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_5"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF
  )
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "cheap-env-nsg"
  location            = azurerm_resource_group.cheap_env.location
  resource_group_name = azurerm_resource_group.cheap_env.name
}

# Allow HTTP Traffic
resource "azurerm_network_security_rule" "http_rule" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "80"
  resource_group_name         = azurerm_resource_group.cheap_env.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Allow SSH Traffic
resource "azurerm_network_security_rule" "ssh_rule" {
  name                        = "allow-ssh"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  resource_group_name         = azurerm_resource_group.cheap_env.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Associate NSG with Network Interface
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Outputs
output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
