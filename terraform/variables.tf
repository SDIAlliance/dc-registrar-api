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