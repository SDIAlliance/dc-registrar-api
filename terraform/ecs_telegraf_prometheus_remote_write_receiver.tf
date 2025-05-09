module "telegraf_promrvc_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "telegraf_promrvc"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/telegraf-prometheus-remote-write-receiver"]}:${var.telegraf_promrvc_image_tag}"

  port_mappings = [
    {
      containerPort = var.telegraf_promrvc_container_port
      name          = "http"
    }
  ]
  mount_points = [
    {
      containerPath = "/etc/letsencrypt",
      sourceVolume  = "telegraf_promrvc-certs"
    }
  ]
  environment = [
    {
      name  = "OUTPUT_INFLUXDB_ORGANIZATION",
      value = var.influxdb_org
    },
    {
      name  = "OUTPUT_INFLUXDB_URL",
      value = "https://influxdb.${var.internal_domain_name}:${var.influxdb_container_port}"
    },
    {
      name  = "OUTPUT_INFLUXDB_BUCKET",
      value = "XION"
    },
    {
      name  = "INPUT_HTTP_PORT",
      value = var.telegraf_promrvc_container_port
    }
  ]
  secrets = [
    {
      name      = "OUTPUT_INFLUXDB_TOKEN",
      valueFrom = aws_secretsmanager_secret.influxdb_admin_token.arn
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.default.name
      awslogs-stream-prefix = "telegraf_promrvc"
    }
  }
}

resource "aws_ecs_task_definition" "telegraf_promrvc" {
  family                   = "${var.namespace}-telegraf_promrvc"
  container_definitions    = module.telegraf_promrvc_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.telegraf_promrvc_cpu
  memory                   = var.telegraf_promrvc_ram
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.telegraf_promrvc_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # FIXME
  }

  volume {
    name = "telegraf_promrvc-certs"

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

resource "aws_iam_role" "telegraf_promrvc_task_role" {
  name = "${var.namespace}-telegraf_promrvc-task-role"
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

#resource "aws_iam_role_policy" "telegraf_promrvc_task_role" {
#  role = aws_iam_role.telegraf_promrvc_task_role.name
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = [
#          "sqs:SendMessage"
#        ]
#        Effect   = "Allow"
#        Sid      = "AllowR53Global"
#        Resource = aws_sqs_queue.snapshot-creation.arn
#      }
#    ]
#  })
#}

resource "aws_ecs_service" "telegraf_promrvc" {
  name                               = "${var.namespace}-${var.stage}-promrcv"
  cluster                            = module.ecs_cluster.name
  task_definition                    = aws_ecs_task_definition.telegraf_promrvc.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.telegraf_promrvc-task.id]
  }
}

resource "aws_security_group" "telegraf_promrvc-task" {
  name   = "${var.namespace}-${var.stage}-telegraf_promrvc"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "telegraf_promrvc-vpc" {
  security_group_id = aws_security_group.telegraf_promrvc-task.id
  from_port         = var.telegraf_promrvc_container_port
  to_port           = var.telegraf_promrvc_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "telegraf_promrvc-ecr" {
  security_group_id = aws_security_group.telegraf_promrvc-task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
  description       = "Access to ECR to pull container"
}

#resource "aws_vpc_security_group_egress_rule" "telegraf_promrvc-database" {
#  security_group_id = aws_security_group.telegraf_promrvc-task.id
#  from_port         = var.mariadb_container_port
#  to_port           = var.mariadb_container_port
#  cidr_ipv4         = module.vpc.vpc_cidr_block
#  ip_protocol       = "tcp"
#  description       = "Database access"
#}

resource "aws_vpc_security_group_egress_rule" "telegraf_promrvc-influxdb" {
  security_group_id = aws_security_group.telegraf_promrvc-task.id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}

# FIXME: close this down to just our EFS mount targets
resource "aws_vpc_security_group_egress_rule" "telegraf_promrvc-task-efs" {
  security_group_id = aws_security_group.telegraf_promrvc-task.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS file system"
}
