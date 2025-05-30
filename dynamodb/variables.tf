variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "name" {
  description = "base name of the table"
  type        = string
}

variable "is_production" {
  description = "Indicates whether production-grade features should be enabled"
  type        = bool
}

variable "attributes" {
  description = "List of nested attribute definitions. Only required for hash_key and range_key attributes. Each attribute has two properties: name - (Required) The name of the attribute, type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data"
  type        = list(object({
    name = string
    type = string
  }))
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key. Must also be defined as an attribute"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key. Must also be defined as an attribute"
  type        = string
  default     = null
}
