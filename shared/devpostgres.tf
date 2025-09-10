locals {
  should_create_dev_postgres = var.create_dev_resources && var.create_db
}

module "dev_postgres" {
  count = local.should_create_dev_postgres ? 1 : 0

  source = "../postgres"

  app = var.app
  environment = "dev"

  providers = {
    aws = aws.dev
  }

  db_config = {
    allocated_storage = 20
    multi_az = false
    proxy = false
    proxy_user = ""
    instance_class = "db.t4g.micro"
    performance_insights_retention_period = 7
  }

  vpc = local.vpc
}