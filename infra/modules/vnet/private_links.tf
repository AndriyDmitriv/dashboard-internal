# modules/networking/private_links.tf

resource "azurerm_private_dns_zone" "main" {
  for_each = var.private_dns_zones

  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = {
    for key, value in var.private_dns_zones :
    key => value if coalesce(value.enabled, true)
  }
  name                  = each.value.link_name != null ? each.value.link_name : "${azurerm_virtual_network.main.name}-link-to-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main[each.key].name
  virtual_network_id    = azurerm_virtual_network.main.id
}


resource "azurerm_private_dns_zone" "postgres" {
  count               = var.create_private_dns_zone_for_postgres ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.create_private_dns_zone_for_postgres ? 1 : 0
  name                  = "${var.vnet_name}-postgres-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_zone" "private_endpoints" {
  for_each = var.private_endpoints_enabled ? {
    "privatelink.blob.core.windows.net" = "aigateway-blob-dns-link-prod"
    "privatelink.file.core.windows.net" = "aigateway-file-dns-link-prod"
    "privatelink.vaultcore.azure.net"   = "aigateway-keyvault-dns-link-prod"
    "privatelink.azurewebsites.net"     = "aigateway-appservice-dns-link-prod"
    "privatelink.openai.azure.com"      = "aigateway-openai-dns-link-prod"
    "privatelink.search.windows.net"    = "aigateway-search-dns-link-prod"
    "privatelink.monitor.azure.com"     = "aigateway-ampls-dns-link-prod"
  } : {}

  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_endpoints" {
  for_each = var.private_endpoints_enabled ? {
    "privatelink.blob.core.windows.net" = "aigateway-blob-dns-link-prod"
    "privatelink.file.core.windows.net" = "aigateway-file-dns-link-prod"
    "privatelink.vaultcore.azure.net"   = "aigateway-keyvault-dns-link-prod"
    "privatelink.azurewebsites.net"     = "aigateway-appservice-dns-link-prod"
    "privatelink.openai.azure.com"      = "aigateway-openai-dns-link-prod"
    "privatelink.search.windows.net"    = "aigateway-search-dns-link-prod"
    "privatelink.monitor.azure.com"     = "aigateway-ampls-dns-link-prod"
  } : {}

  name                  = each.value
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_endpoints[each.key].name
  virtual_network_id    = azurerm_virtual_network.main.id
}