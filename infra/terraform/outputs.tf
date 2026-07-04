# =============================================================================
# These are the handoff values. Kops, Helm, and the CI pipeline all read from
# here (via `terraform output`), so nothing downstream is hardcoded.
# =============================================================================

output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet ids (ALB, NAT)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet ids (Kops nodes / Cirrus pods)"
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "Isolated subnet ids (RDS)"
  value       = aws_subnet.isolated[*].id
}

output "availability_zones" {
  description = "AZs in use"
  value       = local.azs
}

output "app_security_group_id" {
  description = "Attach this to the Kops nodes (additionalSecurityGroups) so RDS accepts them"
  value       = aws_security_group.app.id
}

output "ecr_repository_url" {
  description = "ECR repo URL — docker push target and Helm image.repository"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "RDS address (host only)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "database_url_secret_arn" {
  description = "Secrets Manager ARN holding the full DATABASE_URL for Helm to inject"
  value       = aws_secretsmanager_secret.database_url.arn
}

output "kops_state_store" {
  description = "Set KOPS_STATE_STORE to this"
  value       = "s3://${aws_s3_bucket.kops_state.bucket}"
}

output "artifacts_bucket" {
  description = "General-purpose project bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "ci_ecr_push_policy_arn" {
  description = "Attach to the CI runner identity to allow image pushes"
  value       = aws_iam_policy.ci_ecr_push.arn
}

output "cluster_name" {
  description = "Kops cluster name derived from the app name"
  value       = "${var.app_name}.k8s.local"
}
