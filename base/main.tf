terraform {
  required_version = ">= 1.0.8"

  required_providers {
    kubernetes = "~> 2.17"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "spof"
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "spof"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "spof"
  }
}

# cert-manager
data "kubectl_path_documents" "cert-manager_manifests" {
  pattern = "manifests/cert-manager/*.yaml"
}

resource "kubectl_manifest" "cert-manager" {
  count     = length(data.kubectl_path_documents.cert-manager_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.cert-manager_manifests.documents, count.index)
}

# nginx ingress
data "kubectl_path_documents" "nginx-ingress_manifests" {
  pattern = "manifests/ingress-controller/*.yaml"
}

resource "kubectl_manifest" "nginx-ingress" {
  depends_on = [
    kubectl_manifest.cert-manager
  ]

  count     = length(data.kubectl_path_documents.nginx-ingress_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.nginx-ingress_manifests.documents, count.index)
}

# User for GitHub Actions
data "kubectl_path_documents" "github-actions-user_manifests" {
  pattern = "manifests/gh-actions-user/*.yaml"
}

resource "kubectl_manifest" "github-actions-user" {
  count     = length(data.kubectl_path_documents.github-actions-user_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.github-actions-user_manifests.documents, count.index)
}

# NFS Provisioner
data "kubectl_path_documents" "nfs-provisioner_manifests" {
  pattern = "manifests/nfs-provisioner/*.yaml"
}

resource "kubectl_manifest" "nfs-provisioner" {
  count     = length(data.kubectl_path_documents.nfs-provisioner_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.nfs-provisioner_manifests.documents, count.index)
}

# Postgres DB
data "kubectl_path_documents" "postgres-db_manifests" {
  pattern = "manifests/postgres-db/*.yaml"
  vars = {
    POSTGRES_PASSWORD         = base64encode(var.postgres_settings.admin_password)
    NEXTCLOUD_DB_PASSWORD     = var.nextcloud_settings.db_password
    HOMEASSISTANT_DB_PASSWORD = var.homeassistant_settings.db_password
  }
}

resource "kubectl_manifest" "postgres-db" {
  depends_on = [
    kubectl_manifest.nfs-provisioner
  ]

  count     = length(data.kubectl_path_documents.postgres-db_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.postgres-db_manifests.documents, count.index)
}

# container registry
data "kubectl_path_documents" "container-registry-data_manifests" {
  pattern = "manifests/container-registry-data/*.yaml"

  vars = {
    REGISTRY_USERNAME = var.registry_settings.username
    REGISTRY_HTPASSWD = var.registry_settings.htpasswd
  }
}

resource "kubectl_manifest" "container-registry-data" {
  depends_on = [
    kubectl_manifest.nfs-provisioner
  ]

  count     = length(data.kubectl_path_documents.container-registry-data_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.container-registry-data_manifests.documents, count.index)
}

resource "helm_release" "container-registry" {
  name       = "container-registry"
  chart      = "docker-registry-ui"
  repository = "https://helm.joxit.dev"
  version    = "1.0.1"
  timeout    = 6000
  wait       = true
  
  values = [
    file("manifests/container-registry/values.yaml")
  ]
}

# home-assistant
data "kubectl_path_documents" "home-assistant_manifests" {
  pattern = "manifests/home-assistant/*.yaml"
  vars = {
    HOMEASSISTANT_DB_PASSWORD = var.homeassistant_settings.db_password
  }
}

resource "kubectl_manifest" "home-assistant" {
  depends_on = [
    kubectl_manifest.nfs-provisioner,
    kubectl_manifest.nginx-ingress
  ]

  count     = length(data.kubectl_path_documents.home-assistant_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.home-assistant_manifests.documents, count.index)
}

# esphome
data "kubectl_path_documents" "esphome_manifests" {
  pattern = "manifests/esphome/*.yaml"
}

resource "kubectl_manifest" "esphome" {
  depends_on = [
    kubectl_manifest.nfs-provisioner,
    kubectl_manifest.nginx-ingress,
    kubectl_manifest.home-assistant
  ]

  count     = length(data.kubectl_path_documents.esphome_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.esphome_manifests.documents, count.index)
}

# grafana
data "kubectl_path_documents" "grafana_manifests" {
  pattern = "manifests/grafana/*.yaml"
}

resource "kubectl_manifest" "grafana" {
  depends_on = [
    kubectl_manifest.nfs-provisioner,
    kubectl_manifest.nginx-ingress
  ]

  count     = length(data.kubectl_path_documents.grafana_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.grafana_manifests.documents, count.index)
}

# Kubernetes API ingress
data "kubectl_path_documents" "kubernetes-api-ingress_manifests" {
  pattern = "manifests/kubernetes-api-ingress/*.yaml"
}

resource "kubectl_manifest" "kubernetes-api-ingress" {
  depends_on = [
    kubectl_manifest.nginx-ingress
  ]

  count     = length(data.kubectl_path_documents.kubernetes-api-ingress_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.kubernetes-api-ingress_manifests.documents, count.index)
}

# Kubernetes Dashboard
data "kubectl_path_documents" "kubernetes-dashboard_manifests" {
  pattern = "manifests/kubernetes-dashboard/*.yaml"
}

resource "kubectl_manifest" "kubernetes-dashboard" {
  depends_on = [
    kubectl_manifest.nginx-ingress
  ]

  count     = length(data.kubectl_path_documents.kubernetes-dashboard_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.kubernetes-dashboard_manifests.documents, count.index)
}

# NTFY Server
data "kubectl_path_documents" "ntfy-server_manifests" {
  pattern = "manifests/ntfy/*.yaml"
}

resource "kubectl_manifest" "ntfy-server" {
  depends_on = [
    kubectl_manifest.nfs-provisioner,
    kubectl_manifest.nginx-ingress
  ]

  count     = length(data.kubectl_path_documents.ntfy-server_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.ntfy-server_manifests.documents, count.index)
}

# cronjobs
data "kubectl_path_documents" "cronjobs_manifests" {
  pattern = "manifests/cronjobs/*.yaml"
}

resource "kubectl_manifest" "cronjobs" {
  count     = length(data.kubectl_path_documents.cronjobs_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.cronjobs_manifests.documents, count.index)
}

# parking-reservation-cronjob
data "kubectl_path_documents" "parking-reservation-cronjob_manifests" {
  pattern = "manifests/cronjobs/parking-reservation/*.yaml"
}

resource "kubectl_manifest" "parking-reservation-cronjob" {
  count     = length(data.kubectl_path_documents.parking-reservation-cronjob_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.parking-reservation-cronjob_manifests.documents, count.index)
  depends_on = [kubectl_manifest.cronjobs]
}

# pv23-ticketalert-cronjob
data "kubectl_path_documents" "pv23-ticketalert-cronjob_manifests" {
  pattern = "manifests/cronjobs/pv23_ticketalert/*.yaml"
}

resource "kubectl_manifest" "pv23-ticketalert-cronjob" {
  count     = length(data.kubectl_path_documents.pv23-ticketalert-cronjob_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.pv23-ticketalert-cronjob_manifests.documents, count.index)
  depends_on = [kubectl_manifest.cronjobs]
}

# sealed secrets
data "kubectl_path_documents" "sealed-secrets-resources_manifests" {
  pattern = "manifests/sealed-secrets/resources/*.yaml"
}

resource "kubectl_manifest" "sealed-secrets-resources-cronjob" {
  count     = length(data.kubectl_path_documents.sealed-secrets-resources_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.sealed-secrets-resources_manifests.documents, count.index)
  
}

resource "helm_release" "sealed-secrets" {
  name       = "sealed-secrets"
  chart      = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  version    = "2.10.0"
  timeout    = 6000
  wait       = true
  
  values = [
    file("manifests/sealed-secrets/values.yaml")
  ]
}

# Mosquitto
# data "kubectl_path_documents" "mosquitto_manifests" {
#     pattern = "manifests/mosquitto/*.yaml"
# }

# resource "kubectl_manifest" "mosquitto" {
#     depends_on = [
#         kubectl_manifest.nfs-provisioner,
#         kubectl_manifest.nginx-ingress
#     ]

#     count = length(data.kubectl_path_documents.mosquitto_manifests.documents)
#     yaml_body = element(data.kubectl_path_documents.mosquitto_manifests.documents, count.index)
# }

# Nextcloud
# data "kubectl_path_documents" "nextcloud_manifests" {
#     pattern = "manifests/nextcloud/*.yaml"
#     vars = {
#         NEXTCLOUD_DB_PASSWORD       = base64encode(var.nextcloud_settings.db_password)
#         NEXTCLOUD_ADMIN_PASSWORD    = base64encode(var.nextcloud_settings.admin_password)
#     }
# }

# resource "kubectl_manifest" "nextcloud" {
#     depends_on = [
#         kubectl_manifest.nfs-provisioner,
#         kubectl_manifest.nginx-ingress,
#         kubectl_manifest.postgres-db
#     ]

#     count = length(data.kubectl_path_documents.nextcloud_manifests.documents)
#     yaml_body = element(data.kubectl_path_documents.nextcloud_manifests.documents, count.index)
# }
