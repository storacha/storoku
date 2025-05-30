locals {
  should_create_kms = local.dedicated_resources
}

module "kms" {
  count = local.should_create_kms ? 1 : 0

  source = "../kms"

  app = var.app
  environment = var.environment
}
