proxmox_api_url          = "https://192.168.1.1" 
proxmox_api_token        = "root@pam!packer=ttttttttttt"

vm_name                  = "test"
vm_id                    = 2000
target_node              = "pve1"
template_id              = 3333

vm_cpu	                = 6
vm_cpu_type             = "host"
vm_memory               = 8192
vm_disk_size	          = 60
vm_datastore            = "local"

vm_ip_address           = "192.168.10.109/24"
vm_gateway              = "192.168.10.1"
dns_servers             = ["1.1.1.1", "8.8.8.8"]
vm_interface	          = "vmbr0"

admin_username          = "admin"
ssh_public_key          = "CLE SSH"
