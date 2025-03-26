variable "namespace" {
  type        = string
  description = "Namespace to use for naming through Cloudposse modules"
}

variable "stage" {
  type        = string
  description = "Stage to use for naming with Cloudposse modules"
}

variable "name" {
  type        = string
  description = "Name to use for naming with Cloudposse modules"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR prefix to use for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AWS availability_zones to use"
}

variable "mariadb_image_tag" {
  type        = string
  description = "Tag to use when accessing the MariaDB mirror ECR"
}

variable "registrar_image_tag" {
  type        = string
  description = "Tag to use when accessing the registrar ECR"
}

variable "mariadb_cpu" {
  type        = number
  description = "CPU value for the MariaDB ECS service"
  default     = 256
}

variable "mariadb_ram" {
  type        = number
  description = "RAM in MB to use for the MariaDB ECS service"
  default     = 512
}

variable "registrar_cpu" {
  type        = number
  description = "CPU value for the Registrar ECS service"
  default     = 256
}

variable "registrar_ram" {
  type        = number
  description = "RAM in MB to use for the Registrar ECS service"
  default     = 512
}

variable "internal_domain_name" {
  type        = string
  description = "DNS zone to use for service discovery"
  default     = "leitmotiv.intern"
}

variable "mariadb_container_port" {
  type        = number
  description = "Port where MariaDB listens"
  default     = 3306
}

variable "registrar_container_port" {
  type        = number
  description = "Port where Registrar listens"
  default     = 8080
}

variable "public_zone_name" {
  type        = string
  description = "Name of the public DNS zone"
  default     = "svc.nadiki.work"
}

variable "influxdb_container_port" {
  type        = number
  description = "InfluxDB port"
  default     = 8086
}

variable "influxdb_cpu" {
  type        = number
  description = "CPU value for the InfluxDB ECS service"
  default     = 256
}

variable "influxdb_ram" {
  type        = number
  description = "RAM in MB to use for the InfluxDB ECS service"
  default     = 512
}
