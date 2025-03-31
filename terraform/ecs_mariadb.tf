module "mariadb_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "mariadb"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/mariadb"]}:${var.mariadb_image_tag}"
  port_mappings = [
    {
      containerPort = var.mariadb_container_port,
      name          = "mysql"
    }
  ]
  secrets = [
    {
      name      = "MARIADB_ROOT_PASSWORD",
      valueFrom = aws_secretsmanager_secret.mariadb_root_password.arn
    }
  ]
  mount_points = [
    {
      containerPath = "/var/lib/mysql",
      sourceVolume  = "database-storage"
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.default.name
      awslogs-stream-prefix = "mariadb"
    }
  }
}

resource "aws_ecs_task_definition" "mariadb" {
  family                   = "${var.namespace}-mariadb"
  container_definitions    = module.mariadb_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.mariadb_cpu
  memory                   = var.mariadb_ram
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "database-storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.mariadb.id
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_ecs_service" "mariadb" {
  name                               = "${var.namespace}-${var.stage}-mariadb"
  cluster                            = module.ecs_cluster.name
  task_definition                    = aws_ecs_task_definition.mariadb.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100 # prevent more than one task from accessing the storage
  deployment_minimum_healthy_percent = 0
  service_registries {
    registry_arn = aws_service_discovery_service.default.arn
  }
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.mariadb.id]
  }
}

resource "aws_security_group" "mariadb" {
  name   = "${var.namespace}-${var.stage}-mariadb"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "mariadb" {
  security_group_id = aws_security_group.mariadb.id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "mariadb" {
  security_group_id = aws_security_group.mariadb.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
  description       = "Access to ECR to pull container"
}

resource "aws_vpc_security_group_egress_rule" "mariadb-efs" {
  security_group_id = aws_security_group.mariadb.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS file system"
}

resource "aws_efs_file_system" "mariadb" {
  encrypted = true
  tags = {
    Name = "${var.namespace}-${var.name}-mariadb"
  }
}

resource "aws_efs_mount_target" "mariadb" {
  for_each        = toset(module.dynamic_subnets.private_subnet_ids)
  file_system_id  = aws_efs_file_system.mariadb.id
  security_groups = [aws_security_group.efs.id]
  subnet_id       = each.key
}

resource "aws_security_group" "efs" {
  name   = "${var.namespace}-${var.stage}-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "efs" {
  security_group_id            = aws_security_group.efs.id
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.mariadb.id
  ip_protocol                  = "tcp"
  description                  = "Allow NFS from inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "efs" {
  security_group_id = aws_security_group.efs.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  name        = var.internal_domain_name
  description = "Private DNS namespace for using haproxy with CloudMap"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "default" {
  name = "mariadb"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.default.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
