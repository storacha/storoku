module "tables" {
  for_each = { for table in var.tables : table.name => table }

  source = "../dynamodb"
  environment =  var.environment
  app = var.app
  name = each.key
  is_production = local.is_production
  attributes = each.value.attributes
  hash_key = each.value.hash_key
  range_key = each.value.range_key
}