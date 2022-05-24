# Create a virtual network within the resource group
resource "azurerm_virtual_network" "satake-network" {
  name                = "satake-terraform-network"
  resource_group_name = azurerm_resource_group.satake-terraform.name
  location            = azurerm_resource_group.satake-terraform.location
  address_space       = ["10.0.0.0/16"]
}

# サブネットの作成
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.satake-terraform.name
  virtual_network_name = azurerm_virtual_network.satake-network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# パブリックIPの作成
resource "azurerm_public_ip" "publicip" {
    name                         = "myPublicIP"
    location                     = "japanwest"
    resource_group_name          = azurerm_resource_group.satake-terraform.name
    allocation_method            = "Dynamic"

}

#  NSGの作成と通信ルールの設定（SSH許可）
resource "azurerm_network_security_group" "nsg" {
    name                = "mynsg"
    location            = "japanwest"
    resource_group_name = azurerm_resource_group.satake-terraform.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# ネットワークインターフェイスの作成
resource "azurerm_network_interface" "nic" {
  name                      = "nic"
  location                  = "japanwest"
  resource_group_name       = azurerm_resource_group.satake-terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# SSHキーの作成
resource "tls_private_key" "myazssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.myazssh.private_key_pem 
    sensitive = true
}

# 仮想マシンの作成
# OSはCentOS7.6
resource "azurerm_linux_virtual_machine" "satake-vm" {
  name                = "satake-vm"
  resource_group_name = azurerm_resource_group.satake-terraform.name
  location              = "japanwest"
  size                = "Standard_DS1_v2"
  admin_username = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username       = "azureuser"
    public_key     = tls_private_key.myazssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.6"
    version   = "latest"
  }
}