# =============================================================================
# Managed PostgreSQL, living in the ISOLATED tier. AWS runs the server, backups
# and patching; we just consume the endpoint. The app is DB-agnostic and reads
# DATABASE_URL, so this is a config change from local SQLite, not a code change.
# =============================================================================

# Subnet group pins RDS to the isolated subnets — the ones with no internet route.
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.isolated[*].id

  tags = { Name = "${local.name_prefix}-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2 # allow autoscaling headroom
  storage_type          = "gp3"
  storage_encrypted     = true # encryption at rest

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # the database must never touch the internet
  multi_az               = false # single-AZ for cost; see checkov skip below

  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true                        # free; snapshots inherit our tags
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"] # ship DB logs to CloudWatch
  deletion_protection        = false # learning stack gets torn down often
  skip_final_snapshot        = true  # ditto — no snapshot on destroy

  #checkov:skip=CKV_AWS_157:Single-AZ is a deliberate cost choice for this learning stack; flip var to multi_az for prod.
  #checkov:skip=CKV_AWS_293:deletion_protection off on purpose so `terraform destroy` works during learning.
  #checkov:skip=CKV_AWS_354:Performance Insights encryption not enabled to stay in free tier.

  tags = { Name = "${local.name_prefix}-postgres" }
}

# -----------------------------------------------------------------------------
# Assemble the full SQLAlchemy DATABASE_URL and store it in Secrets Manager.
# Phase 6 (Helm) reads this into a Kubernetes Secret -> DATABASE_URL env var, so
# the connection string never lands in git or a values file.
#   postgresql+psycopg2://<user>:<pass>@<endpoint>:5432/<db>
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "database_url" {
  name        = "${local.name_prefix}/database-url"
  description = "SQLAlchemy DATABASE_URL for the ${var.app_name} app"

  tags = { Name = "${local.name_prefix}-database-url" }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id
  secret_string = jsonencode({
    DATABASE_URL = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/${var.db_name}"
  })
}
