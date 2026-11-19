variable "name" {
  type    = string
  default = "argocd-apps"
}

variable "namespace" {
  type        = string
  description = "Argo CD namespace"
  default     = "argocd"
}

variable "chart_version" {
  type        = string
  description = "Chart version"
  default     = "2.0.8"
}

variable "applications" {
  description = "Applications by name"
  type = map(object({
    repo_url              = string
    path                  = string
    target_revision       = optional(string, "HEAD")
    destination_namespace = string
    project               = optional(string, "default")
    release_name          = optional(string)
    helm_values           = optional(any)
    value_files           = optional(list(string), [])
    prune                 = optional(bool, true)
    self_heal             = optional(bool, true)
  }))
  default = {}
}
