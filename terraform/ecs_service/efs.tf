resource "aws_efs_file_system" "default" {
  count     = var.own_efs_volume_mount_point != null ? 1 : 0
  encrypted = true
  tags = {
    Name = "${var.namespace}-${var.name}"
  }
}

resource "aws_efs_mount_target" "default" {
  for_each        = var.own_efs_volume_mount_point != null ? toset(var.private_subnet_ids) : []
  file_system_id  = aws_efs_file_system.default[0].id
  security_groups = [aws_security_group.efs[0].id]
  subnet_id       = each.key
}

resource "aws_efs_access_point" "default" {
  count          = var.own_efs_volume_mount_point != null ? 1 : 0
  file_system_id = aws_efs_file_system.default[0].id
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