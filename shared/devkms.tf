locals {
  # Only prod and staging get their own VPC. All other envs will share the dev VPC
  should_create_shared_kms = terraform.workspace != "prod" && terraform.workspace != "staging"
}

module "dev_kms" {
  count = local.should_create_shared_kms ? 1 : 0

  source = "../kms"

  app = var.app
  environment = "dev"
}
