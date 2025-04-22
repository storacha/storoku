variable "environment" {
  description = "The environment we are deploying to (your name, dev, prod, staging)"
  type        = string
}

variable "app" {
  description = "The name of the application"
  type        = string
}

variable "kms" {
  description = "id of a KMS key used to encrypt"
  type = object({
    id = string
    arn = string
  })
}

variable "secrets" {
  description = "secrets to create"
  type = map(string)
  default = {}
}