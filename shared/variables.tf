variable "app" {
  description = "The name of the application"
  type        = string
}

variable "domain_base" {
  description = "base domain after the application"
  type        = string
  default = ""
}

variable "setup_cloudflare" {
  description = "setup DNS records on cloudflare"
  type        = bool
  default =  true
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

variable "zone_id" {
  description = "cloudflare zone id for NS records"
  type = string
}