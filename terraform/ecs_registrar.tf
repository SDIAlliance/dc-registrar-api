module "registrar" {
  source             = "./ecs_service"
  name               = "registrar"
  namespace          = var.namespace
  stage              = var.stage
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.dynamic_subnets.public_subnet_ids
  private_subnet_ids = module.dynamic_subnets.private_subnet_ids
  ecs_cluster_name   = module.ecs_cluster.name
  execution_role_arn = aws_iam_role.execution.arn
  #task_role_arn              =
  container_image           = "${module.ecr.repository_url_map["${var.namespace}/registrar"]}:${var.registrar_image_tag}"
  container_entrypoint      = ["gunicorn"]
  container_command         = ["--certfile", "/etc/letsencrypt/live/registrar.svc.nadiki.work/fullchain.pem", "--keyfile", "/etc/letsencrypt/live/registrar.svc.nadiki.work/privkey.pem", "nadiki_registrar.__main__:main()", "-b", "0.0.0.0:443"]
  log_group_name            = aws_cloudwatch_log_group.default.name
  runtime_platform_cpu_arch = "X86_64"
  cpu                       = var.registrar_cpu
  ram                       = var.registrar_ram
  #own_efs_volume_mount_point =
  create_service   = true
  extra_efs_mounts = { "certbot" : { "mount_point" : "/etc/letsencrypt", file_system_id = module.certbot.efs_file_system_id, access_point_id = module.certbot.access_point_id } }
  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
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
      name  = "INFLUXDB_EXTERNAL_ENDPOINT_URL",
      value = "https://influxdb.${var.public_zone_name}:${var.influxdb_container_port}"
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
    },
    {
      name      = "AUTH_USER",
      valueFrom = "${aws_secretsmanager_secret.registrar_basic_auth_credentials.arn}:AUTH_USER::"
    },
    {
      name      = "AUTH_PASSWORD",
      valueFrom = "${aws_secretsmanager_secret.registrar_basic_auth_credentials.arn}:AUTH_PASSWORD::"
    }
  ]
  port_mappings = [
    {
      containerPort = var.registrar_container_port
      name          = "http"
    }
  ]
}

resource "aws_vpc_security_group_egress_rule" "registrar-database" {
  security_group_id = module.registrar.task_security_group_id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "registrar-influxdb" {
  security_group_id = module.registrar.task_security_group_id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}

resource "aws_vpc_security_group_ingress_rule" "registrar-world" {
  security_group_id = module.registrar.task_security_group_id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  description       = "HTTPS access from everywhere"
}
