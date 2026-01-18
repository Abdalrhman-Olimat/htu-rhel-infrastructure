# HTU Infrastructure Automation

## 📖 Project Overview
This repository contains the Infrastructure as Code (IaC) solution for the HTU Infrastructure Modernization Project. It automates provisioning, configuration, and maintenance of a hardened RHEL 9 server on AWS using Packer, Terraform, and Ansible.

## Key Features
- Immutable infrastructure via a custom Golden AMI built with Packer
- Automated provisioning of EC2, EBS, and S3 resources with Terraform
- Zero-touch server configuration with Ansible
- Automated daily backups to AWS S3

## 🛠️ Prerequisites & Installation (Linux)
1) Clone the repository
\`\`\`bash
git clone https://github.com/Abdalrhman-Olimat/htu-rhel-infrastructure.git
cd htu-rhel-infrastructure
\`\`\`

2) Install required tools
- Packer
\`\`\`bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release ; lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y packer
\`\`\`
- Terraform
\`\`\`bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release ; lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install -y terraform
\`\`\`
- Ansible
\`\`\`bash
sudo dnf install -y ansible
\`\`\`
- AWS CLI
\`\`\`bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
\`\`\`

3) Configure AWS credentials
\`\`\`bash
aws configure
# Enter Access Key ID, Secret Key, Region (e.g., us-east-1), and Output format (json)
\`\`\`

## 🚀 How to Run
After prerequisites, create an AWS key pair and place the .pem file at the repo root.

To deploy:
\`\`\`bash
bash deploy.sh --pem YOUR-KEY.pem --key-pair YOUR-KEY --region us-east-1
\`\`\`
Note: make sure your key is in the root of the repo.

## 🧪 Verification
- Web server: visit http://<SERVER_IP>:82 for the HR placeholder pvage
- Storage: SSH in and run `lsblk` to verify disk mounts
- Backups: check the AWS S3 console for the backup bucket

## 🧹 Cleanup
Destroy resources to avoid AWS costs:
\`\`\`bash
bash deploy.sh --pem YOUR-KEY.pem --key-pair YOUR-KEY --destroy
\`\`\`