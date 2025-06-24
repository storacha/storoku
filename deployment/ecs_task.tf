data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-${var.app}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.config.cpu
  memory                   = var.config.memory
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name                   = "first"
      image                  = var.image_tag
      cpu                   = var.config.cpu
      memory                 = var.config.memory
      essential              = true
      readonlyRootFilesystem = var.config.readonly
      portMappings = [
        {
          containerPort = var.config.httpport
          hostPort      = var.config.httpport
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.aws_cloudwatch_log_group.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = var.healthcheck ? {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.config.httpport}/healthcheck>> /proc/1/fd/1 2>&1 || exit 1"]
        interval    = 30
        retries     = 3
        timeout     = 5
        startPeriod = 10
      } : null
      environment = concat(var.env_vars,
        [{
            name = "PUBLIC_URL"
            value = var.public_url
        }],
        [for key, cache in var.caches : {
          name = "${upper(key)}_CACHE_ID"
          value = cache.id
        }],
        [for key, cache in var.caches : {
          name = "${upper(key)}_CACHE_URL"
          value = "${cache.address}:${cache.port}"
        }],
        length(var.caches) > 0 ? [
          {
            name = "CACHE_USER_ID"
            value = var.cache_user_id
          }
        ] : [],
        var.create_db ? [
          {
            name = "PGHOST"
            value = var.database.address
          },
          {
            name = "PGPORT"
            value = var.database.port
          },
          {
            name = "PGDATABASE"
            value = var.db_config.database
          },
          {
            name = "PGUSERNAME"
            value = var.db_config.username
          },
          {
            name = "PG_RDS_IAM_AUTH"
            value = "true"
          },
          {
            name = "PGSSLMODE"
            value = "require"
          }
        ] : [],
        [ for key, bucket in var.buckets : {
          name = "${upper(key)}_BUCKET_NAME"
          value = bucket.bucket
        }],
        [ for key, bucket in var.buckets : {
          name = "${upper(key)}_BUCKET_REGIONAL_DOMAIN"
          value = bucket.regional_domain_name
        }],
        [ for key, queue in var.queues : {
          name = "${upper(key)}_QUEUE_ID"
          value = queue.id
        }],
        [ for key, table in var.tables : {
          name = "${upper(key)}_TABLE_ID"
          value = table.id
        }],
        [ for key, topic in var.topics : {
          name = "${upper(key)}_TOPIC_ID"
          value = topic.id
        }]
      ),
      environmentFiles = [ for object_arn in var.env_files.object_arns : { "value": object_arn, "type": "s3" }]
      secrets = var.secrets
    }
  ])
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-${var.app}-task-role"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          },
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-${var.app}-task-execution-role"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_s3_put_get_document" {
  count = length(var.env_files.object_arns) > 0 ? 1 : 0

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [ "${var.env_files.bucket_arn}/*" ]
  }
  statement {
    actions = [
      "s3:ListBucket","s3:GetBucketLocation"
    ]
    resources = [ var.env_files.bucket_arn ]
  }
}

resource "aws_iam_policy" "task_execution_s3_put_get" {
  count = length(var.env_files.object_arns) > 0 ? 1 : 0

  name        = "${terraform.workspace}-${var.app}-task-execution-s3-put-get"
  description = "This policy will be used by the task executor to put and get objects from S3"
  policy      = data.aws_iam_policy_document.task_execution_s3_put_get_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_execution_s3_put_get" {
  count = length(var.env_files.object_arns) > 0 ? 1 : 0

  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_s3_put_get[0].arn
}


resource "aws_iam_policy" "secrets_manager_read_policy" {
  name        = "${var.environment}-${var.app}-ecs-fargate-secrets-manager-access"
  description = "IAM policy for ECS Fargate to access Secrets Manager secrets and decrypt it."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets[*].valueFrom
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ]
        Resource = [var.kms.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_read_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_secrets_read_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}

data "aws_iam_policy_document" "task_elasticache_connect_document" {
  count = length(var.caches) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "elasticache:Connect"
    ]

    resources = [for cache in var.caches : cache.arn]
  }
}

resource "aws_iam_policy" "task_elasticache_connect" {
  count = length(var.caches) > 0 ? 1 : 0

  name   = "${terraform.workspace}-${var.app}-task-elasticache-connect"
  policy = data.aws_iam_policy_document.task_elasticache_connect_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_elasticache_connect" {
  count = length(var.caches) > 0 ? 1 : 0

  policy_arn = aws_iam_policy.task_elasticache_connect[0].arn
  role       = aws_iam_role.ecs_task_role.name
}


data "aws_iam_policy_document" "task_dynamodb_put_get_document" {
  count = length(var.tables) > 0 ? 1 : 0

  statement {
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]
    resources = [for k, table in var.tables : table.arn]
  }
}

resource "aws_iam_policy" "task_dynamodb_put_get" {
  count = length(var.tables) > 0 ? 1 : 0

  name        = "${terraform.workspace}-${var.app}-task-dynamodb-put-get"
  description = "This policy will be used by the task to put and get data from DynamoDB"
  policy      = data.aws_iam_policy_document.task_dynamodb_put_get_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_dynamodb_put_get" {
  count = length(var.tables) > 0 ? 1 : 0

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_dynamodb_put_get[0].arn
}


data "aws_iam_policy_document" "task_s3_put_get_document" {
  count = length(var.buckets) > 0 ? 1 : 0

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [ for k, bucket in var.buckets: "${bucket.arn}/*" ]
  }
  statement {
    actions = [
      "s3:ListBucket","s3:GetBucketLocation"
    ]
    resources = [ for k, bucket in var.buckets: bucket.arn ]
  }
}

resource "aws_iam_policy" "task_s3_put_get" {
  count = length(var.buckets) > 0 ? 1 : 0

  name        = "${terraform.workspace}-${var.app}-task-s3-put-get"
  description = "This policy will be used by the task to put and get objects from S3"
  policy      = data.aws_iam_policy_document.task_s3_put_get_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_s3_put_get" {
  count = length(var.buckets) > 0 ? 1 : 0

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_s3_put_get[0].arn
}

data "aws_arn" "rds_arn" {
  count = var.create_db ? 1 : 0
  arn = var.database.arn
}

data "aws_iam_policy_document" "task_rds_connect_document" {
  count = var.create_db ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]

    resources = [
      "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${var.database.address == var.database.instance_address ? var.database.id : split(":", data.aws_arn.rds_arn[0].resource)[1]}/${var.db_config.username}"
    ]
  }
}

resource "aws_iam_policy" "task_rds_connect" {
  count = var.create_db ? 1 : 0

  name   = "${var.environment}-${var.app}-task-rds-connect"
  policy = data.aws_iam_policy_document.task_rds_connect_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_rds_connect_attach" {
  count = var.create_db ? 1 : 0
  policy_arn = aws_iam_policy.task_rds_connect[0].arn
  role       = aws_iam_role.ecs_task_role.name
}

data "aws_iam_policy_document" "task_sns_document" {
  count = length(var.topics) > 0 ? 1 : 0

  statement {
    actions = [
      "sns:Publish"
    ]
    resources = [
      for k, topic in var.topics : topic.arn
    ]
  }
}

resource "aws_iam_policy" "task_sns" {
  count = length(var.topics) > 0 ? 1 : 0

  name        = "${terraform.workspace}-${var.app}-task-sns"
  description = "This policy will be used by the task to push to sns"
  policy      = data.aws_iam_policy_document.task_sns_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_sns" {
  count = length(var.topics) > 0 ? 1 : 0

  role       = aws_iam_role.ecs_task_role.arn
  policy_arn = aws_iam_policy.task_sns[0].arn
}

data "aws_iam_policy_document" "task_sqs_document" {
  count = length(var.queues) > 0 ? 1 : 0
  statement {
  
    effect = "Allow"
  
    actions = [
      "sqs:SendMessage*",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [for k, queue in var.queues : queue.arn]
  }
}

resource "aws_iam_policy" "task_sqs" {
  count = length(var.queues) > 0 ? 1 : 0

  name        = "${terraform.workspace}-${var.app}-task-sqs"
  description = "This policy will be used by the task to send messages to an SQS queue"
  policy      = data.aws_iam_policy_document.task_sqs_document[0].json
}

resource "aws_iam_role_policy_attachment" "task_sqs" {
  count = length(var.queues) > 0 ? 1 : 0

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_sqs[0].arn
}
