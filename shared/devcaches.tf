locals {
  should_create_dev_caches = var.create_shared_dev_resources && length(var.caches) > 0
}

module "dev_caches" {
  count = local.should_create_dev_caches ? 1 : 0

  source = "../elasticaches"

  app = var.app
  environment = "dev"

  providers = {
    aws = aws.dev
  }

  node_type = "cache.t4g.micro" # 2 vCPUs, 0.5 GiB memory, 5 Gigabit network, $0.0128/hour
  caches = var.caches

  vpc = local.vpc
}