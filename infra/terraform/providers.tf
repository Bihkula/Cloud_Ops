provider "aws" {
  region = var.region

  # Every resource created by this stack is tagged automatically. This is what
  # lets you find (and destroy) everything for a given app/env, and it is how
  # the v2 rename stays honest: the App tag follows var.app_name everywhere.
  default_tags {
    tags = {
      Project     = var.project
      App         = var.app_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
