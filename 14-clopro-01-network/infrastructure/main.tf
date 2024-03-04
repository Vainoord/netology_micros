# vm private instance
resource "yandex_compute_instance" "vm_private" {
  name                      = "node-private01"
  zone                      = var.yc_network_zone
  allow_stopping_for_update = true
  platform_id               = var.instance_platform_id
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.instance_image_id
      name     = "vol-root-node-private"
      type     = "network-hdd"
      size     = "30"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.yc_subnet_private.id}"
  }

  metadata = {
    user-data = data.template_file.cloud_config_private.rendered
  }
}

# vm public instance
resource "yandex_compute_instance" "vm_public" {
  name                      = "node-public01"
  zone                      = var.yc_network_zone
  allow_stopping_for_update = true
  platform_id               = var.instance_platform_id
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.instance_image_id
      name     = "vol-root-node-public"
      type     = "network-hdd"
      size     = "30"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.yc_subnet_public.id}"
    nat       = true
  }

  metadata = {
    user-data = data.template_file.cloud_config_public.rendered
  }

  connection {
    host        = self.network_interface.0.nat_ip_address
    type        = "ssh"
    user        = "${var.vm_user}"
    private_key = "${file(var.ssh_private_key_path)}"
  }

  provisioner "file" {
    #content     = local_sensitive_file.id_rsa.content
    content     = tls_private_key.vm_ssh_key.private_key_openssh
    destination = "/home/${var.vm_user}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
   inline = [
     "chmod 600 /home/${var.vm_user}/.ssh/id_rsa",
   ]
  }
}

# vm nat instance
resource "yandex_compute_instance" "vm_nat_gateway" {
  name                      = "node-nat-gw01"
  zone                      = var.yc_network_zone
  allow_stopping_for_update = true
  platform_id               = var.instance_platform_id
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_image_id
      name     = "vol-root-node-nat"
      type     = "network-hdd"
      size     = "30"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.yc_subnet_public.id}"
    nat       = true
    ip_address = "192.168.10.254"
  }

  metadata = {
    user-data = data.template_file.cloud_config_public.rendered
  }
}