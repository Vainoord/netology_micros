variable "yc_token" {
  type = string
}
variable "yc_cloud_id" {
  type = string
}
variable "yc_folder_id" {
  type = string
}

variable "yc_network_zone" {
  type        = string
  default     = "ru-central1-a"
}

variable "cidr_public" {
  type        = list(string)
  default     = ["192.168.10.0/24"]
}

variable "cidr_private" {
  type        = list(string)
  default     = ["192.168.20.0/24"]
}

variable "nat_image_id" {
  type    = string
  default = "fd80mrhj8fl2oe87o4e1"
}

variable "instance_image_id" {
  type    = string
  default = "fd8t849k1aoosejtcicj"
}

variable "instance_platform_id" {
  type    = string
  default = "standard-v1"
}

variable "vm_user" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

