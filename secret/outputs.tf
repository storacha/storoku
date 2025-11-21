output "secrets" {
  value = merge(
    { for name, secret in var.secrets : name => aws_secretsmanager_secret.ecs_secret[name].arn },
    { for name in var.external_secrets : name => data.aws_secretsmanager_secret.external_secret[name].arn }
  )
}
