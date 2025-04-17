variable "app" {
  description = "The name of the application"
  type        = string
}

variable "databases" {
  description = "dbs to create"
  type = set(string)
  default = []
}

variable "caches" {
  description = "elasticache caches to create"
  type = set(string)
  default = []
}