output "bucket_id" {
  value = length(var.env_files) > 0 ? aws_s3_bucket.env_file_bucket[0].id : ""
}

output "bucket_arn" {
  value = length(var.env_files) > 0 ? aws_s3_bucket.env_file_bucket[0].arn : ""  
}

output "object_arns" {
  value = [for env_file in var.env_files : aws_s3_object.env_file[basename(env_file)].arn]
}