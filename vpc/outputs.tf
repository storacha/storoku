output "id" {
  value = aws_vpc.vpc.id
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "private_cidr_blocks" {
  value = aws_subnet.vpc_private_subnet[*].cidr_block
}

output "db_cidr_blocks" {
  value = aws_subnet.vpc_db_subnet[*].cidr_block
}

output "elasticache_cidr_blocks" {
  value = aws_subnet.vpc_elasticache_subnet[*].cidr_block
}


output "subnet_ids" {
  value = {
      private = aws_subnet.vpc_private_subnet[*].id
      public  = aws_subnet.vpc_public_subnet[*].id
      db = aws_subnet.vpc_db_subnet[*].id 
      elasticache = aws_subnet.vpc_elasticache_subnet[*].id
    }
}
