module "secrets" {
  app = var.app
  environment = var.environment
  source = "../secret"
  secrets = merge({
    (var.private_key_env_var) = var.private_key
  }, var.secrets)
  external_secrets = var.external_secrets
  kms = local.kms
}
