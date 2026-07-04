# -----------------------------------------------------------------------------
# Team-level decisions live here. Your README says to "agree as a team on: AWS
# region, VPC CIDR, cluster name" and to keep the app name in variables — so
# these are the knobs. Change them in one place (or a .tfvars file), nowhere
# else. This is the whole trick that makes the v2 rebrand a config change.
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region to deploy into. TEAM DECISION — pick one and stick to it."
  type        = string
  default     = "eu-west-1" # Ireland; closest low-latency region to the team in London
}

variable "project" {
  description = "Umbrella project name, used in resource names and tags."
  type        = string
  default     = "cloudops"
}

variable "app_name" {
  description = "The application name. THIS is the string threaded through ECR, K8s, Helm, Prometheus, etc. v2 rebrand = change this one value."
  type        = string
  default     = "cirrus"
}

variable "environment" {
  description = "Deployment environment (prod, staging, dev...)."
  type        = string
  default     = "prod"
}

# --- Networking -------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC. TEAM DECISION."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many Availability Zones to spread each subnet tier across (2 = HA on a budget, 3 = more resilient)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 for this project."
  }
}

variable "single_nat_gateway" {
  description = "true = one shared NAT Gateway (cheap, matches the README diagram). false = one NAT per AZ (HA, ~$32/mo each). Learning: leave true."
  type        = bool
  default     = true
}

# --- Database (RDS PostgreSQL) ---------------------------------------------

variable "db_name" {
  description = "Initial database name created inside the RDS instance."
  type        = string
  default     = "cirrus"
}

variable "db_username" {
  description = "Master username for RDS."
  type        = string
  default     = "cirrus"
}

variable "db_password" {
  description = "Master password for RDS. NEVER commit this. Pass via TF_VAR_db_password env var or a secrets manager. Gitleaks is the safety net."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Use a password of at least 16 characters."
  }
}

variable "db_instance_class" {
  description = "RDS instance size. db.t3.micro is the cheapest sane choice for learning."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB."
  type        = number
  default     = 20
}
