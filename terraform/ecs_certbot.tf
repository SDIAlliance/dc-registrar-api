module "certbot_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "certbot"
  container_image = "certbot/dns-route53"

  command = ["certonly", "--dns-route53", "-m", var.cert_admin_email, "--agree-tos", "-n", "-d", "DOMAIN_GOES_HERE"]
  mount_points = [
    {
      containerPath = "/etc/letsencrypt",
      sourceVolume  = "certbot-efs"
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.default.name
      awslogs-stream-prefix = "certbot"
    }
  }
}

resource "aws_ecs_task_definition" "certbot" {
  family                   = "${var.namespace}-certbot"
  container_definitions    = module.certbot_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.certbot_cpu
  memory                   = var.certbot_ram
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.certbot_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "certbot-efs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.certbot.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.certbot.id
      }
    }
  }
}

resource "aws_iam_role" "certbot_task_role" {
  name = "${var.namespace}-certbot-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "certbot_task_role" {
  role = aws_iam_role.certbot_task_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Effect   = "Allow"
        Sid      = "AllowR53Global"
        Resource = "*"
      },
      {
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Effect = "Allow"
        Sid    = "AllowR53Changes"
        Resource = [
          aws_route53_zone.default.arn
        ]
      }
    ]
  })
}

resource "aws_security_group" "certbot-task" {
  name   = "${var.namespace}-${var.stage}-certbot"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "certbot-task-container-registry" {
  security_group_id = aws_security_group.certbot-task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR or docker hub
  ip_protocol       = "tcp"
  description       = "Access to pull container"
}

resource "aws_vpc_security_group_egress_rule" "certbot-task-efs" {
  for_each          = toset(module.dynamic_subnets.private_subnet_ids)
  security_group_id = aws_security_group.certbot-task.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = "${data.aws_network_interface.certbot-efs[each.key].private_ip}/32"
  ip_protocol       = "tcp"
  description       = "NFS access to Certbot EFS in subnet ${each.key}"
}

resource "aws_efs_file_system" "certbot" {
  encrypted = true
  tags = {
    Name = "${var.namespace}-${var.name}-certbot"
  }
}

resource "aws_efs_mount_target" "certbot" {
  for_each        = toset(module.dynamic_subnets.private_subnet_ids)
  file_system_id  = aws_efs_file_system.certbot.id
  security_groups = [aws_security_group.certbot-efs.id]
  subnet_id       = each.key
}

data "aws_network_interface" "certbot-efs" {
  for_each = toset(module.dynamic_subnets.private_subnet_ids)
  id       = aws_efs_mount_target.certbot[each.key].network_interface_id
}

resource "aws_security_group" "certbot-efs" {
  name   = "${var.namespace}-${var.stage}-certbot-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "certbot-efs-nfs-in" {
  security_group_id = aws_security_group.certbot-efs.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Allow NFS from inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "certbot-efs-nfs-out" {
  security_group_id = aws_security_group.certbot-efs.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}

resource "aws_efs_access_point" "certbot" {
  file_system_id = aws_efs_file_system.certbot.id
  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }
  }
  posix_user {
    uid = 0
    gid = 0
  }
}