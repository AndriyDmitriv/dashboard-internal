locals {
  rg_name      = "rg-${var.name_prefix}"
  vnet_name    = "vnet-${var.name_prefix}"
  cluster_name = "aks-${var.name_prefix}"
  aks_subnet   = "snet-aks"
  vpn_allowed_ips = concat(
    var.vnet_address_space,
    [var.service_cidr, "${var.wireguard_internal_subnet}/24"],
  )
  kubernetes_version = coalesce(
    var.kubernetes_version,
    data.azurerm_kubernetes_service_versions.current.latest_version,
  )
}
data "azurerm_kubernetes_service_versions" "current" {
  location        = var.location
  include_preview = false
}


module "rg" {
  source = "./modules/rg"

  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source = "./modules/vnet"

  resource_group_name = module.rg.name
  location            = module.rg.location
  vnet_name           = local.vnet_name
  vnet_address_space  = var.vnet_address_space
  tags                = var.tags

  subnets = {
    (local.aks_subnet) = {
      address_prefixes = [var.aks_subnet_prefix]
    }
  }
}

module "aks" {
  source              = "./modules/aks"
  cluster_name        = local.cluster_name
  location            = module.rg.location
  resource_group_name = module.rg.name
  kubernetes_version  = local.kubernetes_version
  cluster_subnet_id   = module.vnet.subnet_ids[local.aks_subnet]
  system_node_vm_size = var.system_node_vm_size
  enable_auto_scaling = true
  min_count           = var.system_node_min_count
  max_count           = var.system_node_max_count
  support_plan        = "KubernetesOfficial"
  sku_tier            = var.aks_sku_tier
  network_profile_config = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  tags = var.tags
}


resource "azurerm_public_ip" "wireguard" {
  name                = "pip-${var.name_prefix}-wireguard"
  resource_group_name = module.aks.node_resource_group
  location            = module.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}


module "argocd" {
  source = "./modules/argocd"

  chart_version = var.argocd_chart_version
}

module "wireguard" {
  source = "./modules/wireguard"

  server_url                  = azurerm_public_ip.wireguard.ip_address
  server_port                 = var.wireguard_port
  public_ip_name              = azurerm_public_ip.wireguard.name
  peers                       = var.wireguard_peers
  internal_subnet             = var.wireguard_internal_subnet
  allowed_ips                 = local.vpn_allowed_ips
  peer_dns                    = var.dns_service_ip
  load_balancer_source_ranges = var.wireguard_source_ranges
}

# --- ACR ---
data "azurerm_client_config" "current" {}

module "acr" {
  source = "./modules/acr"

  # globally unique, stable
  name                = "acr${var.name_prefix}${substr(sha1(var.subscription_id), 0, 8)}"
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags

  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id

  github_repository = var.github_repository
  github_oidc_repo  = var.github_oidc_repo
  github_branch     = coalesce(var.github_branch, var.app_target_revision)
}

# --- Ingress ---
resource "azurerm_public_ip" "ingress" {
  name                = "pip-${var.name_prefix}-ingress"
  resource_group_name = module.aks.node_resource_group
  location            = module.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

module "haproxy" {
  source = "./modules/haproxy-ingress"

  public_ip_name = azurerm_public_ip.ingress.name
}

module "cert_manager" {
  source = "./modules/cert-manager"

  acme_email    = var.acme_email
  ingress_class = module.haproxy.ingress_class
}

# --- Argo CD apps ---
module "argocd_apps" {
  source = "./modules/argocd-apps"

  namespace = module.argocd.namespace

  applications = {
    internal-dashboard = {
      repo_url              = var.app_repo_url
      path                  = "charts/internal-dashboard"
      target_revision       = var.app_target_revision
      destination_namespace = var.app_namespace
      release_name          = "dashboard"
      # tags are set by CI
      value_files = ["values-aks.yaml"]

      helm_values = {
        api = {
          image = {
            repository = "${module.acr.login_server}/internal-dashboard-api"
            pullPolicy = "IfNotPresent"
          }
        }
        web = {
          frontend = {
            repository = "${module.acr.login_server}/internal-dashboard-frontend"
            pullPolicy = "IfNotPresent"
          }
        }
        ingress = {
          className = module.haproxy.ingress_class
          host      = var.app_host
          annotations = {
            "cert-manager.io/cluster-issuer" = var.cluster_issuer
          }
          tls = {
            enabled = true
          }
        }
        networkPolicy = {
          traefikNamespace = module.haproxy.namespace
        }
      }
    }
  }

  depends_on = [module.argocd, module.haproxy, module.cert_manager]
}
