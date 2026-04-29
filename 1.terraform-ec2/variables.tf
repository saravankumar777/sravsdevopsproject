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

variable "vm_name" {
  type = list(string)
  default = ["kube-master", "kube-wn01", "kube-wn02"]
}