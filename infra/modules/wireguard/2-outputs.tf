output "namespace" {
  description = "Namespace"
  value       = helm_release.wireguard.namespace
}

output "endpoint" {
  description = "VPN endpoint"
  value       = "${var.server_url}:${var.server_port}"
}

output "peer_config_commands" {
  description = "Commands to get client configs"
  value = {
    for p in var.peers :
    p => "kubectl -n ${helm_release.wireguard.namespace} exec deploy/${var.name} -c wireguard -- cat /config/peer_${p}/peer_${p}.conf"
  }
}
