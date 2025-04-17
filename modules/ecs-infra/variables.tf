variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the cluster will belong to"
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
  description = "The VPC to deploy the cluster in"
  type        = object({
    id         = string
    subnet_ids = object({
      public      = list(string)
      private     = list(string)
      db          = list(string)
      elasticache = list(string)
    })
  })
}

variable "domain" {
  description = "Domain information"
  type = object({
    zone_id = string
    name = string
  })
}

variable "cert_arn" {
  description = "arn for cert to use with HTTPS listener"
  type = string
}