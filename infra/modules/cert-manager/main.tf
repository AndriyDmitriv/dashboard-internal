terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = var.name
  namespace        = var.namespace
  repository       = "oci://quay.io/jetstack/charts"
  chart            = "cert-manager"
  version          = var.chart_version
  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      crds = {
        enabled = true
        keep    = true
      }
    })
  ]
}

# ClusterIssuers via helm: kubernetes_manifest needs CRDs at plan time
resource "helm_release" "issuers" {
  name      = "${var.name}-issuers"
  namespace = var.namespace
  chart     = "${path.module}/issuers"

  values = [
    yamlencode({
      email        = var.acme_email
      ingressClass = var.ingress_class
    })
  ]

  depends_on = [helm_release.cert_manager]
}
