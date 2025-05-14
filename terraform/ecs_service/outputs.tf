output "efs_file_system_id" {
  value = var.own_efs_volume_mount_point != null ? aws_efs_file_system.default[0].id : null
}

output "access_point_id" {
  value = var.own_efs_volume_mount_point != null ? aws_efs_access_point.default[0].id : null
}