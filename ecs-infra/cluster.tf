resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-${var.app}-cluster"
  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"
      kms_key_id = aws_kms_key.encryption_cloudwatch.id
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.logs.name
      }
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}