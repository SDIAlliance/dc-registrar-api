data "aws_network_interface" "efs" {
  for_each = var.own_efs_volume_mount_point != null ? toset(var.subnet_ids) : []
  id       = aws_efs_mount_target.default[each.key].network_interface_id
}

resource "aws_security_group" "task" {
  name   = "${var.namespace}-${var.stage}-${var.name}"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "task-container-registry" {
  security_group_id = aws_security_group.task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR or docker hub
  ip_protocol       = "tcp"
  description       = "Access to pull container"
}

resource "aws_vpc_security_group_egress_rule" "task-efs" {
  security_group_id = aws_security_group.task.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS"
}

resource "aws_security_group" "efs" {
  count  = var.own_efs_volume_mount_point != null ? 1 : 0
  name   = "${var.namespace}-${var.stage}-${var.name}-efs"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "efs-nfs-in" {
  security_group_id = aws_security_group.efs[0].id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  ip_protocol       = "tcp"
  description       = "Allow NFS from inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "efs-nfs-out" {
  security_group_id = aws_security_group.efs[0].id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}
