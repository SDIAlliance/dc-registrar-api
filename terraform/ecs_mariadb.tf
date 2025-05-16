module "mariadb" {
  source             = "./ecs_service"
  name               = "mariadb"
  namespace          = var.namespace
  stage              = var.stage
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.dynamic_subnets.public_subnet_ids
  private_subnet_ids = module.dynamic_subnets.private_subnet_ids
  ecs_cluster_name   = module.ecs_cluster.name
  #capacity_provider_strategy = "FARGATE_SPOT"
  deployment_maximum_percent = 100
  deployment_minimum_percent = 0
  execution_role_arn         = aws_iam_role.execution.arn
  #task_role_arn              = 
  container_image = "${module.ecr.repository_url_map["${var.namespace}/mariadb"]}:${var.mariadb_image_tag}"
  #container_command          = 
  log_group_name             = aws_cloudwatch_log_group.default.name
  runtime_platform_cpu_arch  = "ARM64"
  cpu                        = var.mariadb_cpu
  ram                        = var.mariadb_ram
  own_efs_volume_mount_point = "/var/lib/mysql"
  create_service             = true
  #extra_efs_mounts               = { "certbot" : { "mount_point" : "/etc/letsencrypt", file_system_id = module.certbot.efs_file_system_id, access_point_id = module.certbot.access_point_id } }
  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
  port_mappings = [
    {
      containerPort = var.mariadb_container_port,
      name          = "mysql"
    }
  ]
  secrets = [
    {
      name      = "MARIADB_ROOT_PASSWORD",
      valueFrom = aws_secretsmanager_secret.mariadb_root_password.arn
    }
  ]
}
