# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.84.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Main resource group
resource "azurerm_resource_group" "rg_main" {
  name     = var.resource_group
  location = var.location
}
resource "azurerm_public_ip" "ip" {
  name                = "MC_ESGI-SELWA"
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = azurerm_resource_group.rg_main.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.ip.name
  resource_group_name = azurerm_resource_group.rg_main.name
}


resource "azurerm_kubernetes_cluster" "k8" {
  name                = "k8-aks1"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  dns_prefix          = "k8aks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = azurerm_resource_group.rg_main.location
  sku                 = "Standard"
  admin_enabled       = false

}

# Roles
data "azurerm_client_config" "current" {
}
resource "azurerm_role_assignment" "AcrPull" {
  # principal_id         = azurerm_resource_group.rg_main.id
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
}
resource "azurerm_role_assignment" "AcrPush" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
}

