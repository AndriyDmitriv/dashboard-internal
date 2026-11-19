variable "name" {
  type    = string
  default = "haproxy"
}

variable "namespace" {
  type    = string
  default = "haproxy-controller"
}

variable "chart_version" {
  type        = string
  description = "Chart version"
  default     = "1.57.1"
}

variable "ingress_class" {
  type    = string
  default = "haproxy"
}

variable "default_class" {
  type        = bool
  description = "Default IngressClass"
  default     = true
}

variable "replica_count" {
  type    = number
  default = 2
}

variable "public_ip_name" {
  type        = string
  description = "Static public IP name, null = auto"
  default     = null
}

variable "load_balancer_source_ranges" {
  type    = list(string)
  default = []
}
