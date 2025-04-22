
locals {
  # appspec file
  appspec = {
    version = "0.0"
    Resources = [
      {
        TargetService = {
          Type = "AWS::ECS::Service"
          Properties = {
            TaskDefinition = aws_ecs_task_definition.app.arn
            LoadBalancerInfo = {
              ContainerName = "first"
              ContainerPort = var.config.httpport
            }
          }
        }
      }
    ]
  }

  appspec_content = replace(jsonencode(local.appspec), "\"", "\\\"")
  appspec_sha256  = sha256(jsonencode(local.appspec))

  # create deployment script
  script = <<EOF
#!/bin/bash
set -e

echo "Starting CodeDeploy agent deployment"
aws --version

echo "Constructing deployment command..."
COMMAND=$(cat <<EOT
aws deploy create-deployment \
    --application-name "${aws_codedeploy_app.app.name}" \
    --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
    --deployment-group-name "${aws_codedeploy_deployment_group.deployment_group.deployment_group_name}" \
    --revision '{"revisionType": "AppSpecContent", "appSpecContent": {"content": "${local.appspec_content}", "sha256":"${local.appspec_sha256}"}}' \
    --description "Deployment from Terraform" \
    --output json
EOT
)

echo "Command to be executed:"
echo "$COMMAND"

echo "Executing deployment command..."
DEPLOYMENT_INFO=$(eval "$COMMAND")
COMMAND_EXIT_CODE=$?

echo "Command exit code: $COMMAND_EXIT_CODE"
echo "Raw output:"
echo "$DEPLOYMENT_INFO"

if [ $COMMAND_EXIT_CODE -ne 0 ]; then
    echo "Error: AWS CLI command failed"
    exit $COMMAND_EXIT_CODE
fi

echo "Parsing deployment info..."
if ! DEPLOYMENT_ID=$(echo "$DEPLOYMENT_INFO" | jq -r '.deploymentId'); then
    echo "Error: Failed to parse deployment ID from output"
    exit 1
fi

if [ "$DEPLOYMENT_ID" == "null" ] || [ -z "$DEPLOYMENT_ID" ]; then
    echo "Error: Deployment ID is null or empty"
    exit 1
fi

echo "Deployment ID: $DEPLOYMENT_ID"

echo "Deployment created successfully"
EOF
}

resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.environment}-${var.app}-code-deploy-app"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group
resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.environment}-${var.app}-code-deploy-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }
  ecs_service {
    cluster_name = var.ecs_cluster.name
    service_name = aws_ecs_service.service.name
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.lb_listener.arn]
      }
      target_group {
        name = var.lb_blue_target_group.name
      }
      target_group {
        name = var.lb_green_target_group.name
      }
    }
  }
  lifecycle {
    ignore_changes = [blue_green_deployment_config]
  }
}
resource "aws_iam_role" "codedeploy_role" {
  name             = "${var.environment}-${var.app}-code-deploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachement" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}



#Create the code_deploy.sh file to run the AWS CodeDeploy deployment
#https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "code_deploy_sh" {
  content         = local.script
  filename        = "${path.root}/code_deploy.sh"
  file_permission = "0755"
  depends_on = [
    aws_codedeploy_app.app,
    aws_codedeploy_deployment_group.deployment_group,
    aws_ecs_task_definition.app
  ]
}

#https://developer.hashicorp.com/terraform/language/resources/terraform-data
resource "terraform_data" "trigger_code_deploy_deployment" {
  triggers_replace = local_file.code_deploy_sh
  provisioner "local-exec" {
    command     = "./code_deploy.sh"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [local_file.code_deploy_sh]
  lifecycle {
    replace_triggered_by = [local_file.code_deploy_sh]
  }
}