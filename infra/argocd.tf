resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }

  depends_on = [null_resource.k3s_cluster]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      server = {
        # --insecure: el server habla http puro. El ingress termina ahí
        # (sin TLS por ahora); es lo más simple para un lab local.
        extraArgs = ["--insecure"]
      }
      configs = {
        params = {
          "redis.server" = "argocd-redis.argocd.svc.cluster.local:6379"
        }
      }

      redis = {
        enabled = true
      }
    })
  ]

  depends_on = [helm_release.traefik]
}

resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = "argocd.${var.base_domain}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}

# ArgoCD genera este secret al primer arranque con el password de "admin".
data "kubernetes_secret" "argocd_initial_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

# Application bootstrap: sincroniza gitops/platform/ del repo devops-lab.
# Desde ahí el ApplicationSet descubre y despliega el resto de apps.
resource "null_resource" "argocd_bootstrap" {
  triggers = {
    argocd_release_id = helm_release.argocd.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      TMP=$(mktemp)
      trap 'rm -f "$TMP"' EXIT
      k3d kubeconfig get '${var.cluster_name}' > "$TMP"
      kubectl --kubeconfig "$TMP" apply -f - <<'MANIFEST'
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: platform
        namespace: ${var.argocd_namespace}
        finalizers:
          - resources-finalizer.argocd.argoproj.io
      spec:
        project: default
        source:
          repoURL: https://github.com/CodeForgeGuild/devops-lab.git
          targetRevision: main
          path: gitops/platform
        destination:
          server: https://kubernetes.default.svc
          namespace: ${var.argocd_namespace}
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true
      MANIFEST
    EOT
  }

  depends_on = [helm_release.argocd]
}
