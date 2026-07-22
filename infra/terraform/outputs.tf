output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Pass these to `kops create cluster --subnets`"
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  value = aws_subnet.isolated[*].id
}

output "nat_gateway_ips" {
  value = aws_eip.nat[*].public_ip
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "rds_endpoint" {
  description = "host:port for RDS"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_address" {
  value     = aws_db_instance.main.address
  sensitive = true
}

output "database_url" {
  description = "Full DATABASE_URL — feed this into the Kubernetes Secret, don't print it in CI logs"
  value       = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/${var.db_name}"
  sensitive   = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "kops_state_store" {
  description = "Set this as KOPS_STATE_STORE before running kops commands"
  value       = "s3://${aws_s3_bucket.kops_state.bucket}"
}

output "app_storage_bucket" {
  value = aws_s3_bucket.app_storage.bucket
}

output "node_iam_policy_arn" {
  description = "Attach to the kops node instance role via additionalPolicies"
  value       = aws_iam_policy.node_permissions.arn
}
