resource "aws_security_group" "task" {
  name   = "${var.namespace}-${var.stage}-${var.name}"
  vpc_id = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
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

resource "aws_vpc_security_group_ingress_rule" "task-in" {
  for_each          = { for x in var.port_mappings : x.name => x.containerPort }
  security_group_id = aws_security_group.task.id
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  ip_protocol       = "tcp"
  description       = "Allow access to port ${each.key}"
}

resource "aws_security_group" "efs" {
  count  = var.own_efs_volume_mount_point != null ? 1 : 0
  name   = "${var.namespace}-${var.stage}-${var.name}-efs"
  vpc_id = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs-nfs-in" {
  security_group_id            = aws_security_group.efs[0].id
  from_port                    = 2049
  to_port                      = 2049
  cidr_ipv4                    = var.make_own_efs_available_to_vpc ? data.aws_vpc.default.cidr_block : null
  referenced_security_group_id = var.make_own_efs_available_to_vpc ? null : aws_security_group.task.id
  ip_protocol                  = "tcp"
  description                  = "Allow NFS from inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "efs-nfs-out" {
  security_group_id = aws_security_group.efs[0].id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}
