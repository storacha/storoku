
resource "aws_s3_bucket" "env_file_bucket" {
  count = length(var.env_files) > 0 ? 1 : 0
  bucket = "${var.environment}-${var.app}-ecs-env-file-bucket"
}

resource "aws_s3_object" "env_file" {
  for_each = { for env_file in var.env_files : basename(env_file) => env_file}
  bucket = aws_s3_bucket.env_file_bucket[0].id
  key = "${var.environment}-${var.app}-${each.key}.env"
  source = each.value
  etag = filemd5(each.value)
}

