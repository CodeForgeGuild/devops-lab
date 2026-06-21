# argocd-kind-lab

Cluster Kubernetes local (kind sobre Docker) + ArgoCD + Traefik, todo
provisionado con Terraform/OpenTofu. Sin pasos manuales de instalación: ni
`kind` CLI, ni `kubectl`, ni `helm` CLI, ni `argocd` CLI son necesarios para
levantar el lab.

## Por qué no hace falta instalar nada a mano

- El provider `tehcyx/kind` embebe la librería de kind (`sigs.k8s.io/kind`) y
  habla directo con el daemon de Docker. No necesita el binario `kind`.
- Los providers `kubernetes` y `helm` se configuran encadenados a los
  outputs del cluster (`kind_cluster.lab.endpoint`, certs, etc.), así que
  tampoco hace falta `kubectl` para aplicar nada.
- ArgoCD y Traefik se instalan como `helm_release`, usando sus charts
  oficiales directamente desde el provider `helm`.

## DNS: cómo funciona

El control-plane de kind mapea los puertos 80/443 del host hacia Traefik
(vía `hostPort` en sus entrypoints `web`/`websecure`). Cada servicio se
expone con un `Ingress` (`ingressClassName = "traefik"`) y un hostname bajo
`var.base_domain`.

Por defecto `base_domain = "devops.lab"`: un TLD inventado que nunca sale a
internet, solo vive en tu `/etc/hosts`. Necesitas agregar una línea con
todos los subdominios que vayas a usar:

```
127.0.0.1 argocd.devops.lab traefik.devops.lab app.devops.lab api.devops.lab flower.devops.lab
```

Esta es la única parte del stack que Terraform no toca: escribir en
`/etc/hosts` requiere sudo, y meter `sudo` en un `local-exec` no es buena
práctica (no es portable ni auditable). Es un paso manual, pero de red/OS,
no de instalación de software.

Si prefieres cero pasos manuales (sin tocar `/etc/hosts`), cambia
`base_domain = "127.0.0.1.sslip.io"`: es DNS público real que resuelve
cualquier subdominio que termine en `<ip>.sslip.io` a esa IP,
automáticamente.

**Por qué `/etc/hosts` y no un resolver wildcard propio (dnsmasq/CoreDNS):**
con 4-5 subdominios fijos y conocidos de antemano, un wildcard real no
aporta nada — solo paga dividendos cuando los nombres cambian seguido
(previews por PR, multi-tenant). Montar y mantener tu propio DNS server
para resolver un puñado de nombres fijos en tu laptop es una pieza más que
puede romperse, con configuración distinta por OS. Una línea en
`/etc/hosts`, escrita una vez, es la opción más simple que resuelve el
problema real.

## Requisitos

- Docker Engine corriendo localmente.
- Terraform >= 1.6 **o** OpenTofu (mismos archivos, sin cambios de código:
  cambia `terraform` por `tofu` en los comandos).
- Acceso a internet para descargar providers, charts e imágenes.

## Uso

```bash
terraform init
terraform apply
```

Al terminar:

```bash
terraform output -raw argocd_admin_password
terraform output argocd_url
```

o con los atajos del Makefile:

```bash
make init
make up
make password
make url
```

Abre la URL del output (`http://argocd.devops.lab` por defecto), usuario
`admin`, password el del output anterior. El dashboard de Traefik queda en
`http://traefik.devops.lab` (sin auth — es solo para el lab, no para algo
real).

Si quieres usar `kubectl` contra el cluster (opcional, no requerido para
levantar el lab):

```bash
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl get nodes
```

## Agregar frontend / API / Flower / SonarQube / cualquier otra app

**No van en este repo.** Van en el repo de GitOps como recursos `Application`
de ArgoCD. Este repo solo gestiona infraestructura del cluster:

| Recurso        | Dónde vive | Por qué |
|----------------|------------|---------|
| Cluster kind   | Este repo (Terraform) | Es el propio cluster |
| Traefik        | Este repo (Terraform) | Infraestructura del cluster |
| ArgoCD         | Este repo (Terraform) | Bootstrap: necesita existir antes que GitOps |
| Ingress ArgoCD | Este repo (Terraform) | Excepción justificada: ArgoCD no puede gestionar su propio Ingress antes de arrancar |
| SonarQube      | Repo GitOps | ArgoCD ya está corriendo, puede gestionarlo |
| Frontend       | Repo GitOps | Ídem |
| API            | Repo GitOps | Ídem |
| Flower         | Repo GitOps | Ídem |
| Ingress de cada app | Repo GitOps | Va dentro del manifiesto/chart de cada app |

En el repo de GitOps, cada app es un `Application` de ArgoCD apuntando
a su carpeta o chart de Helm. El `Ingress` de cada servicio forma parte
de esos manifests, no de Terraform.

## Destruir todo

```bash
terraform destroy
```

Esto borra el cluster kind completo (contenedores Docker incluidos), no solo
los recursos de Kubernetes.

## Variables principales (`variables.tf`)

| Variable                  | Default          | Descripción                              |
|----------------------------|------------------|--------------------------------------------|
| `cluster_name`              | `argocd-lab`     | Nombre del cluster kind                    |
| `worker_count`              | `1`              | Nodos worker además del control-plane      |
| `argocd_namespace`          | `argocd`         | Namespace de instalación de ArgoCD         |
| `argocd_chart_version`      | `7.7.3`          | Versión del chart argo-cd                  |
| `traefik_chart_version`     | `33.0.0`         | Versión del chart traefik                  |
| `ingress_host_http_port`    | `80`             | Puerto en tu localhost para HTTP           |
| `ingress_host_https_port`   | `443`            | Puerto en tu localhost para HTTPS          |
| `base_domain`               | `devops.lab`     | Dominio base de todos los hosts del lab    |

Ajusta `argocd_chart_version` / `traefik_chart_version` a las últimas
versiones publicadas en [artifacthub.io](https://artifacthub.io) si quieres
ir siempre al día.

## Siguiente paso

Este repo deja listos: cluster, Traefik y ArgoCD. El GitOps (Applications,
ApplicationSets, estructura de manifests) va en tu otro repo, apuntando al
cluster que generaste aquí (usa `kubeconfig_path` si necesitas registrar
el cluster o aplicar Applications manualmente la primera vez).


