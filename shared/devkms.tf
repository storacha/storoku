locals {
  should_create_dev_kms = var.create_shared_dev_resources
}

module "dev_kms" {
  count = local.should_create_dev_kms ? 1 : 0

  source = "../kms"

  app = var.app
  environment = "dev"

  providers = {
    aws = aws.dev
  }
}
