#module "timeplus_proton" {
#  source             = "./ecs_service"
#  name               = "timeplus_proton"
#  namespace          = var.namespace
#  stage              = var.stage
#  vpc_id             = module.vpc.vpc_id
#  public_subnet_ids  = module.dynamic_subnets.public_subnet_ids
#  private_subnet_ids = module.dynamic_subnets.private_subnet_ids
#  ecs_cluster_name   = module.ecs_cluster.name
#  execution_role_arn = aws_iam_role.execution.arn
#  #task_role_arn              =
#  container_image = "d.timeplus.com/timeplus-io/proton:latest" # unfortunately no explicit tags, but we need v1.6.16 or higher due to a critical bug
#  #container_entrypoint      = 
#  #container_command         = 
#  log_group_name            = aws_cloudwatch_log_group.default.name
#  runtime_platform_cpu_arch = "ARM64"
#  cpu                       = var.timeplus_proton_cpu
#  ram                       = var.timeplus_proton_ram
#  #own_efs_volume_mount_point =
#  create_service = true
#  #extra_efs_mounts = 
#  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
#  environment = [
#  ]
#  secrets = [
#  ]
#  port_mappings = [
#    {
#      containerPort = var.timeplus_proton_container_http_port
#      name          = "http"
#    },
#    {
#      containerPort = var.timeplus_proton_container_tcp_port
#      name          = "tcp"
#    }
#  ]
#}