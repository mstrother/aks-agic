variable "resource_group_name" {
  default = "rg-aks-001"
}

variable "resource_group_location" {
  default = "eastus"
}

variable "virtual_network_name" {
  description = "Virtual network name"
  default     = "aksVirtualNetwork"
}

variable "virtual_network_address_prefix" {
  description = "VNET address prefix"
  default     = "10.1.0.0/18"
}

variable "aks_subnet_name" {
  default = "akssubnet"
}

variable "appgw_subnet_name" {
  default = "appgwsubnet"
}

variable "aks_name" {
  description = "AKS cluster name"
  default     = "aks-cluster1"
}

variable "aks_os_disk_size" {
  description = "Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 applies the default disk size for that agentVMSize."
  default     = 50
}

variable "aks_node_count" {
  description = "The number of agent nodes for the cluster."
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size"
  default     = "Standard_D3_v2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  default     = "1.19.11"
}

variable "aks_service_cidr" {
  description = "CIDR notation IP range from which to assign service cluster IPs"
  default     = "192.168.0.0/20"
}

variable "aks_dns_service_ip" {
  description = "DNS server IP address"
  default     = "192.168.0.10"
}

variable "aks_docker_bridge_cidr" {
  description = "CIDR notation IP for Docker bridge."
  default     = "172.17.0.1/16"
}

variable "aks_private_cluster" {
  description = "This provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located. "
  default     = "false"
}

variable "aks_subnet_address_prefix" {
  default = "10.1.0.0/22"
}

variable "app_gateway_subnet_address_prefix" {
  default = "10.1.4.0/24"
}

variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  default     = "ApplicationGateway1"
}

variable "app_gateway_tier" {
  description = "Tier of the Application Gateway tier"
  default     = "Standard_v2"
}

variable "app_gateway_instance_count" {
  default = "1"
}

variable "aks_enable_rbac" {
  description = "Enable RBAC on the AKS cluster. Defaults to false."
  default     = "true"
}
