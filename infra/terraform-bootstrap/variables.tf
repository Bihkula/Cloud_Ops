variable "aws_region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, for tagging only"
  type        = string
  default     = "cirrus"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name to hold Terraform remote state for the MAIN stack"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "cirrus-terraform-locks"
}
