locals {
  # Only prod and staging get their own resources. All other envs will share the dev shared infra
  shared_resources = terraform.workspace != "prod" && terraform.workspace != "staging" && terraform.workspace != "warm-prod" && terraform.workspace != "warm-staging"

  vpc = module.dev_vpc[0]
}
