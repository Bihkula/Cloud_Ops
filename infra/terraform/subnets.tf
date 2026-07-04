# =============================================================================
# Three subnet tiers, each spread across var.az_count AZs. This is the heart of
# the architecture diagram in the README.
#
#   PUBLIC   -> ALB + NAT       : route to IGW (inbound + outbound internet)
#   PRIVATE  -> k8s nodes/pods   : route to NAT (outbound only)
#   ISOLATED -> RDS              : NO 0.0.0.0/0 route at all
# =============================================================================

# ---- PUBLIC subnets ---------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${local.name_prefix}-public-${local.azs[count.index]}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1" # tells kops/AWS LB controller these hold public ELBs
  }
}

# ---- PRIVATE subnets (Kubernetes) ------------------------------------------
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name                              = "${local.name_prefix}-private-${local.azs[count.index]}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ---- ISOLATED subnets (Database) -------------------------------------------
resource "aws_subnet" "isolated" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.isolated_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-isolated-${local.azs[count.index]}"
    Tier = "isolated"
  }
}

# ---- NAT Gateway (lives in the PUBLIC tier, serves the PRIVATE tier) --------
# One shared NAT by default (cost). Flip var.single_nat_gateway to false for
# one-per-AZ high availability.
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : var.az_count
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ---- Route tables -----------------------------------------------------------

# PUBLIC: default route to the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# PRIVATE: default route to NAT (outbound only). One RT per AZ so that with
# per-AZ NAT each AZ egresses through its own gateway.
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-private-rt-${local.azs[count.index]}" }
}

resource "aws_route" "private_nat" {
  count                  = var.az_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  # With a single NAT, every private RT points at nat[0]; otherwise nat[per-az].
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ISOLATED: a route table with ONLY the implicit local route. No internet path
# exists for the database tier — this is what makes it truly isolated.
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-isolated-rt" }
}

resource "aws_route_table_association" "isolated" {
  count          = var.az_count
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}
