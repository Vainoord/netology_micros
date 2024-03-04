# nat instance internal ip address
output "vm_nat_internal_ip" {
  value = "${yandex_compute_instance.vm_nat_gateway.network_interface.0.ip_address}"
}

# nat instance external ip address
output "vm_nat_external_ip" {
  value = "${yandex_compute_instance.vm_nat_gateway.network_interface.0.nat_ip_address}"
}

# vm_public internal ip address
output "vm_public_internal_ip" {
  value = "${yandex_compute_instance.vm_public.network_interface.0.ip_address}"
}
# vm_public external ip address
output "vm_public_external_ip" {
  value = "${yandex_compute_instance.vm_public.network_interface.0.nat_ip_address}"
}

# vm_private internal ip address
output "vm_private_internal_ip" {
  value = "${yandex_compute_instance.vm_private.network_interface.0.ip_address}"
}

# vm_private external ip address
output "vm_private_external_ip" {
    value = "${yandex_compute_instance.vm_private.network_interface.0.nat_ip_address}"
}