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
  image_tag_mutability   = "MUTABLE"
  principals_full_access = ["arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"]
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
          aws_secretsmanager_secret.mariadb_root_password.arn,
          aws_secretsmanager_secret.influxdb_admin_token.arn
        ]
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Sid    = "AllowLogging"
        Resource = [
          aws_cloudwatch_log_group.default.arn,
          "${aws_cloudwatch_log_group.default.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "mariadb_root_password" {
  name = "${var.namespace}-${var.stage}-mariadb-root-password"
}

resource "aws_secretsmanager_secret" "influxdb_admin_token" {
  name = "${var.namespace}-${var.stage}-influxdb-admin-token"
}

resource "aws_cloudwatch_log_group" "default" {
  name = "/${var.namespace}-${var.name}"
}

module "dns_updater" {
  source = "github.com/dboesswetter/ecs-public-dns-update"
  service_name_mappings = [
    {
      hosted_zone_id   = aws_route53_zone.default.id
      dns_name         = "registrar.${var.public_zone_name}"
      dns_ttl          = 60 # keep it short because deployments will change the IP
      ecs_service_name = aws_ecs_service.registrar.name
      ecs_cluster_name = module.ecs_cluster.name
    },
    {
      hosted_zone_id   = aws_route53_zone.default.id
      dns_name         = "influxdb.${var.public_zone_name}"
      dns_ttl          = 60 # keep it short because deployments will change the IP
      ecs_service_name = aws_ecs_service.influxdb.name
      ecs_cluster_name = module.ecs_cluster.name
    }
  ]
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  name        = var.internal_domain_name
  description = "Private DNS namespace for Nadiki services"
  vpc         = module.vpc.vpc_id
}
