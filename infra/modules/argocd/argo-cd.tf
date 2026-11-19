resource "helm_release" "argo_cd" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  values = concat(
    [file("${path.module}/values.yaml")],
    var.extra_values
  )

  create_namespace = true
}

