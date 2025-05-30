module "ecs_infra" {
  source = "../ecs-infra"
  app = var.app
  environment = var.environment
  is_production = local.is_production
  domain = local.domain
  vpc = local.vpc
  cert_arn = module.cert.cert.arn
  kms = local.kms
  httpport = var.httpport
}