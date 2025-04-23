locals {
  # Only prod and staging get their own caches. All other envs will share the dev caches
    should_create_postgres = var.create_db && (terraform.workspace == "prod" || terraform.workspace == "staging")
}

module "databases" {
  count = local.should_create_postgres ? 1 : 0
  source = "../postgres"

  app = var.app
  environment = var.environment

  db_config = {
    allocated_storage = var.environment == "prod" ? 100 : 20
    multi_az = var.environment == "prod"
    proxy = var.environment == "prod"
    instance_class = var.environment == "prod" ? "db.t4g.large" : "db.t4g.micro"
    performance_insights_retention_period = var.environment == "prod" ? 31 : 7
  }

  vpc = local.vpc
}

module "postgres-provisioner" {
  count = var.create_db ? 1 : 0
  source = "../postgres-provisioner"
  app = var.app
  environment = var.environment
  db_config = {
    app_username = local.db_username
    app_database = local.db_database
    access_policy_arn = local.database.access_policy_arn
    secret_arn = local.database.secret_arn
    address = local.database.instance_address
    port = local.database.port
  }
  vpc = local.vpc
}