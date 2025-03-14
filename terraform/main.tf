module "terraform_state_backend" {
  source    = "cloudposse/tfstate-backend/aws"
  version   = "1.5.0"
  namespace = var.namespace
  stage     = var.stage
  name      = "terraform"

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

module "ecs_cluster" {
  source = "cloudposse/ecs-cluster/aws"

  namespace = var.namespace
  stage = var.stage
  name      = var.name

  container_insights_enabled      = true
  capacity_providers_fargate      = true
}

data "aws_caller_identity" "default" {}

module "ecr" {
  source = "cloudposse/ecr/aws"
  version     = "0.42.1"
  namespace              = var.namespace
  stage                  = var.stage
  name                   = var.name
  image_names = ["${var.namespace}/mariadb", "${var.namespace}/registrar"]
  principals_full_access = ["arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"]
}

module "mariadb_container_definition" {
  source = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name  = "mariadb"
  container_image = module.ecr.repository_url_map["${var.namespace}/mariadb"]
}

resource "aws_ecs_task_definition" "service" {
  family = "mariadb"
  container_definitions = module.mariadb_container_definition.json_map_encoded_list
}