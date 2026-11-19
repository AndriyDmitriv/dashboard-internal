variable "name" {
  type    = string
  default = "cert-manager"
}

variable "namespace" {
  type    = string
  default = "cert-manager"
}

variable "chart_version" {
  type        = string
  description = "Chart version"
  default     = "v1.21.3"
}

variable "acme_email" {
  type        = string
  description = "Let's Encrypt email"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.acme_email))
    error_message = "acme_email must be a valid email address."
  }
}

variable "ingress_class" {
  type        = string
  description = "IngressClass for HTTP-01"
}
