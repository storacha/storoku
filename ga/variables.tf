variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "target_arn" {
  description = "ARN of the target the global accelerator will point to (ALB for example)"
  type        = string
}
