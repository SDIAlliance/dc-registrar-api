module "jupyter-lab_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "jupyter-lab"
  container_image = "${module.ecr.repository_url_map["${var.namespace}/jupyter-lab"]}:${var.jupyter_lab_image_tag}"

  # Why do I need to say this again here? Should this be taken from the Dockerfile-prod???
  #entrypoint = ["gunicorn"]
  #command    = ["--certfile", "/etc/letsencrypt/live/jupyter-lab.svc.nadiki.work/fullchain.pem", "--keyfile", "/etc/letsencrypt/live/jupyter_lab.svc.nadiki.work/privkey.pem", "nadiki_jupyter_lab.__main__:main()", "-b", "0.0.0.0:443"]

  port_mappings = [
    {
      containerPort = var.jupyter_lab_container_port
      name          = "http"
    }
  ]
  mount_points = [
    {
      containerPath = "/etc/letsencrypt",
      sourceVolume  = "jupyter-lab-certs"
    },
    {
      containerPath = "/home/jupyterlab",
      sourceVolume  = "jupyter-lab-data"
    }
  ]
  environment = [
    {
      name  = "TLS_CERTIFICATE_PATH"
      value = "/etc/letsencrypt/live/jupyter.svc.nadiki.work/fullchain.pem"
    },
    {
      name  = "TLS_CA_PATH"
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

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.default.name
      awslogs-stream-prefix = "jupyter-lab"
    }
  }
}

resource "aws_ecs_task_definition" "jupyter-lab" {
  family                   = "${var.namespace}-jupyter-lab"
  container_definitions    = module.jupyter-lab_container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.jupyter_lab_cpu
  memory                   = var.jupyter_lab_ram
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # FIXME
  }

  volume {
    name = "jupyter-lab-certs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.certbot.id
      transit_encryption = "ENABLED"
      authorization_config {
        # we need an access point with root privs in order to read the certificates
        access_point_id = aws_efs_access_point.certbot.id
      }
    }
  }

  volume {
    name = "jupyter-lab-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.jupyter-lab.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.jupyter-lab.id
      }
    }
  }
}

resource "aws_ecs_service" "jupyter-lab" {
  name                               = "${var.namespace}-${var.stage}-jupyter-lab"
  cluster                            = module.ecs_cluster.name
  task_definition                    = aws_ecs_task_definition.jupyter-lab.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    subnets          = module.dynamic_subnets.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.jupyter-lab-task.id]
  }
}

resource "aws_security_group" "jupyter-lab-task" {
  name   = "${var.namespace}-${var.stage}-jupyter-lab"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "jupyter-lab-vpc" {
  security_group_id = aws_security_group.jupyter-lab-task.id
  from_port         = var.jupyter_lab_container_port
  to_port           = var.jupyter_lab_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Inside VPC"
}

resource "aws_vpc_security_group_egress_rule" "jupyter-lab-ecr" {
  security_group_id = aws_security_group.jupyter-lab-task.id
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0" # this could be narrowed down to ECR
  ip_protocol       = "tcp"
  description       = "Access to ECR to pull container"
}

resource "aws_vpc_security_group_egress_rule" "jupyter-lab-database" {
  security_group_id = aws_security_group.jupyter-lab-task.id
  from_port         = var.mariadb_container_port
  to_port           = var.mariadb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "Database access"
}

resource "aws_vpc_security_group_egress_rule" "jupyter-lab-influxdb" {
  security_group_id = aws_security_group.jupyter-lab-task.id
  from_port         = var.influxdb_container_port
  to_port           = var.influxdb_container_port
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "InfluxDB access"
}

# FIXME: close this down to just our EFS mount targets
resource "aws_vpc_security_group_egress_rule" "jupyter-lab-task-efs" {
  security_group_id = aws_security_group.jupyter-lab-task.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  description       = "NFS access to EFS file system"
}

resource "aws_efs_file_system" "jupyter-lab" {
  encrypted = true
  tags = {
    Name = "${var.namespace}-${var.name}-jupyter-lab"
  }
}

resource "aws_efs_mount_target" "jupyter-lab" {
  for_each        = toset(module.dynamic_subnets.private_subnet_ids)
  file_system_id  = aws_efs_file_system.jupyter-lab.id
  security_groups = [aws_security_group.jupyter-lab-efs.id]
  subnet_id       = each.key
}

resource "aws_security_group" "jupyter-lab-efs" {
  name   = "${var.namespace}-${var.stage}-jupyter-lab-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "jupyter-lab-efs-nfs-in" {
  security_group_id            = aws_security_group.jupyter-lab-efs.id
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.jupyter-lab-task.id
  ip_protocol                  = "tcp"
  description                  = "Allow NFS from Jupyter Lab"
}

resource "aws_vpc_security_group_egress_rule" "jupyter-lab-efs-out" {
  security_group_id = aws_security_group.jupyter-lab-efs.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
  description       = "Allow to serve data inside VPC"
}

resource "aws_efs_access_point" "jupyter-lab" {
  file_system_id = aws_efs_file_system.jupyter-lab.id
  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }
  }
  posix_user {
    uid = 0
    gid = 0
  }
}