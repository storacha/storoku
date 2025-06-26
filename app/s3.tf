module "buckets" {
  for_each = { for bucket in var.buckets : bucket.name => bucket }
  source = "../s3"
  app = var.app
  environment = var.environment
  name = each.key
  public = each.value.public
  object_expiration_days = each.value.object_expiration_days
}
