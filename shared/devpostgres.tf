locals {
  # Only prod and staging get their own caches. All other envs will share the dev caches
  should_create_shared_postgres = var.create_db && terraform.workspace != "prod" && terraform.workspace != "staging"
}

module "dev_postgres" {
  count = local.should_create_shared_postgres ? 1 : 0

  source = "../postgres"

  app = var.app
  environment = "dev"

  db_config = {
    allocated_storage = 20
    multi_az = false
    proxy = false
    instance_class = "db.t4g.micro"
    performance_insights_retention_period = 7
  }

  vpc = local.vpc
}