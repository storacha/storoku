output "secrets" {
  value = { for name, secret in var.secrets : name => aws_secretsmanager_secret.ecs_secret[name].arn }
}