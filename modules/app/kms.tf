locals {
  # Only prod and staging get their own VPC. All other envs will share the dev VPC
  should_create_kms = var.environment == "prod" || var.environment == "staging"
}

module "kms" {
  count = local.should_create_kms ? 1 : 0

  source = "../kms"

  app = var.app
  environment = var.environment
}
