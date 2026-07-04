resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # required for RDS private DNS and VPC endpoints

  tags = {
    Name = "${local.name_prefix}-vpc"
    # Kops discovers subnets/resources by this tag. Value must match the cluster name.
    "kubernetes.io/cluster/${var.app_name}.k8s.local" = "shared"
  }
}

# The only door to the public internet, used exclusively by the public tier.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}
