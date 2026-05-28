resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  create_namespace = false

  values = [
    yamlencode({
      server = {
        service = {
          type = "NodePort"
        }

        ingress = {
          enabled = false
        }
      }
    })
  ]
}

resource "kubectl_manifest" "root_app" {
  yaml_body = file("${path.module}/../gitops/bootstrap/root.yml")

  depends_on = [ helm_release.argocd ]
}