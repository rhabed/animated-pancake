#!/bin/bash
set -e

STACK_NAME=${1:-"security-agent-stack"}
TEMPLATE_FILE="template.yaml"
PARAMETERS_FILE="parameters.json"

if [ ! -f "$PARAMETERS_FILE" ]; then
    echo "Error: $PARAMETERS_FILE not found."
    exit 1
fi

echo "Updating CloudFormation stack: $STACK_NAME..."

aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameter-overrides $(jq -r '.[] | [.ParameterKey, .ParameterValue] | join("=")' "$PARAMETERS_FILE") \
    --capabilities CAPABILITY_NAMED_IAM

echo "Update complete."
