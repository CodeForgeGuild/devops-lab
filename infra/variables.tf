variable "cluster_name" {
  description = "Nombre del cluster k3d"
  type        = string
  default     = "devops-lab"
}

variable "argocd_namespace" {
  description = "Namespace donde se instala ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Versión del chart argo-cd (repo argoproj/argo-helm)"
  type        = string
  default     = "9.5.21"
}

variable "traefik_chart_version" {
  description = "Versión del chart traefik (repo traefik.github.io/charts)"
  type        = string
  default     = "33.0.0"
}

variable "ingress_host_http_port" {
  description = "Puerto en localhost mapeado al 80 del ingress controller"
  type        = number
  default     = 80
}

variable "ingress_host_https_port" {
  description = "Puerto en localhost mapeado al 443 del ingress controller"
  type        = number
  default     = 443
}

variable "base_domain" {
  description = <<-EOT
    Dominio base para los hosts del lab (argocd.<base_domain>, etc).
    Por defecto "devops.lab": un TLD inventado que solo existe en /etc/hosts.
    Alternativa sin tocar /etc/hosts: "127.0.0.1.sslip.io".
  EOT
  type        = string
  default     = "devops.lab"
}
