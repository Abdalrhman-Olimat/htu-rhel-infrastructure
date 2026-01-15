# 1. Get the Packer AMI

data "aws_ami" "htu_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["htu-rhel-v1-*"]
  }
}

# 2. Networking & Security
# Define the Firewall rules
resource "aws_security_group" "htu_sg" {
  name        = "htu-security-group"
  description = "Allow SSH and Web traffic"

  # Inbound: SSH (Only from your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] 
  }

  # Inbound: HTTP (App Port)
  ingress {
    from_port   = 82
    to_port     = 82
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow everything (updates, S3 access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. The Server (EC2)
resource "aws_instance" "htu_server" {
  ami           = data.aws_ami.htu_image.id
  instance_type = var.instance_type
  key_name      = var.key_name 

  # Attach the Security Group
  vpc_security_group_ids = [aws_security_group.htu_sg.id]

  # Volume A: Root Disk (OS) - 20GB
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    tags = {
      Name = "HTU-Root-Disk"
    }
  }

  tags = {
    Name = "HTU-Enterprise-Server"
  }
}

# 4. Storage (EBS Volumes)

# Volume B: Data (40GB)
resource "aws_ebs_volume" "data_vol" {
  availability_zone = aws_instance.htu_server.availability_zone
  size              = 40
  type              = "gp3"

  tags = {
    Name = "HTU-Data-Disk"
  }
}

# Attach Volume B
resource "aws_volume_attachment" "att_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data_vol.id
  instance_id = aws_instance.htu_server.id
}

# Volume C: Backup (20GB)
resource "aws_ebs_volume" "backup_vol" {
  availability_zone = aws_instance.htu_server.availability_zone
  size              = 20
  type              = "gp3"

  tags = {
    Name = "HTU-Backup-Disk"
  }
}

# Attach Volume C
resource "aws_volume_attachment" "att_backup" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.backup_vol.id
  instance_id = aws_instance.htu_server.id
}

# 5. Cloud Storage (S3 Bucket)
# We use random_id to ensure the bucket name is unique globally
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "htu_backup_bucket" {
  bucket = "htu-backup-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true # Allows deleting bucket even if it has files (for testing)

  tags = {
    Name        = "HTU Backup Storage"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.htu_backup_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}