resource "aws_ecr_repository" "ecr" {
  name                 = "${var.environment}-${var.app}-ecr"
  image_tag_mutability = "IMMUTABLE"
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}