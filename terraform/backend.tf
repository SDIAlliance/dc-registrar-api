terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region  = "eu-central-1"
    bucket  = "nadiki-prod-terraform"
    key     = "terraform.tfstate"
    profile = ""
    encrypt = "true"

    dynamodb_table = "nadiki-prod-terraform-lock"
  }
}
