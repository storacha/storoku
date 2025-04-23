locals {
  secret_name_with_postfix = element(split(":", var.db_config.secret_arn), length(split(":", var.db_config.secret_arn)) - 1)
  segments                 = split("-", local.secret_name_with_postfix)
  master_user_secret_name  = join("-", slice(local.segments, 0, length(local.segments) - 1))
}

module "provisoner_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 5.0"

  function_name = "${var.environment}-${var.app}-db-provisioner"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  source_path = "${path.module}/lambda"

  cloudwatch_logs_retention_in_days       = 30
  create_current_version_allowed_triggers = false

  vpc_subnet_ids         = var.vpc.subnet_ids.private
  vpc_security_group_ids = [aws_security_group.lambda.id]

  role_name = "${var.environment}-${var.app}-db-provisioner-execution-role"

  attach_policies    = true
  number_of_policies = 3

  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    var.db_config.access_policy_arn
  ]

  environment_variables = {
    RDS_HOST                      = var.db_config.address
    RDS_PORT                      = var.db_config.port
    DB_USERNAME                   = var.db_config.app_username
    DB_DATABASE                   = var.db_config.app_database
    CREATE_DATABASE               = true
    DB_MASTER_SECRET_MANAGER_NAME = local.master_user_secret_name
  }

  layers = [
    data.aws_lambda_layer_version.psycopg2_lambda_layer.arn
  ]
}

data "aws_lambda_layer_version" "psycopg2_lambda_layer" {
  layer_name = "psycopg2"

  depends_on = [aws_lambda_layer_version.psycopg2_lambda_layer]
}

# tflint-ignore: terraform_unused_declarations
data "aws_lambda_invocation" "default" {
  
  depends_on = [
    module.provisoner_lambda
  ]

  function_name = module.provisoner_lambda.lambda_function_name
  input         = ""
}

resource "aws_lambda_layer_version" "psycopg2_lambda_layer" {
  layer_name  = "psycopg2"
  description = "A layer to enable psycopg2 for python3.12"

  filename                 = "${path.module}/lambda_layers/psycopg2-layer.zip"
  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]
}

resource "aws_security_group" "lambda" {
  name        = "${var.environment}-${var.app}-lambda-provisioner-security-group"
  description = "Egress traffic to db"
  vpc_id      = var.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}