locals {
  should_create_caches = length(var.caches) > 0 && local.dedicated_resources
}

module "caches" {
  count = local.should_create_caches ? 1 : 0
  caches = var.caches
  source = "../elasticaches"

  app = var.app
  environment = var.environment

  # cache.r7g.large => 2 vCPUs, 13.07 GiB memory, 12.5 Gigabit network, $0.1752/hour
  # cache.t4g.micro => 2 vCPUs, 0.5 GiB memory, 5 Gigabit network, $0.0128/hour
  node_type = local.is_production ? "cache.r7g.large" : "cache.t4g.micro"
  vpc = local.vpc
}