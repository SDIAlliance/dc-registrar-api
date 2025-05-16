module "telegraf_promrcv" {
  source             = "./ecs_service"
  name               = "promrcv"
  namespace          = var.namespace
  stage              = var.stage
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.dynamic_subnets.public_subnet_ids
  private_subnet_ids = module.dynamic_subnets.private_subnet_ids
  ecs_cluster_name   = module.ecs_cluster.name
  execution_role_arn = aws_iam_role.execution.arn
  #task_role_arn              =
  container_image = "${module.ecr.repository_url_map["${var.namespace}/telegraf-prometheus-remote-write-receiver"]}:${var.telegraf_promrcv_image_tag}"
  #container_entrypoint      =
  #container_command         =
  log_group_name            = aws_cloudwatch_log_group.default.name
  runtime_platform_cpu_arch = "X86_64"
  cpu                       = var.telegraf_promrcv_cpu
  ram                       = var.telegraf_promrcv_ram
  #own_efs_volume_mount_point =
  create_service   = true
  extra_efs_mounts = { "certbot" : { "mount_point" : "/etc/letsencrypt", file_system_id = module.certbot.efs_file_system_id, access_point_id = module.certbot.access_point_id } }
  #service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
  port_mappings = [
    {
      containerPort = var.telegraf_promrcv_container_port
      name          = "http"
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
      value = var.telegraf_promrcv_container_port
    }
  ]
  secrets = [
    {
      name      = "OUTPUT_INFLUXDB_TOKEN",
      valueFrom = aws_secretsmanager_secret.influxdb_admin_token.arn
    }
  ]
}

resource "aws_vpc_security_group_egress_rule" "telegraf_promrvc-influxdb" {
  security_group_id = module.telegraf_promrcv.task_security_group_id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}
