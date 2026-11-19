output "namespace" {
  value = helm_release.cert_manager.namespace
}

output "cluster_issuers" {
  description = "ClusterIssuer names"
  value       = ["letsencrypt-staging", "letsencrypt-prod"]
}
