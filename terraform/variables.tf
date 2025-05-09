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

variable "ui_image_tag" {
  type        = string
  description = "Tag to use when accessing the UI ECR"
}

variable "jupyter_lab_image_tag" {
  type        = string
  description = "Tag to use when accessing the Jupyter Lab ECR"
}

variable "telegraf_promrvc_image_tag" {
  type        = string
  description = "Tag to use when accessing the Telegraf Prometheus Remote Write Receiver ECR"
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

variable "ui_cpu" {
  type        = number
  description = "CPU value for the UI ECS service"
  default     = 256
}

variable "ui_ram" {
  type        = number
  description = "RAM in MB to use for the UI ECS service"
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
  default     = 443
}

variable "ui_container_port" {
  type        = number
  description = "Port where UI listens"
  default     = 80
}

variable "jupyter_lab_container_port" {
  type        = number
  description = "Port where Jupyter Lab listens"
  default     = 80
}

variable "telegraf_promrvc_container_port" {
  type        = number
  description = "Port where Telegraf listens"
  default     = 80
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

variable "jupyter_lab_cpu" {
  type        = number
  description = "CPU value for the Jupyter Lab ECS service"
  default     = 256
}

variable "jupyter_lab_ram" {
  type        = number
  description = "RAM in MB to use for the Jupyter Lab ECS service"
  default     = 512
}

variable "telegraf_promrvc_cpu" {
  type        = number
  description = "CPU value for Telegraf"
  default     = 256
}

variable "telegraf_promrvc_ram" {
  type        = number
  description = "RAM in MB to use for Telegraf"
  default     = 512
}

variable "certbot_cpu" {
  type        = number
  description = "CPU value for the certbot ECS task"
  default     = 256
}

variable "certbot_ram" {
  type        = number
  description = "RAM in MB to use for the certbot ECS task"
  default     = 512
}

variable "cert_admin_email" {
  type        = string
  default     = "daniel@daniel-boesswetter.de"
  description = "E-mail address to specify when retrieving letsencrypt certificates"
}

variable "influxdb_org" {
  type        = string
  default     = "Leitmotiv"
  description = "InfluxDB organization to authenticate with"
}