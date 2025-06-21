# Contains output configuration

output "dockerbox_ip" {
    description = "Local IP of node dockerbox"
    value = proxmox_vm_qemu.dockerbox.ssh_host
}
# output "dockerbox_worker_1_ip" {
#     description = "Local IP of node dockerbox-worker-1"
#     value = proxmox_vm_qemu.dockerbox-worker-1.ssh_host
# }
# output "dockerbox_worker_2_ip" {
#     description = "Local IP of node dockerbox-worker-2"
#     value = proxmox_vm_qemu.dockerbox-worker-2.ssh_host
# }