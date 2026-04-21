#!/bin/bash
set -e

STACK_NAME=${1:-"security-agent-stack"}
TEMPLATE_FILE="template.yaml"
PARAMETERS_FILE="parameters.json"

if [ ! -f "$PARAMETERS_FILE" ]; then
    echo "Error: $PARAMETERS_FILE not found."
    echo "Please create it from parameters.json.example"
    exit 1
fi

echo "Deploying CloudFormation stack: $STACK_NAME..."

aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameter-overrides $(jq -r '.[] | [.ParameterKey, .ParameterValue] | join("=")' "$PARAMETERS_FILE") \
    --capabilities CAPABILITY_NAMED_IAM

echo "Deployment complete."
