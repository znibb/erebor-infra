# https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/vm_qemu

resource "proxmox_vm_qemu" "dockerbox" {
    vmid = 201
    name = "dockerbox"
    desc = ""
    target_node = "pve"
    onboot = true

    clone = "alpine-template"
    full_clone = true
    bios = "ovmf"
    agent = 0
    scsihw = "virtio-scsi-single"

    cpu_type = "x86-64-v2-AES"
    sockets = 1
    cores = 1
    memory = 2048
    balloon = 2048

    disks {
        scsi {
            scsi0 {
                disk {
                    size = "32G"
                    storage = "vm-storage"
                    format = "qcow2"
                }
            }
        }
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
    }

    lifecycle {
        ignore_changes = [
            network
        ]
    }
}
