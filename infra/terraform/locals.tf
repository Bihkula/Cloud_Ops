data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # cloudops-cirrus-prod — the base for every resource name.
  name_prefix = "${var.project}-${var.app_name}-${var.environment}"

  # Take the first az_count AZs in the region.
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Carve the VPC (/16) into /20 blocks and hand them out per tier, one per AZ.
  # newbits = 4  ->  16 x /20 subnets available inside a /16.
  #   public   -> blocks 0,1,2      (10.0.0.0/20,  10.0.16.0/20, ...)
  #   private  -> blocks 4,5,6      (10.0.64.0/20, ...)  <- k8s nodes / pods
  #   isolated -> blocks 8,9,10     (10.0.128.0/20, ...) <- RDS only
  public_subnet_cidrs   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 4)]
  isolated_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
}
