output "database" {
  value = { 
    id = var.db_config.proxy ? aws_db_proxy.db_proxy[0].id : aws_db_instance.rds.id
    arn = var.db_config.proxy ? aws_db_proxy.db_proxy[0].arn :aws_db_instance.rds.arn
    access_policy_arn = aws_iam_policy.rds_access_iam_policy.arn
    secret_arn = aws_db_instance.rds.master_user_secret[0].secret_arn
    proxy_user_secret_arn = var.db_config.proxy ? aws_secretsmanager_secret.proxy_user_secret[0].arn : null
    address = local.rds_endpoint
    instance_address = split(":", aws_db_instance.rds.endpoint)[0]
    port = local.rds_port
  }
}