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
# IAM Role for EC2 to access S3
resource "aws_iam_role" "htu_s3_role" {
  name = "htu-server-s3-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "htu_s3_policy" {
  name = "htu-s3-access"
  role = aws_iam_role.htu_s3_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        aws_s3_bucket.htu_backup_bucket.arn,
        "${aws_s3_bucket.htu_backup_bucket.arn}/*"
      ]
    }]
  })
}
resource "aws_iam_instance_profile" "htu_profile" {
  name = "htu-ec2-instance-profile"
  role = aws_iam_role.htu_s3_role.name
}

# 3. The Server (EC2)
resource "aws_instance" "htu_server" {
  ami           = data.aws_ami.htu_image.id
  instance_type = var.instance_type
  key_name      = var.key_name 
  iam_instance_profile = aws_iam_instance_profile.htu_profile.name

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

   encrypted = true # Enable encryption
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


# 5. Cloud Storage (S3 Bucket)
# We use random_id to ensure the bucket name is unique globally
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "htu_backup_bucket" {
  bucket = "htu-backup-storage"
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

resource "aws_s3_bucket_server_side_encryption_configuration" "backup_encryption" {
  bucket = aws_s3_bucket.htu_backup_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_lifecycle" {
  bucket = aws_s3_bucket.htu_backup_bucket.id

  rule {
    id     = "archive-old-backups"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}