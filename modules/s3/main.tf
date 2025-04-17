
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.environment}-${var.app}-${var.name}"
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count = var.public ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  count = var.public ? 1 : 0
  bucket = aws_s3_bucket.bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["Content-Length", "Content-Type", "Content-MD5", "ETag"]
    max_age_seconds = 86400
  }
}

resource "aws_s3_bucket_policy" "policy" {
  count = var.public ? 1 : 0
  depends_on = [ aws_s3_bucket_public_access_block.public_access_block ]
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicRead",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["s3:GetObject", "s3:GetObjectVersion"],
        "Resource" : ["${aws_s3_bucket.bucket.arn}/*"]
      }
    ]
  })
}