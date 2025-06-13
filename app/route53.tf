module "cert" {
  source = "../cert"
  domain = local.domain
}

resource "aws_route53_record" "alb" {
  zone_id = data.terraform_remote_state.shared.outputs.route53_zones[var.network].zone_id
  name    = local.domain.name
  type    = "A"

  alias {
    name                   = local.is_production ? module.cloudfront[0].distribution.domain_name : module.ecs_infra.lb.dns_name
    zone_id                = local.is_production ? module.cloudfront[0].distribution.hosted_zone_id : module.ecs_infra.lb.zone_id
    evaluate_target_health = true
  }
}