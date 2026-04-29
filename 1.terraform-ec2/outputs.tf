output "instance_ids" {
  description = "IDs of all 3 EC2 instances"
  value       = aws_instance.ubuntu_servers[*].id
}

output "public_ips" {
  description = "Public IPs of all 3 EC2 instances"
  value       = aws_instance.ubuntu_servers[*].public_ip
}

output "private_ips" {
  description = "Private IPs of all 3 EC2 instances"
  value       = aws_instance.ubuntu_servers[*].private_ip
}
