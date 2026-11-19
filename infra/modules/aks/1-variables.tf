variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "location" {
  description = "Region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "K8s version"
  type        = string
  default     = "1.29.2"
}

variable "cluster_subnet_id" {
  description = "Node subnet ID"
  type        = string
}

variable "system_node_pool_name" {
  description = "System pool name"
  type        = string
  default     = "systempool"
}

variable "system_node_count" {
  description = "System pool node count"
  type        = number
  default     = 2
}

variable "system_node_vm_size" {
  description = "System pool VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_auto_scaling" {
  description = "Autoscaling"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Min nodes"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Max nodes"
  type        = number
  default     = 3
}

variable "system_os_disk_size_gb" {
  type    = number
  default = 30
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "network_profile_config" {
  description = "Network profile"
  type = object({
    network_plugin      = optional(string, "azure")
    service_cidr        = optional(string, "10.1.0.0/16")
    dns_service_ip      = optional(string, "10.1.0.10")
    network_plugin_mode = optional(string)
    network_policy      = optional(string) # azure | calico | cilium
  })
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics"
  type        = bool
  default     = false
}

variable "oms_msi_auth_enabled" {
  description = "MSI auth for monitoring"
  type        = bool
  default     = false
}

#dynamic "upgrade_settings"
variable "default_pool_upgrade_max_surge" {
  description = "Upgrade max surge"
  type        = string
  default     = "10%"
}

variable "default_pool_drain_timeout" {
  description = "Drain timeout, min"
  type        = number
  default     = 0
}

variable "default_pool_node_soak" {
  description = "Node soak, min"
  type        = number
  default     = 0
}

variable "enable_default_pool_upgrade_settings" {
  description = "Manage upgrade settings"
  type        = bool
  default     = false
}

variable "user_node_pools" {
  description = "User node pools"
  type = map(object({
    vm_size             = string
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    os_type             = optional(string, "Linux")
    vnet_subnet_id      = optional(string)
    priority            = optional(string, "Regular")
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
  }))
  default = {}
}

variable "support_plan" {
  description = "KubernetesOfficial or AKSLongTermSupport"
  type        = string
  default     = "AKSLongTermSupport"
}

variable "sku_tier" {
  type    = string
  default = "Free"

}

variable "enable_upgrade_override" {
  type    = bool
  default = false
}

variable "enable_force_upgrade" {
  type    = bool
  default = false
}

variable "monitor_metrics_enabled" {
  description = "Managed Prometheus"
  type        = bool
  default     = false
}

variable "temporary_name_for_rotation" {
  type        = string
  default     = null
  description = "Temp pool name for rotation"
  validation {
    condition     = var.temporary_name_for_rotation == null || can(regex("^[a-z0-9]{3,12}$", var.temporary_name_for_rotation))
    error_message = "temporary_name_for_rotation must be 3–12 chars, lowercase letters and digits only."
  }
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix"
  default     = null
}
