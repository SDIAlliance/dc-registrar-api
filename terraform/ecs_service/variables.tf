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

variable "capacity_provider_strategy" {
  type        = string
  description = "Capacity provider strategy for the service"
  default     = "FARGATE"
}

variable "deployment_minimum_percent" {
  type    = number
  default = 100
}

variable "deployment_maximum_percent" {
  type    = number
  default = 200
}

variable "container_image" {
  type        = string
  description = "Container image to use for this service"
}

variable "container_command" {
  type        = list(string)
  description = "Command to execute in the container"
  default     = null
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

variable "make_own_efs_available_to_vpc" {
  type        = bool
  description = "If true, the created EFS access points will be available for the whole VPC, otherwise only for this service"
  default     = false
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
  default     = null
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

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs to use for the service"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs to use for the EFS"
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

variable "environment" {
  type        = list(object({ name = string, value = string }))
  description = "Environment variables to pass to the container"
  default     = []
}

variable "port_mappings" {
  type        = list(object({ name = string, containerPort = number }))
  description = "Port mappings for the service"
  default     = []
}

variable "service_discovery_namespace_id" {
  type        = string
  description = "ID of the namespace to use for service discovery"
  default     = null
}
