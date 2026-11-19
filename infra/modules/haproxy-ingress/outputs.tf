output "namespace" {
  value = helm_release.haproxy.namespace
}

output "ingress_class" {
  value = var.ingress_class
}
