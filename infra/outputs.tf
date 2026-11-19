output "resource_group_name" {
  value = module.rg.name
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "aks_get_credentials" {
  description = "kubeconfig command"
  value       = "az aks get-credentials -g ${module.rg.name} -n ${module.aks.name}"
}

output "kubernetes_version" {
  value = local.kubernetes_version
}

output "wireguard_endpoint" {
  value = module.wireguard.endpoint
}

output "wireguard_peer_config_commands" {
  value = module.wireguard.peer_config_commands
}

output "argocd_url_via_vpn" {
  description = "Argo CD URL (VPN only)"
  value       = "http://${module.argocd.argo_cd_server_service}"
}

output "argocd_admin_password_command" {
  value = "kubectl -n ${module.argocd.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "ingress_public_ip" {
  description = "Point app_host DNS here"
  value       = azurerm_public_ip.ingress.ip_address
}

output "app_url" {
  value = "https://${var.app_host}"
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "github_actions_variables" {
  description = "GitHub Actions variables"
  value = var.github_repository == null ? null : {
    AZURE_CLIENT_ID       = module.acr.github_client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = var.subscription_id
    ACR_NAME              = module.acr.name
  }
}
