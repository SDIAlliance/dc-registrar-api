
data "aws_region" "current" {}

data "aws_caller_identity" "default" {}

data "aws_vpc" "default" {
  id = var.vpc_id
}