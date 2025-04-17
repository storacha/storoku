output "db" {
  value = aws_db_instance.rds
}

output "connection" {
  value = aws_ssm_parameter.rds_connection
}