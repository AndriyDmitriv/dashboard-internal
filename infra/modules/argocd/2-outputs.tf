locals {
  argocd_fullname = strcontains(var.name, "argocd") ? var.name : "${var.name}-argocd"
}

output "argo_cd_server_service" {
  description = "Argo CD server DNS name"
  value       = "${local.argocd_fullname}-server.${var.namespace}.svc.cluster.local"
}

output "namespace" {
  description = "Namespace"
  value       = helm_release.argo_cd.namespace
}

output "initial_admin_secret" {
  description = "Admin password secret"
  value       = "${var.namespace}/argocd-initial-admin-secret"
}
