provider "google" {
  project = "projet-sdtd"
  region  = "us-central1"
  zone    = "us-central1-c"
}

// Une addresse ipv4 publique qu'on va allouer à la vm master
resource "google_compute_address" "static_master" {
  name = "ipv4-address-master"
}

// Une addresse ipv4 publique qu'on va allouer à la vm worker
resource "google_compute_address" "static_worker" {
  name = "ipv4-address-worker"
}

// A single Compute Engine instance
resource "google_compute_instance" "masterserver" {
  name         = "master-server"
  machine_type = "e2-highcpu-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = "${google_compute_address.static_master.address}"
    }
  }
}

// A single Compute Engine instance
resource "google_compute_instance" "workerserver" {
  name         = "worker-server"
  machine_type = "e2-highcpu-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = "${google_compute_address.static_worker.address}"
    }
  }
}

// A machine for testing on the same network 
resource "google_compute_instance" "testserver" {
  name         = "test-server"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

// Output après un apply
// On pourrait aussi invoquer cet output (terraform output ip_master)
output "ip_master" {
  value="${google_compute_instance.masterserver.network_interface.0.access_config.0.nat_ip}"
}

output "ip_worker" {
  value="${google_compute_instance.workerserver.network_interface.0.access_config.0.nat_ip}"
}
