packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "debian" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_username
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                     = var.proxmox_node
  vm_id                    = "3333"
  vm_name                  = "packer-debian"

  boot_iso {
	  type         = "scsi"
	  iso_file     = var.iso_file
	  unmount      = true
  }

  qemu_agent               = true

  scsi_controller          = "virtio-scsi-pci"

  cores                    = 2
  cpu_type		             = "host"
  sockets                  = 1
  memory                   = 2048

  cloud_init               = true
  cloud_init_storage_pool  = "local"

  vga {
    type                   = "virtio"
  }

  disks {
    disk_size              = "20G"
    format                 = "qcow2"
    storage_pool           =  var.disks_storage_pool
    type                   = "scsi"
  }

  network_adapters {
    model                  = "virtio"
    bridge                 = "vmbr0"
    firewall               = false
  }

  http_directory           = "./"
  boot_wait                = "10s"
  boot_command             = ["<esc><wait>auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"]

  ssh_username             = var.ssh_username
  ssh_password             = var.ssh_password

  ssh_timeout               = "10m"
}

build {
  sources = ["source.proxmox-iso.debian"]

  provisioner "file" {
    source      = "cloud-cfg/99-base.cfg"
    destination = "/tmp/99-base.cfg"
  }

  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install curl vim nano micro tcpdump -y",
      "sudo cloud-init clean --logs",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo mkdir -p /etc/cloud/cloud.cfg.d",
      "sudo mv /tmp/99-base.cfg /etc/cloud/cloud.cfg.d/99-base.cfg",
      "sudo chown root:root /etc/cloud/cloud.cfg.d/99-base.cfg",
      "sudo chmod 644 /etc/cloud/cloud.cfg.d/99-base.cfg"
    ]
  }
}
