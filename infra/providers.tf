terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubernetes" {
  config_path = "../.kube/config"
  config_context = "kind-gitops-lab"
}

provider "helm" {
  kubernetes = {
    config_path = "../.kube/config"
  }
}

provider "kubectl" {
  config_path = "../.kube/config"
  config_context = "kind-gitops-lab"
}