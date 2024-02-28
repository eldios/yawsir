terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10"
    }
  }
}
