variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "ubuntu-key"
}

variable "public_key_path" {
  description = "Path to your public key file"
  default     = "~/.ssh/id_rsa.pub"
}
