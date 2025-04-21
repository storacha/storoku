output "ssm_params" {
  value = {
    id = aws_ssm_parameter.rds_connection.id
    arn = aws_ssm_parameter.rds_connection.arn
  }
}

output "databases" {
  value = { 
    id = var.db_config.proxy ? aws_db_proxy.db_proxy[0].id : aws_db_instance.rds.id
    arn = var.db_config.proxy ? aws_db_proxy.db_proxy[0].arn :aws_db_instance.rds.arn
  }
}