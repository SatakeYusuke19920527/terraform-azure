# Create a resource group
resource "azurerm_resource_group" "satake-terraform" {
  name     = "satake-terraform"
  location = "japanwest"
}