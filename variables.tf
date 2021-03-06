variable "project_id" {
  description = "The project ID to host the cluster in"
  default = "work-examples"
}
variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = "gcp-gke-cluster"
}
variable "env_name" {
  description = "The environment for the GKE cluster"
  default     = "prod"
}
variable "region" {
  description = "The region to host the cluster in"
  default     = "europe-west1"
}
variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "gke-network"
}
variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "gke-subnet"
}
variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}
variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-range-services"
}

variable "world_repo_owner" {
  description = "GitHub repo owner"
  default     = "nayatronix01"
}


variable "world_repo_name" {
  description = "GitHub repo name"
  default     = "gcp-gke-cloudbuild"
}





