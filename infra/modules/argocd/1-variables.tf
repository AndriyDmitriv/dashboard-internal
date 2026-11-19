variable "name" {
  type    = string
  default = "argo-cd"
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type    = string
  default = "5.46.4"
}

variable "extra_values" {
  type        = list(string)
  description = "Extra values (YAML)"
  default     = []
}
