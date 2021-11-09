variable "pub_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_username" {
  default = "amine"
}

variable "project" {
  default = "projet-sdtd"
}

variable "project_region" {
  default = "us-central1"
}

variable "project_zone" {
  default = "us-central1-c"
}

variable "playbook_master" {
  default = "playbook_example.yml"
}

provider "google" {
  project = "${var.project}"
  region  = "${var.project_region}"
  zone    = "${var.project_zone}"
}

// Une addresse ipv4 publique qu'on va allouer à la vm master
resource "google_compute_address" "static_master" {
  name = "ipv4-address-master"
}

// Une addresse ipv4 publique qu'on va allouer à la vm worker
resource "google_compute_address" "static_worker" {
  name = "ipv4-address-worker"
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

  // On lance le remote-exec avant pour s'assurer que la machine est bien en marche avant de lancer le local-exec
  provisioner "remote-exec" {
    inline = ["sudo apt update"]

    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = "${var.ssh_username}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' ${var.playbook_master}"
    //command = "ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' playbook_example.yml"
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

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = "${google_compute_address.static_worker.address}"
    }
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
