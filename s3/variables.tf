variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "name" {
  description = "base name of the bucket"
  type        = string
}

variable "public" {
  description = "configure this bucket for public reads"
  type        = bool
  default = false
}

variable "object_expiration_days" {
  description = "Number of days after which objects will expire. Set to 0 to disable expiration."
  type        = number
  default     = 0

  validation {
    condition     = var.object_expiration_days >= 0 && var.object_expiration_days <= 2147483647
    error_message = "The object_expiration_days value must be between 0 and 2147483647 (inclusive)."
  }
}
