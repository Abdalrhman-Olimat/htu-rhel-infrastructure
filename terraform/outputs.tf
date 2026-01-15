output "server_public_ip" {
  description = "Public IP of the HTU Server"
  value       = aws_instance.htu_server.public_ip
}

output "s3_bucket_name" {
  description = "Name of the created S3 Backup Bucket"
  value       = aws_s3_bucket.htu_backup_bucket.id
}

output "ssh_command" {
  description = "Command to connect to the server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.htu_server.public_ip}"
}