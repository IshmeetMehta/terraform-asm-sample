resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  
  membership_id = "membership-hub-${module.gke.name}"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke.cluster_id}"
    }
  }
  # depends_on = [module.gke.name, module.enabled_google_apis.activate_apis] 
}

module "asm" {
  source = "git::https://github.com/Monkeyanator/terraform-google-kubernetes-engine.git//modules/asm?ref=rewrite-asm-module"
  cluster_name     = module.gke.name
  cluster_location = var.region
  project_id = module.enabled_google_apis.project_id
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "<add-kube-context"
}