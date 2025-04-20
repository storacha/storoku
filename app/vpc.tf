locals {
  # Only prod and staging get their own VPC. All other envs will share the dev VPC
  should_create_vpc = var.environment == "prod" || var.environment == "staging"
}

module "vpc" {
  count = local.should_create_vpc ? 1 : 0
  create_elasticache_net = length(var.caches) > 0
  create_db_net = length(var.databases) > 0

  source = "../vpc"

  app = var.app
  environment = var.environment
}
