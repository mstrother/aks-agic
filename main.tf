terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.67"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.virtual_network_address_prefix]

  subnet {
    name           = var.aks_subnet_name
    address_prefix = var.aks_subnet_address_prefix
  }

  subnet {
    name           = var.appgw_subnet_name
    address_prefix = var.app_gateway_subnet_address_prefix
  }
}

data "azurerm_subnet" "kubesubnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on = [azurerm_virtual_network.vnet]
}

data "azurerm_subnet" "appgwsubnet" {
  name                 = var.appgw_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on = [azurerm_virtual_network.vnet]
}

# data "azurerm_user_assigned_identity" "aks" {
#   name                = "${azurerm_kubernetes_cluster.aks.name}-agentpool"
#   resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
# }

# data "azurerm_user_assigned_identity" "ingress" {
#   name                = "ingressapplicationgateway-${azurerm_kubernetes_cluster.aks.name}"
#   resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
# }

# data "azurerm_kubernetes_cluster_node_pool" "agentpool" {
#   name                    = "agentpool"
#   kubernetes_cluster_name = azurerm_kubernetes_cluster.aks.name
#   resource_group_name     = azurerm_resource_group.rg.name
# }


resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.aks_name
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = var.aks_name
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.aks_private_cluster

  default_node_pool {
    name            = "agentpool"
    node_count      = var.aks_node_count
    vm_size         = var.aks_vm_size
    os_disk_size_gb = var.aks_os_disk_size
    max_pods        = 100
    vnet_subnet_id  = data.azurerm_subnet.kubesubnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = var.aks_enable_rbac
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }

  # addon_profile {
  #   ingress_application_gateway {
  #     enabled    = true
  #     gateway_id = resource.azurerm_application_gateway.appgw.id
  #   }
  # }

  depends_on = [azurerm_application_gateway.appgw]
}

resource "azurerm_public_ip" "pip" {
  name                = "appgw-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = var.app_gateway_tier
    tier     = var.app_gateway_tier
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = data.azurerm_subnet.appgwsubnet.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "beap"
  }

  backend_http_settings {
    name                  = "be-htst"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "httplstn"
    frontend_ip_configuration_name = "feip"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "httplstn"
    backend_address_pool_name  = "beap"
    backend_http_settings_name = "be-htst"
  }
}

# resource "azurerm_role_assignment" "ra1" {
#   scope                = data.azurerm_subnet.kubesubnet.id
#   role_definition_name = "Network Contributor"
#   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
#   depends_on = [azurerm_virtual_network.vnet]
# }

# resource "azurerm_role_assignment" "ra4" {
#   scope                = azurerm_application_gateway.appgw.id
#   role_definition_name = "Contributor"
#   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
# }

# resource "azurerm_role_assignment" "ra5" {
#   scope                = azurerm_resource_group.rg.id
#   role_definition_name = "Reader"
#   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
# }

# resource "azurerm_role_assignment" "ra6" {
#   scope                = data.azurerm_kubernetes_cluster_node_pool.agentpool.id
#   role_definition_name = "Contributor"
#   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
#   depends_on           = [data.azurerm_user_assigned_identity.ingress, data.azurerm_kubernetes_cluster_node_pool.agentpool]
# }
