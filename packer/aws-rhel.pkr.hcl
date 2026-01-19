packer {
  required_plugins {
    amazon = {
      version = "~> 1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_name" {
  type    = string
  default = "htu-rhel-v1"
}

source "amazon-ebs" "rhel" {
  ami_name      = "${var.ami_name}-{{timestamp}}" # Appends timestamp to avoid name collisions
  instance_type = var.instance_type
  region        = var.aws_region
  ssh_username  = "ec2-user"

  source_ami = "ami-03f1d522d98841360"
}

build {
  name = "htu-project-builder"
  sources = [
    "source.amazon-ebs.rhel"
  ]

  provisioner "shell" {
    script = "./scripts/setup.sh"
  }
  
  # Simple check to verify it worked
  provisioner "shell" {
    inline = [
      "echo 'Build Complete. Verifying versions:'",
      "aws --version",
      "git --version"
    ]
  }
}