# =============================================================================
# BOOTSTRAP — run this ONCE, before the main stack.
# Creates the S3 bucket that stores Terraform remote state and the DynamoDB
# table used for state locking. Uses LOCAL state itself (there's no remote
# backend to store the backend in).
#
#   terraform init
#   terraform apply
#   # then copy the outputs into ../backend.tf and run `terraform init -migrate-state`
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "Terraform"
      Component = "tf-state-bootstrap"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "cloudops"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project}-tfstate-${random_id.suffix.hex}"

  # Guard against a fat-fingered `terraform destroy` blowing away all state.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    id     = "expire-noncurrent-and-cleanup"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_dynamodb_table" "tflock" {
  #checkov:skip=CKV_AWS_119:Lock table holds only ephemeral lock IDs; AWS-owned encryption is sufficient, a KMS CMK isn't worth the cost here.
  point_in_time_recovery {
    enabled = true # cheap insurance for the state lock table
  }

  name         = "${var.project}-tflock-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "tfstate_bucket" {
  description = "Put this in backend.tf -> bucket"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tflock_table" {
  description = "Put this in backend.tf -> dynamodb_table"
  value       = aws_dynamodb_table.tflock.name
}
