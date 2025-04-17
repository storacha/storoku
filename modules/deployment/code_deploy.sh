#!/bin/bash
set -e

echo "Starting CodeDeploy agent deployment"
aws --version

echo "Constructing deployment command..."
COMMAND=$(cat <<EOT
aws deploy create-deployment \
    --application-name "hannah-httptest-code-deploy-app" \
    --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
    --deployment-group-name "hannah-httptest-code-deploy-deployment-group" \
    --revision '{"revisionType": "AppSpecContent", "appSpecContent": {"content": "{\"Resources\":[{\"TargetService\":{\"Properties\":{\"LoadBalancerInfo\":{\"ContainerName\":\"first\",\"ContainerPort\":8080},\"TaskDefinition\":\"arn:aws:ecs:us-west-2:505595374361:task-definition/hannah-httptest:1\"},\"Type\":\"AWS::ECS::Service\"}}],\"version\":\"0.0\"}", "sha256":"dc251226068a238567b1b683689df6bc0b821d9a0781e712f4138aafe80315f2"}}' \
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
