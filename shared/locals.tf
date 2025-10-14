locals {
  # Ensure 'hot' is always in the networks list
  all_networks = toset(concat(["hot"], var.networks))

  # Generate Cloudflare records for all networks if enabled
  cloudflare_records = var.setup_cloudflare ? merge([
    for net in local.all_networks : {
      for i in range(4) :
        "${net}-${i}" => {
          idx     = i
          network = net
        }
    }
  ]...) : {}

  vpc = length(module.dev_vpc) > 0 ? module.dev_vpc[0] : null
}
