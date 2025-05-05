locals {
  dedicated_resources = var.environment == "prod" || var.environment == "staging"
  kms = local.dedicated_resources ? module.kms[0].kms : data.terraform_remote_state.shared.outputs.dev_kms
  vpc = local.dedicated_resources ? module.vpc[0] : data.terraform_remote_state.shared.outputs.dev_vpc
  buckets = var.buckets 
  caches = local.dedicated_resources ? length(var.caches) > 0 ? module.caches[0].caches : {} : try(data.terraform_remote_state.shared.outputs.dev_caches.caches, {})
  database = local.dedicated_resources ? var.create_db ? module.databases[0].database : null : try(data.terraform_remote_state.shared.outputs.dev_databases.database, null)
  domain_base = var.domain_base != "" ? var.domain_base : "${var.app}.storacha.network"
  domain = {
    name = var.environment == "prod" ? local.domain_base : "${var.environment}.${local.domain_base}"
    zone_id = data.terraform_remote_state.shared.outputs.primary_zone.zone_id
  }
  env_vars = concat(var.deployment_env_vars,
    [{
      name = var.did_env_var
      value = var.did
    }],
    [{
      name = var.principal_mapping_env_var
      value = var.principal_mapping
    }])
  secrets = [ for secret, arn in module.secrets.secrets : { name = secret, valueFrom = arn }]
  config = var.deployment_config != null ? var.deployment_config : var.environment == "prod" ? {
    cpu = 1024
    memory = 2048
    service_min = 1
    service_max = 10
    httpport = var.httpport
  } : {
    cpu = 256
    memory = 512
    service_min = 1
    service_max = 2
    httpport = var.httpport
  }
  db_username = "${var.environment}_${var.app}"
  db_database = "${var.environment}_${var.app}"
}