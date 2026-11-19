terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
  }
}

resource "helm_release" "apps" {
  name       = var.name
  namespace  = var.namespace
  repository = "oci://ghcr.io/argoproj/argo-helm"
  chart      = "argocd-apps"
  version    = var.chart_version

  values = [
    yamlencode({
      applications = {
        for name, app in var.applications : name => {
          namespace = var.namespace
          project   = app.project
          finalizers = [
            "resources-finalizer.argocd.argoproj.io",
          ]
          source = merge(
            {
              repoURL        = app.repo_url
              targetRevision = app.target_revision
              path           = app.path
            },
            app.helm_values == null && length(app.value_files) == 0 ? {} : {
              helm = merge(
                { releaseName = coalesce(app.release_name, name) },
                length(app.value_files) == 0 ? {} : { valueFiles = app.value_files },
                app.helm_values == null ? {} : { valuesObject = app.helm_values },
              )
            },
          )
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = app.destination_namespace
          }
          syncPolicy = {
            automated = {
              prune    = app.prune
              selfHeal = app.self_heal
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    })
  ]
}
