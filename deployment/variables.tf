variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "kms" {
  description = "id of a KMS key used to encrypt"
  type = object({
    id = string
    arn = string
  })
}

variable "vpc" {
  description = "The VPC to deploy the db in"
  type        = object({
    id                 = string
    cidr_block         = string
    subnet_ids = object({
      public      = list(string)
      private     = list(string)
      db          = list(string)
      elasticache = list(string)
    })
  })
}

variable "lb_blue_target_group" {
  type = object({
    name = string
    arn = string
  })
}
variable "lb_green_target_group" {
  type = object({
    name = string
    arn = string
  })
}

variable "lb_listener" {
  type = object({
    arn = string
  })
}

variable "lb" {
  type = object({
    arn = string
  })
}

variable "lb_security_group" {
  type = object({
    id = string
  })
}


variable "ecs_cluster" {
  type = object({
    name = string
    id = string
  })
}

variable "aws_cloudwatch_log_group" {
  type = object({
    name = string
    arn = string
  })
}

variable "config" {
  type = object({
    cpu = number
    memory = number
    service_min = number
    service_max = number
    httpport = number
  })
}

variable "image_tag" {
  type = string
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "env_vars" {
  type = list(object({
    name      = string
    value     = string
  }))
  default = []
}

variable "env_files" {
  type = object({
    bucket_arn = string
    object_arns = list(string)
  })
}

variable "healthcheck" {
  type = bool
  default = false
}

variable "caches" {
  type = map(object({
    id      = string
    arn     = string
    address = string
    port    = number
  }))
}

variable "buckets" {
  type = map(object({
    arn = string
    bucket = string
  }))
}

variable "tables" {
  type = map( object({
    id = string
    arn = string
  }))
}


variable "topics" {
  type = map(object({
    id = string
    arn = string
  }))
}

variable "queues" {
  type = map(object({
    id = string
    arn = string
  }))
}

variable "create_db" {
  type = bool
  default = false
}

variable "database" {
  type = object({
    id = string
    arn = string
    address = string
    port = string
  })
  default = {
    id = ""
    arn = ""
    address = ""
    port = ""
  }
}

variable "db_config" {
  description = "db config"
  type = object({
    username = string
    database = string
  }) 
}