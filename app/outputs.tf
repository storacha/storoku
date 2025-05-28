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
  value = local.secrets
}

output "ecs_infra" {
  value = module.ecs_infra
}

output "deployment" {
  value = module.deployment
}

output "buckets" {
  value = module.buckets
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

output "env_files" {
  value = module.env_files
}
