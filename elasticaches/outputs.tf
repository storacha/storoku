output "caches" {
  value = {
    for cache in var.caches : cache => {
    id      = aws_elasticache_replication_group.cache[cache].id
    arn     = aws_elasticache_replication_group.cache[cache].arn
    address = aws_elasticache_replication_group.cache[cache].configuration_endpoint_address
    port    = aws_elasticache_replication_group.cache[cache].port
    }
  }
}

output "iam_user" {
  value = {
    arn     = aws_elasticache_user.cache_iam_user.arn
    user_id = aws_elasticache_user.cache_iam_user.user_id
  }
}

output "security_group_id" {
  value = aws_security_group.cache_security_group.id
}
