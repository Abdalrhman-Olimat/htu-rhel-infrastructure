#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

# 1. System Updates & Timezone

sudo dnf update -y
sudo timedatectl set-timezone Asia/Amman
# Ensure locale is set
sudo localectl set-locale LANG=en_US.UTF-8

# 2. Install Base Software

sudo dnf install -y git vim-enhanced unzip lvm2 wget

# 3. Install AWS CLI v2

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version

# 4. Security Hardening
# Disable Root Login
# We use sed to find the line 'PermitRootLogin' and change it to 'no'

sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 5. Cleanup

sudo dnf clean all
# Remove residual cache to keep image small
sudo rm -rf /var/cache/dnf

