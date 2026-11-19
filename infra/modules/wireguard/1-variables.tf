variable "name" {
  type        = string
  description = "Release name"
  default     = "wireguard"
}

variable "namespace" {
  type        = string
  description = "Namespace"
  default     = "wireguard"
}

variable "image_tag" {
  type        = string
  description = "Image tag"
  default     = "1.0.20260223-r0-ls129"
}

variable "server_url" {
  type        = string
  description = "Public endpoint for clients"
}

variable "server_port" {
  type        = number
  description = "UDP port"
  default     = 51820
}

variable "peers" {
  type        = list(string)
  description = "Client names"
  default     = ["admin"]

  validation {
    condition     = length(var.peers) > 0 && alltrue([for p in var.peers : can(regex("^[a-zA-Z0-9]+$", p))])
    error_message = "peers must be a non-empty list of alphanumeric names (linuxserver/wireguard restriction)."
  }
}

variable "peer_dns" {
  type        = string
  description = "DNS for clients"
  default     = "auto"
}

variable "internal_subnet" {
  type        = string
  description = "Tunnel network"
  default     = "10.13.13.0"
}

variable "allowed_ips" {
  type        = list(string)
  description = "Routes pushed to clients"
  default     = ["10.13.13.0/24"]
}

variable "public_ip_name" {
  type        = string
  description = "Static public IP name, null = auto"
  default     = null
}

variable "public_ip_resource_group" {
  type        = string
  description = "Public IP resource group, if not the node RG"
  default     = null
}

variable "load_balancer_source_ranges" {
  type        = list(string)
  description = "Allowed source CIDRs, empty = any"
  default     = []
}

variable "persistence_size" {
  type        = string
  description = "Keys PVC size"
  default     = "1Gi"
}

variable "storage_class_name" {
  type        = string
  description = "StorageClass, empty = default"
  default     = ""
}
