
resource "aws_cloudwatch_log_group" "logs" {
  name              = "${var.environment}-${var.app}-ecs-cluster-log"
  retention_in_days = var.is_production ? 365 : 14
  kms_key_id        = aws_kms_key.encryption_cloudwatch.arn
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

// KMS 
resource "aws_kms_key" "encryption_cloudwatch" {
  enable_key_rotation     = true
  description             = "Key to encrypt the ${var.app} cloudwatch resources."
  deletion_window_in_days = 7
  tags = {
    Name = "${var.environment}-${var.app}-cloudwatch-kms-key"
  }
}

resource "aws_kms_alias" "encryption_cloudwatch" {
  name          = "alias/${var.environment}-${var.app}-cloudwatch-kms"
  target_key_id = aws_kms_key.encryption_cloudwatch.key_id
}

data "aws_iam_policy_document" "encryption_cloudwatch_policy" {
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
    resources = [aws_kms_key.encryption_cloudwatch.arn]
  }
  statement {
    sid    = "Allow Secrets Manager to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = [aws_kms_key.encryption_cloudwatch.arn]
  }
  statement {
    sid    = "Allow SSM to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.encryption_cloudwatch.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
  statement      {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    actions = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
    ]
    resources = [aws_kms_key.encryption_cloudwatch.arn]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.environment}-${var.app}-ecs-cluster-log"]
      }
  }
}

resource "aws_kms_key_policy" "encryption_key" {
  key_id = aws_kms_key.encryption_cloudwatch.id
  policy = data.aws_iam_policy_document.encryption_cloudwatch_policy.json
}
