locals {
  domain_base = var.domain_base != "" ? var.domain_base : "${var.app}.storacha.network"
}
resource "aws_route53_zone" "primary" {
  name = local.domain_base
}

resource "cloudflare_dns_record" "app" {
  for_each = toset(var.setup_cloudflare ? aws_route53_zone.primary.name_servers : [])
  zone_id = var.zone_id
  comment = "route53 DNS record"
  content = each.key
  name = local.domain_base
  type = "NS"
  ttl = 1
  depends_on = [ aws_route53_zone.primary ]
}
