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
  default     = false
}

variable "high_throughput" {
  description = "Enable high throughput mode for FIFO queues"
  type        = bool
  default     = false
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days)."
  type        = number
  default     = 0

  validation {
    condition     = var.message_retention_seconds == 0 || (var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600)
    error_message = "The message_retention_seconds value must be between 60 and 1209600 seconds (14 days), or 0 to use the default (345600 seconds/4 days)."
  }
}
