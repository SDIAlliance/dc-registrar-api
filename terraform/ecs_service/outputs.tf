output "efs_file_system_id" {
  value = var.own_efs_volume_mount_point != null ? aws_efs_file_system.default[0].id : null
}

output "access_point_id" {
  value = var.own_efs_volume_mount_point != null ? aws_efs_access_point.default[0].id : null
}

output "task_security_group_id" {
  value = aws_security_group.task.id
}

output "ecs_service_name" {
  value = var.create_service ? aws_ecs_service.default[0].name : null
}
