resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_prefix = var.cluster_name

  kubernetes_version      = var.k8s_version
  sku_tier                = "Free"
  private_cluster_enabled = false

  network_profile {
    network_plugin = "kubenet"
  }

  default_node_pool {
    name                = replace("${substr(var.cluster_name, 0, min(length("${var.cluster_name}"), 6))}", "-", "")
    vnet_subnet_id      = var.vnet_subnet
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 5
    vm_size             = "Standard_DS2_v2"
    type                = "VirtualMachineScaleSets"
    os_disk_size_gb     = 50
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Name            = "${var.cluster_name}_tsb_sandbox_blue"
  })

}

resource "azurerm_role_assignment" "attach_acr" {
  scope                            = var.registry_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

