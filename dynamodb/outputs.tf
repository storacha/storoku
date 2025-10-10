output "id" {
  value = aws_dynamodb_table.table.id
}
output "arn" {
  value = aws_dynamodb_table.table.arn
}
output "global_secondary_indexes" {
  value = var.global_secondary_indexes
}
output "local_secondary_indexes" {
  value = var.local_secondary_indexes
}
