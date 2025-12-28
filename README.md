# Terraform EC2 and RDS Infrastructure

This repository contains Terraform configurations to deploy an AWS infrastructure with:
- **EC2 Instance**: t4g.nano ARM-based instance running Ubuntu 22.04 LTS
- **RDS PostgreSQL Database**: db.t4g.micro ARM-based instance with PostgreSQL 16
- **Networking**: VPC with public subnets, Internet Gateway, and security groups
- **Public Access**: RDS instance is publicly accessible for easy connectivity

## Architecture

The infrastructure includes:
- VPC with configurable CIDR block
- Two public subnets across different availability zones
- Internet Gateway for public internet access
- EC2 instance (t4g.nano) with PostgreSQL client pre-installed
- RDS PostgreSQL instance (db.t4g.micro) with public accessibility
- Security groups configured for SSH (EC2) and PostgreSQL (RDS) access
- Encrypted storage for both EC2 and RDS instances
- Automatic backup configuration for RDS

## Prerequisites

1. **Terraform**: Install Terraform >= 1.0 ([Download](https://www.terraform.io/downloads))
2. **AWS Account**: Active AWS account with appropriate permissions
3. **AWS CLI**: Configured with credentials ([Setup Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html))
4. **EC2 Key Pair** (Optional): For SSH access to EC2 instance

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/khaya/tf-ec2-rds.git
cd tf-ec2-rds
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your preferences:

```hcl
aws_region  = "us-east-1"
environment = "dev"
ec2_key_name = "your-key-pair-name"  # Optional: for SSH access
```

**Security Note**: For production use, restrict `allowed_ssh_cidr` and `allowed_db_cidr` to specific IP ranges instead of `0.0.0.0/0`.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

## Accessing Your Resources

### Database Connection

After deployment, retrieve the connection information:

```bash
# Get database endpoint
terraform output rds_address

# Get database credentials (sensitive)
terraform output -raw rds_username
terraform output -raw rds_password
```

Connect to PostgreSQL from your local machine:

```bash
PGPASSWORD='<password>' psql -h <rds-endpoint> -p 5432 -U dbadmin -d appdb
```

### EC2 Instance Access

If you configured an EC2 key pair:

```bash
# Get SSH command
terraform output ssh_command

# Or manually SSH
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-public-ip>
```

Once connected to EC2, you can use the pre-configured connection script:

```bash
./connect-db.sh
```

## Resource Details

### EC2 Instance
- **Type**: t4g.nano (ARM64 architecture)
- **OS**: Ubuntu 22.04 LTS (Jammy)
- **Storage**: 8 GB encrypted GP3 volume
- **Software**: PostgreSQL client pre-installed
- **IMDSv2**: Enabled for enhanced security

### RDS Instance
- **Type**: db.t4g.micro (ARM64 architecture)
- **Engine**: PostgreSQL 16.3
- **Storage**: 20 GB encrypted GP3 volume
- **Backups**: 7-day retention period
- **Public Access**: Enabled
- **High Availability**: Not enabled (single-AZ deployment)

### Security Groups

**EC2 Security Group**:
- Inbound: SSH (22) from configured CIDR
- Outbound: All traffic

**RDS Security Group**:
- Inbound: PostgreSQL (5432) from EC2 security group and configured CIDR
- Outbound: All traffic

## Outputs

The following outputs are available after deployment:

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `ec2_instance_id` | ID of the EC2 instance |
| `ec2_public_ip` | Public IP address of EC2 instance |
| `ec2_public_dns` | Public DNS name of EC2 instance |
| `rds_endpoint` | Full RDS endpoint (hostname:port) |
| `rds_address` | RDS hostname |
| `rds_port` | RDS port (5432) |
| `rds_database_name` | Database name |
| `rds_username` | Database master username (sensitive) |
| `rds_password` | Database master password (sensitive) |

## Cost Estimate

Approximate monthly costs (us-east-1 pricing):
- EC2 t4g.nano: ~$3.00/month
- RDS db.t4g.micro: ~$12.00/month
- Storage and data transfer: ~$2-5/month

**Total**: ~$17-20/month

## Security Best Practices

This configuration follows AWS security best practices:

1. ✅ Encrypted storage for both EC2 and RDS
2. ✅ IMDSv2 enabled on EC2 instance
3. ✅ Randomly generated strong database password
4. ✅ Security groups with least privilege access
5. ✅ VPC with isolated network segments
6. ✅ Automated backups for RDS
7. ✅ CloudWatch logs enabled for RDS

**Important**: For production use:
- Restrict security group rules to specific IP ranges
- Enable Multi-AZ deployment for RDS
- Enable deletion protection for RDS
- Use AWS Secrets Manager for password management
- Implement proper backup and disaster recovery procedures
- Consider private subnets with NAT Gateway for enhanced security

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted to confirm deletion.

## Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-east-1` | No |
| `environment` | Environment name | `dev` | No |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `public_subnet_cidrs` | Public subnet CIDR blocks | `["10.0.1.0/24", "10.0.2.0/24"]` | No |
| `db_name` | PostgreSQL database name | `appdb` | No |
| `db_username` | Database master username | `dbadmin` | No |
| `allowed_ssh_cidr` | CIDR allowed for SSH access | `0.0.0.0/0` | No |
| `allowed_db_cidr` | CIDR allowed for DB access | `0.0.0.0/0` | No |
| `ec2_key_name` | EC2 key pair name | `""` | No |

## Troubleshooting

### Cannot connect to RDS from local machine

1. Verify security group allows your IP:
   ```bash
   terraform output rds_address
   # Check if your IP is in allowed_db_cidr
   ```

2. Ensure RDS is publicly accessible:
   ```bash
   aws rds describe-db-instances --db-instance-identifier <identifier>
   ```

### EC2 instance cannot connect to RDS

1. Check security group rules allow traffic from EC2 to RDS
2. Verify RDS endpoint is correct in the connection script
3. Check VPC and subnet configuration

### Terraform errors during apply

1. Ensure AWS credentials are configured correctly
2. Verify you have necessary IAM permissions
3. Check AWS service quotas for your account

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.