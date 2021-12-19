resource "google_compute_address" "static_node1" {
  name = "ipv4-address-node1"
}

resource "google_compute_address" "static_node2" {
  name = "ipv4-address-node2"
}

// Un compute engine
resource "google_compute_instance" "cassandra_node1" {
  name         = "cassandra-node1"
  machine_type = "e2-highcpu-2"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.pub_key)}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = google_compute_address.static_node1.address
    }
  }

  // On lance le remote-exec avant pour s'assurer que la machine est bien en marche avant de lancer le local-exec
  provisioner "remote-exec" {
    inline = ["sudo apt update"]

    connection {
      host        = self.network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      user        = var.ssh_username
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.cassandra_setup_playbook}"
  }
}


resource "google_compute_instance" "cassandra_node2" {
  name         = "cassandra-node2"
  machine_type = "e2-highcpu-2"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.pub_key)}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = google_compute_address.static_node2.address
    }
  }

  // On lance le remote-exec avant pour s'assurer que la machine est bien en marche avant de lancer le local-exec
  provisioner "remote-exec" {
    inline = ["sudo apt update"]

    connection {
      host        = self.network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      user        = var.ssh_username
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_username} -i '${self.network_interface.0.access_config.0.nat_ip},' --private-key ${var.pvt_key} ${var.cassandra_setup_playbook}"
  }
}
