# Las credenciales vienen de data.external.k3d_kubeconfig, cuyo valor es
# desconocido en plan time (el cluster aún no existe). Terraform difiere la
# configuración del provider al apply, igual que hacía con kind_cluster.lab.
provider "kubernetes" {
  host                   = data.external.k3d_kubeconfig.result["host"]
  cluster_ca_certificate = base64decode(data.external.k3d_kubeconfig.result["ca"])
  client_certificate     = base64decode(data.external.k3d_kubeconfig.result["cert"])
  client_key             = base64decode(data.external.k3d_kubeconfig.result["key"])
}

provider "helm" {
  kubernetes {
    host                   = data.external.k3d_kubeconfig.result["host"]
    cluster_ca_certificate = base64decode(data.external.k3d_kubeconfig.result["ca"])
    client_certificate     = base64decode(data.external.k3d_kubeconfig.result["cert"])
    client_key             = base64decode(data.external.k3d_kubeconfig.result["key"])
  }
}
