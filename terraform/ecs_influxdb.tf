#module "influxdb" {
#  source                     = "./ecs_service"
#  name                       = "influxdb"
#  namespace                  = var.namespace
#  stage                      = var.stage
#  vpc_id                     = module.vpc.vpc_id
#  public_subnet_ids          = module.dynamic_subnets.public_subnet_ids
#  private_subnet_ids         = module.dynamic_subnets.private_subnet_ids
#  ecs_cluster_name           = module.ecs_cluster.name
#  capacity_provider_strategy = "FARGATE"
#  deployment_maximum_percent = 100
#  deployment_minimum_percent = 0
#  execution_role_arn         = aws_iam_role.execution.arn
#  #task_role_arn              = 
#  container_image = "influxdb:2"
#  #container_command          = 
#  log_group_name                 = aws_cloudwatch_log_group.default.name
#  runtime_platform_cpu_arch      = "ARM64"
#  cpu                            = var.influxdb_cpu
#  ram                            = var.influxdb_ram
#  own_efs_volume_mount_point     = "/var/lib/influxdb2"
#  create_service                 = true
#  extra_efs_mounts               = { "certbot" : { "mount_point" : "/etc/letsencrypt", file_system_id = module.certbot.efs_file_system_id, access_point_id = module.certbot.access_point_id } }
#  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
#  environment = [
#    {
#      name  = "INFLUXD_TLS_CERT"
#      value = "/etc/letsencrypt/live/influxdb.svc.nadiki.work/fullchain.pem"
#    },
#    {
#      name  = "INFLUXD_TLS_KEY"
#      value = "/etc/letsencrypt/live/influxdb.svc.nadiki.work/privkey.pem"
#    },
#    {
#      name  = "INFLUXD_HTTP_BIND_ADDRESS",
#      value = ":${var.influxdb_container_port}"
#    }
#  ]
#  port_mappings = [
#    {
#      containerPort = var.influxdb_container_port,
#      name          = "influxdb"
#    }
#  ]
#}
#
#resource "aws_vpc_security_group_ingress_rule" "influxdb-world" {
#  security_group_id = module.influxdb.task_security_group_id
#  from_port         = 8443
#  to_port           = 8443
#  cidr_ipv4         = "0.0.0.0/0"
#  ip_protocol       = "tcp"
#  description       = "InfluxDB access from everywhere"
#}
#