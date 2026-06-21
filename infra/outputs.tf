output "kubeconfig_context" {
  description = "Contexto de kubeconfig para el cluster k3d"
  value       = "k3d-${var.cluster_name}"
}

output "argocd_url" {
  description = "URL de la UI de ArgoCD"
  value       = "http://argocd.${var.base_domain}"
}

output "base_domain" {
  description = "Dominio base usado para los hosts del lab"
  value       = var.base_domain
}

output "argocd_admin_user" {
  description = "Usuario admin de ArgoCD"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "Password inicial de admin (cámbialo tras el primer login)"
  value       = data.kubernetes_secret.argocd_initial_admin.data["password"]
  sensitive   = true
}

output "epub_to_audiobook_url" {
  description = "URL del frontend de epub-to-audiobook"
  value       = "http://epub-to-audiobook.${var.base_domain}"
}

output "flower_url" {
  description = "URL del dashboard Flower (monitorización Celery)"
  value       = "http://flower.${var.base_domain}"
}
