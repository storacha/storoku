variable "app" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment the caches will belong to"
  type        = string
}

variable "env_files" {
  description = "list of environment variable files to upload"
  type = list(string)
}