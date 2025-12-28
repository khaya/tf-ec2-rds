terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "tf-ec2-rds-state-bucket-2025"
    key     = "tf-ec2-rds-state"
    region  = "af-south-1"
    encrypt = true
    
    # Optional: Enable state locking with DynamoDB
    # dynamodb_table = "terraform-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "tf-ec2-rds"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
