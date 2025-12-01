terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

# Create namespace
resource "kubernetes_namespace" "devops_challenge" {
  metadata {
    name = "devops-challenge"
  }
}

# Create ResourceQuota
resource "kubernetes_resource_quota" "devops_challenge_quota" {
  metadata {
    name      = "devops-challenge-quota"
    namespace = kubernetes_namespace.devops_challenge.metadata[0].name
  }

  spec {
    hard = {
      "limits.memory" = "512Mi"
    }
  }
}
