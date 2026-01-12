variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "target_node" {
  type = string
}

variable "template_id" {
  type = number
}

variable "vm_cpu" {
  type = number
}

variable "vm_cpu_type" {
  type = string
}

variable "vm_memory" {
  type = number
}

variable "vm_datastore" {
    type = string
}

variable "vm_disk_size" {
  type = number
}

variable "vm_ip_address" {
  type = string
}

variable "vm_gateway" {
  type = string
}

variable "dns_servers" {
  type = list(string)
}

variable "vm_interface" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}
