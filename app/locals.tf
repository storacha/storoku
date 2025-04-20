locals {
  dedicated_resources = var.environment == "prod" || var.environment == "staging"
  kms = local.dedicated_resources ? module.kms[0].kms : data.terraform_remote_state.shared.outputs.dev_kms
  vpc = local.dedicated_resources ? {
    id = module.vpc[0].id
    cidr_block = module.vpc[0].cidr_block 
    subnet_ids = module.vpc[0].subnet_ids
  } : {
    id = data.terraform_remote_state.shared.outputs.dev_vpc.id
    cidr_block = data.terraform_remote_state.shared.outputs.dev_vpc.cidr_block
    subnet_ids = data.terraform_remote_state.shared.outputs.dev_vpc.subnet_ids
  }
  caches = local.dedicated_resources ? module.caches[0].caches : data.terraform_remote_state.shared.outputs.dev_caches != null ? data.terraform_remote_state.shared.outputs.dev_caches.caches : {}
  databases = local.dedicated_resources ? module.databases[0].connection : data.terraform_remote_state.shared.outputs.dev_databases != null ? data.terraform_remote_state.shared.outputs.dev_databases.connection : {}
  domain = {
    name = var.environment == "prod" ? "${var.app}.storacha.network" : "${var.environment}.${var.app}.storacha.network"
    zone_id = data.terraform_remote_state.shared.outputs.primary_zone.zone_id
  }
  env_vars = concat(var.deployment_env_vars,
    [for key, cache in local.caches : {
      name = "${upper(key)}_CACHE_ID"
      value = cache.id
    }],
    [for key, cache in local.caches : {
      name = "${upper(key)}_CACHE_URL"
      value = "${cache.address}:${cache.port}"
    }],
    )
  secrets = concat(var.secrets, [{
    name = "private_key"
    valueFrom = aws_secretsmanager_secret.ecs_secret.arn
  }])
  config = var.deployment_config != null ? var.deployment_config : var.environment == "prod" ? {
    cpu = 1024
    memory = 2048
    service_min = 1
    service_max = 10
  } : {
    cpu = 256
    memory = 512
    service_min = 1
    service_max = 2
  }
}