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

module "ecr" {
  source                 = "cloudposse/ecr/aws"
  version                = "0.42.1"
  namespace              = var.namespace
  stage                  = var.stage
  name                   = var.name
  image_names            = ["${var.namespace}/mariadb", "${var.namespace}/registrar", "${var.namespace}/ui", "${var.namespace}/jupyter-lab", "${var.namespace}/telegraf-siec"]
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
          aws_secretsmanager_secret.influxdb_admin_token.arn,
          aws_secretsmanager_secret.registrar_basic_auth_credentials.arn
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

resource "aws_secretsmanager_secret" "registrar_basic_auth_credentials" {
  name = "${var.namespace}-${var.stage}-registrar-basic-auth-credentials"
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
      ecs_service_name = module.registrar.ecs_service_name
      ecs_cluster_name = module.ecs_cluster.name
    },
    {
      hosted_zone_id   = aws_route53_zone.default.id
      dns_name         = "influxdb.${var.public_zone_name}"
      dns_ttl          = 60 # keep it short because deployments will change the IP
      ecs_service_name = module.influxdb.ecs_service_name
      ecs_cluster_name = module.ecs_cluster.name
    },
    {
      hosted_zone_id   = aws_route53_zone.default.id
      dns_name         = "app.${var.public_zone_name}"
      dns_ttl          = 60 # keep it short because deployments will change the IP
      ecs_service_name = module.ui.ecs_service_name
      ecs_cluster_name = module.ecs_cluster.name
    },
    {
      hosted_zone_id   = aws_route53_zone.default.id
      dns_name         = "jupyter.${var.public_zone_name}"
      dns_ttl          = 60 # keep it short because deployments will change the IP
      ecs_service_name = module.jupyter-lab.ecs_service_name
      ecs_cluster_name = module.ecs_cluster.name
    },
    #    {
    #      hosted_zone_id   = aws_route53_zone.default.id
    #      dns_name         = "promrcv.${var.public_zone_name}"
    #      dns_ttl          = 60 # keep it short because deployments will change the IP
    #      ecs_service_name = module.telegraf_promrcv.ecs_service_name
    #      ecs_cluster_name = module.ecs_cluster.name
    #    }
  ]
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  name        = var.internal_domain_name
  description = "Private DNS namespace for Nadiki services"
  vpc         = module.vpc.vpc_id
}

resource "aws_route53_zone" "default" {
  name = var.public_zone_name
}
