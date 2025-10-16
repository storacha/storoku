module "queues" {
  for_each                  = { for queue in var.queues : queue.name => queue }
  source                    = "../sqs"
  app                       = var.app
  environment               = var.environment
  name                      = each.key
  fifo                      = each.value.fifo
  high_throughput           = each.value.high_throughput
  message_retention_seconds = each.value.message_retention_seconds
}
