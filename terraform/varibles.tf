variable "aws_region" {
  default     = "us-east-1"
}

variable "instance_type" {
  default     = "t2.micro"
}

variable "key_name" {
  type        = string
  default     = "htu-redhat" 
}

variable "my_ip" {
  description = "Your IP address for SSH access (CIDR format)"
  type        = string
  default     = "34.204.107.88/32" # WARNING: Change this
}
#curl -s https://checkip.amazonaws.com
# terraform apply -var="my_ip=$(curl -s https://checkip.amazonaws.com)/32"