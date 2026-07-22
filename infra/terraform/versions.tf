terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # --- Remote state (S3) ---
  # The bucket (and, optionally, a DynamoDB table for locking) used here must
  # exist BEFORE you run `terraform init`, so it's created out-of-band (a
  # tiny one-off `aws s3 mb` / separate bootstrap stack) rather than by this
  # configuration itself — Terraform can't create the bucket it's about to
  # store its own state in.
  #
  # backend "s3" {
  #   bucket       = "cirrus-terraform-state"   # <- your bootstrap bucket
  #   key          = "cirrus/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true                       # S3-native locking (AWS provider >= 5.x)
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
