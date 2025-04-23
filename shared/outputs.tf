output "primary_zone" {
  value = aws_route53_zone.primary
}

output "dev_vpc" {
  value = length(module.dev_vpc) > 0 ? module.dev_vpc[0] : null
}

output "dev_caches" {
  value = length(module.dev_caches) > 0 ? module.dev_caches[0] : null
}

output "dev_databases" {
  value = length(module.dev_postgres) > 0 ? module.dev_postgres[0] : null
}

output "dev_kms" {
  value = module.dev_kms[0].kms
}