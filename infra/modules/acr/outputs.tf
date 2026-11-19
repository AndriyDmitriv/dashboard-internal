output "id" {
  value = azurerm_container_registry.main.id
}

output "name" {
  value = azurerm_container_registry.main.name
}

output "login_server" {
  value = azurerm_container_registry.main.login_server
}

output "github_client_id" {
  description = "CI identity client ID"
  value       = one(azurerm_user_assigned_identity.github[*].client_id)
}
