#module "ui" {
#  source             = "./ecs_service"
#  name               = "ui"
#  namespace          = var.namespace
#  stage              = var.stage
#  vpc_id             = module.vpc.vpc_id
#  public_subnet_ids  = module.dynamic_subnets.public_subnet_ids
#  private_subnet_ids = module.dynamic_subnets.private_subnet_ids
#  ecs_cluster_name   = module.ecs_cluster.name
#  execution_role_arn = aws_iam_role.execution.arn
#  #task_role_arn              =
#  container_image           = "${module.ecr.repository_url_map["${var.namespace}/ui"]}:${var.ui_image_tag}"
#  container_entrypoint      = ["gunicorn"]
#  container_command         = ["--certfile", "/etc/letsencrypt/live/app.svc.nadiki.work/fullchain.pem", "--keyfile", "/etc/letsencrypt/live/app.svc.nadiki.work/privkey.pem", "nadiki_ui:app", "-b", "0.0.0.0:${var.ui_container_port}"]
#  log_group_name            = aws_cloudwatch_log_group.default.name
#  runtime_platform_cpu_arch = "X86_64"
#  cpu                       = var.ui_cpu
#  ram                       = var.ui_ram
#  #own_efs_volume_mount_point =
#  create_service   = true
#  extra_efs_mounts = { "certbot" : { "mount_point" : "/etc/letsencrypt", file_system_id = module.certbot.efs_file_system_id, access_point_id = module.certbot.access_point_id } }
#  #service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
#  port_mappings = [
#    {
#      containerPort = var.ui_container_port
#      name          = "http"
#    }
#  ]
#  environment = [
#    {
#      name  = "DATABASE_HOST",
#      value = "mariadb.${var.internal_domain_name}"
#    },
#    {
#      name  = "DATABASE_USER",
#      value = "root" # FIXME
#    },
#    {
#      name  = "INFLUXDB_ORG",
#      value = var.influxdb_org
#    },
#    {
#      name  = "INFLUXDB_ENDPOINT_URL",
#      value = "https://influxdb.${var.internal_domain_name}:${var.influxdb_container_port}"
#    }
#  ]
#  secrets = [
#    {
#      name      = "DATABASE_PASSWORD",
#      valueFrom = aws_secretsmanager_secret.mariadb_root_password.arn
#    },
#    {
#      name      = "INFLUXDB_ADMIN_TOKEN",
#      valueFrom = aws_secretsmanager_secret.influxdb_admin_token.arn
#    }
#  ]
#}
#
#resource "aws_vpc_security_group_egress_rule" "ui-database" {
#  security_group_id = module.ui.task_security_group_id
#  from_port         = var.mariadb_container_port
#  to_port           = var.mariadb_container_port
#  cidr_ipv4         = module.vpc.vpc_cidr_block
#  ip_protocol       = "tcp"
#  description       = "Database access"
#}
#
#resource "aws_vpc_security_group_egress_rule" "ui-influxdb" {
#  security_group_id = module.ui.task_security_group_id
#  from_port         = var.influxdb_container_port
#  to_port           = var.influxdb_container_port
#  cidr_ipv4         = module.vpc.vpc_cidr_block
#  ip_protocol       = "tcp"
#  description       = "InfluxDB access"
#}
#