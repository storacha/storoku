resource "aws_dynamodb_table" "table" {
  name         = "${var.environment}-${var.app}-${var.name}"
  billing_mode = "PAY_PER_REQUEST"

  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  hash_key  = var.hash_key
  range_key = var.range_key

  tags = {
    Name = "${var.environment}-${var.app}-${var.name}"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod"
  }

  deletion_protection_enabled = var.environment == "prod"
}