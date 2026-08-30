provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-task-manager"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "k3d-task-manager"
  }
}
