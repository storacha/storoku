locals {
  should_create_shared_kms = local.shared_resources
}

module "dev_kms" {
  count = local.should_create_shared_kms ? 1 : 0

  source = "../kms"

  app = var.app
  environment = "dev"

  providers = {
    aws = aws.dev
  }
}
