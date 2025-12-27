# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source to get latest Amazon Linux 2023 ARM64 AMI
data "aws_ami" "amazon_linux_2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Generate a random password for the RDS instance
resource "random_password" "db_password" {
  length  = 20
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Route Table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 Instance
resource "aws_security_group" "ec2" {
  name_prefix = "${var.environment}-ec2-sg-"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for RDS Instance
resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-sg-"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL access from EC2
  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # PostgreSQL access from public internet
  ingress {
    description = "PostgreSQL from allowed CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_db_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.environment}-db-subnet-group-"
  description = "Database subnet group for RDS"
  subnet_ids  = aws_subnet.public[*].id

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023_arm64.id
  instance_type          = "t4g.nano"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.ec2_key_name != "" ? var.ec2_key_name : null

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              dnf update -y
              
              # Install PostgreSQL client
              dnf install -y postgresql15
              
              # Create a connection script
              cat > /home/ec2-user/connect-db.sh << 'SCRIPT'
              #!/bin/bash
              echo "Connecting to PostgreSQL database..."
              echo "Host: ${aws_db_instance.postgres.address}"
              echo "Port: ${aws_db_instance.postgres.port}"
              echo "Database: ${aws_db_instance.postgres.db_name}"
              echo "Username: ${aws_db_instance.postgres.username}"
              echo ""
              PGPASSWORD='${random_password.db_password.result}' psql -h ${aws_db_instance.postgres.address} -p ${aws_db_instance.postgres.port} -U ${aws_db_instance.postgres.username} -d ${aws_db_instance.postgres.db_name}
              SCRIPT
              
              chmod +x /home/ec2-user/connect-db.sh
              chown ec2-user:ec2-user /home/ec2-user/connect-db.sh
              
              # Save connection details
              cat > /home/ec2-user/db-connection-info.txt << 'INFO'
              Database Connection Information
              ================================
              Host: ${aws_db_instance.postgres.address}
              Port: ${aws_db_instance.postgres.port}
              Database: ${aws_db_instance.postgres.db_name}
              Username: ${aws_db_instance.postgres.username}
              Password: ${random_password.db_password.result}
              
              To connect, run: ./connect-db.sh
              INFO
              
              chown ec2-user:ec2-user /home/ec2-user/db-connection-info.txt
              chmod 600 /home/ec2-user/db-connection-info.txt
              EOF

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${var.environment}-app-instance"
  }

  depends_on = [aws_db_instance.postgres]
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier_prefix = "${var.environment}-postgres-"

  # Instance configuration
  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true

  # Backup and maintenance
  backup_retention_period    = 7
  backup_window              = "03:00-04:00"
  maintenance_window         = "mon:04:00-mon:05:00"
  auto_minor_version_upgrade = true

  # Performance and monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = false
  monitoring_interval             = 0

  # Deletion protection
  deletion_protection = false
  skip_final_snapshot = true

  # Parameter group
  parameter_group_name = "default.postgres16"

  tags = {
    Name = "${var.environment}-postgres-db"
  }

  lifecycle {
    ignore_changes = [
      password,
    ]
  }
}
