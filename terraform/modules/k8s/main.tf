terraform {
  required_version = ">= 1.0.5, < 1.0.12"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

resource "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name   = var.cluster_name
  region = var.cluster_region
  version = var.cluster_version

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = var.node_count
  }

}

resource "digitalocean_project" "project" {
  name        = var.project_name
  description = var.project_description
  purpose     = var.project_purpose
  environment = var.project_environment
  resources   = [digitalocean_kubernetes_cluster.k8s_cluster.urn]


   # this should be in the cluster - just a work-around so the state-file is populated only when local-exec runs
  provisioner "local-exec" {
    # working_dir = "${path.module}"
    command = <<EOF
      pwd
      jq -r \
        '.resources[]
        | select(.type == "digitalocean_kubernetes_cluster")
        | .instances[].attributes.kube_config[].raw_config' terraform.tfstate > kubeconfig/.config && cp kubeconfig/.config ~/.kube/config
    EOF
  }
}