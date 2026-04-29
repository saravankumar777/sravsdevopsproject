terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Security Group (shared by all 3 VMs) ──────────────────────────
resource "aws_security_group" "ubuntu_sg" {
  name        = "ubuntu-servers-sg"
  description = "Security group for Ubuntu EC2 instances"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom App Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ubuntu-servers-sg"
  }
}

# ── Key Pair ──────────────────────────────────────────────────────
resource "aws_key_pair" "ubuntu_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# ── Data source: Ubuntu 24.04 AMI ─────────────────────────────────
data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── 3 EC2 Instances ───────────────────────────────────────────────
resource "aws_instance" "ubuntu_servers" {
  count                  = length(var.vm_name)
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.ubuntu_key.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = var.vm_name[count.index]
    Environment = "dev"
  }
}
