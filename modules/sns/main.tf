resource "aws_sns_topic" "topic" {
  name = "${var.environment}-${var.app}-${var.name}"
}
