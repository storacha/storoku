locals {
  should_create_shared_caches = length(var.caches) > 0 && local.shared_resources
}

module "dev_caches" {
  count = local.should_create_shared_caches ? 1 : 0

  source = "../elasticaches"

  app = var.app
  environment = "dev"
  node_type = "cache.t4g.micro" # 2 vCPUs, 0.5 GiB memory, 5 Gigabit network, $0.0128/hour
  caches = var.caches

  vpc = local.vpc
}