locals {
  # Only prod gets a CloudFront distribution
  should_create_cloudfront = var.environment == "prod"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
      configuration_aliases = [ aws.acm ]
    }
  }
}

module "cloudfront" {
  count = local.should_create_cloudfront ? 1 : 0
  source = "../cloudfront"
  domain = local.domain
  providers = {
    aws = aws
    aws.acm = aws.acm
  }
}