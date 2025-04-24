variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the VPC will belong to"
  type        = string
}

variable "db_config" {
  description = "parameters for the db instance"
  type        = object({
    allocated_storage = number
    instance_class = string
    multi_az = bool
    proxy = bool
    proxy_user = string
    performance_insights_retention_period = number
  })
}

variable "vpc" {
  description = "The VPC to deploy the db in"
  type        = object({
    id                 = string
    cidr_block         = string
    private_cidr_blocks = list(string)
    db_cidr_blocks = list(string)
    subnet_ids = object({
      public      = list(string)
      private     = list(string)
      db          = list(string)
      elasticache = list(string)
    })
  })
}
