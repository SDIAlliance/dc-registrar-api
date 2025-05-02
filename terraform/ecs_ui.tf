module "ui_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "ui"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/ui"]}:${var.ui_image_tag}"

  # Why do I need to say this again here? Should this be taken from the Dockerfile-prod???
  entrypoint = ["gunicorn"]
  command    = ["--certfile", "/etc/letsencrypt/live/app.svc.nadiki.work/fullchain.pem", "--keyfile", "/etc/letsencrypt/live/app.svc.nadiki.work/privkey.pem", "nadiki_ui:app", "-b", "0.0.0.0:${var.ui_container_port}"]

  port_mappings = [
    {
      containerPort = var.ui_container_port
      name          = "http"
    }
  ]
  mount_points = [
    {
      containerPath = "/etc/letsencrypt",
      sourceVolume  = "ui-certs"
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
    },
    {
      name  = "SQS_QUEUE_URL",
      value = aws_sqs_queue.snapshot-creation.url
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
      awslogs-stream-prefix = "ui"
    }
  }
}

resource "aws_ecs_task_definition" "ui" {
  family                   = "${var.namespace}-ui"
  container_definitions    = module.ui_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ui_cpu
  memory                   = var.ui_ram
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.ui_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # FIXME
  }

  volume {
    name = "ui-certs"

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

resource "aws_iam_role" "ui_task_role" {
  name = "${var.namespace}-ui-task-role"
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

resource "aws_iam_role_policy" "ui_task_role" {
  role = aws_iam_role.ui_task_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Sid      = "AllowR53Global"
        Resource = aws_sqs_queue.snapshot-creation.arn
      }
    ]
  })
}

resource "aws_ecs_service" "ui" {
  name                               = "${var.namespace}-${var.stage}-ui"
  cluster                            = module.ecs_cluster.name
  task_definition                    = aws_ecs_task_definition.ui.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ui-task.id]
  }
}

resource "aws_security_group" "ui-task" {
  name   = "${var.namespace}-${var.stage}-ui"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ui-vpc" {
  security_group_id = aws_security_group.ui-task.id
  from_port         = var.ui_container_port
  to_port           = var.ui_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "ui-ecr" {
  security_group_id = aws_security_group.ui-task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
  description       = "Access to ECR to pull container"
}

resource "aws_vpc_security_group_egress_rule" "ui-database" {
  security_group_id = aws_security_group.ui-task.id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "ui-influxdb" {
  security_group_id = aws_security_group.ui-task.id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}

# FIXME: close this down to just our EFS mount targets
resource "aws_vpc_security_group_egress_rule" "ui-task-efs" {
  security_group_id = aws_security_group.ui-task.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS file system"
}

locals {
  snapshot_creation_queue_name = "${var.namespace}-snapshot-creation"
}

resource "aws_sqs_queue" "snapshot-creation" {
  name = local.snapshot_creation_queue_name
  policy = jsonencode({
    Version : "2012-10-17",
    Id : "__default_policy_ID",
    Statement : [
      {
        Sid : "__owner_statement",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"
        },
        Action : "SQS:*",
        Resource : "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.default.account_id}:${local.snapshot_creation_queue_name}"
      }
    ]
  })
  #  delay_seconds             = 90
  #  max_message_size          = 2048
  #  message_retention_seconds = 86400
  #  receive_wait_time_seconds = 10
  #  redrive_policy = jsonencode({
  #    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #    maxReceiveCount     = 4
  #  })
  #
  #  tags = {
  #    Environment = "production"
  #  }
}