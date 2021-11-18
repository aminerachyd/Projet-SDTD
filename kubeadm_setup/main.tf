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
  project = "${var.project}"
  region  = "${var.project_region}"
  zone    = "${var.project_zone}"
}

// Enable GCE API
resource "google_project_service" "compute_service" {
  project = "${var.project}"
  service = "compute.googleapis.com"
}

// Une addresse ipv4 publique qu'on va allouer à la vm master
resource "google_compute_address" "static_master" {
  name = "ipv4-address-master"

  depends_on = [
    google_project_service.compute_service,
  ]
}

// Une addresse ipv4 publique qu'on va allouer à la vm worker
resource "google_compute_address" "static_worker" {
  name = "ipv4-address-worker"

  depends_on = [
    google_project_service.compute_service,
  ]
}

resource "google_compute_firewall" "default" {
  name = "network-firewall"
  network = "default"

  // Le 80 est que pour tester le nginx
  allow {
    protocol = "tcp"
    ports = ["22","80"]
  }

  source_ranges = ["0.0.0.0/0"]

  depends_on = [
    google_project_service.compute_service,
  ]
}


// Le compute engine qui sera le master
resource "google_compute_instance" "masterserver" {
  name         = "master-server"
  machine_type = "e2-highcpu-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.pub_key)}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = "${google_compute_address.static_master.address}"
    }
  }

  depends_on = [
    google_project_service.compute_service,
  ]

  // On lance le remote-exec avant pour s'assurer que la machine est bien en marche avant de lancer le local-exec
  provisioner "remote-exec" {
    inline = ["sudo apt update"]

    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = "${var.ssh_username}"
      private_key = file(var.pvt_key)
    }
  }

  // Playbook d'installation de Docker
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.docker_playbook}"
  }

  // Playbook d'installation de Kubeadm
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.k8s_playbook}"
  }

  // Playbook d'init de Kubeadm pour le master
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.kubeadm_master_playbook}"
  }
}

// Le compute engine qui sera le worker
resource "google_compute_instance" "workerserver" {
  name         = "worker-server"
  machine_type = "e2-highcpu-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.pub_key)}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = "${google_compute_address.static_worker.address}"
    }
  }

  depends_on = [
    google_project_service.compute_service,
    google_compute_instance.masterserver,
  ]

  // On lance le remote-exec avant pour s'assurer que la machine est bien en marche avant de lancer le local-exec
  provisioner "remote-exec" {
    inline = ["sudo apt update"]

    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = "${var.ssh_username}"
      private_key = file(var.pvt_key)
    }
  }

  // Playbook d'installation de Docker
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.docker_playbook}"
  }

  // Playbook d'installation de Kubeadm
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.k8s_playbook}"
  }

  // Playbook de join Kubeadm
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.kubeadm_worker_playbook}"
  }
}

// Output après un apply
// On pourrait invoquer cet output avec la commande : terraform output ip_master
output "ip_master" {
  value="${google_compute_instance.masterserver.network_interface.0.access_config.0.nat_ip}"
}

// On pourrait invoquer cet output avec la commande : terraform output ip_worker
output "ip_worker" {
  value="${google_compute_instance.workerserver.network_interface.0.access_config.0.nat_ip}"
}
