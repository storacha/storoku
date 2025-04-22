resource "aws_secretsmanager_secret" "ecs_secret" {
  for_each = var.secrets
  #checkov:skip=CKV2_AWS_57: This variable does not need to be rotated
  name                    = "/${var.app}/${var.environment}/Secret/${upper(each.key)}/value"
  recovery_window_in_days = 0
  kms_key_id              = var.kms.id
}

resource "aws_secretsmanager_secret_version" "ecs_secret_version" {
  for_each = var.secrets
  secret_id     = aws_secretsmanager_secret.ecs_secret[each.key].id
  secret_string = each.value
}