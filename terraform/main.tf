terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}

resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      k3d cluster delete task-manager || true

      k3d cluster create task-manager \
        --image rancher/k3s:v1.31.5-k3s1 \
        --servers 1 \
        --agents 1 \
        -p "8081:80@loadbalancer"

      kubectl wait \
        --for=condition=Ready \
        nodes \
        --all \
        --timeout=180s
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete task-manager || true"
  }
}

resource "null_resource" "monitoring" {
  depends_on = [null_resource.k3d_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
      helm repo update

      helm upgrade --install monitoring \
        prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --wait \
        --timeout 10m
    EOT
  }
}

resource "null_resource" "loki" {
  depends_on = [null_resource.monitoring]

  provisioner "local-exec" {
    command = <<-EOT
      helm repo add grafana https://grafana.github.io/helm-charts
      helm repo update

      helm upgrade --install loki \
        grafana/loki-stack \
        --namespace monitoring \
        --set loki.image.tag=2.9.3 \
        --wait \
        --timeout 10m
    EOT
  }
}
