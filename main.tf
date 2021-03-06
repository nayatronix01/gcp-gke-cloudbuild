module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}
resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}
module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.5"
  project_id   = var.project_id
  network_name = "${var.network}-${var.env_name}"
  subnets = [
    {
      subnet_name   = "${var.subnetwork}-${var.env_name}"
      subnet_ip     = "10.10.0.0/16"
      subnet_region = var.region
    },
  ]
  secondary_ranges = {
    "${var.subnetwork}-${var.env_name}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "10.30.0.0/16"
      },
    ]
  }
}

module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id             = var.project_id
  name                   = "${var.cluster_name}-${var.env_name}"
  regional               = true
  region                 = var.region
  network                = module.gcp-network.network_name
  subnetwork             = module.gcp-network.subnets_names[0]
  ip_range_pods          = var.ip_range_pods_name
  ip_range_services      = var.ip_range_services_name
  node_pools = [
    {
      name                      = "node-pool"
      machine_type              = "e2-medium"
      node_locations            = "europe-west1-b,europe-west1-c,europe-west1-d"
      min_count                 = 1
      max_count                 = 2
      disk_size_gb              = 30
    },
  ]
}


resource "google_cloudbuild_trigger" "gcp-gke-cloudbuild" {
  
  #trigger_template {
  #  branch_name = ".*"
  #  repo_name   = "https://github.com/nayatronix01/gcp-gke-cloudbuild.git"
  #}
 
  github {
    owner = "${var.world_repo_owner}"
    name = "${var.world_repo_name}"
    push {
      branch = "^main$"
    }
  }

  name    = "gcp-gke-cloudbuild"
  provider = google-beta
  project = var.project_id
  #service_account = google_service_account.cloudbuild_service_account.id
  filename        = "cloudbuild.yaml"
  depends_on = [
    google_project_iam_member.act_as,
    google_project_iam_member.logs_writer
  ]
}




resource "google_cloudbuild_trigger" "kube-prometheus-stack" {

  #trigger_template {
  #  branch_name = ".*"
  #  repo_name   = "https://github.com/nayatronix01/gcp-gke-cloudbuild.git"
  #}

  github {
    owner = "${var.world_repo_owner}"
    name = "${var.world_repo_name}"
    push {
      branch = "^staging"
    }
  }

  name    = "kube-prometheus-stack"
  provider = google-beta
  project = var.project_id
  #service_account = google_service_account.cloudbuild_service_account.id
  filename        = "cloudbuild.yaml"
  depends_on = [
    google_project_iam_member.act_as,
    google_project_iam_member.logs_writer
  ]
}






resource "google_service_account" "cluster_service_account" {
  account_id   = "cloudbuild-sa"
  display_name = "Terraform-managed service account for cluster gcp-gke-cluster-prod"
  project = var.project_id
}

resource "google_project_iam_member" "act_as" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "logs_writer" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "cloud_build_service_account" {
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "kubernetes_engine_developer" {
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "project_iam_admin" {
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "secret_manager_secret_accessor" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
  project = var.project_id
}

resource "google_storage_bucket" "work-examples" {
  name          = "work-examples-project-bucket"
  location      = "EU"
  force_destroy = true
  project = var.project_id

  uniform_bucket_level_access = true
}
