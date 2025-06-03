module "jupyter-lab" {
  source             = "./ecs_service"
  name               = "jupyter-lab"
  namespace          = var.namespace
  stage              = var.stage
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.dynamic_subnets.public_subnet_ids
  private_subnet_ids = module.dynamic_subnets.private_subnet_ids
  ecs_cluster_name   = module.ecs_cluster.name
  execution_role_arn = aws_iam_role.execution.arn
  #task_role_arn              = 
  container_image = "${module.ecr.repository_url_map["${var.namespace}/jupyter-lab"]}:${var.jupyter_lab_image_tag}"
  #container_command          = 
  log_group_name             = aws_cloudwatch_log_group.default.name
  runtime_platform_cpu_arch  = "X86_64"
  cpu                        = var.jupyter_lab_cpu
  ram                        = var.jupyter_lab_ram
  own_efs_volume_mount_point = "/home/jupyterlab"
  create_service             = true
  extra_efs_mounts           = { "certbot" : { "mount_point" : "/etc/letsencrypt", file_system_id = module.certbot.efs_file_system_id, access_point_id = module.certbot.access_point_id } }
  #service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.default.id
  environment = [
    {
      name  = "TLS_CERTIFICATE_PATH"
      value = "/etc/letsencrypt/live/jupyter.svc.nadiki.work/fullchain.pem"
    },
    {
      name  = "TLS_KEY_PATH"
      value = "/etc/letsencrypt/live/jupyter.svc.nadiki.work/privkey.pem"
    },
    {
      name  = "JUPYTER_PORT"
      value = var.jupyter_lab_container_port
    }
  ]
  port_mappings = [
    {
      containerPort = var.jupyter_lab_container_port
      name          = "http"
    }
  ]
}

resource "aws_vpc_security_group_egress_rule" "jupyter-lab-database" {
  security_group_id = module.jupyter-lab.task_security_group_id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "jupyter-lab-influxdb" {
  security_group_id = module.jupyter-lab.task_security_group_id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}

resource "aws_vpc_security_group_ingress_rule" "jupyter-world" {
  security_group_id = module.jupyter-lab.task_security_group_id
  from_port         = 8443
  to_port           = 8443
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  description       = "Jupyter Access from everywhere"
}
