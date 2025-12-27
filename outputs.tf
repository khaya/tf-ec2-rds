output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app.public_dns
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Name of the PostgreSQL database"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Master username for the RDS instance"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "rds_password" {
  description = "Master password for the RDS instance"
  value       = random_password.db_password.result
  sensitive   = true
}

output "connection_command" {
  description = "Command to connect to the database from your local machine"
  value       = "PGPASSWORD='<password>' psql -h ${aws_db_instance.postgres.address} -p ${aws_db_instance.postgres.port} -U ${aws_db_instance.postgres.username} -d ${aws_db_instance.postgres.db_name}"
}

output "ssh_command" {
  description = "Command to SSH into the EC2 instance (requires key pair)"
  value       = var.ec2_key_name != "" ? "ssh -i ~/.ssh/${var.ec2_key_name}.pem ec2-user@${aws_instance.app.public_ip}" : "SSH key not configured. Set ec2_key_name variable to enable SSH access."
}
