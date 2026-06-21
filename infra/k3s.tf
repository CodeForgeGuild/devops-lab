resource "null_resource" "k3s_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    http_port    = var.ingress_host_http_port
    https_port   = var.ingress_host_https_port
  }

  provisioner "local-exec" {
    command = <<-EOT
      k3d cluster create ${var.cluster_name} \
        --image rancher/k3s:v1.30.12-k3s1 \
        --k3s-arg "--disable=traefik@server:0" \
        --port "${var.ingress_host_http_port}:80@loadbalancer" \
        --port "${var.ingress_host_https_port}:443@loadbalancer" \
        --wait
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }
}

# Extrae las credenciales del cluster k3d para configurar los providers.
# Al tener depends_on sobre un recurso que aún no existe, Terraform difiere
# su evaluación al apply (no al plan), lo que evita el error de "context not
# found" antes de que el cluster esté levantado — mismo patrón que kind usaba.
data "external" "k3d_kubeconfig" {
  depends_on = [null_resource.k3s_cluster]

  program = ["bash", "-c", <<-SCRIPT
    set -euo pipefail
    TMP=$(mktemp)
    trap 'rm -f $TMP' EXIT
    k3d kubeconfig get '${var.cluster_name}' > $TMP
    kubectl --kubeconfig $TMP config view --minify --raw -o json | jq '{
      host: .clusters[0].cluster.server,
      ca:   .clusters[0].cluster["certificate-authority-data"],
      cert: .users[0].user["client-certificate-data"],
      key:  .users[0].user["client-key-data"]
    }'
  SCRIPT
  ]
}
