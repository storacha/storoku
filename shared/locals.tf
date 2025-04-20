locals {
  vpc = {
    id = module.dev_vpc[0].id
    cidr_block = module.dev_vpc[0].cidr_block
    subnet_ids = module.dev_vpc[0].subnet_ids
  }
}