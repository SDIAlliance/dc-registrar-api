module "influxdb_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "influxdb"
  container_image = "influxdb:2"
  port_mappings = [
    {
      containerPort = var.influxdb_container_port,
      name          = "influxdb"
    }
  ]
  mount_points = [
    {
      containerPath = "/var/lib/influxdb2",
      sourceVolume  = "influxdb-storage"
    },
    {
      containerPath = "/etc/influxdb2/certs",
      sourceVolume  = "influxdb-certs"
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.default.name
      awslogs-stream-prefix = "influxdb"
    }
  }
}

resource "aws_ecs_task_definition" "influxdb" {
  family                   = "${var.namespace}-influxdb"
  container_definitions    = module.influxdb_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.influxdb_cpu
  memory                   = var.influxdb_ram
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "influxdb-storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.influxdb.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.default["data"].id
      }
    }
  }

  volume {
    name = "influxdb-certs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.influxdb.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.default["certs"].id
      }
    }
  }
}

resource "aws_ecs_service" "influxdb" {
  name                               = "${var.namespace}-${var.stage}-influxdb"
  cluster                            = module.ecs_cluster.name
  task_definition                    = aws_ecs_task_definition.influxdb.arn
  desired_count                      = 1
  deployment_maximum_percent         = 100 # prevent more than one task from accessing the storage
  deployment_minimum_healthy_percent = 0
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.influxdb.id]
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

resource "aws_security_group" "influxdb" {
  name   = "${var.namespace}-${var.stage}-influxdb"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "influxdb" {
  security_group_id = aws_security_group.influxdb.id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "influxdb" {
  security_group_id = aws_security_group.influxdb.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR or docker hub
  ip_protocol       = "tcp"
  description       = "Access to pull container"
}

resource "aws_vpc_security_group_egress_rule" "influxdb-efs" {
  security_group_id = aws_security_group.influxdb.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS file system"
}

resource "aws_efs_file_system" "influxdb" {
  encrypted = true
  tags = {
    Name = "${var.namespace}-${var.name}-influxdb"
  }
}

resource "aws_efs_mount_target" "influxdb" {
  for_each        = toset(module.dynamic_subnets.private_subnet_ids)
  file_system_id  = aws_efs_file_system.influxdb.id
  security_groups = [aws_security_group.influxdb-efs.id]
  subnet_id       = each.key
}

resource "aws_efs_access_point" "default" {
  for_each = toset(["data", "certs"])
  file_system_id = aws_efs_file_system.influxdb.id
  root_directory {
    path = "/${each.key}"
    creation_info {
      owner_gid = 0
      owner_uid = 0
      permissions = 0755
    }
  }
}

resource "aws_security_group" "influxdb-efs" {
  name   = "${var.namespace}-${var.stage}-influx-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "influxdb-efs" {
  security_group_id            = aws_security_group.influxdb-efs.id
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.influxdb.id
  ip_protocol                  = "tcp"
  description                  = "Allow NFS from inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "efs-influxdb" {
  security_group_id = aws_security_group.influxdb-efs.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}
