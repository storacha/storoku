output "ssm_params" {
  value = { for instance in var.instances : instance => {
    id = aws_ssm_parameter.rds_connection[instance].id
    arn = aws_ssm_parameter.rds_connection[instance].arn
  }}
}

output "databases" {
  value = { for instance in var.instances : instance => {
    id = var.db_config.proxy ? aws_db_proxy.db_proxy[instance].id : aws_db_instance.rds[instance].id
    arn = var.db_config.proxy ? aws_db_proxy.db_proxy[instance].arn :aws_db_instance.rds[instance].arn
  }}
}