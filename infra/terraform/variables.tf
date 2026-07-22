variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project/app. Kept variable-driven everywhere so the v2 rebrand is a var change, not a find-and-replace."
  type        = string
  default     = "cirrus"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ---------------- Networking ----------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread each subnet tier across"
  type        = number
  default     = 3
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the public subnet tier (ALB, NAT Gateway)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for the private subnet tier (Kops/Kubernetes nodes)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "isolated_subnet_cidrs" {
  description = "CIDRs for the isolated subnet tier (RDS)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway shared by all AZs (cheaper, less HA, fine for learning). Set false for one NAT per AZ."
  type        = bool
  default     = true
}

variable "app_port" {
  description = "Port the app listens on inside the cluster"
  type        = number
  default     = 8000
}

# ---------------- RDS ----------------

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "cirrus"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "cirrus_admin"
}

variable "db_password" {
  description = "Master password for RDS. Pass via TF_VAR_db_password (env var) or a secrets manager — never commit a real value."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS, in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "db_multi_az" {
  description = "Whether RDS runs Multi-AZ (leave false for learning/cost)"
  type        = bool
  default     = false
}

# ---------------- S3 ----------------

variable "kops_state_bucket_name" {
  description = "Globally-unique S3 bucket name for the Kops cluster state store"
  type        = string
}

variable "app_storage_bucket_name" {
  description = "Globally-unique S3 bucket name for general app object storage"
  type        = string
}
