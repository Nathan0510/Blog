variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_username" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
}

variable "ssh_username" {
  type      = string
}

variable "ssh_password" {
  type      = string
}

variable "iso_file" {
  type      = string
}

variable "proxmox_node" {
  type      = string
}

variable "disks_storage_pool" {
  type      = string
}
