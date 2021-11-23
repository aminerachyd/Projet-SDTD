variable "pvt_key" {}
variable "pub_key" {}
variable "ssh_username" {}
variable "project" {}
variable "project_region" {}
variable "project_zone" {}

// Les playbooks
variable "docker_playbook" {}
variable "k8s_playbook" {}
variable "kubeadm_master_playbook" {}
variable "kubeadm_worker_playbook" {}

provider "google" {
  project = var.project
  region  = var.project_region
  zone    = var.project_zone
}

// Enable GCE API
resource "google_project_service" "compute_service" {
  project = var.project
  service = "compute.googleapis.com"
}

// Firewall for the VMs on the cloud
resource "google_compute_firewall" "default" {
  name    = "network-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  depends_on = [
    google_project_service.compute_service,
  ]
}
