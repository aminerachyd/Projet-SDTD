variable "pvt_key" {}
variable "pub_key" {}
variable "ssh_username" {}
variable "project" {}
variable "project_region" {}
variable "project_zone" {}

provider "google" {
  project = var.project
  region  = var.project_region
  zone    = var.project_zone
}

// Firewall for the VMs on the cloud
resource "google_compute_firewall" "default" {
  name    = "network-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "7000", "9042"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}
