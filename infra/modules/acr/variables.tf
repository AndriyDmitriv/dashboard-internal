variable "name" {
  type        = string
  description = "Registry name"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}

variable "aks_kubelet_identity_object_id" {
  type        = string
  description = "Kubelet identity object ID"
}

variable "github_repository" {
  type        = string
  description = "GitHub repo owner/name, null = no CI"
  default     = null
}

variable "github_branch" {
  type        = string
  description = "CI branch"
  default     = "main"
}

variable "tags" {
  type    = map(string)
  default = {}
}
