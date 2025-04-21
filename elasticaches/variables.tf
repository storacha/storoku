variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "node_type" {
  description = "The type of nodes to use for the cache"
  type        = string
}

variable "vpc" {
  description = "The VPC to deploy the caches in"
  type        = object({
    id                 = string
    cidr_block         = string
    private_cidr_blocks = list(string)
    elasticache_cidr_blocks = list(string)
    subnet_ids = object({
      public      = list(string)
      private     = list(string)
      db          = list(string)
      elasticache = list(string)
    })
  })
}

variable "caches" {
  description = "valkey caches to create"
  type= set(string)
}