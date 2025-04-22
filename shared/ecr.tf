data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "ecr" {
  name                 = "${var.app}-ecr"
  image_tag_mutability = "IMMUTABLE"
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_kms_key.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_kms_key" "ecr_kms_key" {
  description             = "KMS key to encrypt ECR images "
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
# KMS key policy allowing AccountB to use the key for ECR image encryption/decryption
resource "aws_kms_alias" "ecr_key_alias" {
  name          = "alias/${var.app}-ecr-repository-key"
  target_key_id = aws_kms_key.ecr_kms_key.key_id
}

data "aws_iam_policy_document" "encryption_key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:Create*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource"
    ]
    resources = [aws_kms_key.ecr_kms_key.arn]
  }
}

resource "aws_kms_key_policy" "encryption_key" {
  key_id = aws_kms_key.ecr_kms_key.id
  policy = data.aws_iam_policy_document.encryption_key_policy.json
}
