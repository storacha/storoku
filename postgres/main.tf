
// VPC Subnet group
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_db_subnet_group" "rds" {
  name        = "${var.environment}-${var.app}-rds-subnet-group"
  description = "Database subnet group for ${var.app}"
  subnet_ids  = var.vpc.subnet_ids.db
  tags = {
    Name = "${var.environment}-${var.app}-rds-subnet-group"
  }
}

// Security group rule to allow DB ingress

resource "aws_security_group" "rds" {
  name        = "${var.environment}-${var.app}-rds-security-group"
  description = "Ingress traffic from rds subnets"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = flatten([var.vpc.private_cidr_blocks, var.vpc.db_cidr_blocks])
  }
  
  // ingress bastion host
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Bastion"
    cidr_blocks = ["${aws_instance.database_bastion_host.private_ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Monitoring role for the DB

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.environment}-${var.app}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "managed_rds_monitoring_policy_attachement" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

locals {
  rds_endpoint = var.db_config.proxy ? split(":", aws_db_proxy.db_proxy[0].endpoint)[0] : split(":", aws_db_instance.rds.endpoint)[0]
  rds_port = var.db_config.proxy ? split(":", aws_db_proxy.db_proxy[0].endpoint)[1] : split(":", aws_db_instance.rds.endpoint)[1]
}

// Parameter group for the DB

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.environment}-${var.app}-rds-parameter-group"
  family = "postgres16"
  parameter {
    name  = "log_statement"
    value = "all"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1"
  }
  parameter {
    apply_method = "pending-reboot"
    name  = "rds.force_ssl"
    value = "1"
  }
}

// rotation schedule for the password

resource "aws_secretsmanager_secret_rotation" "rds" {

  secret_id          = aws_db_instance.rds.master_user_secret[0].secret_arn
  rotate_immediately = false

  rotation_rules {
    schedule_expression      = "rate(15 days)"
  }
}

// Encryption key for the db

resource "aws_kms_key" "encryption_rds" {
  enable_key_rotation     = true
  description             = "Key to encrypt the ${var.environment} ${var.app} database resources."
  deletion_window_in_days = 7
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias
resource "aws_kms_alias" "encryption_rds" {
  name          = "alias/${var.environment}-${var.app}-rds-kms"
  target_key_id = aws_kms_key.encryption_rds.key_id
}

data "aws_iam_policy_document" "encryption_rds_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:Create*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource"
    ]
    resources = [aws_kms_key.encryption_rds.arn]
  }
  statement {
    sid    = "Allow RDS to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = [aws_kms_key.encryption_rds.arn]
  }
  statement {
    sid    = "Allow Secrets Manager to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = [aws_kms_key.encryption_rds.arn]
  }
  statement {
    sid    = "Allow SSM to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.encryption_rds.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}
resource "aws_kms_key_policy" "encryption_rds" {
  key_id = aws_kms_key.encryption_rds.id
  policy = data.aws_iam_policy_document.encryption_rds_policy.json
}

// DB instance

resource "aws_db_instance" "rds" {
  
  allocated_storage                   = var.db_config.allocated_storage
  storage_type                        = "gp3"
  engine                              = "postgres"
  engine_version                      = "16.3"
  instance_class                      = var.db_config.instance_class
  identifier                          = "${var.environment}-${var.app}-rds-instance"
  username                            = "postgres"
  skip_final_snapshot                 = true # Change to false if you want a final snapshot
  db_subnet_group_name                = aws_db_subnet_group.rds.id
  storage_encrypted                   = true
  parameter_group_name                = aws_db_parameter_group.postgres.name
  multi_az                            = var.db_config.multi_az
  vpc_security_group_ids              = [aws_security_group.rds.id]
  iam_database_authentication_enabled = true
  #checkov: CKV_AWS_161: "Ensure RDS database has IAM authentication enabled"
  auto_minor_version_upgrade = true
  #checkov: CKV_AWS_226: "Ensure DB instance gets all minor upgrades automatically"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  #checkov: CKV_AWS_129: "Ensure that respective logs of Amazon Relational Database Service (Amazon RDS) are enabled"
  monitoring_interval = 10
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  #checkov: CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances"
  deletion_protection = true
  #checkov: CKV_AWS_293: "Ensure that AWS database instances have deletion protection enabled"
  copy_tags_to_snapshot                 = true
  manage_master_user_password           = true
  master_user_secret_kms_key_id         = aws_kms_key.encryption_rds.arn
  kms_key_id                            = aws_kms_key.encryption_rds.arn
  performance_insights_enabled          = true
  performance_insights_retention_period = var.db_config.performance_insights_retention_period
  performance_insights_kms_key_id       = aws_kms_key.encryption_rds.arn
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  apply_immediately                     = true
}

// DB Proxy (if needed)

# Setup a policy + role that allows the proxy to get RDS perms & also to
# read the secrets

data "aws_iam_policy_document" "rds_assume_role" {
  count = var.db_config.proxy ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "rds_proxy_policy_document" {
  count = var.db_config.proxy ? 1 : 0
  statement {
    sid = "AllowProxyToGetDbCredsFromSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_db_instance.rds.master_user_secret[0].secret_arn
    ]
  }

  statement {
    sid = "AllowProxyToDecryptDbCredsFromSecretsManager"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }
}

resource "aws_iam_policy" "rds_proxy_iam_policy" {
  count = var.db_config.proxy ? 1 : 0
  name   = "${var.environment}-${var.app}-rds-proxy-policy"
  policy = data.aws_iam_policy_document.rds_proxy_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "rds_proxy_iam_attach" {
  count = var.db_config.proxy ? 1 : 0
  policy_arn = aws_iam_policy.rds_proxy_iam_policy[0].arn
  role       = aws_iam_role.rds_proxy_iam_role[0].name
}

resource "aws_iam_role" "rds_proxy_iam_role" {
  count = var.db_config.proxy ? 1 : 0
  name               = "${var.environment}-${var.app}-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.rds_assume_role[0].json
}

resource "aws_db_proxy_default_target_group" "rds_proxy_target_group" {
  count = var.db_config.proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.db_proxy[0].name

  connection_pool_config {
    connection_borrow_timeout = 120
    max_connections_percent = 70
    max_idle_connections_percent = 30
  }
}

resource "aws_db_proxy_target" "rds_proxy_target" {
  count = var.db_config.proxy ? 1 : 0

  db_instance_identifier = aws_db_instance.rds.identifier
  db_proxy_name          = aws_db_proxy.db_proxy[0].name
  target_group_name      = aws_db_proxy_default_target_group.rds_proxy_target_group[0].name
}

resource "aws_db_proxy" "db_proxy" {
  count = var.db_config.proxy ? 1 : 0
  name = "${var.environment}-${var.app}-rds-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy_iam_role[0].arn
  vpc_security_group_ids = [aws_security_group.rds.id]
  vpc_subnet_ids = var.vpc.subnet_ids.db

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_db_instance.rds.master_user_secret[0].secret_arn
  }
}

// Bastion Host for console access
resource "aws_security_group" "bastion_host" {
  name        = "${var.environment}-${var.app}-bastion-host-sg"
  description = "allow ssh from public places for database access"
  vpc_id      = var.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.app} allow ssh to bastion host"
  }
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_instance" "database_bastion_host" {
  ami           = data.aws_ssm_parameter.ami.value
  instance_type          = "t4g.micro"
  key_name               = "${var.environment}-${var.app}-bastion-host-key-pair"
  subnet_id              = var.vpc.subnet_ids.public[0]
  vpc_security_group_ids = [aws_security_group.bastion_host.id]
  tags = {
    Name = "${var.environment}-${var.app}-database-bastion-host"
  }
}

resource "aws_eip" "bastion-host-eip" {
  instance = aws_instance.database_bastion_host.id
  tags = {
    Name = "${var.environment}-${var.app}-bastion-host-eip"
  }
}

resource "aws_key_pair" "bastion-host-key-pair" {
  key_name   = "${var.environment}-${var.app}-bastion-host-key-pair"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqrbMBTBIWSq2MVbCis0cFZ//fLuZzoB9TIBzloqpU7 admin@storacha.network"
}
