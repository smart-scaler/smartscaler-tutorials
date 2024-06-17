terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
  }
}

provider "helm" {
  # Configuration options
  kubernetes {
    config_path = "~/.kube/config"
  }
}
