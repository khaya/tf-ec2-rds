variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
  default     = "dbadmin"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the EC2 instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_db_cidr" {
  description = "CIDR block allowed to connect to the RDS instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ec2_key_name" {
  description = "Name of the SSH key pair for EC2 instance (must exist in AWS)"
  type        = string
  default     = ""
}
