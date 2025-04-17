variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "name" {
  description = "base name of the queue"
  type        = string
}

variable "fifo" {
  description = "is this a fifo queue"
  type        = bool
  default = false
}
