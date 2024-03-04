# init cloud network
resource "yandex_vpc_network" "yc_vpc" {
  name = "vpc"
}

# init public subnet
resource "yandex_vpc_subnet" "yc_subnet_public" {
  name           = "subnet-public"
  description    = "a public subnet for the task"
  network_id     = "${yandex_vpc_network.yc_vpc.id}"
  v4_cidr_blocks = var.cidr_public
  zone           = "${var.yc_network_zone}"
}

# init private subnet
resource "yandex_vpc_subnet" "yc_subnet_private" {
  name           = "subnet-private"
  description    = "a public subnet for the task"
  network_id     = "${yandex_vpc_network.yc_vpc.id}"
  v4_cidr_blocks = var.cidr_private
  route_table_id = "${yandex_vpc_route_table.yc_rt.id}"
  zone           = "${var.yc_network_zone}"
}

# init route table
resource "yandex_vpc_route_table" "yc_rt" {
  name        = "vpc-route-table"
  description = "a route table for traffic from private network"
  network_id  = "${yandex_vpc_network.yc_vpc.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "${yandex_compute_instance.vm_nat_gateway.network_interface.0.ip_address}"
  }
}