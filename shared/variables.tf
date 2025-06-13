variable "app" {
  description = "The name of the application"
  type        = string
}

variable "networks" {
  description = "List of networks to create (a default, 'hot' network is always created)"
  type        = list(string)
  default     = []
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

variable "caches" {
  description = "elasticache caches to create"
  type = set(string)
  default = []
}

variable "zone_id" {
  description = "cloudflare zone id for NS records"
  type = string
}