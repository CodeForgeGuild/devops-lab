resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = "traefik"
  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      # k3d mapea los puertos al loadbalancer; service LoadBalancer
      # recibe el tráfico directamente sin necesidad de hostPort.
      service = {
        type = "LoadBalancer"
      }

      ingressClass = {
        enabled        = true
        isDefaultClass = true
      }

      # Dashboard sin auth, solo para el lab.
      additionalArguments = [
        "--api.insecure=true"
      ]

      ingressRoute = {
        dashboard = {
          enabled     = true
          entryPoints = ["web"]
          matchRule   = "Host(`traefik.${var.base_domain}`)"
        }
      }
    })
  ]

  depends_on = [null_resource.k3s_cluster]
}
