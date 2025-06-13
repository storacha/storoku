terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
  backend "s3" {
    bucket = "storacha-terraform-state"
   
    region = "us-west-2"
    encrypt = true
  }
}

provider "aws" {
  allowed_account_ids = [var.allowed_account_id]
  region = "us-west-2"
  default_tags {
    tags = {
      "Environment" = terraform.workspace
      "ManagedBy"   = "OpenTofu"
      Owner         = "storacha"
      Team          = "Storacha Engineering"
      Organization  = "Storacha"
      Project       = "${var.app}"
    }
  }
}

module "shared" {
  source = "github.com/storacha/storoku//shared?ref={{.Version}}"
  create_db = {{.CreateDB}}
  caches = [ {{range .Caches}}"{{.}}",{{end}} ]
  networks = [ {{range .Networks}}"{{.}}",{{end}} ]
  app = var.app
  zone_id = {{if .Cloudflare}}var.cloudflare_zone_id{{else}}""{{end}}
  domain_base = var.domain_base
  setup_cloudflare = {{.Cloudflare}}
}