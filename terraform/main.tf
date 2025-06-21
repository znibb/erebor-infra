# https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/vm_qemu

locals {
    ## Manager
    # General
    manager_target_node = "pve"
    manager_desc = "Cloned from alpine-template"
    manager_clone = "alpine-template"
    manager_full_clone = true
    manager_onboot = true

    # System
    manager_machine = "q35"
    manager_bios = "seabios"
    manager_scsihw = "virtio-scsi-single"
    manager_agent = 1

    # Disks
    manager_disk_storage = "vm-storage"
    manager_disk_size = "32G"
    manager_disk_format = "qcow2"

    # CPU
    manager_sockets = 1
    manager_cores = 2
    manager_cpu_type = "x86-64-v2-AES"

    # Memory
    manager_memory = 2048
    manager_balloon = 2048

    # Network
    manager_skip_ipv6 = true
    manager_bridge = "vmbr0"
    manager_model = "virtio"

    ## Worker
    # General
    worker_target_node = "pve"
    worker_desc = "Cloned from alpine-template"
    worker_clone = "alpine-template"
    worker_full_clone = true
    worker_onboot = true

    # System
    worker_machine = "q35"
    worker_bios = "seabios"
    worker_scsihw = "virtio-scsi-single"
    worker_agent = 1

    # Disks
    worker_disk_storage = "vm-storage"
    worker_disk_size = "32G"
    worker_disk_format = "qcow2"

    # CPU
    worker_sockets = 1
    worker_cores = 2
    worker_cpu_type = "x86-64-v2-AES"

    # Memory
    worker_memory = 2048
    worker_balloon = 2048

    # Network
    worker_skip_ipv6 = true
    worker_bridge = "vmbr0"
    worker_model = "virtio"
}

resource "proxmox_vm_qemu" "dockerbox" {
    vmid = 201
    name = "dockerbox"

    # General
    target_node = local.manager_target_node
    desc = local.manager_desc
    clone = local.manager_clone
    full_clone = local.manager_full_clone
    onboot = local.manager_onboot

    # System
    machine = local.manager_machine
    bios = local.manager_bios
    scsihw = local.manager_scsihw
    agent = local.manager_agent

    # Disks
    disks {
        scsi {
            scsi0 {
                disk {
                    storage = local.manager_disk_storage
                    size = local.manager_disk_size
                    format = local.manager_disk_format
                }
            }
        }
    }

    # CPU
    sockets = local.manager_sockets
    cores = local.manager_cores
    cpu_type = local.manager_cpu_type

    # Memory
    memory = local.manager_memory
    balloon = local.manager_balloon

    # Network
    skip_ipv6 = local.manager_skip_ipv6
    network {
        id = 0
        bridge = local.manager_bridge
        model = local.manager_model
    }

    # Block IP update flagging resource as `changed`
    lifecycle {
        ignore_changes = [
            network
        ]
    }
}

# resource "proxmox_vm_qemu" "dockerbox-worker-1" {
#     vmid = 202
#     name = "dockerbox-worker-1"

#     # General
#     target_node = local.worker_target_node
#     desc = local.worker_desc
#     clone = local.worker_clone
#     full_clone = local.worker_full_clone
#     onboot = local.worker_onboot

#     # System
#     machine = local.worker_machine
#     bios = local.worker_bios
#     scsihw = local.worker_scsihw
#     agent = local.worker_agent

#     # Disks
#     disks {
#         scsi {
#             scsi0 {
#                 disk {
#                     storage = local.worker_disk_storage
#                     size = local.worker_disk_size
#                     format = local.worker_disk_format
#                 }
#             }
#         }
#     }

#     # CPU
#     sockets = local.worker_sockets
#     cores = local.worker_cores
#     cpu_type = local.worker_cpu_type

#     # Memory
#     memory = local.worker_memory
#     balloon = local.worker_balloon

#     # Network
#     skip_ipv6 = local.worker_skip_ipv6
#     network {
#         id = 0
#         bridge = local.worker_bridge
#         model = local.worker_model
#     }

#     # Block IP update flagging resource as `changed`
#     lifecycle {
#         ignore_changes = [
#             network
#         ]
#     }
# }

# resource "proxmox_vm_qemu" "dockerbox-worker-2" {
#     vmid = 203
#     name = "dockerbox-worker-2"

#     # General
#     target_node = local.worker_target_node
#     desc = local.worker_desc
#     clone = local.worker_clone
#     full_clone = local.worker_full_clone
#     onboot = local.worker_onboot

#     # System
#     machine = local.worker_machine
#     bios = local.worker_bios
#     scsihw = local.worker_scsihw
#     agent = local.worker_agent

#     # Disks
#     disks {
#         scsi {
#             scsi0 {
#                 disk {
#                     storage = local.worker_disk_storage
#                     size = local.worker_disk_size
#                     format = local.worker_disk_format
#                 }
#             }
#         }
#     }

#     # CPU
#     sockets = local.worker_sockets
#     cores = local.worker_cores
#     cpu_type = local.worker_cpu_type

#     # Memory
#     memory = local.worker_memory
#     balloon = local.worker_balloon

#     # Network
#     skip_ipv6 = local.worker_skip_ipv6
#     network {
#         id = 0
#         bridge = local.worker_bridge
#         model = local.worker_model
#     }

#     # Block IP update flagging resource as `changed`
#     lifecycle {
#         ignore_changes = [
#             network
#         ]
#     }
# }