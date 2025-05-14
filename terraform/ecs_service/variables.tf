variable "namespace" {
  type        = string
  description = "Namespace to use for prefixing names"
}

variable "name" {
  type        = string
  description = "Name of this service"
}

variable "stage" {
  type        = string
  description = "Stage to use for naming with Cloudposse modules"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "container_image" {
  type        = string
  description = "Container image to use for this service"
}

variable "container_command" {
  type        = list(string)
  description = "Command to execute in the container"
}

variable "extra_efs_mounts" {
  type        = map(object({ mount_point = string, file_system_id = string, access_point_id = string }))
  description = "Map of objects describing extra EFS mounts (in addition to our own EFS filesystem)"
  default     = {}
}

variable "own_efs_volume_mount_point" {
  type        = string
  description = "If specified, an EFS volume is created and mounted under this directory"
}

variable "log_group_name" {
  type        = string
  description = "Name of the log group to use"
}

variable "cpu" {
  type        = number
  description = "CPU value for the service"
  default     = 256
}

variable "ram" {
  type        = number
  description = "RAM in MB for the service"
  default     = 512
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the execution role"
}

variable "task_role_arn" {
  type        = string
  description = "ARN of the task role"
}

variable "runtime_platform_os_family" {
  type        = string
  description = "OS family of the runtime platform"
  default     = "LINUX"
}

variable "runtime_platform_cpu_arch" {
  type        = string
  description = "CPU architecture of the runtime platform"
}

variable "service_discovery_registry_arn" {
  type        = string
  description = "ARN of the service discovery to register the service with"
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the service"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID in which the subnets live"
}

variable "create_service" {
  type        = bool
  description = "Whether to create the ECS service"
  default     = true
}
