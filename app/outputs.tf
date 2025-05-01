output "database" {
  value = local.database
}

output "caches" {
  value = local.caches
}

output "vpc" {
  value = local.vpc
}

output "kms" {
  value = local.kms
}

output "secrets" {
  value = module.secrets.secrets
}

output "ecs_infra" {
  value = module.ecs_infra
}

output "deployment" {
  value = module.deployment
}

output "tables" {
  value = module.tables
}

output "queue" {
  value = module.queues
}

output "topics" {
  value = module.topics
}