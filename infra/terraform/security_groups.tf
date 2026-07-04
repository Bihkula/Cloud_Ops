# =============================================================================
# Security groups model the traffic flow from the diagram:
#   internet -> ALB (80/443) -> app/nodes (nodeport) -> RDS (5432)
# Each SG only trusts the SG "in front of" it, never raw CIDRs (except the
# public ALB, which by definition faces the internet).
# =============================================================================

# ---- ALB: the only thing allowed to take traffic from the internet ---------
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public ALB ingress"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_security_group_rule" "alb_http_in" {
  #checkov:skip=CKV_AWS_260:The ALB is internet-facing by design; open 80/443 is expected here and only here.
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from internet (redirect to HTTPS at the LB)"
}

resource "aws_security_group_rule" "alb_https_in" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS from internet"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "ALB to targets"
}

# ---- App / Kubernetes nodes -------------------------------------------------
# Attach this SG to the Kops nodes (spec.additionalSecurityGroups) so RDS can
# reference it. Only the ALB may reach the app, on the k8s NodePort range.
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Cirrus app / k8s nodes"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-app-sg" }
}

resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "NodePort range from the ALB only"
}

resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  security_group_id = aws_security_group.app.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound via NAT (image pulls, updates, RDS, S3)"
}

# ---- RDS: reachable ONLY from the app SG, on 5432 --------------------------
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "PostgreSQL reachable only from the app tier"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-rds-sg" }
}

resource "aws_security_group_rule" "rds_from_app" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "PostgreSQL from the Cirrus app SG only"
}
# NOTE: no egress rule on the RDS SG — the database never initiates connections.
