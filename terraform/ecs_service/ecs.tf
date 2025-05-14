locals {
  efs_mounts = var.own_efs_volume_mount_point == null ? var.extra_efs_mounts : merge(var.extra_efs_mounts, { "${var.name}-efs" = { file_system_id = aws_efs_file_system.default[0].id, mount_point = var.own_efs_volume_mount_point, access_point_id = aws_efs_access_point.default[0].id } })
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = var.name
  container_image = var.container_image
  command         = var.container_command
  mount_points    = [for k, v in local.efs_mounts : { containerPath = v.mount_point, sourceVolume = k }]
  environment     = var.environment
  port_mappings   = var.port_mappings

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = var.log_group_name
      awslogs-stream-prefix = var.name
    }
  }
}

resource "aws_ecs_task_definition" "default" {
  family                   = "${var.namespace}-${var.name}"
  container_definitions    = module.container_definition.json_map_encoded_list
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.ram
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = var.runtime_platform_os_family
    cpu_architecture        = var.runtime_platform_cpu_arch
  }

  dynamic "volume" {
    for_each = keys(local.efs_mounts)
    content {
      name = volume.value
      efs_volume_configuration {
        file_system_id     = local.efs_mounts[volume.value].file_system_id
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = local.efs_mounts[volume.value].access_point_id
        }
      }
    }
  }
}

resource "aws_ecs_service" "default" {
  count                              = var.create_service ? 1 : 0
  name                               = "${var.namespace}-${var.stage}-${var.name}" # FIXME: use stage always or never
  cluster                            = var.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.default.arn
  desired_count                      = 1
  deployment_maximum_percent         = 100 # prevent more than one task from accessing the storage
  deployment_minimum_healthy_percent = 0
  dynamic "service_registries" {
    for_each = aws_service_discovery_service.default.*
    content {
      registry_arn = aws_service_discovery_service.default[0].arn
    }
  }
  network_configuration {
    subnets          = var.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.task.id]
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

resource "aws_service_discovery_service" "default" {
  count = var.service_discovery_namespace_id != null ? 1 : 0
  name  = var.name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
