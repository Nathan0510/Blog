terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.60.0"
    }
  }
}

provider "proxmox" {
  insecure = true
  endpoint = var.proxmox_api_url
  api_token = var.proxmox_api_token
}

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.target_node      
  vm_id     = var.vm_id                       
  name      = var.vm_name       

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.vm_cpu
    type  = var.vm_cpu_type
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = var.vm_disk_size
  }

  network_device {
    model  = "virtio"
    bridge = var.vm_interface
    mtu = 1450
  }

  initialization {

    datastore_id         = var.vm_datastore

    user_account {
      username = var.admin_username
      keys     = [var.ssh_public_key]
    }

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.vm_ip_address
        gateway = var.vm_gateway
      }
    }
  }

}
