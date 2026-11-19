locals {
  service_annotations = merge(
    var.public_ip_name == null ? {} : {
      "service.beta.kubernetes.io/azure-pip-name" = var.public_ip_name
    },
    var.public_ip_resource_group == null ? {} : {
      "service.beta.kubernetes.io/azure-load-balancer-resource-group" = var.public_ip_resource_group
    },
  )
}

resource "helm_release" "wireguard" {
  name             = var.name
  namespace        = var.namespace
  chart            = "${path.module}/charts"
  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      image = {
        tag = var.image_tag
      }
      server = {
        url            = var.server_url
        port           = var.server_port
        peers          = join(",", var.peers)
        peerDns        = var.peer_dns
        internalSubnet = var.internal_subnet
        allowedIps     = join(",", var.allowed_ips)
      }
      service = {
        annotations              = local.service_annotations
        loadBalancerSourceRanges = var.load_balancer_source_ranges
      }
      persistence = {
        size             = var.persistence_size
        storageClassName = var.storage_class_name
      }
    })
  ]
}
