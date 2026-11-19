resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = coalesce(var.dns_prefix, var.cluster_name)
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags
  support_plan        = var.support_plan
  sku_tier            = var.sku_tier

  dynamic "monitor_metrics" {
    for_each = var.monitor_metrics_enabled ? [1] : []
    content {
      annotations_allowed = null
      labels_allowed      = null
    }
  }

  default_node_pool {
    name = var.system_node_pool_name
    # autoscaler owns node_count
    node_count                  = var.enable_auto_scaling ? null : var.system_node_count
    vm_size                     = var.system_node_vm_size
    vnet_subnet_id              = var.cluster_subnet_id
    os_disk_size_gb             = var.system_os_disk_size_gb
    temporary_name_for_rotation = var.temporary_name_for_rotation
    auto_scaling_enabled        = var.enable_auto_scaling
    min_count                   = var.min_count
    max_count                   = var.max_count
    dynamic "upgrade_settings" {
      for_each = var.enable_default_pool_upgrade_settings ? [1] : []
      content {
        max_surge                     = var.default_pool_upgrade_max_surge
        drain_timeout_in_minutes      = var.default_pool_drain_timeout
        node_soak_duration_in_minutes = var.default_pool_node_soak
      }
    }
  }

  network_profile {
    network_plugin      = var.network_profile_config.network_plugin
    service_cidr        = var.network_profile_config.service_cidr
    dns_service_ip      = var.network_profile_config.dns_service_ip
    network_plugin_mode = try(var.network_profile_config.network_plugin_mode, null)
    network_policy      = try(var.network_profile_config.network_policy, null)
  }

  identity {
    type = "SystemAssigned"
  }
  dynamic "upgrade_override" {
    for_each = var.enable_upgrade_override ? [1] : []
    content {
      force_upgrade_enabled = var.enable_force_upgrade
    }
  }
  dynamic "oms_agent" {
    for_each = var.enable_log_analytics ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = var.oms_msi_auth_enabled
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_pools" {
  for_each                    = var.user_node_pools
  name                        = each.key
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.main.id
  vm_size                     = each.value.vm_size
  os_type                     = each.value.os_type
  vnet_subnet_id              = coalesce(each.value.vnet_subnet_id, var.cluster_subnet_id)
  auto_scaling_enabled        = each.value.enable_auto_scaling
  min_count                   = each.value.min_count
  max_count                   = each.value.max_count
  priority                    = each.value.priority
  node_labels                 = each.value.node_labels
  node_taints                 = each.value.node_taints
  tags                        = var.tags
  temporary_name_for_rotation = "${each.key}temprot"
}