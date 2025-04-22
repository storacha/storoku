resource "aws_route53_zone" "primary" {
  name = "${var.app}.storacha.network"
}

resource "cloudflare_dns_record" "app" {
  for_each = toset(aws_route53_zone.primary.name_servers)
  zone_id = var.zone_id
  comment = "route53 DNS record"
  content = each.key
  name = "${var.app}.storacha.network"
  type = "NS"
  ttl = 1
  depends_on = [ aws_route53_zone.primary ]
}
