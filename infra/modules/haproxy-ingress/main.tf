terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
  }
}

locals {
  service_annotations = merge(
    {
      # HTTP probe on / gets 404 from HAProxy, use TCP
      "service.beta.kubernetes.io/port_80_health-probe_protocol"  = "tcp"
      "service.beta.kubernetes.io/port_443_health-probe_protocol" = "tcp"
    },
    var.public_ip_name == null ? {} : {
      "service.beta.kubernetes.io/azure-pip-name" = var.public_ip_name
    },
  )
}

resource "helm_release" "haproxy" {
  name             = var.name
  namespace        = var.namespace
  repository       = "oci://ghcr.io/haproxytech/helm-charts"
  chart            = "kubernetes-ingress"
  version          = var.chart_version
  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      controller = {
        replicaCount = var.replica_count
        ingressClass = var.ingress_class
        ingressClassResource = {
          name    = var.ingress_class
          default = var.default_class
        }
        service = {
          type        = "LoadBalancer"
          annotations = local.service_annotations
          enablePorts = {
            http  = true
            https = true
            quic  = false
            stat  = false
            admin = false
          }
          loadBalancerSourceRanges = var.load_balancer_source_ranges
        }
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }
    })
  ]
}
