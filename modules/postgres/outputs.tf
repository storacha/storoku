output "connection" {
  value = [ for instance in var.instances : {
    id = aws_ssm_parameter.rds_connection[instance].id
    arn = aws_ssm_parameter.rds_connection[instance].arn
  }]
}