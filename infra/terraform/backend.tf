# -----------------------------------------------------------------------------
# Remote state backend.
#
# Chicken-and-egg: the bucket that holds Terraform state can't be created by the
# same Terraform run that uses it as a backend. So:
#
#   1. cd bootstrap && terraform init && terraform apply   (creates state bucket + lock table, LOCAL state)
#   2. Fill in the bucket/table names below from the bootstrap outputs.
#   3. Uncomment this block.
#   4. Back in infra/terraform: terraform init -migrate-state
#
# After that, state lives in S3 and is locked via DynamoDB for the whole team.
# -----------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-with-bootstrap-tfstate-bucket"
#     key            = "cirrus/infra/terraform.tfstate"
#     region         = "eu-west-1"
#     dynamodb_table = "REPLACE-with-bootstrap-lock-table"
#     encrypt        = true
#   }
# }
