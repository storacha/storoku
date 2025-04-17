variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the VPC will belong to"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR used in the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_db_net" {
  description = "create a private subnet for a database"
  type = bool
  default = true
}

variable "create_elasticache_net" {
  description = "create a private subnet for elasticache"
  type = bool
  default = false
}
