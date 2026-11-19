terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

resource "azurerm_container_registry" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.aks_kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

# GitHub Actions OIDC -> AcrPush
resource "azurerm_user_assigned_identity" "github" {
  count = var.github_repository == null ? 0 : 1

  name                = "id-${var.name}-github"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github" {
  count = var.github_repository == null ? 0 : 1

  name                      = "github-${replace(var.github_repository, "/", "-")}-${var.github_branch}"
  user_assigned_identity_id = azurerm_user_assigned_identity.github[0].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${coalesce(var.github_oidc_repo, var.github_repository)}:ref:refs/heads/${var.github_branch}"
}

resource "azurerm_role_assignment" "github_push" {
  count = var.github_repository == null ? 0 : 1

  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_user_assigned_identity.github[0].principal_id
  skip_service_principal_aad_check = true
}
