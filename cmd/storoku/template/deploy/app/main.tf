terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
  backend "s3" {
    bucket = "storacha-terraform-state"
    key = "storacha/${var.app}/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}

provider "aws" {
  allowed_account_ids = [var.allowed_account_id]
  region = var.region
  default_tags {
    
    tags = {
      "Environment" = terraform.workspace
      "ManagedBy"   = "OpenTofu"
      Owner         = "storacha"
      Team          = "Storacha Engineering"
      Organization  = "Storacha"
      Project       = "${var.app}"
    }
  }
}

# CloudFront is a global service. Certs must be created in us-east-1, where the core ACM infra lives
provider "aws" {
  region = "us-east-1"
  alias = "acm"
}

{{range .Secrets}}{{if .Variable}}{{else}}
resource "random_password" "{{.Lower}}" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
{{end}}{{end}}

module "app" {
  source = "github.com/storacha/storoku//app?ref={{.Version}}"
  private_key = var.private_key{{if .PrivateKeyEnvVar}}
  private_key_env_var = "{{ .PrivateKeyEnvVar }}"{{end}}{{if .Port}}
  httpport = {{ .Port }}{{end}}
  principal_mapping = var.principal_mapping
  did = var.did{{if .DIDEnvVar}}
  did_env_var = "{{.DIDEnvVar}}"{{end}}
  app = var.app
  appState = var.app
  write_to_container = {{.WriteToContainer}}
  environment = terraform.workspace
  network = var.network
  # if there are any env vars you want available only to your container
  # in the vpc as opposed to set in the dockerfile, enter them here
  # NOTE: do not put sensitive data in env-vars. use secrets
  deployment_env_vars = []
  image_tag = var.image_tag
  create_db = {{ .CreateDB }}
  # enter secret values your app will use here -- these will be available
  # as env vars in the container at runtime
  secrets = { {{range .Secrets }}
    "{{.Upper}}" = {{if .Variable}}var.{{.Lower}}{{else}}random_password.{{.Lower}}.result{{end}}{{end}}
  }
  # enter any sqs queues you want to create here
  queues = [{{range .Queues}}
    {
      name = "{{ .Name }}"
      fifo = {{ .Fifo }}
      message_retention_seconds = {{ .MessageRetentionSeconds }}
    },
  {{end}}]
  caches = [{{range .Caches}}"{{.}}",{{end}}]
  topics = [{{range .Topics}}"{{.}}",{{end}}]
  tables = [{{range .Tables}}
    {
      name = "{{.Name}}"
      attributes = [{{range .Attributes}}
        {
          name = "{{.Name}}"
          type = "{{.Type}}"
        },{{end}}
      ]
      hash_key = "{{.HashKey}}"{{if .RangeKey }}
      range_key ="{{.RangeKey}}"{{end}}
    },{{end}}
  ]
  buckets = [{{range .Buckets}}
    {
      name = "{{ .Name }}"
      public = {{ .Public }}
    },
  {{end}}]
  providers = {
    aws = aws
    aws.acm = aws.acm
  }
  env_files = var.env_files
  domain_base = var.domain_base
}