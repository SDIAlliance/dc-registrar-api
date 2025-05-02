module "registrar_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "registrar"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/registrar"]}:${var.registrar_image_tag}"

  # Why do I need to say this again here? Should this be taken from the Dockerfile-prod???
  entrypoint = ["gunicorn"]
  command    = ["--certfile", "/etc/letsencrypt/live/registrar.svc.nadiki.work/fullchain.pem", "--keyfile", "/etc/letsencrypt/live/registrar.svc.nadiki.work/privkey.pem", "nadiki_registrar.__main__:main()", "-b", "0.0.0.0:443"]

  port_mappings = [
    {
      containerPort = var.registrar_container_port
      name          = "http"
    }
  ]
  mount_points = [
    {
      containerPath = "/etc/letsencrypt",
      sourceVolume  = "registrar-certs"
    }
  ]
  environment = [
    {
      name  = "DATABASE_HOST",
      value = "mariadb.${var.internal_domain_name}"
    },
    {
      name  = "DATABASE_USER",
      value = "root" # FIXME
    },
    {
      name  = "INFLUXDB_ORG",
      value = var.influxdb_org
    },
    {
      name  = "INFLUXDB_ENDPOINT_URL",
      value = "https://influxdb.${var.internal_domain_name}:${var.influxdb_container_port}"
    }
  ]
  secrets = [
    {
      name      = "DATABASE_PASSWORD",
      valueFrom = aws_secretsmanager_secret.mariadb_root_password.arn
    },
    {
      name      = "INFLUXDB_ADMIN_TOKEN",
      valueFrom = aws_secretsmanager_secret.influxdb_admin_token.arn
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.default.name
      awslogs-stream-prefix = "registrar"
    }
  }
}

resource "aws_ecs_task_definition" "registrar" {
  family                   = "${var.namespace}-registrar"
  container_definitions    = module.registrar_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.registrar_cpu
  memory                   = var.registrar_ram
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # FIXME
  }

  volume {
    name = "registrar-certs"

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

resource "aws_ecs_service" "registrar" {
  name                               = "${var.namespace}-${var.stage}-registrar"
  cluster                            = module.ecs_cluster.name
  task_definition                    = aws_ecs_task_definition.registrar.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.registrar-task.id]
  }
}

resource "aws_security_group" "registrar-task" {
  name   = "${var.namespace}-${var.stage}-registrar"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "registrar-vpc" {
  security_group_id = aws_security_group.registrar-task.id
  from_port         = var.registrar_container_port
  to_port           = var.registrar_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "registrar-ecr" {
  security_group_id = aws_security_group.registrar-task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
  description       = "Access to ECR to pull container"
}

resource "aws_vpc_security_group_egress_rule" "registrar-database" {
  security_group_id = aws_security_group.registrar-task.id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "registrar-influxdb" {
  security_group_id = aws_security_group.registrar-task.id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}

# FIXME: close this down to just our EFS mount targets
resource "aws_vpc_security_group_egress_rule" "registrar-task-efs" {
  security_group_id = aws_security_group.registrar-task.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS file system"
}
