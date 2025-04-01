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
      containerPath = "/etc/letsencrypt",
      sourceVolume  = "influxdb-certs"
    }
  ]
  environment = [
    {
      name  = "INFLUXD_TLS_CERT"
      value = "/etc/letsencrypt/live/influxdb.svc.nadiki.work/fullchain.pem"
    },
    {
      name  = "INFLUXD_TLS_KEY"
      value = "/etc/letsencrypt/live/influxdb.svc.nadiki.work/privkey.pem"
    },
    {
      name  = "INFLUXD_HTTP_BIND_ADDRESS",
      value = ":${var.influxdb_container_port}"
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
    }
  }

  volume {
    name = "influxdb-certs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.certbot.id
      transit_encryption = "ENABLED"
      authorization_config {
        # we need an access point with root privs in order to read the certificates
        access_point_id = aws_efs_access_point.certbot.id
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
  service_registries {
    registry_arn = aws_service_discovery_service.influxdb.arn
  }
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.influxdb-task.id]
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

resource "aws_security_group" "influxdb-task" {
  name   = "${var.namespace}-${var.stage}-influxdb"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "influxdb-task-http-in" {
  security_group_id = aws_security_group.influxdb-task.id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "influxdb-task-container-registry" {
  security_group_id = aws_security_group.influxdb-task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR or docker hub
  ip_protocol       = "tcp"
  description       = "Access to pull container"
}

# FIXME: close this down to just our EFS mount targets
resource "aws_vpc_security_group_egress_rule" "influxdb-task-efs" {
  security_group_id = aws_security_group.influxdb-task.id
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

resource "aws_security_group" "influxdb-efs" {
  name   = "${var.namespace}-${var.stage}-influx-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "influxdb-efs-nfs-in" {
  security_group_id            = aws_security_group.influxdb-efs.id
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.influxdb-task.id
  ip_protocol                  = "tcp"
  description                  = "Allow NFS from InfluxDB"
}

resource "aws_vpc_security_group_egress_rule" "influxedb-efs-out" {
  security_group_id = aws_security_group.influxdb-efs.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}

resource "aws_service_discovery_service" "influxdb" {
  name = "influxdb"

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
