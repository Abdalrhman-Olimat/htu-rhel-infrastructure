#!/usr/bin/env bash
set -euo pipefail

# HTU Infrastructure Deploy Script
# Orchestrates: Packer → Terraform → Ansible

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKER_DIR="$ROOT_DIR/packer"
TF_DIR="$ROOT_DIR/terraform"
ANSIBLE_DIR="$ROOT_DIR/ansible"

usage() {
	echo "Usage: $0 --pem <path/to/client.pem> [--key-pair <aws_key_pair_name>] [--region <aws-region>] [--destroy]"
	echo "  --pem        Path to the client's .pem key (required)"
	echo "  --key-pair   AWS EC2 key pair name (default: basename of .pem)"
	echo "  --region     AWS region to use (default: us-east-1)"
	echo "  --destroy    Destroy Terraform resources (skip Packer/Ansible)"
}

CLIENT_PEM=""
KEY_PAIR_NAME=""
AWS_REGION="us-east-1"
DO_DESTROY="false"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--pem)
			CLIENT_PEM="$2"; shift 2 ;;
		--key-pair)
			KEY_PAIR_NAME="$2"; shift 2 ;;
		--region)
			AWS_REGION="$2"; shift 2 ;;
		--destroy)
			DO_DESTROY="true"; shift 1 ;;
		-h|--help)
			usage; exit 0 ;;
		*)
			echo "Unknown argument: $1"; usage; exit 1 ;;
	esac
done

if [[ -z "$CLIENT_PEM" ]]; then
	echo "Error: --pem is required."
	usage
	exit 1
fi

# If PEM path is relative (not starting with /), prepend ../
if [[ "$CLIENT_PEM" != /* ]]; then
  CLIENT_PEM="../$CLIENT_PEM"
fi

if [[ -z "$KEY_PAIR_NAME" ]]; then
	KEY_PAIR_NAME="$(basename "$CLIENT_PEM" .pem)"
fi

# Ensure PEM permissions
chmod 400 "$CLIENT_PEM" || true

# Check required CLIs
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' is required"; exit 1; }; }
need_cmd aws
need_cmd packer
need_cmd terraform
need_cmd ansible-playbook

# Verify AWS credentials
echo "Verifying AWS credentials..."
aws sts get-caller-identity >/dev/null

if [[ "$DO_DESTROY" == "true" ]]; then
	echo "Running Terraform destroy..."
	pushd "$TF_DIR" >/dev/null
	terraform init -input=false
	MY_IP_CIDR="$(curl -s https://checkip.amazonaws.com)/32"
	terraform destroy -auto-approve -var="my_ip=$MY_IP_CIDR" -var="key_name=$KEY_PAIR_NAME"
	popd >/dev/null
	echo "Destroy complete."
	exit 0
fi

echo "Starting Packer build (region: $AWS_REGION)..."
pushd "$PACKER_DIR" >/dev/null
packer init aws-rhel.pkr.hcl
packer build -var "aws_region=$AWS_REGION" -var "instance_type=t2.micro" -var "ami_name=htu-rhel-v1" aws-rhel.pkr.hcl
popd >/dev/null

echo "Applying Terraform..."
pushd "$TF_DIR" >/dev/null
terraform init -input=false
MY_IP_CIDR="$(curl -s https://checkip.amazonaws.com)/32"
terraform apply -auto-approve -var="my_ip=$MY_IP_CIDR" -var="key_name=$KEY_PAIR_NAME"

SERVER_IP="$(terraform output -raw server_public_ip)"
S3_BUCKET_NAME="$(terraform output -raw s3_bucket_name)"
popd >/dev/null




# Refresh inventory.ini so it's always in sync with the freshly created instance
cat > "$ANSIBLE_DIR/inventory.ini" <<EOF
[htu_servers]
$SERVER_IP ansible_user=ec2-user ansible_ssh_private_key_file=$CLIENT_PEM
EOF

cd $ANSIBLE_DIR
ansible-playbook playbook.yml -i inventory.ini -e "s3_bucket_name=$S3_BUCKET_NAME"
# popd >/dev/null

echo "Deployment complete."