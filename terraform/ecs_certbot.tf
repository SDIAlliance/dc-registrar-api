module "certbot" {
  source                     = "./ecs_service"
  name                       = "certbot"
  namespace                  = var.namespace
  stage                      = var.stage
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.dynamic_subnets.private_subnet_ids
  ecs_cluster_name           = module.ecs_cluster.name
  execution_role_arn         = aws_iam_role.execution.arn
  task_role_arn              = aws_iam_role.certbot_task_role.arn
  container_image            = "certbot/dns-route53"
  container_command          = ["certonly", "--dns-route53", "-m", var.cert_admin_email, "--agree-tos", "-n", "-d", "DOMAIN_GOES_HERE"]
  log_group_name             = aws_cloudwatch_log_group.default.name
  runtime_platform_cpu_arch  = "ARM64"
  own_efs_volume_mount_point = "/etc/letsencrypt"
  create_service             = false
}

resource "aws_iam_role" "certbot_task_role" {
  name = "${var.namespace}-certbot-task-role"
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

resource "aws_iam_role_policy" "certbot_task_role" {
  role = aws_iam_role.certbot_task_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Effect   = "Allow"
        Sid      = "AllowR53Global"
        Resource = "*"
      },
      {
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Effect = "Allow"
        Sid    = "AllowR53Changes"
        Resource = [
          aws_route53_zone.default.arn
        ]
      }
    ]
  })
}
