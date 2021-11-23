// Une addresse ipv4 publique qu'on va allouer à la vm master
resource "google_compute_address" "static_master" {
  name = "ipv4-address-master"

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
      nat_ip = google_compute_address.static_master.address
    }
  }

  depends_on = [
    google_project_service.compute_service,
  ]

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

// Output après un apply
// On pourrait invoquer cet output avec la commande : terraform output ip_master
output "ip_master" {
  value = google_compute_instance.masterserver.network_interface.0.access_config.0.nat_ip
}
