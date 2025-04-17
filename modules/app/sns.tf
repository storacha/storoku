module "topics" {
  for_each = var.topics
  source = "../sns"
  app = var.app
  environment = var.environment
  name = each.key
}