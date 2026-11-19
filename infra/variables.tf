variable "subscription_id" {
  type        = string
  description = "Subscription ID"
}

variable "location" {
  type        = string
  description = "Region"
  default     = "westeurope"
}

variable "name_prefix" {
  type        = string
  description = "Name prefix, 3-12 lowercase/digits"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.name_prefix))
    error_message = "name_prefix must be 3-12 lowercase letters/digits."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet CIDR"
  default     = ["10.30.0.0/16"]
}

variable "aks_subnet_prefix" {
  type        = string
  description = "AKS node subnet"
  default     = "10.30.0.0/22"
}

variable "service_cidr" {
  type        = string
  description = "K8s service CIDR"
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "CoreDNS IP"
  default     = "10.100.0.10"
}

variable "kubernetes_version" {
  type        = string
  description = "K8s version, null = latest"
  default     = null
}

variable "system_node_vm_size" {
  type        = string
  description = "Node VM size"
  default     = "Standard_D2s_v7"
}

variable "system_node_min_count" {
  type    = number
  default = 1
}

variable "system_node_max_count" {
  type    = number
  default = 3
}

variable "aks_sku_tier" {
  type        = string
  description = "Free or Standard"
  default     = "Free"
}

variable "argocd_chart_version" {
  type        = string
  description = "argo-cd chart version"
  default     = "10.18.2"
}

variable "wireguard_peers" {
  type        = list(string)
  description = "VPN client names"
  default     = ["admin"]
}

variable "wireguard_port" {
  type    = number
  default = 51820
}

variable "wireguard_internal_subnet" {
  type        = string
  description = "VPN tunnel network"
  default     = "10.13.13.0"
}

variable "wireguard_source_ranges" {
  type        = list(string)
  description = "Allowed VPN source CIDRs"
  default     = []
}

variable "acme_email" {
  type        = string
  description = "Let's Encrypt email"
}

variable "cluster_issuer" {
  type        = string
  description = "letsencrypt-staging or letsencrypt-prod"
  default     = "letsencrypt-prod"

  validation {
    condition     = contains(["letsencrypt-staging", "letsencrypt-prod"], var.cluster_issuer)
    error_message = "cluster_issuer must be letsencrypt-staging or letsencrypt-prod."
  }
}

variable "app_host" {
  type        = string
  description = "App domain"
}

variable "app_repo_url" {
  type        = string
  description = "Git URL for Argo CD"
}

variable "app_target_revision" {
  type    = string
  default = "main"
}

variable "app_namespace" {
  type    = string
  default = "dashboard"
}

variable "github_repository" {
  type        = string
  description = "GitHub owner/repo for CI"
  default     = null
}

variable "github_branch" {
  type        = string
  description = "CI branch"
  default     = null
}
