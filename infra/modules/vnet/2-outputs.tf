output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "Subnet IDs by name"
  value = merge(
    { for k, v in azurerm_subnet.main : k => v.id },
    var.private_endpoints_enabled ? { "private-endpoints-subnet" = azurerm_subnet.private_endpoints[0].id } : {}
  )
}

output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name
}

#output "redis_subnet_id" {
#  value = azurerm_subnet.main["redis-subnet"].id
#}


output "private_dns_zone_id" {
  description = "PostgreSQL DNS zone ID"
  value       = one(azurerm_private_dns_zone.postgres[*].id)
}

output "postgres_private_dns_zone_id" {
  description = "PostgreSQL DNS zone ID (from private_dns_zones)"
  value       = try(azurerm_private_dns_zone.main["aigateway-pg-prod.private.postgres.database.azure.com"].id, null)
}

output "private_endpoint_subnet_id" {
  description = "Private endpoints subnet ID"
  value       = var.private_endpoints_enabled ? azurerm_subnet.private_endpoints[0].id : try(azurerm_subnet.main["private-endpoints-subnet"].id, null)
}

output "blob_private_dns_zone_id" {
  description = "Blob DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.blob.core.windows.net"].id : try(azurerm_private_dns_zone.main["privatelink.blob.core.windows.net"].id, null)
}

output "file_private_dns_zone_id" {
  description = "File DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.file.core.windows.net"].id : try(azurerm_private_dns_zone.main["privatelink.file.core.windows.net"].id, null)
}

output "keyvault_private_dns_zone_id" {
  description = "Key Vault DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.vaultcore.azure.net"].id : try(azurerm_private_dns_zone.main["privatelink.vaultcore.azure.net"].id, null)
}

output "appservice_private_dns_zone_id" {
  description = "App Service DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.azurewebsites.net"].id : try(azurerm_private_dns_zone.main["privatelink.azurewebsites.net"].id, null)
}

output "openai_private_dns_zone_id" {
  description = "OpenAI DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.openai.azure.com"].id : null
}

output "search_private_dns_zone_id" {
  description = "Search DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.search.windows.net"].id : null
}

output "monitor_private_dns_zone_id" {
  description = "Monitor DNS zone ID"
  value       = var.private_endpoints_enabled ? azurerm_private_dns_zone.private_endpoints["privatelink.monitor.azure.com"].id : null
}
