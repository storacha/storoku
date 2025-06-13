locals {
  # Only prod and staging get their own resources. All other envs will share the dev shared infra
  is_production = terraform.workspace == "prod" || terraform.workspace == "warm-prod"
  is_staging = terraform.workspace == "staging" || terraform.workspace == "warm-staging"
  shared_resources = !local.is_production && !local.is_staging

  # Ensure 'hot' is always in the networks list
  all_networks = toset(concat(["hot"], var.networks))

  # Generate Cloudflare records for all networks if enabled
  cloudflare_records = var.setup_cloudflare ? flatten([
    for net in local.all_networks : [
      for i in range(4) : {
        idx     = i
        network = net
      }
    ]
  ]) : []

  vpc = length(module.dev_vpc) > 0 ? module.dev_vpc[0] : null
}
