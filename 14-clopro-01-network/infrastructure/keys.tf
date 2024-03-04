# ssh public key for public and nat instances
# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "cloud_config_public" {
  template = file("metadata.tpl")
  vars     = {
    ssh_user = var.vm_user
    ssh_key  = "${file(var.ssh_public_key_path)}"
  }
}

# ssh key generation for public instance
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
resource "tls_private_key" "vm_ssh_key" {
  algorithm = "ED25519"
}

# ssh public key for private instance
data "template_file" "cloud_config_private" {
  template = file("metadata.tpl")
  vars     = {
    ssh_user = var.vm_user
    ssh_key  = tls_private_key.vm_ssh_key.public_key_openssh
  }
}