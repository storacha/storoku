locals {
  # Only prod and staging get their own caches. All other envs will share the dev caches
    should_create_postgres = length(var.databases) > 0 && terraform.workspace == "prod" || terraform.workspace == "staging"
}

module "databases" {
  count = local.should_create_postgres ? 1 : 0
  instances = var.databases
  source = "../postgres"

  app = var.app
  environment = terraform.workspace

  db_config = {
    allocated_storage = terraform.workspace == "prod" ? 100 : 10
    multi_az = terraform.workspace == "prod"
    instance_class = terraform.workspace == "prod" ? "db.t4g.large" : "db.t4g.micro"
    performance_insights_retention_period = terraform.workspace == "prod" ? 31 : 7
  }

  vpc = local.vpc
}