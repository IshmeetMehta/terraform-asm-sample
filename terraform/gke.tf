resource "null_resource" "previous" {}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "120s"
}

module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 10.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "anthos.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "gkehub.googleapis.com"
  ]
 
}

# google_client_config and kubernetes provider must be explicitly specified like the following.

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}


module "gke" {
  depends_on         = [time_sleep.wait_120_seconds]
  source             = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  version            = "~> 16.0"
  project_id         = module.enabled_google_apis.project_id
  name               = "asm-cluster-1"
  region             = var.region
  zones              = [var.zone]
  initial_node_count = 4
  network            = "default"
  subnetwork         = "default"
  ip_range_pods      = ""
  ip_range_services  = ""
  config_connector   = true
}

module "wi" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 16.0.1"
  gcp_sa_name         = "cnrmsa"
  cluster_name        = module.gke.name
  name                = "cnrm-controller-manager"
  location            = var.zone
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  namespace           = "cnrm-system"
  project_id          = module.enabled_google_apis.project_id
  roles               = ["roles/owner"]
}

