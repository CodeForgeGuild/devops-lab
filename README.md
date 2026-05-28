# devops-lab

Local devops lab with kubernetes to test and try applications and technologies.

kind create cluster --name gitops-lab --config kind.yaml

kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d

añadir a hosts

127.0.0.1 argocd.local
