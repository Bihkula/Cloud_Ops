# S3 is a regional service reached over the public API by default. A Gateway
# VPC Endpoint adds an S3 route to our route tables so traffic to buckets
# (Terraform state, Kops state store, artifacts) stays on AWS's private network
# and the private-tier nodes never need to egress through NAT to reach S3.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  # Attach to the private route tables (where the k8s nodes / Kops live).
  route_table_ids = aws_route_table.private[*].id

  tags = {
    Name = "${local.name_prefix}-s3-endpoint"
  }
}
