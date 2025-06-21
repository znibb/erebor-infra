# erebor-infra
IaC repo for Erebor

**Table of contents:**
- [Future upgrades](#future-upgrades)
- [Hardware](#hardware)
  - [Case](#case)
    - [Rails](#rails)
    - [Fans](#fans)
  - [PSU](#psu)
  - [Motherboard](#motherboard)
  - [CPU](#cpu)
  - [CPU cooler](#cpu-cooler)
  - [RAM](#ram)
  - [Boot drive](#boot-drive)
    - [HBA](#hba)
  - [SATA HDDs](#sata-hdds)
- [Proxmox](#proxmox)
  - [Disable subscription notice](#disable-subscription-notice)
  - [Create new user](#create-new-user)
  - [Updates](#updates)
  - [Startup](#startup)
  - [Notifications](#notifications)
  - [Trusted TLS certificates](#trusted-tls-certificates)
  - [Backups](#backups)
  - [Passthrough motherboard SATA HDDs](#passthrough-motherboard-sata-hdds)
  - [Passthrough PCIe devices](#passthrough-pcie-devices)
  - [Passthrough internal CDROM](#passthrough-internal-cdrom)
  - [Alpine template VM](#alpine-template-vm)
- [TrueNAS](#truenas)
  - [VM setup](#vm-setup)
  - [Installation](#installation)
  - [Configuration checklist](#configuration-checklist)
  - [NFS share for use in Proxmox](#nfs-share-for-use-in-proxmox)
- [Terraform](#terraform)
  - [Proxmox setup](#proxmox-setup)
  - [Local setup](#local-setup)
  - [Win 10 vm](#win-10-vm)
- [Ansible](#ansible)

## Future upgrades
1. Change motherboard/RAM to enable using ECC memory
2. Add another HBA to allow more HDDs
3. Add dedicated GPU

## Hardware
Details about the hardware components

### Case
Inter-Tech 4U4129L

#### Rails
Inter-Tech Utdragbara skenor för rack 2U, 455 mm (500-800 mm), max 30 kg

#### Fans
2x Noctua IndustrialPPC NF-F12, 120 mm
2x Noctua Redux NF-R8, 80 mm

### PSU
Corsair RM650 650W ATX 80 PLUS Gold

### Motherboard
MSI Pro B760-P DDR4 II LGA1700 ATX

### CPU
Intel Core i5 13400, LGA1700
10 cores
6 performance cores
4 efficient cores
16 threads

### CPU cooler
Thermalright Peerless Assasin 120 SE

### RAM
Kingston FURY Beast 64GB 3200MT/s DDR4, 2x32 GB

### Boot drive
2x Kingston NV2 500GB SSD M.2 PCIe 4.0

#### HBA
LSI 9211-8i, IT Mode, P20 FW

### SATA HDDs
Western Digital Ultrastar DC HC520 HUH721212ALE600 0F29612 12TB 7.2k RP SATA 6Gb/s 512e Power-Disable 3.5in Recertified Hard Drive
5QHUARXB ATA errors

## Proxmox
Instructions for how to configure the base Proxmox install

### Disable subscription notice
1. Run `sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service` in the node shell
2. You might need to clear browser cache for the change to take effect

Note that you likely will need to re-run the above command after certain updates

### Create new user
1. Open node shell
2. Run `adduser <NAME>`
3. Go to `Datacenter->Permissions->Users`
4. Add user with name matching above
5. Go up a level to `Datacenter->Permissions`
6. Click `Add->User Permission`
7. To make it an equivalent admin account select `Path: /`, `User: <NAME>` and `Role: Adminstrator`, click `Add`

### Updates
By default Proxmox is configured to look for updates using the enterprise repo that is available if you have an active subscription. Change to using the no-subscription with these steps:

1. Go to `Updates->Repositories` in the node menu
2. Make sure the pve-enterprise repo is disabled
3. (Optional) Also disable the ceph repository (since it's enterprise only)
4. Click `Add` and select `Repository: No-Subscription

### Startup
When using a VM to host storage you need to delay startup of subsequent VMs to allow the VM providing the storage to start first.

1. Under VM->Options set `Start/Shutdown order` to `1` for the NAS VM
2. Set `Startup delay` to control the delay until the **NEXT** VM starts, for TrueNAS 120 worked so use 180 (s) to be safe
3. Set the VMs relying on the NAS storage to prio 2 and all should be well

### Notifications
1. Go to `Datacenter->Notifications` and add a new Notification Target of the type `SMTP`
2. For using Gmail as outgoing SMTP server:
    - Endpoint Name: E.g. `mail-to-<USER>`
    - Server: smtp.gmail.com
    - Encryption: TLS
    - Port: 465
    - Username: ADDRESS@gmail.com
    - Password: Create [app password](https://myaccount.google.com/apppasswords)
    - From Address: Same as `Username` above
    - Recipient(s): Select which user accounts to notify (requires user to have email setup)
3. Click `Add`
4. Under `Notification Matchers` click `Add`
5. Fill out `General` with `Matcher Name` being e.g. `notify-<USER>` (note: can't contain spaces)
6. `Match Rules` should default to `All`, adjust as needed
7. Under `Targets to notify` select the previously created notification target

### Trusted TLS certificates
Using a trusted TLS certificate even when accessing the web UI locally has the advantage of getting rid of the annoying browser warning that you're accessing an insecure host  

This setup requires a public domain name and a DNS provider (e.g. Cloudflare)

1. Log in to Cloudflare Dashboard, go to `Websites-><YOUR_DOMAIN>->DNS->Records` and add an A record called e.g. `pve` that points to the *local* IP address of your Proxmox server, make sure that `Proxy status` is disabled and says `DNS only`
2. Click on the profile icon in the top right, go to `My Profile->API Tokens` and click `Create Token`
3. Use the `Edit zone DNS` template
4. Under `Zone Resources` select your desired domain name
5. Click `Continue to summary` followed by `Create Token`
6. Take note of the API Token, this will be used later
6. Log in to the Proxmox web UI as **root** user (important)
7. Click on `Datacenter->ACME` and add a `Challenge Plugin`:
    - Plugin ID: E.g. `cloudflare-dns`
    - DNS API: `Cloudflare Managed DNS`
    - CF_Email: Your Cloudflare email address
    - CF_Token: The API Token generated above
8. Click `Add`
9. Add an account:
    - Account Name: E.g. `cloudflare-dns`
    - E-Mail: Optional, contact email
    - ACME Directory: `Let's Encrypt V2` (important, don't use the staging server)
    - Accept TOS: Check
10. Click on your node and go to `System->Certificates`
11. Under `ACME` select the account you created earlier then add a new domain name:
    - Challenge Type: DNS
    - Plugin: Select the plugin created above (cloudflare-dns)
    - Domain: This needs to match the A record and domain name set up in Cloudflare, e.g. `pve.DOMAIN.TLD`
12. Click `Order Certificates Now` and check log output, should end with `TASK OK`

For a Proxmox cluster repeat the last 3 steps for each node and additionally add a SAN domain for the datacenter itself to each node  

Now you can access `https://pve.DOMAIN.TLD:8006` and use the web UI with TLS (locally)

### Backups
The host OS has very limited storage space to setting up backups to be stored on a NFS share exported from TrueNAS is a sensible option

First we need to setup the external storage

1. Go to your TrueNAS web UI and go to the  `Datasets` section
2. Click on your desired pool and then `Add Dataset`
3. Name it e.g. `vm-backup` and click `Save`
4. Go to the `Shares` section and add an NFS share
5. Under `Path` select the recently created dataset
6. (Optional) Add a sensible description
7. Under `Hosts` enter the IP address of the Proxmox host to limit access to the share to that device
8. Click `Advanced Options` and set both `Maproot User` and `Maaproot Group` to `root`
9. Click `Save`
10. If prompted about starting the NFS service comply
11. Open the Proxmox web UI and go to `Datacenter->Storage`
12. Click `Add->NFS` and enter:
    - ID: E.g. `vm-backup`
    - Server: TrueNAS IP address
    - Export: Expand dropdown list and you should see `/mnt/<POOL_NAME>/<SHARE_NAME>` corresponding to what you set up in TrueNAS previously
    - Content: Select `VZDump backup file`
13. Click `OK`

Then we configure the actual backups

1. Go to `Datacenter->Backup` and click `Add`:
    - Storage: Select the storage created previously
    - Schedule: For daily backups enter e.g. `03:00`
    - Selection mode: `Include selected VMs`
    - Notification mode: `Notification system`
    - Compression: `ZSTD (fast and good)`
    - Mode: `Snapshot` (keeps the VMs running meanwhile)
2. Select the VMs to backup in the list at the bottom (if your NAS instance is running as a VM under Proxmox obviously don't include that in this backup job)
3. Go to the `Retention` tab, to keep daily backups for the last week, one backup per week for the last month and a monthly backup for the last year enter:
    - Keep Last: 3
    - Keep Daily: 6
    - Keep Monthly: 11
    - Keep Weekly: 4
4. Go to the `Advanced` tab and check `Repeat missed`
5. Click `Create`

### Passthrough motherboard SATA HDDs
1. Create your VM but don't launch it
2. Take not that you probably used scsi0 for the boot drive for the VM so **DON'T USE THAT NUMBER WHEN PASSING THROUGH DISKS**
3. Find disk IDs by opening the Proxmox shell and running `lsblk | awk 'NR==1{print $0" DEVICE-ID(S)"}NR>1{dev=$1;printf $0" ";system("find /dev/disk/by-id -lname \"*"dev"\" -printf \" %p\"");print "";}'|grep -v -E 'part|lvm'`, use the ID that includes the serial number
4. Enter `qm set <VM_ID> -scsi? /dev/disk/by-id/<DISK_ID>,serial=<DISK_SERIAL>` respectively and it should reply with a `update vm` message
5. Go to your VM and check `Hardware` tab for `Hard Disk (scsi?)`
6. If you forgot to add serial numbers to your disks that can be added manually to `/etc/pve/qemu-server/<VM_ID>.conf`
7. Start VM

### Passthrough PCIe devices
**BE AWARE** that your NIC might change enumeration when adding PCIe devices, if web UI doesn't start connect physically to the server and compare network device name outputs of `ip a` and `cat /etc/network/interfaces` (e.g. `enp3s0`)

1. Create your VM but don't launch it
2. Open the `Hardware` menu for the VM and click `Add->PCI Device`
3. Select `Raw Device` and look for the device in the `Device` dropdown list
4. Make sure `All Functions` is checked
5. Make sure `PCI-Express` is checked (under Advanced)
5. Click `Add`
6. Start VM

If noVNC stops working after passing through a GPU go to Hardware settings for the VM and change Display type to `VirtIO-GPU (virtio)`

### Passthrough internal CDROM
Needs to use iSCSI if attached to internal motherboard SATA port

In the Proxmox shell:
1. `apt install tgt open-iscsi lsscsi`
2. Start/enable services:
```
systemctl start tgt.service
systemctl enable tgt.service
systemctl start open-iscsi.service
systemctl enable open-iscsi.service
```
3. Run `lsscsi -g` and look for the drive, can look like:
  - `[4:0:0:0]    cd/dvd  ASUS     BW-16D1HT        3.11  /dev/sr0   /dev/sg0`
4. Run `cat /etc/iscsi/initiatorname.iscsi` and check for InitiatorName value, can look like:
  - `InitiatorName=iqn.1993-08.org.debian:01:655fa276a514`
5. Run the following commands to set up iSCSI hosting (take not of the initiatorname and the local IP subnet):
```
tgtadm --lld iscsi --op new --mode target --tid 1 --targetname iqn.1993-08.org.debian:01:655fa276a514:burner
tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 2 --bstype=sg --device-type=pt -b /dev/sg0
tgtadm --lld iscsi --mode target --op bind --tid 1 -I 10.0.0.0/24
tgt-admin --dump > /etc/tgt/targets.conf
```
6. Open `/etc/tgt/targets.conf`, add `device-type pt`, `bs-type sg` and change `initiator-name` into `initiator-address`, should look like:
  ```
  default-driver iscsi

  <target iqn.1993-08.org.debian:01:655fa276a514:burner>
          device-type pt
          bs-type sg
          backing-store /dev/sg0
          initiator-address 10.0.0.0/24
  </target>
  ```
7. Run `systemctl restart tgt.service`

Now you should be able to open your Windows VM and run `iSCSI Initiator`, enter your Proxmox host's IP under `Target` and click `Quick Connect...`

### Alpine template VM
We need to manually add qemu-guest-agent after install for Terraform to be able to communicate properly when setting up new nodes based on the template

1. Run through setup-alpine normally
  - Machine: q35
  - BIOS: Default (SeaBIOS)
  - Qemu Agent: Checked
  - Storage: vm-storage
  - Default credentials: root/<blank>
1. Reboot
1. Check that community repos were enabled in `/etc/apk/repositories`
1. Install qemu-guest-agent, `apk add qemu-guest-agent`
1. Enable guest agent on boot, `rc-update add qemu-guest-agent`
1. Start guest agent service, `service qemu-guest-agent start`
1. Power off VM (Pause->Stop)
1. Convert to template

## TrueNAS
Instructions for how to set up the TrueNAS VM under Proxmox (written for TrueNAS Scale 24.10)

### VM setup
1. Upload TrueNAS ISO to Proxmox (local->ISO Images)
2. Create VM, specs:
    - System: Default
    - Hard Disk: 32 GB (default)
    - CPU: 1 socket, 2 cores
    - Memory: 16 GB, 8 GB minimum with `Balloning Device` active (16384/8192 MiB)
    - Network: Default
    - Confirm: Make sure `Start after created` is unchecked
3. Perform the [HDD passthrough](#passthrough-motherboard-sata-hdds) step in [Proxmox](#proxmox) setup

### Installation
1. Select `1 Install/Upgrade`
2. Make sure you select the boot drive you created with the VM and not any of your intended storage disks
3. Select `Configure using Web UI`
4. Select `Yes` when asked to `Allow EFI boot`
5. Reboot device and check console output for web user interface IP
6. Open a web browser and go to the aforementioned IP and set a `truenas_admin` password

### Configuration checklist
1. System->Update
2. Credentials->Users
    - Create a personal user account
    - (Optional) Add `builtin_administrators` under `Auxiliary Groups` to make it an admin account (required for WebUI login)
3. System->General Settings
    - Localization
    - Email
      - Use `GMail OAuth`
4. System->Advanced Settings
    - Access->Configure (Session Timeout)
5. System->Alert Settings
    - Email: Set recipient of email alerts
6. Data Protection->Periodic Snapshot Tasks

### NFS share for use in Proxmox
See Proxmox [backups](#backups) section

## Terraform
### Proxmox setup
1. Go to Datacenter->Permissions
2. Create a Terraform role with the following privileges:
    - Datastore.AllocateSpace
    - Datastore.Audit
    - Pool.Allocate
    - SDN.Use
    - Sys.Audit
    - Sys.Console
    - Sys.Modify
    - VM.Allocate
    - VM.Audit
    - VM.Clone
    - VM.Config.CDROM
    - VM.Config.CPU
    - VM.Config.Cloudinit
    - VM.Config.Disk
    - VM.Config.HWType
    - VM.Config.Memory
    - VM.Config.Network
    - VM.Config.Options
    - VM.Migrate
    - VM.Monitor
    - VM.PowerMgmt
3. Create a Terraform user (use instead of TERRAFORM_USER in credentials.auto.tfvars)
4. Create a Terraform API Token (take note of the Token ID/Name and Secret created at this stage, you will need it for Terraform credentials file):
    - User: The previously created user
    - Token ID: E.g. `terraform`
    - Privilege Separation: Unchecked
5. Click on `Permissions` and add a `User Permission`:
    - Path: `/`
    - User: The one created above
    - Role: The one created above
    - Propagage: Checked

### Local setup
For convenience sake terraform will be run through the use of a Docker container.

1. Enter the `terraform` subdirectory
1. Copy `credentials.template` to `credentials.auto.tfvars` and update the capitalized parts with your relevant information: `cp credentials.template credentials.auto.tfvars`
1. Run `./terraform.sh plan` to check planned changes
1. Run `./deploy.sh`

### Win 10 vm
1. Proxmox->Options, change `OS Type` to `Microsoft Windows 10/2016/2019`, enable `QEMU Guest Agent`,
1. Hardware->Network Device, check `Disabled` to disable connectivity (this to be able to set up Windows without a Microsoft account)
1. Start VM and immediately enter `Console`, be ready to press any key to enter setup
1. Run through the Windows install
  1. Select Custom
  1. Load Drivers, select `Red Hat VirtIO SCSI pass-through controller (D:\amd64\w10\vioscsi.inf)
1. When Windows starts re-enable the network device in Proxmox
1. Install the `virtio-win-gt-x64.msi` file from the virtio cdrom drive
1. Install the Guest Agent file from the virtio cdrom drive (D:\guest-agent\qemu-ga-x86_64.msi)

## Ansible
1. Create an ssh key for use with ansible to connect to various hosts: `ssh-keygen -t ed25519 -C USER@HOST -f ansible-erebor` (suggested to run from ~/.ssh)
1. Create an ssh key for manually logging into the server as the `docker` user: `ssh-keygen -t ed25519 -C USER@HOST -f docker-erebor` (suggested to run from ~/.ssh)
1. Enter the `ansible` subdirectory
1. Install the required ansible collections: `ansible-galaxy install -r requirements.yml`
1. Run `./deploy.sh`
1. Connect via ssh as the `ansible` user: `ssh ansible@dockerbox -i ~/.ssh/ansible-erebor`
1. Set a password for the `docker` user (to be able to use sudo): `sudo passwd docker`
1. Disconnect (Ctrl+D)
1. Connect using ssh: `ssh docker@dockerbox -i ~/.ssh/docker-erebor`
1. Go to `~/.dotfiles` and run `ansible-playbook hosts-dockerbox.yml` to set up dotfiles

### Testing help
* Check connectivity/permissions with controlled nodes: `ansible <group> -i inventory.ini -m ping`