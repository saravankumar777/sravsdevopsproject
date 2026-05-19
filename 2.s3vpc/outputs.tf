output "vpc_id" {
  value = aws_vpc.main.id
}

output "ec2_public_ip" {
  description = "Open this in browser"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Use this to connect to MySQL"
  value       = aws_db_instance.mysql.endpoint
}

output "state_bucket" {
  description = "S3 bucket storing Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}
