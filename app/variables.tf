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

variable "private_key_env_var" {
  description = "env var set on the machine for the did private key"
  type = string
  default = "PRIVATE_KEY"
}

variable "did" {
  description = "DID for this deployment (did:web:... for example)"
  type = string
}

variable "did_env_var" {
  description = "env var set on the machine for the did public key"
  type = string
  default = "DID"
}

variable "principal_mapping" {
  type        = string
  description = "JSON encoded mapping of did:web to did:key"
  default     = ""
}

variable "principal_mapping_env_var" {
  description = "env var set on the machine for mapping did:web to did:key"
  type = string
  default = "PRINCIPAL_MAPPING"
}

variable "caches" {
  description = "elasticache caches to create"
  type = set(string)
  default = []
}

variable "create_db" {
  type = bool
  default = false
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
  type = map(string)
  default = {}
}

variable "deployment_env_vars" {
  description = "list of environment variables to upload and use in the container definition (NO SENSITIVE DATA)"
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

variable "httpport" {
  type = number
  default = 8080
}

variable "env_files" {
  description = "list of environment variable files to upload and use in the container definition (NO SENSITIVE DATA)"
  type = list(string)
  default = []
}