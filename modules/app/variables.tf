variable "environment" {
  description = "The environment we are deploying to (your name, dev, prod, staging)"
  type        = string
}

variable "app" {
  description = "The name of the application"
  type        = string
}

variable "appState" {
  description = "folder for application state"
  type        = string
}

variable "allowed_account_ids" {
  description = "account ids used for AWS"
  type = list(string)
  default = ["505595374361"]
}

variable "private_key" {
  description = "private_key for the peer for this deployment"
  type = string
}

variable "did" {
  description = "DID for this deployment (did:web:... for example)"
  type = string
}

variable "principal_mapping" {
  type        = string
  description = "JSON encoded mapping of did:web to did:key"
  default     = ""
}

variable "caches" {
  description = "elasticache caches to create"
  type = set(string)
  default = []
}

variable "databases" {
  description = "dbs to create"
  type = set(string)
  default = []
}

variable "buckets" {
  description = "s3 buckets to create"
  type = list(object({
    name = string
    public = optional(bool, false)
  }))
  default = []
}

variable "queues" {
  description = "sqs queues to create"
  type = list(object({
    name = string
    fifo = optional(bool, false)
  }))
  default = []
}

variable "tables" {
  description = "dynamodb tables to create"
  type = list(object({
    name = string
    attributes = list(object({
      name = string
      type = string
    }))
    hash_key = string
    range_key = optional(string)
  }))
  default = []
}

variable "topics" {
  description = "sns topics to create"
  type = set(string)
  default = []
}


variable "deployment_config" {
  type = object({
    cpu = number
    memory = number
    service_min = number
    service_max = number
  })
  default = null
}

variable "image_tag" {
  type = string
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "deployment_env_vars" {
  type = list(object({
    name      = string
    value     = string
  }))
  default = []
}

variable "healthcheck" {
  type = bool
  default = false
}