variable "app" {
  description = "The name of the application"
  type        = string
}

variable "create_db" {
  type = bool
  default = false
}

variable "db_config" {
  description = "db config"
  type = object({
    username = string
    database = string
  }) 
  default = {
    username = "default"
    database = "default"
  }
}

variable "caches" {
  description = "elasticache caches to create"
  type = set(string)
  default = []
}