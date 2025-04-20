resource "aws_secretsmanager_secret" "ecs_secret" {
  #checkov:skip=CKV2_AWS_57: This variable does not need to be rotated
  name                    = "/${var.app}/${var.environment}/Secret/PRIVATE_KEY/value"
  recovery_window_in_days = 0
  kms_key_id              = local.kms.id
}

resource "aws_secretsmanager_secret_version" "ecs_secret_version" {
  secret_id     = aws_secretsmanager_secret.ecs_secret.id
  secret_string = var.private_key
}