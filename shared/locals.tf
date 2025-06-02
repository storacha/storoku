locals {
  # Only prod and staging get their own resources. All other envs will share the dev shared infra
  is_production = terraform.workspace == "prod" || terraform.workspace == "warm-prod"
  is_staging = terraform.workspace == "staging" || terraform.workspace == "warm-staging"
  shared_resources = !local.is_production && !local.is_staging

  vpc = module.dev_vpc[0]
}
