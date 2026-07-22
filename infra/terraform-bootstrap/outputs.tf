output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.locks.name
}

output "backend_config_snippet" {
  description = "Paste this into infra/terraform/versions.tf"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.state.bucket}"
      key            = "cirrus/terraform.tfstate"
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.locks.name}"
      encrypt        = true
    }
  EOT
}
