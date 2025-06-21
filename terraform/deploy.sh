#!/bin/sh

# Apply terraform plan
./terraform.sh init > /dev/null 2>&1
./terraform.sh apply

# Store outputs
mkdir -p .tmp
./terraform.sh output -json dockerbox_ip | jq -r > .tmp/dockerbox_ip.txt
# ./terraform.sh output -json dockerbox_worker_1_ip | jq -r > .tmp/worker_ips.txt
# ./terraform.sh output -json dockerbox_worker_2_ip | jq -r >> .tmp/worker_ips.txt

# Create ansible inventory.ini
echo "[managers]" > ../ansible/inventory.ini
## dockerbox
DOCKERBOX_IP=$(< .tmp/dockerbox_ip.txt)
echo "dockerbox ansible_host=$DOCKERBOX_IP node_name=dockerbox" >> ../ansible/inventory.ini
# echo "[workers]" >> ../ansible/inventory.ini
# TBA