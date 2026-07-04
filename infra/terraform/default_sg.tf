# The default security group is created implicitly with every VPC and permits
# all traffic between anything attached to it. Best practice is to adopt it and
# strip every rule so nothing accidentally rides on it. Free, and closes a real
# soft spot.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  # No ingress and no egress blocks == deny all.
  tags = { Name = "${local.name_prefix}-default-locked" }
}
