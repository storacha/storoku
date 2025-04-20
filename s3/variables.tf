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

