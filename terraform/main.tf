module "terraform_state_backend" {
  source    = "cloudposse/tfstate-backend/aws"
  version   = "1.5.0"
  namespace = var.namespace
  stage     = var.stage
  name      = "terraform"

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

module "ecs_cluster" {
  source = "cloudposse/ecs-cluster/aws"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  container_insights_enabled = true
  capacity_providers_fargate = true
}

data "aws_caller_identity" "default" {}

module "ecr" {
  source                 = "cloudposse/ecr/aws"
  version                = "0.42.1"
  namespace              = var.namespace
  stage                  = var.stage
  name                   = var.name
  image_names            = ["${var.namespace}/mariadb", "${var.namespace}/registrar"]
  principals_full_access = ["arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"]
}

module "mariadb_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "mariadb"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/mariadb"]}:${var.mariadb_image_tag}"
  port_mappings = [
    {
      containerPort = 3306,
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
}

resource "aws_ecs_task_definition" "mariadb" {
  family                   = "mariadb"
  container_definitions    = module.mariadb_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # TODO: migrate to ARM
  }

  volume {
    name = "database-storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.mariadb.id
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_iam_role" "execution" {
  name = "${var.namespace}-${var.stage}-ecs-execution-role"
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

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy" "execution-secrets" {
  role = aws_iam_role.execution.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue",
        Effect = "Allow"
        Sid    = "AllowRootPassword"
        Resource = [
          aws_secretsmanager_secret.mariadb_root_password.arn
        ]
      },
    ]

  })
}

resource "aws_ecs_service" "mariadb" {
  name            = "${var.namespace}-${var.stage}-mariadb"
  cluster         = module.ecs_cluster.name
  task_definition = aws_ecs_task_definition.mariadb.arn
  desired_count   = 1
  launch_type     = "FARGATE"
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
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mariadb" {
  security_group_id = aws_security_group.mariadb.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mariadb-efs" {
  security_group_id = aws_security_group.mariadb.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
}

resource "aws_secretsmanager_secret" "mariadb_root_password" {
  name = "${var.namespace}-${var.stage}-mariadb-root-password"
}

resource "aws_efs_file_system" "mariadb" {
  encrypted = true
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
}

resource "aws_vpc_security_group_egress_rule" "efs" {
  security_group_id = aws_security_group.efs.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}