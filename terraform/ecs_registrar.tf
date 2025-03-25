module "registrar_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "registrar"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/registrar"]}:${var.registrar_image_tag}"
  port_mappings = [
    {
      containerPort = var.registrar_container_port
      name          = "http"
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
    }
  ]
  secrets = [
    {
      name      = "DATABASE_PASSWORD",
      valueFrom = aws_secretsmanager_secret.mariadb_root_password.arn
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
    security_groups  = [aws_security_group.registrar.id]
  }
}

resource "aws_security_group" "registrar" {
  name   = "${var.namespace}-${var.stage}-registrar"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "registrar-daniel" {
  security_group_id = aws_security_group.registrar.id
  from_port         = var.registrar_container_port
  to_port           = var.registrar_container_port
  cidr_ipv4         = "79.238.45.3/32"
  ip_protocol       = "tcp"
  description       = "Daniel @ Home"
}

resource "aws_vpc_security_group_ingress_rule" "registrar-vpc" {
  security_group_id = aws_security_group.registrar.id
  from_port         = var.registrar_container_port
  to_port           = var.registrar_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "registrar-ecr" {
  security_group_id = aws_security_group.registrar.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
  description       = "Access to ECR to pull container"
}

resource "aws_vpc_security_group_egress_rule" "registrar-database" {
  security_group_id = aws_security_group.registrar.id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_route53_zone" "default" {
  name = var.public_zone_name
}
