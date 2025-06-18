# Create a route53 zone for each network
resource "aws_route53_zone" "network" {
  for_each = local.all_networks

  # For 'hot' network, use the base domain directly
  # For other networks, include the network name in the domain
  name = each.key == "hot" ? (
    var.domain_base != "" ? var.domain_base : "${var.app}.storacha.network"
  ) : (
    var.domain_base != "" ? "${each.key}.${var.domain_base}" : "${var.app}.${each.key}.storacha.network"
  )
}

# Create Cloudflare NS records for each route53 zone if Cloudflare is enabled
resource "cloudflare_dns_record" "ns" {
  for_each = local.cloudflare_records

  zone_id = var.zone_id
  comment = "route53 DNS record for ${each.value.network} network"
  content = aws_route53_zone.network[each.value.network].name_servers[each.value.idx]
  name    = aws_route53_zone.network[each.value.network].name
  type    = "NS"
  ttl     = 1

  depends_on = [aws_route53_zone.network]
}
