locals {
  # Only prod gets a Global Accelerator
  should_create_ga = local.is_production
}

module "ga" {
  count       = local.should_create_ga ? 1 : 0
  source      = "../ga"
  target_arn  = module.ecs_infra.lb.arn
  environment = var.environment
  app         = var.app
}
