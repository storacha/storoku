output "database" {
  value = { 
    id = var.db_config.proxy ? aws_db_proxy.db_proxy[0].id : aws_db_instance.rds.id
    arn = var.db_config.proxy ? aws_db_proxy.db_proxy[0].arn :aws_db_instance.rds.arn
    address = local.rds_endpoint
    port = local.rds_port
  }
}